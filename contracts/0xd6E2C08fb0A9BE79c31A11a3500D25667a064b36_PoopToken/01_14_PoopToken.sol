// SPDX-License-Identifier: GPL-3.0

/// @title The Nouns ERC-721 token

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import { IPoopToken } from './interfaces/IPoopToken.sol';
import { IERC1155 } from '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import { ERC1155 } from '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import { IProxyRegistry } from './external/opensea/IProxyRegistry.sol';

contract PoopToken is IPoopToken, Ownable, ERC1155 {
    string public name = "Lil Goblin Poop";

    // The lilnounders DAO address (creators org)
    address public lilgoblinkings;

    // An address who has permissions to mint Poops
    address public minter;

    // Whether the minter can be updated
    bool public isMinterLocked;

    // OpenSea's Proxy Registry
    IProxyRegistry public immutable proxyRegistry;

    /**
     * @notice Require that the sender is the lil nounders DAO.
     */
    modifier onlyLilGoblinKings() {
        require(msg.sender == lilgoblinkings, 'Sender is not the lil nounders DAO');
        _;
    }

    /**
     * @notice Require that the sender is the minter.
     */
    modifier onlyMinter() {
        require(msg.sender == minter, 'Sender is not the minter');
        _;
    }

    /**
     * @notice Require that the minter has not been locked.
     */
    modifier whenMinterNotLocked() {
        require(!isMinterLocked, 'Minter is locked');
        _;
    }

    constructor(
        address _lilgoblinkings,
        address _minter,
        IProxyRegistry _proxyRegistry
    ) ERC1155("ipfs://bafkreifxwpllpcgjq75evqoi4z6dnhqhnt4i22zl5wp5qct347oeqxqevm") {
        lilgoblinkings = _lilgoblinkings;
        minter = _minter;
        proxyRegistry = _proxyRegistry;
    }

    /**
     * @notice Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator) public view override(IERC1155, ERC1155) returns (bool) {
        // Whitelist OpenSea proxy contract for easy trading.
        if (proxyRegistry.proxies(owner) == operator) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }
    
    // Mint tokens. Assign directly to _to[].
    function mint(address to, uint256 amount) public override onlyMinter{
        _mint(to, 1, amount, "");
    }

    // Burn tokens. Assign directly to _to[].
    function burn(address from, uint256 amount) public override onlyMinter{
        _burn(from, 1, amount);
    }

    /**
     * @notice Set the token minter.
     * @dev Only callable by the owner when not locked.
     */
    function setMinter(address _minter) external override onlyOwner whenMinterNotLocked {
        minter = _minter;

        emit MinterUpdated(_minter);
    }
    
    /**
     * @notice Lock the minter.
     * @dev This cannot be reversed and is only callable by the owner when not locked.
     */
    function lockMinter() external override onlyOwner whenMinterNotLocked {
        isMinterLocked = true;

        emit MinterLocked();
    }

    /**
     * @notice Set the lil nounders DAO.
     * @dev Only callable by the lilnounders DAO when not locked.
     */
    function setLilGoblinKings(address _lilgoblinkings) external override onlyLilGoblinKings {
        lilgoblinkings = _lilgoblinkings;

        emit LilGoblinKingsUpdated(_lilgoblinkings);
    }
}