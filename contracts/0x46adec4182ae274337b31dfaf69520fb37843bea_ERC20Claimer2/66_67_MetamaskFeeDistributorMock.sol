// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import '../interfaces/IMetamaskFeeDistributor.sol';

contract MetamaskFeeDistributorMock is IMetamaskFeeDistributor {
    function available(address token, address) public view override returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    function withdraw(address[] memory tokens) external override {
        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20(tokens[i]).transfer(msg.sender, available(tokens[i], msg.sender));
        }
    }
}