// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @custom:security-contact [email protected]
contract AirdropToken is ERC20, Ownable {
    constructor() ERC20("AirdropToken", "ADT") {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function airdropMint(address[] memory addrArr, uint256[] memory amountArr) public onlyOwner {
        for (uint256 i = 0;i < addrArr.length; i++) {
            _mint(addrArr[i], amountArr[i] * 10 ** decimals());
        }
    }
}