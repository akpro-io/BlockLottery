pragma solidity ^0.8.0;
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

import { randomn_number_consumer_interface } from "./interfaces/randomn_number_consumer_interface.sol";
import { governance_interface } from "./interfaces/governance_interface.sol";

contract Lottery is ChainlinkClient {
    address owner;

    enum LOTTERY_STATE { OPEN, CLOSED, CALCULATING_WINNER }
    LOTTERY_STATE public lottery_state;
    uint128 public lotteryId;
    uint8 internal winningRatio = 0.9;

    address payable[] public players;
    mapping(address => uint8) bets;
    governance_interface public governance;

    // .01 ETH minimum for place a bet
    uint256 public MINIMUM = 1000000000000000;
    // 0.1 LINK to place requests with oracle
    uint256 public ORACLE_PAYMENT = 100000000000000000;

    address CHAINLINK_ALARM_ORACLE = 0xc99B3D447826532722E41bc36e644ba3479E4365;
    bytes32 CHAINLINK_ALARM_JOB_ID = "2ebb1c1a4b1e4229adac24ee0b5f784f";

    event LotteryStart();
    event LotteryWin(address indexed _winner);
    event LotteryClose();
    event LotteryPotUpdate(uint256 _amount);

    constructor(address _governance) public {
        setPublicChainlinkToken();

        owner = msg.sender;
        lotteryId = 1;
        lottery_state = LOTTERY_STATE.CLOSED;
        governance = governance_interface(_governance);
    }

    function enter(uint8 bet) public payable {
        require(msg.value == MINIMUM);
        require(bet > 0, "Bet can not be zero");
        assert(lottery_state == LOTTERY_STATE.OPEN);

        players.push(msg.sender);
        bets[msg.sender] = bet;

        emit LotteryPotUpdate(address(this).balance);
    }

    function start_new_lottery(uint256 duration) public {
        require(lottery_state == LOTTERY_STATE.CLOSED, "Can not start a new lottery yet");
        lottery_state = LOTTERY_STATE.OPEN;

        Chainlink.Request memory req = buildChainlinkRequest(CHAINLINK_ALARM_JOB_ID, address(this), this.fulfill_alarm.selector);
        req.addUint("until", now + duration);
        sendChainlinkRequestTo(CHAINLINK_ALARM_ORACLE, req, ORACLE_PAYMENT);

        emit LotteryStart();
    }

    function fulfill_alarm(bytes32 _requestId) public recordChainlinkFulfillment(_requestId) {
        require(lottery_state == LOTTERY_STATE.OPEN, "Lottery isn't started yet!");

        lottery_state = LOTTERY_STATE.CALCULATING_WINNER;
        pickWinner();
    }

    function pickWinner() private {
        require(lottery_state == LOTTERY_STATE.CALCULATING_WINNER, "We are not picking the winner yet.");
        randomn_number_consumer_interface(governance.randomness()).getRandom(lotteryId);
    }

    function fulfill_random(uint256 randomness) external {
        require(lottery_state == LOTTERY_STATE.CALCULATING_WINNER, "We are not picking the winner yet.");
        assert(randomness > 0, "Random not found");
        assert(msg.sender == governance.randomness());

        uint8 playersLen = players.length;
        uint256 winningBet = randomness % playersLen;
        address winner = address(0);

        for (uint ii = 0; ii < playersLen; ii++) {
            if(bets[players[ii]] == winningBet) {
                winner = players[ii];
                break;
            }
        }

        assert(winner != address(0), "No winner found.");

        if(winner == address(0)) {
            owner.transfer(address(this).balance);

            emit LotteryClose();
        } else {
            // transfer winning amount to winner and commission to contract owner
            winner.transfer(address(this).balance * winningRatio);
            owner.transfer(address (this).balance * (1 - winningRatio));

            emit LotteryWin(winner);
        }

        // close the lottery
        lottery_state = LOTTERY_STATE.CLOSED;

        // restart the lottery if there is sufficient LINK balance in the contract
        /*if(LINK.balanceOf(this) > 2 * ORACLE_PAYMENT) {
            start_new_lottery();
        }*/
    }

    function get_pot() public view returns(uint256) {
        return address(this).balance;
    }
}
