//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BaseTokenURIProvider.sol";
import "./ChainScoutMetadata.sol";
import "./ExtensibleERC721Enumerable.sol";
import "./Generator.sol";
import "./IChainScouts.sol";
import "./IUtilityERC20.sol";
import "./MerkleWhitelistERC721Enumerable.sol";
import "./Rng.sol";

contract ChainScouts is IChainScouts, MerkleWhitelistERC721Enumerable {
    using RngLibrary for Rng;

    mapping (string => ChainScoutsExtension) public extensions;
    Rng private rng = RngLibrary.newRng();
    mapping (uint => ChainScoutMetadata) internal tokenIdToMetadata;
    uint private _mintPriceWei = 0.068 ether;

    event MetadataChanged(uint tokenId);

    constructor(Payee[] memory payees, bytes32 merkleRoot)
    ERC721A("Chain Scouts", "CS")
    MerkleWhitelistERC721Enumerable(
        payees,        // _payees
        5,             // max mints per tx
        6888,          // supply
        3,             // max wl mints
        merkleRoot     // wl merkle root
    ) {}

    function adminCreateChainScout(ChainScoutMetadata calldata tbd, address owner) external override onlyAdmin {
        require(totalSupply() < maxSupply, "ChainScouts: totalSupply >= maxSupply");
        uint tokenId = _currentIndex;
        _mint(owner, 1, "", false);
        tokenIdToMetadata[tokenId] = tbd;
    }

    function adminSetChainScoutMetadata(uint tokenId, ChainScoutMetadata calldata tbd) external override onlyAdmin {
        tokenIdToMetadata[tokenId] = tbd;
        emit MetadataChanged(tokenId);
    }

    function adminRemoveExtension(string calldata key) external override onlyAdmin {
        delete extensions[key];
    }

    function adminSetExtension(string calldata key, ChainScoutsExtension extension) external override onlyAdmin {
        extensions[key] = extension;
    }

    function adminSetMintPriceWei(uint max) external onlyAdmin {
        _mintPriceWei = max;
    }

    function getChainScoutMetadata(uint tokenId) external view override returns (ChainScoutMetadata memory) {
        return tokenIdToMetadata[tokenId];
    }

    function createMetadataForMintedToken(uint tokenId) internal override {
        (tokenIdToMetadata[tokenId], rng) = Generator.getRandomMetadata(rng);
    }

    function tokenURI(uint tokenId) public override view returns (string memory) {
        return BaseTokenURIProvider(address(extensions["tokenUri"])).tokenURI(tokenId);
    }

    function mintPriceWei() public view override returns (uint) {
        return _mintPriceWei;
    }

    function whitelistMintAndStake(bytes32[] calldata proof, uint count) external payable returns (uint) {
        uint start = whitelistMint(proof, count);

        uint[] memory ids = new uint[](count);
        for (uint i = 0; i < count; ++i) {
            ids[i] = start + i;
        }

        IUtilityERC20(address(extensions["token"])).stake(ids);

        return start;
    }

    function publicMintAndStake(uint count) external payable returns (uint) {
        uint start = publicMint(count);

        uint[] memory ids = new uint[](count);
        for (uint i = 0; i < count; ++i) {
            ids[i] = start + i;
        }

        IUtilityERC20(address(extensions["token"])).stake(ids);

        return start;
    }
}