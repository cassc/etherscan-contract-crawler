// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

interface IOasisVault {
    event ChainTokenWithdrawed(uint256 amount);

    event ERC20Withdrawed(address tokenAddress, uint256 amount);

    function changeReceiver(address _receiver) external;

    function withdrawChainToken(uint256 _amount) external;

    function withdrawERC20Token(address _tokenAddress, uint256 _amount)
        external;
}