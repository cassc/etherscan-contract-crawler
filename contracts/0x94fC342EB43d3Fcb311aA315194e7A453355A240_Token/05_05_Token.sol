// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20 {
    constructor(address[] memory _minterAddresses, uint256[] memory _tokenAmount) ERC20("Methereum", "METH") {
        uint256 _minterAddressesLength = _minterAddresses.length;
        uint256 _tokenAmountLength = _tokenAmount.length;
        require(_minterAddressesLength == _tokenAmountLength, "Minter Addresses and Token Amount arrays need to have the same size.");

        for (uint256 i = 0; i < _minterAddressesLength;) {
            _mint(_minterAddresses[i], _tokenAmount[i] * 10**uint(decimals()));
            unchecked { ++i; }
        }
    }
}