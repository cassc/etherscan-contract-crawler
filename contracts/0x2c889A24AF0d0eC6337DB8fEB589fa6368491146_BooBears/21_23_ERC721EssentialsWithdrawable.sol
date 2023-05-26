// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/* External Imports */
import {AccessControl} from "AccessControl.sol";
import {ERC721} from "ERC721.sol";
import {ERC721Enumerable} from "ERC721Enumerable.sol";
import {ReentrancyGuard} from "ReentrancyGuard.sol";
import {Strings} from "Strings.sol";

/* Internal Imports */
import {ERC721Essentials} from "ERC721Essentials.sol";
import {Constants} from "Constants.sol";

//=====================================================================================================================
/// 😎 Free Internet Money 😎
//=====================================================================================================================

contract ERC721EssentialsWithdrawable is ERC721Essentials {
    using Strings for string;

    //=================================================================================================================
    /// Constructor
    //=================================================================================================================

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        uint256[] memory uintArgs_,
        bool publicMintingEnabled_
    ) ERC721Essentials(name_, symbol_, baseURI_, uintArgs_, publicMintingEnabled_) {
        return;
    }

    //=================================================================================================================
    /// Finance
    //=================================================================================================================

    /**
     * @dev Public function that pulls a set amount of Ether from the contract. Only callable by contract admins.
     * @param amount uint256: The amount of wei to withdraw from the contract.
     */
    function withdraw(uint256 amount) public nonReentrant onlyRole(DEFAULT_ADMIN_ROLE) {
        payable(msg.sender).transfer(amount);
    }

    /**
     * @dev Public function that pulls the entire balance of Ether from the contract. Only callable by contract admins.
     */
    function withdrawAll() public nonReentrant onlyRole(DEFAULT_ADMIN_ROLE) {
        payable(msg.sender).transfer(address(this).balance);
    }
}