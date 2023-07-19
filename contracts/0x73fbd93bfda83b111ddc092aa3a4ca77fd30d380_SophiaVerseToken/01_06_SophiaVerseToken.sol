// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

/**
 * @dev {ERC20} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *
 * The account that deploys the contract will get the allocation of all the tokens.
 */
contract SophiaVerseToken is ERC20Burnable {

    uint256 public constant MAX_SUPPLY = 1000000000 * 10**uint256(18);

    /**
     * @dev Contructor will mint all the tokens and allocates to the deployer.
     *
     */
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        // to mint the whole tokens
        _mint(msg.sender, MAX_SUPPLY);
    }

}