// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC20Burnable {
    function burn(uint256 amount) external returns (bool);
    function burnFrom(address account, uint256 amount) external returns (bool);
}

interface IERC20Decimals {
    function decimals() external returns (uint8);
}

contract OmDaoSwapTigr is Ownable {
    address public addrOMD;
    address public addromdwTigr;
    address public addrTigr;
    address public addrSafe;
    uint256 public PriceomdwTigr;

    constructor() {
      addrOMD = address(0xA4282798c2199a1C58843088297265acD748168c);
      addromdwTigr = address(0x9a4d39F46044400Aa48Ab528f8EC3DD3B793f885);
    }

    function setAddressOMD(address _addrOMD) external onlyOwner{
        require(_addrOMD != address(0), "ERC20: contract is the zero address");
        addrOMD = _addrOMD;
    }

    function setAddressTigr(address _addrTigr) external onlyOwner{
        addrTigr = _addrTigr;
    }

    function setAddressSafe(address _addrSafe) external onlyOwner{
        addrSafe = _addrSafe;
    }

    function setAddromdwTigr(address _addromdwTigr) external onlyOwner{
        addromdwTigr = _addromdwTigr;
    }

    function setPriceomdwTigr(uint256 _priceomdwTigr) external onlyOwner{
        PriceomdwTigr = _priceomdwTigr;
    }

    function buyToken(uint256 _amount) external{
        require(PriceomdwTigr > 0,"PriceomdwTigr must be greater than 0. Sales round not active");
        require(_amount >= 1 * 10**6,"Amount must be greater than or equal to 1 OMD.");
        IERC20 omd = IERC20(addrOMD);
        if (addrSafe == address(0)) addrSafe = owner();
        (bool success1) = omd.transferFrom(msg.sender, addrSafe, _amount);
        require(success1,"Transfer failed! Please approve amount OMD for this contract.");
        IERC20 omdwTigr = IERC20(addromdwTigr);
        (bool success2) = omdwTigr.transfer(msg.sender, _amount * 10**6 / PriceomdwTigr);
        require(success2,"Transfer failed! No more tokens omdwTigr for sale.");
    }

    function swapToken(uint256 _amount) external{
        require(addrTigr != address(0),"Too early, no Tigr tokens yet.");
        require(_amount >= 1 * 10**6,"Amount must be greater than or equal to 1 token.");
        IERC20Burnable omdwTigr = IERC20Burnable(addromdwTigr);
        (bool success1) = omdwTigr.burnFrom(msg.sender, _amount);
        require(success1,"Transfer failed! Please approve amount omdwTigr for this contract.");
        IERC20 Tigr = IERC20(addrTigr);
        IERC20Decimals TigrDecimals = IERC20Decimals(addrTigr);
        uint8 tigrDecimal = TigrDecimals.decimals();
        (bool success2) = Tigr.transfer(msg.sender, _amount * 10**tigrDecimal / 10**6);
        require(success2,"Transfer failed! No more tokens Tigr on this contract.");
    }

    function withdrawToken(address _tokenContract, uint256 _amount) external onlyOwner{
        require(_tokenContract != address(0), "ERC20: contract is the zero address");
        IERC20 tokenContract = IERC20(_tokenContract);
        tokenContract.transfer(msg.sender, _amount);
    }
}