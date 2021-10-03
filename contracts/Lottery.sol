// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";

contract Oracle {
    function getRandomNumber() external view returns (uint256) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
    }
}

contract Lottery is Ownable {
    Oracle private oracle;
    enum LOTTERY_STATE { CLOSED, OPEN, CALCULATING_WINNER }
    LOTTERY_STATE public lottery_state;
    uint256 public lottery_duration = 300000; // time in ms. Can be used by FE for clock purposes.
    uint256 public last_started_at;

    address payable[] public players;
    mapping(address => uint256) bets;

    uint256 public MINIMUM = 1000000000000000;

    event LotteryStart(uint256 _duration);
    event LotteryPotUpdate(uint256 _amount);
    event LotteryClose();
    event LotteryWin(address indexed _winner);

    modifier atStage(LOTTERY_STATE _state) {
        require(_state == lottery_state, "Can not be called at this time.");
        _;
    }

    modifier atMinimumValue() {
        require(msg.value >= MINIMUM, "Need minimum 0.01ETH.");
        _;
    }

    constructor() {
        lottery_state = LOTTERY_STATE.CLOSED;
        oracle = new Oracle();
    }

    // starting the lottery here
    function start_lottery() public onlyOwner atStage(LOTTERY_STATE.CLOSED) {
        lottery_state = LOTTERY_STATE.OPEN;
        last_started_at = block.timestamp;
        emit LotteryStart(lottery_duration);
    }

    // get the current pot amount
    function get_pot() public view returns(uint256) {
        return address(this).balance;
    }

    function enter(uint256 _bet) public payable atMinimumValue atStage(LOTTERY_STATE.OPEN) {
        players.push(payable(msg.sender));
        bets[msg.sender] = _bet;

        emit LotteryPotUpdate(get_pot());
    }

    function close_lottery() public onlyOwner atStage(LOTTERY_STATE.OPEN) {
        lottery_state = LOTTERY_STATE.CLOSED;
        emit LotteryClose();

        if(players.length > 0) {
            pickWinner();
        }
    }

    function pickWinner() private {
        uint randomNumber = oracle.getRandomNumber();
        uint256 totalPlayers = players.length;

        uint winningBet = randomNumber % totalPlayers;
        address payable winner;

        uint256 ii = 0;

        for(ii = 0; ii < totalPlayers; ii++) {
            if(bets[players[ii]] == winningBet) {
                winner = players[ii];
                break;
            }
        }

        if(winner == address(0)) {
            // payable(owner).transfer(address(this).balance);
        } else {
            winner.transfer((address(this).balance * 9) / 10);
            // owner.transfer(address(this).balance / 10);
        }

        emit LotteryWin(winner);
    }
}
