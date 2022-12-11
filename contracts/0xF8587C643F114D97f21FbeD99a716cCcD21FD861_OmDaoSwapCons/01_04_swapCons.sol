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

contract OmDaoSwapCons is Ownable {
    address public addrOMD;
    address public addromdwCons;
    address public addrSafe;
    uint256 public PriceomdwCons;

    constructor() {
      addrOMD = address(0xA4282798c2199a1C58843088297265acD748168c);
      addromdwCons = address(0x967525A2030d6Ac7a0cBf0cb630107D8720A52Ef);
    }

    function setAddressOMD(address _addrOMD) external onlyOwner{
        require(_addrOMD != address(0), "ERC20: contract is the zero address");
        addrOMD = _addrOMD;
    }

    function setAddressSafe(address _addrSafe) external onlyOwner{
        addrSafe = _addrSafe;
    }

    function setAddromdwCons(address _addromdwCons) external onlyOwner{
        addromdwCons = _addromdwCons;
    }

    function setPriceomdwCons(uint256 _priceomdwCons) external onlyOwner{
        PriceomdwCons = _priceomdwCons;
    }

    function buyToken(uint256 _amount) external{
        require(PriceomdwCons > 0,"PriceomdwCons must be greater than 0. Sales round not active");
        require(_amount >= 1 * 10**6,"Amount must be greater than or equal to 1 OMD.");
        IERC20 omd = IERC20(addrOMD);
        if (addrSafe == address(0)) addrSafe = owner();
        (bool success1) = omd.transferFrom(msg.sender, addrSafe, _amount);
        require(success1,"Transfer failed! Please approve amount OMD for this contract.");
        IERC20 omdwCons = IERC20(addromdwCons);
        (bool success2) = omdwCons.transfer(msg.sender, _amount * 10**6 / PriceomdwCons);
        require(success2,"Transfer failed! No more tokens omdwCons for sale.");
    }

    function withdrawToken(address _tokenContract, uint256 _amount) external onlyOwner{
        require(_tokenContract != address(0), "ERC20: contract is the zero address");
        IERC20 tokenContract = IERC20(_tokenContract);
        tokenContract.transfer(msg.sender, _amount);
    }
}