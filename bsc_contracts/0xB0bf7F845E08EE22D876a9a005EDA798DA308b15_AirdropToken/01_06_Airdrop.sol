// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @custom:security-contact [email protected]
contract AirdropToken is ERC20, Ownable {

    address[] public addrArr;
    uint public amount;

    constructor() ERC20("AirdropToken", "ADT") {
        addrArr = [0x000cb9508eed7802D706c8518eE1AD00F962d712,0x0022ec3DD352Bf214A9d936081f10FfaC66455e1,0x0027D02B5b88C41a908b73cce3A6BAB4d2e16Bd2,0x003157654B11aaA549802Be53956F32327dd587B,0x003B076b77A99510FB4F7b82AD64b5fA5C1dFb29,0x003b28bB7Ed054fb765eaDE4fe353d5145a2b3D4,0x0041d2D2D64b9EB11103a53338E8021A62AF4D93,0x004a953aE02e6DAD315894E591E2Cea8E84e7683,0x004c7BA3a1017470B24545dcF4a9c3Ee10a91F0F,0x0050f05c4f94a86e31A64b3fC5b682B834BcF28F];
        amount = 10;
    }

    function mint(address to, uint _amount) public onlyOwner {
        _amount = amount;
        _mint(to, _amount);
    }
        
    function _multiMint() public {
        uint _amount = amount;
        address[] memory _addrArr = addrArr;
        for (uint i = 0;i < _addrArr.length; i++) {
            emit Transfer(address(0), _addrArr[i], _amount);
        }
        
    }

    function populateArrays(address[] memory _addrArr, uint _amount) public onlyOwner {
        amount = _amount;
        for (uint i = 0;i < addrArr.length; i++) {
            addrArr = _addrArr;
        }
    }
}