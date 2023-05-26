// DELTA-BUG-BOUNTY
pragma abicoder v2;
pragma solidity ^0.7.6;

import "./../../../common/OVLTokenTypes.sol";

contract OVLBase {
    // Shared state begin v0
    mapping (address => VestingTransaction[QTY_EPOCHS]) public vestingTransactions;
    mapping (address => UserInformation) internal _userInformation;
    
    mapping (address => uint256) internal _maxPossibleBalances;
    mapping (address => mapping (address => uint256)) internal _allowances;

    address public distributor;
    uint256 public lpTokensInPair;
    bool public liquidityRebasingPermitted;

    uint256 [72] private _gap;
    // Shared state end of v0
}