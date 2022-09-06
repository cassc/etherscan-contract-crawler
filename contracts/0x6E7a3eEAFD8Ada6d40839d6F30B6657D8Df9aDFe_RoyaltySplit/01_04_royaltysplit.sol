// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RoyaltySplit is Ownable {
    receive() external payable {}

    function getToken() external payable {}

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;

        payable(0x672313cFFBbD435C16c741adc9D2e5A2AA013622).transfer((balance * 0.50 ether) / 1 ether); // 50%
        payable(0xAd33b98015eE6Cca65f55317f567Ed865BDd4959).transfer((balance * 0.50 ether) / 1 ether); // 50%
    }

    function withdrawERC20(IERC20 _erc20) external onlyOwner {
        uint256 balance = _erc20.balanceOf(address(this));

        _erc20.transfer(0x672313cFFBbD435C16c741adc9D2e5A2AA013622, (balance * 0.50 ether) / 1 ether); //  50%
        _erc20.transfer(0xAd33b98015eE6Cca65f55317f567Ed865BDd4959, (balance * 0.50 ether) / 1 ether); //  50%
    }
}