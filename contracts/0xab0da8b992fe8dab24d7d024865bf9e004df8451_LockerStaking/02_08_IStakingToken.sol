// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ILockerToken.sol";

interface IStakingToken is ILockerToken {
    function burnFrom(address account_, uint256 amount_) external;
}