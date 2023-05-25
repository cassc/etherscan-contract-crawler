// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

import "@animoca/ethereum-contracts-assets/contracts/token/ERC20/ERC20.sol";

/**
 * @title DOSE
 */
contract DOSE is ERC20 {
    constructor(
        address[] memory recipients,
        uint256[] memory values,
        string memory tokenURI_
    ) ERC20("DOSE", "DOSE", 18, tokenURI_) {
        _batchMint(recipients, values);
    }
}