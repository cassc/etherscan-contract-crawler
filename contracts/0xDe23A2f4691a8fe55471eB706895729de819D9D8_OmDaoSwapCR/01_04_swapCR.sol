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

contract OmDaoSwapCR is Ownable {
    address public addrOMD;
    address public addromdwCR;
    address public addrSafe;
    uint256 public PriceomdwCR;

    constructor() {
      addrOMD = address(0xA4282798c2199a1C58843088297265acD748168c);
      addromdwCR = address(0x178825587FC1A7D5D6373221182290a7A4566a0A);
    }

    function setAddressOMD(address _addrOMD) external onlyOwner{
        require(_addrOMD != address(0), "ERC20: contract is the zero address");
        addrOMD = _addrOMD;
    }

    function setAddressSafe(address _addrSafe) external onlyOwner{
        addrSafe = _addrSafe;
    }

    function setAddromdwCR(address _addromdwCR) external onlyOwner{
        addromdwCR = _addromdwCR;
    }

    function setPriceomdwCR(uint256 _priceomdwCR) external onlyOwner{
        PriceomdwCR = _priceomdwCR;
    }

    function buyToken(uint256 _amount) external{
        require(PriceomdwCR > 0,"PriceomdwCR must be greater than 0. Sales round not active");
        require(_amount >= 1 * 10**6,"Amount must be greater than or equal to 1 OMD.");
        IERC20 omd = IERC20(addrOMD);
        if (addrSafe == address(0)) addrSafe = owner();
        (bool success1) = omd.transferFrom(msg.sender, addrSafe, _amount);
        require(success1,"Transfer failed! Please approve amount OMD for this contract.");
        IERC20 omdwCR = IERC20(addromdwCR);
        (bool success2) = omdwCR.transfer(msg.sender, _amount * 10**6 / PriceomdwCR);
        require(success2,"Transfer failed! No more tokens omdwCR for sale.");
    }

    function withdrawToken(address _tokenContract, uint256 _amount) external onlyOwner{
        require(_tokenContract != address(0), "ERC20: contract is the zero address");
        IERC20 tokenContract = IERC20(_tokenContract);
        tokenContract.transfer(msg.sender, _amount);
    }
}