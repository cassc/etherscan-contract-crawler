// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";

import "../common/interfaces/IVaultKey.sol";

contract VaultKey is IVaultKey, ERC721PresetMinterPauserAutoId {
    uint256 public vaultKeyTransferLastBlock;

    event VaultKeyTransfer(uint256 previousBlock, address from, address indexed to, uint256 indexed tokenId);

    constructor(
        string memory name,
        string memory symbol,
        string memory tokenURI
    ) ERC721PresetMinterPauserAutoId(name, symbol, tokenURI) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function lastMintedKeyId(address beneficiary) external view override returns (uint256) {
        uint256 balance = balanceOf(beneficiary);

        return tokenOfOwnerByIndex(beneficiary, balance - 1);
    }

    function mintKey(address to) external override {
        super.mint(to);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        super._transfer(from, to, tokenId);
        emit VaultKeyTransfer(vaultKeyTransferLastBlock, from, to, tokenId);
        vaultKeyTransferLastBlock = block.number;
    }
}