/// SPDX-License-Identifier: GNU Affero General Public License v3.0

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title MochiToken
 * @author Liqhtworks LLC
 * @notice Mochi Token Contract
 */
contract MochiToken is ERC20, Ownable {
    using Address for address;

    constructor(string memory name, string memory symbol, address reserve, uint256 initialSupply) ERC20(name, symbol) {
        // mint an initial supply of tokens to hold in reserve
        _mint(reserve, initialSupply);
    }

    /**
     * @notice Mint additional tokens if the initial supply isn't sufficient
     * @param amount the amount of new tokens to be distributed
     * @param recipient the receiver of new tokens minted
     */
    function mint(uint256 amount, address recipient) public onlyOwner {
        _mint(recipient, amount);
    }
}