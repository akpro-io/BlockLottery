pragma solidity ^0.8.0;
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

import { lottery_interface } from "./interfaces/lottery_interface.sol";
import { governance_interface } from "./interfaces/governance_interface.sol";

contract RandomNumberConsumer is VRFConsumerBase {
    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 public randomNumber;
    governance_interface public governance;

    constructor(address _governance) VRFConsumerBase(
        0xf720CF1B963e0e7bE9F58fd471EFa67e7bF00cfb,
        0x20fE562d797A42Dcb3399062AE9546cd06f63280
    ) public {
        keyHash = 0xced103054e349b8dfb51352f0f8fa9b5d20dde3d06f9f43cb2b85bc64b238205;
        fee = 0.1 * 10 ** 18;
        governance = governance_interface(_governance);
    }

    function getRandom(uint256 userProvidedSeed) public {
        require(LINK.balanceOf(address(this)) > fee, "Need enough LINK tokens.");
        requestRandomness(keyHash, fee, userProvidedSeed);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) external override {
        require(msg.sender == vrfCoordinator, "Fulillment only permitted by Coordinator");
        randomNumber = randomness;
        lottery_interface(governance.lottery()).fulfill_random(randomness);
    }
}
