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
 * @title WoW Drips
 * @author WoW Studio LTD
 */
contract WoWDrips is ERC1155, ERC1155Burnable, Ownable {
    mapping(uint256 => bool) private _migrationActivePerToken;
    mapping(uint256 => bool) private _lockedTokens;
    mapping(uint256 => address) private _authorizedContracts;

    constructor(string memory uri_) ERC1155(uri_) {} // solhint-disable-line

    function authorizedContract(uint256 index) public view returns (address) {
        return _authorizedContracts[index];
    }

    /**
     * @notice Mint and send different amounts of tokenId to different receivers
     * @param tokenId The token id of the merch item we airdrop
     * @param amount The amount of tokens per dropAddress we airdrop
     * @param dropAddresses An array of receivers
     */
    function mint(
        uint256 tokenId,
        uint256[] calldata amount,
        address[] calldata dropAddresses
    ) external onlyOwner {
        require(!_lockedTokens[tokenId], "Token locked");

        for (uint256 i = 0; i < dropAddresses.length; i++) {
            _mint(dropAddresses[i], tokenId, amount[i], "");
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
     * @notice Define which contract to use when migrating a specific tokenId
     * @param tokenId The token id of the merch item we want to burn/create an interaction with
     * @param contractAddress The contract address we'll use to call the mintTranfer
     */
    function setAuthorizedContractForToken(uint256 tokenId, address contractAddress)
        external
        onlyOwner
    {
        _authorizedContracts[tokenId] = contractAddress;
    }

    /**
     * @notice Enable migration to an other contract for a given token id
     * @param tokenId The token id of the merch item we want to burn/create an interaction with
     */
    function toggleMigrationForToken(uint256 tokenId) external onlyOwner {
        require(_authorizedContracts[tokenId] != address(0), "Authorized Contract not set");
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

        MigrateTokenContract migrationContract = MigrateTokenContract(
            _authorizedContracts[tokenId]
        );
        migrationContract.mintTransfer(msg.sender, tokenId, amount); // Mint ... What?
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