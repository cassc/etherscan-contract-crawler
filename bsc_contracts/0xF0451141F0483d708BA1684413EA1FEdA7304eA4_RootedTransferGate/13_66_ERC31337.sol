// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.4;

import "./SafeERC20.sol";

import "./IERC20.sol";
import "./IERC31337.sol";
import "./IFloorCalculator.sol";

import "./WrappedERC20.sol";

contract ERC31337 is WrappedERC20, IERC31337 {
    using SafeERC20 for IERC20;

    IFloorCalculator public override floorCalculator;
    
    mapping (address => bool) public override sweepers;

    constructor(IERC20 _wrappedToken, string memory _name, string memory _symbol) WrappedERC20(_wrappedToken, _name, _symbol) {}

    function setFloorCalculator(IFloorCalculator _floorCalculator) public override ownerOnly() {
        floorCalculator = _floorCalculator;
    }

    function setSweeper(address sweeper, bool allow) public override ownerOnly() {
        sweepers[sweeper] = allow;
    }

    function sweepFloor(address to) public override returns (uint256 amountSwept) {
        require (to != address(0));
        require (sweepers[msg.sender], "Sweepers only");
        amountSwept = floorCalculator.calculateSubFloor(wrappedToken, this);
        if (amountSwept > 0) {
            wrappedToken.safeTransfer(to, amountSwept);
        }
    }
}