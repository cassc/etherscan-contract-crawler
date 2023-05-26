// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

import "./TokenVesting.sol";

/// @title PreJPEG
/// @notice {JPEG} vesting contract, beneficiaries get {PreJPEG}, which can be burned linearly to unlock {JPEG}.
/// {PreJPEG} cannot be transferred.
contract PreJPEG is ERC20Votes, TokenVesting {

    /// @param _jpeg The token to vest
    constructor(address _jpeg)
        ERC20("preJPEG", "pJPEG")
        ERC20Permit("preJPEG")
        TokenVesting(_jpeg)
    {}

    /// @inheritdoc TokenVesting
    /// @notice Beneficiaries get an amount of {PreJPEG} equal to `totalAllocation`
    function vestTokens(
        address beneficiary,
        uint256 totalAllocation,
        uint256 start,
        uint256 cliffDuration,
        uint256 duration
    ) public virtual override {
        super.vestTokens(
            beneficiary,
            totalAllocation,
            start,
            cliffDuration,
            duration
        );

        _mint(beneficiary, totalAllocation);
    }

    /// @inheritdoc TokenVesting
    /// @notice The {PreJPEG} balance of `account` is burnt when calling this function
    function revoke(address account) public override {
        super.revoke(account);
        _burn(account, balanceOf(account));
    }

    /// @inheritdoc TokenVesting
    /// @notice An amount of {PreJPEG} equal to the amount of {JPEG} released is burnt from the sender's wallet when this function is called 
    function release() public override {
        uint256 balanceBeforeRelease = token.balanceOf(address(this));
        super.release();
        _burn(
            msg.sender,
            balanceBeforeRelease - token.balanceOf(address(this))
        );
    }

    /// @dev {PreJPEG} is not transferrable
    function _transfer(address, address, uint256) internal pure override {
        revert("Transfers are locked");
    }
}