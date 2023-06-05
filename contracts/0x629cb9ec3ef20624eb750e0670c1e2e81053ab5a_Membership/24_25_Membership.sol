// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// interfaces
import {IMembership} from "./IMembership.sol";
import {ITokenGuard} from "src/lib/guard/ITokenGuard.sol";
import {IRenderer} from "../lib/renderer/IRenderer.sol";
// contracts
import {UUPSUpgradeable} from "openzeppelin-contracts/proxy/utils/UUPSUpgradeable.sol";
import {ERC721Upgradeable} from "openzeppelin-contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {Permissions} from "../lib/Permissions.sol";
import {Batch} from "../lib/Batch.sol";
import {MembershipStorageV0} from "./storage/MembershipStorageV0.sol";

contract Membership is IMembership, UUPSUpgradeable, ERC721Upgradeable, Permissions, Batch, MembershipStorageV0 {
    constructor() {}

    /// @notice Initializes the ERC721 token.
    /// @param newOwner The address to transfer ownership to.
    /// @param newRenderer The address of the renderer.
    /// @param newName The name of the token.
    /// @param newSymbol The symbol of the token.
    function init(address newOwner, address newRenderer, string calldata newName, string calldata newSymbol)
        public
        initializer
    {
        _transferOwnership(newOwner);
        _updateRenderer(newRenderer);
        __ERC721_init(newName, newSymbol);
    }

    function _authorizeUpgrade(address newImplementation) internal override permitted(Operation.UPGRADE) {}

    function updateRenderer(address newRenderer) external permitted(Operation.RENDER) returns (bool success) {
        _updateRenderer(newRenderer);
        return true;
    }

    function _updateRenderer(address newRenderer) internal {
        renderer = newRenderer;
        emit UpdatedRenderer(newRenderer);
    }

    function updatePaymentCollector(address newPaymentCollector)
        external
        permitted(Operation.UPGRADE)
        returns (bool success)
    {
        paymentCollector = newPaymentCollector;
        emit UpdatedPaymentCollector(newPaymentCollector);
        return true;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        return IRenderer(renderer).tokenURI(id);
    }

    function mintTo(address recipient) external permitted(Operation.MINT) returns (uint256 tokenId) {
        tokenId = ++totalSupply;
        _safeMint(recipient, tokenId);
        return tokenId;
    }

    function burnFrom(uint256 tokenId) external permitted(Operation.BURN) returns (bool success) {
        _burn(tokenId);
        return true;
    }

    function burn(uint256 tokenId) external returns (bool success) {
        require(msg.sender == ownerOf(tokenId));
        _burn(tokenId);
        return true;
    }

    function _afterTokenTransfer(address from, address to, uint256 tokenId, uint256) internal override {
        address guard;
        // MINT
        if (from == address(0)) {
            guard = guardOf[Operation.MINT];
        }
        // BURN
        else if (to == address(0)) {
            guard = guardOf[Operation.BURN];
        }
        // TRANSFER
        else {
            guard = guardOf[Operation.TRANSFER];
        }

        require(
            guard != MAX_ADDRESS && (guard == address(0) || ITokenGuard(guard).isAllowed(msg.sender, from, to, tokenId)),
            "NOT_ALLOWED"
        );
    }
}