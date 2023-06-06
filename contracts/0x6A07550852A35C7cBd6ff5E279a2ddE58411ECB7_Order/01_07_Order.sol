// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Order is Ownable, ReentrancyGuard {
    uint256 public NativePrice = 0.01 ether;
    uint256 public USDTPrice = 20 * 10 ** 6;
    address public USDTAddress = 0x288Ba1D112e8AbFfB54165fA9667073EA4EF12B1;

    event OrderByNative(address player, uint256 amount, string indexed verify);
    event OrderByUSDT(address player, uint256 amount, string indexed verify);

    function buyNative(string calldata verify) nonReentrant payable external {
        require(msg.value >= NativePrice, "Not enough Native currency");
        require(bytes(verify).length > 0, "Verify not empty");
        emit OrderByNative(msg.sender, msg.value, verify);
    }

    function buyUSDT(uint256 amount, string calldata verify) nonReentrant external {
        require(amount >= USDTPrice, "Not enough USDT");
        require(bytes(verify).length > 0, "Verify not empty");
        IERC20 usdt = IERC20(USDTAddress);
        usdt.transferFrom(msg.sender, address(this), amount);
        emit OrderByUSDT(msg.sender, amount, verify);
    }

    function setNativePrice(uint256 newPrice) onlyOwner external {
        NativePrice = newPrice;
    }

    function setUSDTPrice(uint256 newPrice) onlyOwner external {
        USDTPrice = newPrice;
    }


    function setUSDTAddress(address newAddress) onlyOwner external {
        USDTAddress = newAddress;
    }

    function withdraw() onlyOwner external  nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function withdrawTokens(address _token, uint256 _amount) onlyOwner external nonReentrant {
        IERC20 token = IERC20(_token);
        token.transfer(msg.sender, _amount);
    }
}