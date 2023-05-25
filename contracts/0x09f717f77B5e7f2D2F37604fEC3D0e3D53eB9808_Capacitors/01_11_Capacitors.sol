// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract MigrateTokenContract {
    function mintTransfer(
        address to,
        uint256 tokenId,
        uint256 amount
    ) external virtual;
}

/**
 * @title Capacitors
 * @author WoW Studio LTD
 */
contract Capacitors is ERC1155, ERC1155Burnable, Ownable {
    mapping(uint256 => bool) private _migrationActivePerToken;
    mapping(uint256 => bool) private _lockedTokens;
    address private _externalContract1;
    address private _externalContract2;

    constructor(string memory uri_) ERC1155(uri_) {} // solhint-disable-line

    function externalContract1() public view returns (address) {
        return _externalContract1;
    }

    function externalContract2() public view returns (address) {
        return _externalContract2;
    }

    /**
     * @notice Mint and send different amounts of tokenId to different receivers
     * @param tokenId The token id of the merch item we airdrop
     * @param amounts Amounts of tokens per dropAddress we airdrop
     * @param dropAddresses An array of receivers
     */
    function mint(
        uint256 tokenId,
        uint256[] calldata amounts,
        address[] calldata dropAddresses
    ) external onlyOwner {
        require(!_lockedTokens[tokenId], "Token locked");

        for (uint256 i = 0; i < dropAddresses.length; i++) {
            _mint(dropAddresses[i], tokenId, amounts[i], "");
        }
    }

    /**
     * @notice Set the _uri parameter
     * @param newuri A global uri for all the tokens Following EIP-1155, should contain `{id}`
     */
    function setURI(string memory newuri) external onlyOwner {
        _setURI(newuri);
    }

    /**
     * @notice Set the authorizedContract parameter
     * @param externalContract1_ The authorized contract address
     */
    function setExternalContract1(address externalContract1_) external onlyOwner {
        _externalContract1 = externalContract1_;
    }

    /**
     * @notice Set the authorizedContract parameter
     * @param externalContract2_ The authorized contract address
     */
    function setExternalContract2(address externalContract2_) external onlyOwner {
        _externalContract2 = externalContract2_;
    }

    /**
     * @notice Enable migration to an other contract for a given token id
     * @param tokenId The token id of the merch item we want to burn/create an interaction with
     */
    function toggleMigrationForToken(uint256 tokenId) external onlyOwner {
        require(_externalContract1 != address(0), "External contract 1 not set");
        require(_externalContract2 != address(0), "External contract 2 not set");
        _migrationActivePerToken[tokenId] = !_migrationActivePerToken[tokenId];
    }

    /**
     * @notice Used to lock a token id. Once locked, it's no longer possible to create more of this token
     * @param tokenId The token id of the merch item we want to lock
     */
    function lockToken(uint256 tokenId) external onlyOwner {
        require(!_lockedTokens[tokenId], "Token already locked");
        _lockedTokens[tokenId] = true;
    }

    /**
     * @notice Migrate an amount of tokenId using the defined authorized contract
     * @param tokenId The token id of the merch item we want to migrate
     * @param amount The amount we want to migrate
     */
    function migrateTokens(uint256 tokenId, uint256 amount) external {
        require(_migrationActivePerToken[tokenId], "Migration is not active");
        require(balanceOf(msg.sender, tokenId) >= amount, "Doesn't own that amount of token");

        burn(msg.sender, tokenId, amount); // Burn

        MigrateTokenContract migrationContract1 = MigrateTokenContract(_externalContract1);
        migrationContract1.mintTransfer(msg.sender, tokenId, amount);

        MigrateTokenContract migrationContract2 = MigrateTokenContract(_externalContract2);
        migrationContract2.mintTransfer(msg.sender, tokenId, amount);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155)
        returns (bool)
    {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}