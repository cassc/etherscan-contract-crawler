// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

import "../../interfaces/ITokenStaking.sol";

import "../Staking.sol";

contract TokenStaking is Staking, ITokenStaking {

    // address of the erc20 token
    IERC20 internal _erc20Token;
    // reserve some gap for the future upgrades
    uint256[100 - 2] private __reserved;

    function __TokenStaking_init(IStakingConfig chainConfig, IERC20 erc20Token) internal {
        _stakingConfig = chainConfig;
        _erc20Token = erc20Token;
    }

    function getErc20Token() external view override returns (IERC20) {
        return _erc20Token;
    }

    function delegate(address validatorAddress, uint256 amount) payable external override {
        require(_erc20Token.transferFrom(msg.sender, address(this), amount), "failed to transfer");
        _delegateTo(msg.sender, validatorAddress, amount);
    }

    function distributeRewards(address validatorAddress, uint256 amount) external override {
        require(_erc20Token.transferFrom(msg.sender, address(this), amount), "failed to transfer");
        _depositFee(validatorAddress, amount);
    }

    function _safeTransferWithGasLimit(address payable recipient, uint256 amount) internal override {
        require(_erc20Token.transfer(recipient, amount), "failed to safe transfer");
    }

    function _unsafeTransfer(address payable recipient, uint256 amount) internal override {
        require(_erc20Token.transfer(recipient, amount), "failed to safe transfer");
    }
}