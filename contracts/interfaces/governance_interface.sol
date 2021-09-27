// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface governance_interface {
    function lottery() external view returns (address);
    function randomness() external view returns (address);
}
