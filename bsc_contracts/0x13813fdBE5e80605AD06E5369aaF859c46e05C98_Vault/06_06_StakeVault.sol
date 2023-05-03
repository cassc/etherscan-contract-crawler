// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IVault.sol";

contract Vault is Ownable, IVault {

    function safeTransfer(IERC20 from, address to, uint amount) external override onlyOwner {
        from.transfer(to, amount);
    }

    function safeTransfer(address _to, uint _value) external override onlyOwner {
        payable(_to).transfer(_value);
    }

    function getTokenAddressBalance(address token) external view override returns (uint) {
        return IERC20(token).balanceOf(address(this));
    }

    function getTokenBalance(IERC20 token) external view override returns (uint) {
        return token.balanceOf(address(this));
    }

    function getBalance() external view override returns (uint) {
        return address(this).balance;
    }

}