pragma solidity ^0.6.6;

contract Governance {
    uint256 public one_time;
    address public lottery;
    address randomness;

    constructor() public {
        one_time = 1;
    }

    function init(address _lottery, address _randomness) public {
        require(_lottery != address(0), "Lottery address is required");
        require(_randomness != address(0), "Randomness address is required");
        require(one_time > 0, "Can be called only once");

        one_time = one_time - 1;
        randomness = _randomness;
        lottery = _lottery;
    }
}
