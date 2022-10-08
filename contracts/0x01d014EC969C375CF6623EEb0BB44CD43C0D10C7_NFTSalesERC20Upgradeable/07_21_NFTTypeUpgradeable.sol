//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./utils/ERC721BaseUpgradeable.sol";

abstract contract NFTTypeUpgradeable is
    Initializable,
    OwnableUpgradeable,
    ERC721BaseUpgradeable
{
    using StringsUpgradeable for uint256;

    uint256 public maxNFTsToParse;
    mapping(uint32 => string) public nftTypeURIs; // metadata per NFT Type
    mapping(uint32 => uint32) public tokenIDToNFTType;
    mapping(uint32 => mapping(address => uint16)) public nftTypeToAddressCount;

    error tooManyIDs(uint sent, uint max);

    function __NFTTypeUpgradeable_init(
        string memory name_,
        string memory symbol_
    ) internal onlyInitializing {
        __NFTTypeUpgradeable_init_unchained(name_, symbol_);
    }

    function __NFTTypeUpgradeable_init_unchained(
        string memory name_,
        string memory symbol_
    ) internal onlyInitializing {
        __ERC721BaseUpgradeable_init(name_, symbol_);
        OwnableUpgradeable.__Ownable_init();
        maxNFTsToParse = 500;
    }

    // mint NFTs to a list of receivers, assigning an NFT type to each minted NFT
    function airdrop(address[] calldata receivers, uint32[] calldata nftTypes)
        external
        onlyOwner
        consistentArrayLengths(receivers.length, nftTypes.length)
    {
        for (uint256 i; i < receivers.length; i++) {
            _mintAndAssignNFTType(receivers[i], nftTypes[i]);
        }
    }

    function getNFTTypeForTokenID(uint32 tokenID)
        external
        view
        returns (uint32)
    {
        return tokenIDToNFTType[tokenID];
    }

    function getNFTTypesForTokenIDs(uint32[] calldata tokenIDs)
        external
        view
        returns (uint32[] memory)
    {
        uint32[] memory nftTypes = new uint32[](tokenIDs.length);
        for (uint x; x < tokenIDs.length; x++) {
            nftTypes[x] = tokenIDToNFTType[tokenIDs[x]];
        }
        return nftTypes;
    }

    // assign a new NFT type to existing NFTs
    function _assignNFTType(
        uint32[] calldata nftIDs,
        uint32[] calldata nftTypes
    ) internal consistentArrayLengths(nftIDs.length, nftTypes.length) {
        _assignNFTTypeFiltered(nftIDs, nftTypes, 0, false);
    }

    // assign a new NFT type to existing NFTs, but only for NFTs with current type filterNFTType
    function _assignNFTTypeWithFilter(
        uint32[] calldata nftIDs,
        uint32[] calldata nftTypes,
        uint32 filterNFTType
    ) internal consistentArrayLengths(nftIDs.length, nftTypes.length) {
        _assignNFTTypeFiltered(nftIDs, nftTypes, filterNFTType, true);
    }

    // mint NFTs to single receiver with various NFT type per mint
    function _batchMint(address receiver, uint32[] calldata nftTypes) internal {
        for (uint256 i; i < nftTypes.length; i++) {
            _mintAndAssignNFTType(receiver, nftTypes[i]);
        }
    }

    // retrieve count of owned NFTs for a user for a specific NFT type
    function getNFTTypeCount(address account, uint32 nftType)
        external
        view
        returns (uint256)
    {
        return nftTypeToAddressCount[nftType][account];
    }

    // retrieve count of owner NFTs for a user for multiple NFT types
    function getNFTTypeCounts(address account, uint32[] calldata nftTypes)
        external
        view
        returns (uint256 result)
    {
        for (uint256 x; x < nftTypes.length; x++) {
            result += nftTypeToAddressCount[nftTypes[x]][account];
        }
    }

    function setNFTTypeURI(uint32 nftTypeID, string calldata uri)
        external
        onlyOwner
    {
        nftTypeURIs[nftTypeID] = uri;
    }

    // returns specific tokenURI is one is assigned to the token
    // if not, then returns URI for NFT type using tokenBaseURI
    function tokenURI(uint256 tokenID)
        external
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenID)) revert NonexistentToken(tokenID);
        if (bytes(tokenURIs[uint32(tokenID)]).length != 0)
            return tokenURIs[uint32(tokenID)];
        if (bytes(nftTypeURIs[uint32(tokenID)]).length != 0)
            return nftTypeURIs[uint32(tokenID)];
        return
            string(
                abi.encodePacked(
                    _tokenBaseURI,
                    uint256(tokenIDToNFTType[uint32(tokenID)]).toString()
                )
            );
    }

    /*** INTERNAL ***/

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        uint32 nftType = tokenIDToNFTType[uint32(tokenId)];
        _decrementNFTTypeCountForAddress(nftType, from, 1);
        _incrementNFTTypeCountForAddress(nftType, to, 1);
        super._transfer(from, to, tokenId);
    }

    // mint multiple NFTs to multiple receivers with same NFT type
    function _batchMintAndAssignNFTType(
        address receiver,
        uint16 amount,
        uint32 nftType
    ) internal {
        for (uint256 i; i < amount; i++) {
            _mintAndAssignNFTType(receiver, nftType);
        }
        _incrementNFTTypeCountForAddress(nftType, receiver, amount);
    }

    // mint single NFT to single receiver with single NFT type
    function _mintAndAssignNFTType(address receiver, uint32 nftType) internal {
        _mint(receiver);
        tokenIDToNFTType[uint32(_owners.length - 1)] = nftType;
        _incrementNFTTypeCountForAddress(nftType, receiver, 1);
    }

    function _decrementNFTTypeCountForAddress(
        uint32 nftType,
        address _address,
        uint16 amount
    ) internal {
        nftTypeToAddressCount[nftType][_address] -= amount;
    }

    function _incrementNFTTypeCountForAddress(
        uint32 nftType,
        address _address,
        uint16 amount
    ) internal {
        nftTypeToAddressCount[nftType][_address] += amount;
    }

    function _assignNFTTypeFiltered(
        uint32[] calldata nftIDs,
        uint32[] calldata nftTypes,
        uint32 filterNFTType,
        bool useFilter
    ) private consistentArrayLengths(nftIDs.length, nftTypes.length) {
        for (uint256 x; x < nftIDs.length; x++) {
            uint32 nftType = tokenIDToNFTType[nftIDs[x]];
            if (useFilter && nftType != filterNFTType) continue;
            address nftOwner = _owners[nftIDs[x]];
            //decrement unknown for owner and increment new nft type for owner
            _decrementNFTTypeCountForAddress(nftType, nftOwner, 1);
            _incrementNFTTypeCountForAddress(nftTypes[x], nftOwner, 1);
            tokenIDToNFTType[nftIDs[x]] = nftTypes[x];
        }
    }
}