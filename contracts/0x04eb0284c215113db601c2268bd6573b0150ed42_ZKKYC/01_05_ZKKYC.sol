// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ZKKYC is ERC20 {

    constructor(address minter) ERC20("Zero-knowledge Know Your Customers", "ZK-KYC") {
        uint256 totalSupply = 1000000000 * 1e18;
        _mint(minter, totalSupply);
    }

}