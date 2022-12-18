// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "./Base64.sol";
import "./interfaces/IVanillaDNFTDeployer.sol";
import "./BaseDerivativeNFT.sol";

/*, IERC721Receiver*/
contract VanillaDerivativeNFT is BaseDerivativeNFT {
    using Counters for Counters.Counter;

    struct TokenInfo {
        address contractAddress;
        uint tokenId;
        uint expTime;
        uint mintType;
        uint mintPrice;
        string mediaUri;
        string mintTypeName;
        uint256 createdAt;
        string jsonDescription;
    }

    struct MintTypeInfo {
        // Basic mint type info
        uint totalLicenses;
        uint soldLicenses;
        uint256 mintPrice;
        string jsonName;
        string jsonDescription;
        string mediaUri;
        // Vanilla unique info
        uint id;
        uint validDuration; // in seconds
        uint maxExpTime; // UNIX in seconds
        bool isSaleEnabled;
    }

    mapping(uint => TokenInfo) public tokenInfoMap;
    MintTypeInfo[] public mintTypeInfoArray;
    uint public collectionMaxExpTime;

    event AllPayableReceived(address indexed caller, uint256 indexed value);
    event PayableReceived(
        address indexed to,
        uint256 indexed tokenId,
        uint256 indexed value
    );
    event NewMintType(
        uint256 indexed mintType,
        uint256 totalLicenses,
        uint256 indexed mintPrice,
        string jsonName,
        string jsonDescription,
        string mediaUri
    );
    event UpdateMintType(
        uint256 mintType,
        string jsonName,
        string jsonDescription,
        string mediaUrl
    );
    event MintItem(
        bytes32 indexed to,
        uint256 indexed tokenId,
        uint256 indexed prices,
        uint256 expirationTime,
        uint256 blockTimeStamp
    );

    modifier onlyOriginalNFTHolder() {
        require(
            getContractOwner() == spanningMsgSender(),
            "Not the original NFT holder"
        );
        _;
    }

    modifier validMintType(uint _mintType) {
        require(_mintType < totalMintType, "Provided mint type not valid");
        _;
    }

    modifier isSaleEnabled(uint256 mintType) {
        require(
            mintTypeInfoArray[mintType].isSaleEnabled == true,
            "DNFT: sales not enabled."
        );
        _;
    }
    modifier hasRemainingLicenses(uint256 mintType) {
        require(
            mintTypeInfoArray[mintType].totalLicenses >
                mintTypeInfoArray[mintType].soldLicenses,
            "DNFT: all licenses are sold out."
        );
        _;
    }

    // set contract name and ticker.
    constructor(address delegate_)
        BaseDerivativeNFT("FroopylandVanillaDerivativeNFT", "FVD", delegate_)
    {
        (factory, originNFTAddress, originNFTTokenID) = IVanillaDNFTDeployer(
            msg.sender
        ).parameters();
        SpanningERC721 originalNFTContract = SpanningERC721(originNFTAddress);
        originNFTMediaUri = originalNFTContract.tokenURI(originNFTTokenID);
    }

    function addMintType(
        uint _totalLicenses,
        uint256 _mintPrice,
        string memory _jsonName,
        string memory _jsonDescription,
        string memory _mediaUri,
        uint256 _validDuration,
        bool _enableSale
    ) public onlyOriginalNFTHolder returns (uint256) {
        mintTypeInfoArray.push(
            MintTypeInfo(
                _totalLicenses,
                0,
                _mintPrice,
                _jsonName,
                _jsonDescription,
                _mediaUri,
                totalMintType,
                _validDuration,
                0,
                _enableSale
            )
        );
        mintPrice.push(_mintPrice);
        totalMintType++;
        emit NewMintType(
            totalMintType - 1,
            _totalLicenses,
            _mintPrice,
            _jsonName,
            _jsonDescription,
            _mediaUri
        );
        return totalMintType - 1;
    }

    function updateMintType(
        uint _mintType,
        string memory _jsonName,
        string memory _jsonDescription,
        string memory _mediaUri
    ) public validMintType(_mintType) onlyOriginalNFTHolder returns (uint256) {
        mintTypeInfoArray[_mintType].jsonName = _jsonName;
        mintTypeInfoArray[_mintType].jsonDescription = _jsonDescription;
        mintTypeInfoArray[_mintType].mediaUri = _mediaUri;
        emit UpdateMintType(_mintType, _jsonName, _jsonDescription, _mediaUri);
        return _mintType;
    }

    function getMintType(
        uint mintTypeId
    ) public view validMintType(mintTypeId) returns (MintTypeInfo memory) {
        return mintTypeInfoArray[mintTypeId];
    }

    function getAllMintTypes() public view returns (MintTypeInfo[] memory) {
        return mintTypeInfoArray;
    }

    function mintItem(
        uint mintType
    )
        public
        payable
        isSaleEnabled(mintType)
        hasRemainingLicenses(mintType)
        validMintType(mintType)
        returns (uint256 tokenId)
    {
        tokenId = _mintItem(mintType);
        tokenInfoMap[tokenId] = TokenInfo(
            address(this),
            tokenId,
            block.timestamp + mintTypeInfoArray[mintType].validDuration,
            mintType,
            mintTypeInfoArray[mintType].mintPrice,
            mintTypeInfoArray[mintType].mediaUri,
            mintTypeInfoArray[mintType].jsonName,
            block.timestamp,
            mintTypeInfoArray[mintType].jsonDescription
        );
        if (
            mintTypeInfoArray[mintType].maxExpTime <
            tokenInfoMap[tokenId].expTime
        ) {
            mintTypeInfoArray[mintType].maxExpTime = tokenInfoMap[tokenId]
                .expTime;
        }
        if (collectionMaxExpTime < tokenInfoMap[tokenId].expTime) {
            collectionMaxExpTime = tokenInfoMap[tokenId].expTime;
        }
        mintTypeInfoArray[mintType].soldLicenses++;
        emit MintItem(
            spanningMsgSender(),
            tokenId,
            mintTypeInfoArray[mintType].mintPrice,
            tokenInfoMap[tokenId].expTime,
            block.timestamp
        );
    }

    function receivePayable(
        uint256 tokenId
    ) external payable onlyOriginalNFTHolder {
        require(
            block.timestamp > tokenInfoMap[tokenId].expTime,
            "Can not collect payable before license expire"
        );
        require(_exists(tokenId), "License already burned");
        _burn(tokenId);
        uint256 toBeCollected = tokenInfoMap[tokenId].mintPrice;
        payable(getLegacyFromAddress(getContractOwner())).transfer(toBeCollected);
        emit PayableReceived(msg.sender, tokenId, toBeCollected);
    }

    function receiveAllPayable() public payable onlyOriginalNFTHolder {
        uint256 toBeCollected = 0;
        address contractOwner = getLegacyFromAddress(getContractOwner());
        for (uint i = 0; i < _tokenCounter.current(); i++) {
            if (_exists(i) && block.timestamp > tokenInfoMap[i].expTime) {
                _burn(i);
                toBeCollected += tokenInfoMap[i].mintPrice;
            }
        }
        payable(contractOwner).transfer(toBeCollected);
        emit AllPayableReceived(msg.sender, toBeCollected);
    }

    function enableSale(
        uint256 _mintType
    ) public validMintType(_mintType) onlyOriginalNFTHolder {
        mintTypeInfoArray[_mintType].isSaleEnabled = true;
        emit SaleEnabled(_mintType);
    }

    function disableSale(
        uint256 _mintType
    )
        public
        validMintType(_mintType)
        onlyOriginalNFTHolder
        isSaleEnabled(_mintType)
    {
        mintTypeInfoArray[_mintType].isSaleEnabled = false;
        emit SaleDisabled(_mintType);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        return mintTypeInfoArray[tokenInfoMap[tokenId].mintType].mediaUri;
    }

    function getTokenInfoList()
        public
        view
        returns (TokenInfo[] memory tokenInfoList)
    {
        tokenInfoList = new TokenInfo[](_tokenCounter.current());
        uint256 index = 0;
        for (uint i = 0; i < _tokenCounter.current(); i++) {
            if (_exists(i)) {
                TokenInfo storage tokenInfoItem = tokenInfoMap[i];
                tokenInfoList[index] = tokenInfoItem;
                index++;
            }
        }
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function getTotalMintTypes() public view returns (uint256) {
        return totalMintType;
    }

    function getContractOwner() public view returns (bytes32) {
        bytes32 ownerFound;
        try IERC721(originNFTAddress).ownerOf(originNFTTokenID) returns (
            address owner
        ) {
            ownerFound = getAddressFromLegacy(owner);
        } catch Error(string memory reason) {
            // skip the invalid token check
        }
        return ownerFound;
    }

    function _beforeTokenTransfer(
        bytes32 from,
        bytes32 to,
        uint256
    ) internal view override {
        require(
            spanningMsgSender() == getContractOwner() || to != bytes32(0),
            "License is not transferable"
        );
    }
}