// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./royalties/RoyaltiesV2Impl.sol";
import "./royalties/LibPart.sol";

error InvalidInput(string message);

contract NftMint is ERC721URIStorageUpgradeable, UUPSUpgradeable, OwnableUpgradeable, RoyaltiesV2Impl {
    event NewNFT(uint256 id, address owner, string metadataUri, LibPart.Part[] royalties);

    struct Mint721Data {
        LibPart.Part[] royalties;
    }

    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIds;

    function initialize(string memory tokenName, string memory tokenSymbol) external initializer {
        __ERC721_init(tokenName, tokenSymbol);
        __Ownable_init();
    }

    /// @param tokenOwner of the NFT, URI of the minted NFT metadata
    /// @return minted token id
    function mintToken(
        Mint721Data memory data,
        address tokenOwner,
        string memory metadataURI
    ) external returns (uint256) {
        require(bytes(metadataURI).length > 0, "NFT metadataURI must not be empty.");
        _tokenIds.increment();
        uint256 id = _tokenIds.current();
        _mint(tokenOwner, id);
        _setTokenURI(id, metadataURI);
        _saveRoyalties(id, data.royalties);
        emit NewNFT(id, msg.sender, metadataURI, data.royalties);
        return id;
    }

    bytes4 public constant ROYALTIES_INTERFACE_ID = 0xcad96cca;
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Upgradeable) returns (bool) {
        return interfaceId == ROYALTIES_INTERFACE_ID || super.supportsInterface(interfaceId);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    uint256[50] private ______gap;
}