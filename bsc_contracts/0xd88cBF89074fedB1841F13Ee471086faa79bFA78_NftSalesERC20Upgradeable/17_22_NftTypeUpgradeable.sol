//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./utils/ERC721BaseUpgradeable.sol";

abstract contract NftTypeUpgradeable is
    Initializable,
    OwnableUpgradeable,
    ERC721BaseUpgradeable
{
    using StringsUpgradeable for uint256;

    uint256 public maxNftsToParse;
    mapping(uint32 => string) public nftTypeURIs; // metadata per Nft Type
    mapping(uint32 => uint32) public tokenIdToNftType;
    mapping(uint32 => mapping(address => uint16)) public nftTypeToAddressCount;

    error tooManyIDs(uint sent, uint max);

    function __NftTypeUpgradeable_init(
        string memory name_,
        string memory symbol_
    ) internal onlyInitializing {
        __NftTypeUpgradeable_init_unchained(name_, symbol_);
    }

    function __NftTypeUpgradeable_init_unchained(
        string memory name_,
        string memory symbol_
    ) internal onlyInitializing {
        __ERC721BaseUpgradeable_init(name_, symbol_);
        OwnableUpgradeable.__Ownable_init();
        maxNftsToParse = 500;
    }

    // mint Nfts to a list of receivers, assigning an Nft type to each minted Nft
    function airdrop(
        address[] calldata receivers,
        uint32[] calldata nftTypes
    )
        external
        onlyOwner
        consistentArrayLengths(receivers.length, nftTypes.length)
    {
        for (uint256 i; i < receivers.length; i++) {
            _mintAndAssignNftType(receivers[i], nftTypes[i]);
        }
    }

    // retrieve count of owned Nfts for a user for a specific Nft type
    function getNftTypeCount(
        address account,
        uint32 nftType
    ) external view returns (uint256) {
        return nftTypeToAddressCount[nftType][account];
    }

    // retrieve count of owner Nfts for a user for multiple Nft types
    function getNftTypeCounts(
        address account,
        uint32[] calldata nftTypes
    ) external view returns (uint256 result) {
        for (uint256 x; x < nftTypes.length; x++) {
            result += nftTypeToAddressCount[nftTypes[x]][account];
        }
    }

    function getNftTypeForTokenID(
        uint32 tokenId
    ) external view returns (uint32) {
        return tokenIdToNftType[tokenId];
    }

    function getNftTypesForTokenIDs(
        uint32[] calldata tokenIds
    ) external view returns (uint32[] memory) {
        uint32[] memory nftTypes = new uint32[](tokenIds.length);
        for (uint x; x < tokenIds.length; x++) {
            nftTypes[x] = tokenIdToNftType[tokenIds[x]];
        }
        return nftTypes;
    }

    function setNftTypeURI(
        uint32 nftTypeID,
        string calldata uri
    ) external onlyOwner {
        nftTypeURIs[nftTypeID] = uri;
    }

    // returns specific tokenURI is one is assigned to the token
    // if not, then returns URI for Nft type using tokenBaseURI
    function tokenURI(
        uint256 tokenId
    ) external view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert NonexistentToken(tokenId);
        if (bytes(tokenURIs[uint32(tokenId)]).length != 0)
            return tokenURIs[uint32(tokenId)];
        if (bytes(nftTypeURIs[uint32(tokenId)]).length != 0)
            return nftTypeURIs[uint32(tokenId)];
        return
            string(
                abi.encodePacked(
                    _tokenBaseURI,
                    uint256(tokenIdToNftType[uint32(tokenId)]).toString()
                )
            );
    }

    /*** INTERNAL ***/

    // assign a new Nft type to existing Nfts
    function _assignNftType(
        uint32[] calldata nftIDs,
        uint32[] calldata nftTypes
    ) internal consistentArrayLengths(nftIDs.length, nftTypes.length) {
        _assignNftTypeFiltered(nftIDs, nftTypes, 0, false);
    }

    function _assignNftTypeFiltered(
        uint32[] calldata nftIDs,
        uint32[] calldata nftTypes,
        uint32 filterNftType,
        bool useFilter
    ) private consistentArrayLengths(nftIDs.length, nftTypes.length) {
        for (uint256 x; x < nftIDs.length; x++) {
            uint32 nftType = tokenIdToNftType[nftIDs[x]];
            if (useFilter && nftType != filterNftType) continue;
            address nftOwner = _owners[nftIDs[x]];
            //decrement unknown for owner and increment new nft type for owner
            _decrementNftTypeCountForAddress(nftType, nftOwner, 1);
            _incrementNftTypeCountForAddress(nftTypes[x], nftOwner, 1);
            tokenIdToNftType[nftIDs[x]] = nftTypes[x];
        }
    }

    // assign a new Nft type to existing Nfts, but only for Nfts with current type filterNftType
    function _assignNftTypeWithFilter(
        uint32[] calldata nftIDs,
        uint32[] calldata nftTypes,
        uint32 filterNftType
    ) internal consistentArrayLengths(nftIDs.length, nftTypes.length) {
        _assignNftTypeFiltered(nftIDs, nftTypes, filterNftType, true);
    }

    // mint multiple Nfts to multiple receivers with same Nft type
    function _batchMintAndAssignNftType(
        address receiver,
        uint16 amount,
        uint32 nftType
    ) internal returns (uint32[] memory) {
        uint32[] memory result = new uint32[](amount);
        for (uint256 x; x < amount; x++) {
            result[x] = _mintAndAssignNftType(receiver, nftType);
        }
        _incrementNftTypeCountForAddress(nftType, receiver, amount);
        return result;
    }

    function _decrementNftTypeCountForAddress(
        uint32 nftType,
        address _address,
        uint16 amount
    ) internal {
        nftTypeToAddressCount[nftType][_address] -= amount;
    }

    // mint Nfts to single receiver with various Nft type per mint
    function _batchMint(address receiver, uint32[] calldata nftTypes) internal {
        for (uint256 i; i < nftTypes.length; i++) {
            _mintAndAssignNftType(receiver, nftTypes[i]);
        }
    }

    function _incrementNftTypeCountForAddress(
        uint32 nftType,
        address _address,
        uint16 amount
    ) internal {
        nftTypeToAddressCount[nftType][_address] += amount;
    }

    // mint single Nft to single receiver with single Nft type
    function _mintAndAssignNftType(
        address receiver,
        uint32 nftType
    ) internal returns (uint32) {
        _mint(receiver);
        uint32 id = uint32(_owners.length - 1);
        tokenIdToNftType[id] = nftType;
        _incrementNftTypeCountForAddress(nftType, receiver, 1);
        return id;
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        uint32 nftType = tokenIdToNftType[uint32(tokenId)];
        _decrementNftTypeCountForAddress(nftType, from, 1);
        _incrementNftTypeCountForAddress(nftType, to, 1);
        super._transfer(from, to, tokenId);
    }
}