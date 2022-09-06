// SPDX-License-Identifier: Apache License 2.0

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract CoordinationTokenMock is ERC20 {
    constructor(
        string memory _tokenName,
        string memory _tokenSymbol
    )
    ERC20(
        _tokenName,
        _tokenSymbol
    )
    {}

    function mint(address account, uint256 value) public{
        _mint(account, value);
    }


    function burn(address account, uint256 value) public{
        _burn(account, value);
    }
}