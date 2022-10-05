// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";

// check balance and withdraw WETH
interface WETH {
    function transferFrom(address _from,address _to, uint _value) external returns (bool success);
    function balanceOf(address _owner) external returns (uint balance);
    function transfer(address _to, uint256 _amount) external returns (bool);
}

contract AquaCultureNFT is Initializable, ERC721Upgradeable, OwnableUpgradeable, UUPSUpgradeable, ERC721URIStorageUpgradeable{ 
    address wethAddress;

    using ECDSA for bytes32;
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    mapping(address => mapping(uint256 => bool)) seenNonces; //for mi
    mapping(uint256 => tokenInfo) public allTokensInfo;
    mapping(uint256 => assetInfo) public allAssetsInfo;
    uint256 PLATFORM_SHARE_PERCENT;
    uint256 ROYALTY_PERCENT;

    uint256 public newItemId;
    Counters.Counter private _tokenIds;
    Counters.Counter private _assetIds;

    struct tokenInfo {
        uint256 tokenId;
        address payable creator;
    }
    struct assetInfo {
        address creator;
        string metadata;
        uint256 assetId;
        uint256 maxMints;
        uint256 currentMints;
        uint256 price;
    }
    struct createNftData {
        string metaData;
        address creator;
        string encodeKey;
        uint256 nonce;
        uint256 amount;
        bytes signature;
    }
    struct PercentagesResponse {
        uint256 royaltyPercent;
        uint256 platformSharePercent;
    }
    struct createAssetPublicData {
        string encodeKey;
        uint256 nonce;
        uint256 amount;
        bytes signature;
        uint256 maxAllowed;
        string metadata;
        uint256 price;
    }
    struct createNFTPublicData {
        string encodeKey;
        uint256 nonce;
        uint256 amount;
        bytes signature;
        uint256 maxAllowed;
        string metadata;
        uint256 price;
    }
    struct buyAndMintData {
        string encodeKey;
        uint256 nonce;
        uint256 amount;
        bytes signature;
        uint256 assetId;
        uint payThrough;
        string metadata;
    }
    struct buyAndMintAssetAcceptData {
        string encodeKey;
        uint256 nonce;
        uint256 amount;
        bytes signature;
        uint256 assetId;
        address newOwner;
        string metadata;
    }
    struct transferByAcceptData {
        string encodeKey;
        uint256 nonce;
        uint256 amount;
        bytes signature;
        uint256 tokenId;
        address newOwner;
    }
    struct buyNowData {
        string encodeKey;
        uint256 nonce;
        uint256 amount;
        bytes signature;
        uint256 tokenId;
        uint payThrough;
        address owner;
    }
    event NewNFT(uint256 indexed tokenId);
    event NewAssetTransferred(uint256 indexed tokenId, address from, address to);
    event OfferAccepted(uint256 indexed tokenId,uint256 indexed price,address from,address to);
    event BidAccepted(uint256 indexed tokenId,uint256 indexed price,address from,address to);
    event NFTPurchased(uint256 indexed tokenId,uint256 indexed price,address from,address to);
    event NewAsset(uint256 assetId);

    function initialize(string memory tokenName, string memory tokenSymbol, address _weth, uint256 platform_share_percentage, uint256 royalty_percentage) public initializer {
        __ERC721_init(tokenName, tokenSymbol);
        __Ownable_init();
        __UUPSUpgradeable_init();
        wethAddress = _weth;
        PLATFORM_SHARE_PERCENT = platform_share_percentage;
        ROYALTY_PERCENT = royalty_percentage;
	}
    function _authorizeUpgrade(address) internal override onlyOwner{}
    function createAsset(uint256 maxAllowed, string memory metadata, uint256 price) public onlyOwner onlyProxy {
        _assetIds.increment();
        uint256 newAssetId = _assetIds.current();
        assetInfo memory newAsset = assetInfo(
            owner(),
            metadata,
            newAssetId,
            maxAllowed,
            0,
            price
        );
        allAssetsInfo[newAssetId] = newAsset;
        emit NewAsset(newAssetId);
    }
    function createAssetPublic(createAssetPublicData memory _createAssetData) public onlyProxy {
        require(!seenNonces[msg.sender][_createAssetData.nonce], "Invalid request");
        seenNonces[msg.sender][_createAssetData.nonce] = true;
        require(verify(msg.sender, msg.sender, _createAssetData.amount, _createAssetData.encodeKey, _createAssetData.nonce, _createAssetData.signature), "invalid signature");

        _assetIds.increment();
        uint256 newAssetId = _assetIds.current();
        assetInfo memory newAsset = assetInfo(
            msg.sender,
            _createAssetData.metadata,
            newAssetId,
            _createAssetData.maxAllowed,
            0,
            _createAssetData.price
        );
        allAssetsInfo[newAssetId] = newAsset;
        emit NewAsset(newAssetId);
    }
    function createNFT(createNftData memory _nftData) public onlyProxy {
        require(!seenNonces[msg.sender][_nftData.nonce], "Invalid request");
        seenNonces[msg.sender][_nftData.nonce] = true;
        require(verify(msg.sender, msg.sender, _nftData.amount, _nftData.encodeKey, _nftData.nonce, _nftData.signature), "invalid signature");

        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        require(!_exists(newTokenId), "Token ID already exists");
        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, _nftData.metaData);
        tokenInfo memory newTokenInfo = tokenInfo(
            newTokenId,
            payable(msg.sender)
        );
        allTokensInfo[newTokenId] = newTokenInfo;
        emit NewNFT(newTokenId);
    }
    function buyAndMintAsset(buyAndMintData memory _buyAndMintData) external payable onlyProxy {
        require(!seenNonces[msg.sender][_buyAndMintData.nonce], "Invalid request");
        seenNonces[msg.sender][_buyAndMintData.nonce] = true;
        require(verify(msg.sender, msg.sender, _buyAndMintData.amount, _buyAndMintData.encodeKey, _buyAndMintData.nonce, _buyAndMintData.signature), "invalid signature");

        assetInfo memory assetInfoById = allAssetsInfo[_buyAndMintData.assetId];
        uint256 amount = msg.value;
        if(_buyAndMintData.payThrough == 1) {
            require(msg.value >= assetInfoById.price, "Invalid Price");
        }
        require(assetInfoById.maxMints >= assetInfoById.currentMints, "NFT Not available");
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, _buyAndMintData.metadata);
        assetInfoById.currentMints = assetInfoById.currentMints+1;
        allAssetsInfo[_buyAndMintData.assetId] = assetInfoById;
        tokenInfo memory newTokenInfo = tokenInfo(
            newTokenId,
            payable(assetInfoById.creator)
        );
        allTokensInfo[newTokenId] = newTokenInfo;
        uint256 amountToTransfer = amount;
        if(assetInfoById.creator != owner()) {
            if(PLATFORM_SHARE_PERCENT > 0) {
                uint256 platformSharePercent = calculatePercentValue(amount, PLATFORM_SHARE_PERCENT);
                amountToTransfer = amountToTransfer-platformSharePercent;
            }
            payable(assetInfoById.creator).transfer(amountToTransfer);
        }
        emit NewNFT(newTokenId);
        emit NewAssetTransferred(newTokenId, assetInfoById.creator, msg.sender);
    }
    function buyAndMintAssetByAccept(buyAndMintAssetAcceptData memory _buyAndMintAssetAcceptData) external payable onlyProxy{
        require(!seenNonces[msg.sender][_buyAndMintAssetAcceptData.nonce], "Invalid request");
        seenNonces[msg.sender][_buyAndMintAssetAcceptData.nonce] = true;
        require(verify(msg.sender, msg.sender, _buyAndMintAssetAcceptData.amount, _buyAndMintAssetAcceptData.encodeKey, _buyAndMintAssetAcceptData.nonce, _buyAndMintAssetAcceptData.signature), "invalid signature");

        assetInfo memory assetInfoById = allAssetsInfo[_buyAndMintAssetAcceptData.assetId];
        require(assetInfoById.maxMints >= assetInfoById.currentMints, "NFT Not available");
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, _buyAndMintAssetAcceptData.metadata);
        _transfer(msg.sender, _buyAndMintAssetAcceptData.newOwner, newTokenId);
        assetInfoById.currentMints = assetInfoById.currentMints+1;
        allAssetsInfo[_buyAndMintAssetAcceptData.assetId] = assetInfoById;
        tokenInfo memory newTokenInfo = tokenInfo(
            newTokenId,
            payable(assetInfoById.creator)
        );
        allTokensInfo[newTokenId] = newTokenInfo;
        uint256 amountToTransfer = _buyAndMintAssetAcceptData.amount;
        if(PLATFORM_SHARE_PERCENT > 0) {
            uint256 platformSharePercent = calculatePercentValue(_buyAndMintAssetAcceptData.amount, PLATFORM_SHARE_PERCENT);
            amountToTransfer = amountToTransfer-platformSharePercent;
            transferwethToOwner(_buyAndMintAssetAcceptData.newOwner, address(this), platformSharePercent);
        }
        transferwethToOwner(_buyAndMintAssetAcceptData.newOwner, msg.sender, amountToTransfer);
        emit NewNFT(newTokenId);
        emit NewAssetTransferred(newTokenId, msg.sender, _buyAndMintAssetAcceptData.newOwner);
    }
    function transferByAccept(transferByAcceptData memory _transferByAcceptData) external payable onlyProxy {
        require(!seenNonces[msg.sender][_transferByAcceptData.nonce], "Invalid request");
        seenNonces[msg.sender][_transferByAcceptData.nonce] = true;
        require(verify(msg.sender, msg.sender, _transferByAcceptData.amount, _transferByAcceptData.encodeKey, _transferByAcceptData.nonce, _transferByAcceptData.signature), "invalid signature");

        tokenInfo memory tokenInfoById = allTokensInfo[_transferByAcceptData.tokenId];
        uint256 amountToTransfer = _transferByAcceptData.amount;
        uint256 platformShareAfterRoyalty = PLATFORM_SHARE_PERCENT;
        if(msg.sender != tokenInfoById.creator && ROYALTY_PERCENT > 0 && PLATFORM_SHARE_PERCENT > 0) {
            uint256 royaltyPercent = calculatePercentValue(_transferByAcceptData.amount, ROYALTY_PERCENT);
            amountToTransfer = amountToTransfer-royaltyPercent;
            transferwethToOwner(_transferByAcceptData.newOwner, tokenInfoById.creator, royaltyPercent);
            platformShareAfterRoyalty = platformShareAfterRoyalty - royaltyPercent;
        }
        if(platformShareAfterRoyalty > 0) {
            uint256 platformSharePercent = calculatePercentValue(_transferByAcceptData.amount, platformShareAfterRoyalty);
            amountToTransfer = amountToTransfer-platformSharePercent;
            transferwethToOwner(_transferByAcceptData.newOwner, address(this), platformSharePercent);
        }
        transferwethToOwner(_transferByAcceptData.newOwner, msg.sender, amountToTransfer);
        _transfer(msg.sender, _transferByAcceptData.newOwner, _transferByAcceptData.tokenId);
        emit OfferAccepted(_transferByAcceptData.tokenId,_transferByAcceptData.amount,msg.sender,_transferByAcceptData.newOwner);
    }
    function acceptBid(uint256 tokenId, address newOwner, address owner, uint256 amount) external payable onlyOwner onlyProxy {
        tokenInfo memory tokenInfoById = allTokensInfo[tokenId];
        uint256 amountToTransfer = amount;
        if(PLATFORM_SHARE_PERCENT > 0) {
            uint256 platformSharePercent = calculatePercentValue(amount, PLATFORM_SHARE_PERCENT);
            amountToTransfer = amountToTransfer-platformSharePercent;
            transferwethToOwner(newOwner, address(this), platformSharePercent);
        }
        if(ROYALTY_PERCENT > 0) {
            uint256 royaltyPercent = calculatePercentValue(amount, PLATFORM_SHARE_PERCENT);
            amountToTransfer = amountToTransfer-royaltyPercent;
            transferwethToOwner(newOwner, tokenInfoById.creator, royaltyPercent);
        }
        transferwethToOwner(newOwner, owner, amountToTransfer);
        _transfer(owner, newOwner, tokenId);
        emit BidAccepted(tokenId,amount,owner,newOwner);
    }
    function buyNow(buyNowData memory _buyNowData) external payable onlyProxy{
        require(!seenNonces[msg.sender][_buyNowData.nonce], "Invalid request");
        seenNonces[msg.sender][_buyNowData.nonce] = true;
        require(verify(msg.sender, msg.sender, _buyNowData.amount, _buyNowData.encodeKey, _buyNowData.nonce, _buyNowData.signature), "invalid signature");

        uint256 amount = msg.value;
        tokenInfo memory tokenInfoById = allTokensInfo[_buyNowData.tokenId];
        address owner = _buyNowData.owner;
        uint256 amountToTransfer = amount;

        uint256 platformShareAfterRoyalty = PLATFORM_SHARE_PERCENT;
        if(owner != tokenInfoById.creator && ROYALTY_PERCENT > 0 && PLATFORM_SHARE_PERCENT > 0) {
            uint256 royaltyPercent = calculatePercentValue(_buyNowData.amount, ROYALTY_PERCENT);
            payable(tokenInfoById.creator).transfer(royaltyPercent);
            amountToTransfer = amountToTransfer-royaltyPercent;
            platformShareAfterRoyalty = platformShareAfterRoyalty - royaltyPercent;
        }
        if(platformShareAfterRoyalty > 0) {
            uint256 platformSharePercent = calculatePercentValue(_buyNowData.amount, platformShareAfterRoyalty);
            amountToTransfer = amountToTransfer-platformSharePercent;
        }
        payable(owner).transfer(amountToTransfer);
        _transfer(owner, msg.sender, _buyNowData.tokenId);
        emit NFTPurchased(_buyNowData.tokenId,msg.value,owner,msg.sender);
    }
    // fallback function to receive direct payments sent by metamask (for testing)
    fallback () payable external {}
    receive () payable external {}
    function checkPercentages() public view onlyProxy returns (PercentagesResponse memory) {
        PercentagesResponse memory percentagesResponse = PercentagesResponse(
            PLATFORM_SHARE_PERCENT,
            ROYALTY_PERCENT
        );
        return percentagesResponse;
    }
    function updatePercentages(uint256 platformPercent, uint256 royaltyPercent) public onlyProxy onlyOwner{
        PLATFORM_SHARE_PERCENT = platformPercent;
        ROYALTY_PERCENT = royaltyPercent;
    }
    function updatePlatformSharePercent(uint256 percent) public onlyProxy onlyOwner{
        PLATFORM_SHARE_PERCENT = percent;
    }
    function updateRoyaltyPercent(uint256 percent) public onlyProxy onlyOwner{
        ROYALTY_PERCENT = percent;
    }
    function checkPlatformSharePercent() public view onlyProxy returns (uint256) {
        return PLATFORM_SHARE_PERCENT;
    }
    function checkRoyaltyPercent() public view onlyProxy returns (uint256) {
        return ROYALTY_PERCENT;
    }
    function calculatePercentValue(uint256 total, uint256 percent) pure private returns(uint256) {
        uint256 division = total.mul(percent);
        uint256 percentValue = division.div(100);
        return percentValue;
    }
    function transferwethToOwner(address from, address to, uint256 amount) private {
        WETH weth = WETH(wethAddress);
        uint256 balance = weth.balanceOf(from);
        require(balance >= amount, "insufficient balance" );
        weth.transferFrom(from, to, amount);
    }
    function safeMint(address to, string memory uri) public onlyOwner onlyProxy{
        uint256 tokenId = _tokenIds.current();
        _tokenIds.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }
    // The following functions are overrides required by Solidity.
    function _burn(uint256 tokenId) internal override(ERC721Upgradeable, ERC721URIStorageUpgradeable) onlyOwner onlyProxy{
        super._burn(tokenId);
    }
    function tokenURI(uint256 tokenId) public view onlyProxy override(ERC721Upgradeable, ERC721URIStorageUpgradeable) returns (string memory) {
        return super.tokenURI(tokenId);
    }
    function withdrawETH() public onlyOwner onlyProxy {
        payable(owner()).transfer(address(this).balance);
    }
    function withdrawWETH() public onlyOwner onlyProxy {
        WETH weth = WETH(wethAddress);
        uint256 balance = weth.balanceOf(address(this));
        require(balance >= 0, "insufficient balance" );
        weth.transfer(owner(), balance);
    }
    function verify( address _signer, address _to, uint256 _amount, string memory _message, uint256 _nonce, bytes memory signature) internal pure returns (bool) {
        bytes32 messageHash = getMessageHash(_to, _amount, _message, _nonce);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }
    function getMessageHash( address _to, uint256 _amount, string memory _message, uint256 _nonce) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_to, _amount, _message, _nonce));
    }
    function getEthSignedMessageHash(bytes32 _messageHash) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
            );
    }
    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }
    function splitSignature(bytes memory sig) internal pure returns ( bytes32 r, bytes32 s, uint8 v ) {
        require(sig.length == 65, "invalid signature length");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
}