pragma solidity 0.8.0;

interface randomn_number_consumer_interface {
    function randomNumber(uint) external view returns (uint);
    function getRandom(uint) external;
}
