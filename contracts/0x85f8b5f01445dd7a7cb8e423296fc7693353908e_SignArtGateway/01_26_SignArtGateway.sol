// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract SignArtGateway is Initializable, UUPSUpgradeable, ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721URIStorageUpgradeable, ERC721HolderUpgradeable, OwnableUpgradeable, ERC721BurnableUpgradeable, ERC2981Upgradeable {

    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIdCounter;

    string constant unlocked = "UNLOCKED";
    string constant locked = "LOCKED";

    // set these var after init deploy
    uint256 public gatewayFee;
    address public usd_eth_oracle;
    bool public appRunning;
    string public pausedReason;

    struct NFT {
        string wavesAssetId;
        uint256 evmAssetId;
        string status;
        bool minted;
    }

    struct releasedToWaves {
        string recipient;
        uint timestamp;
        uint256 evmAssetId;
        address sender;
    }

    mapping(string => NFT) public nftData;
    mapping(string => uint256) public wavesAssetToEvm;
    mapping(uint256 => string) public evmAssetToWaves;
    mapping(string => releasedToWaves) public released;

    event newTransfer(string _assetId, string _recipient, uint256 _evmAssetId, address _sender);

    modifier isAppRunning {
        require(appRunning, pausedReason);
        _;
    }

    function initialize() initializer public {
        appRunning = false;
        pausedReason = "Init variables first.";
        gatewayFee = 2;
        __ERC721_init("SignArtGateway", "SAG");
        __ERC721Enumerable_init();
        __ERC721Burnable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function safeMint(address _to, string memory _uri, string memory _wavesAssetId, address _creatorETHaddr) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        
        require(!nftData[_wavesAssetId].minted, "This NFT already exist");

        nftData[_wavesAssetId].wavesAssetId = _wavesAssetId;
        nftData[_wavesAssetId].evmAssetId = tokenId;
        nftData[_wavesAssetId].minted = true;
        nftData[_wavesAssetId].status = unlocked;

        wavesAssetToEvm[_wavesAssetId] = tokenId;
        evmAssetToWaves[tokenId] = _wavesAssetId;

        _tokenIdCounter.increment();
        _safeMint(_to, tokenId);
        _setTokenURI(tokenId, _uri);
        _setTokenRoyalty(tokenId, _creatorETHaddr, 1000);

    }

    function unlock(address _to, string memory _wavesAssetId) public onlyOwner {
        require(nftData[_wavesAssetId].minted, "This NFT is not minted yet");
        require(keccak256(bytes(nftData[_wavesAssetId].status)) == keccak256(bytes(locked)), "This NFT is already unlocked");
        nftData[_wavesAssetId].status = unlocked;
        _transfer(address(this), _to, nftData[_wavesAssetId].evmAssetId);
    }

    function lock(uint256 _evmAssetId, string memory _recipient) public payable isAppRunning {
        string memory wavesAssetId = evmAssetToWaves[_evmAssetId];
        require(nftData[wavesAssetId].minted, "This NFT is not minted yet");
        require(ownerOf(nftData[wavesAssetId].evmAssetId) == msg.sender, "You must own the token");
        require(msg.value >= getPrice() * gatewayFee, "Wrong gateway fee, please try again.");
        
        nftData[wavesAssetId].status = locked;

        released[wavesAssetId].timestamp = block.timestamp;
        released[wavesAssetId].recipient = _recipient;
        released[wavesAssetId].evmAssetId = _evmAssetId;
        released[wavesAssetId].sender = msg.sender;

        safeTransferFrom(msg.sender, address(this), nftData[wavesAssetId].evmAssetId);
        emit newTransfer(wavesAssetId, _recipient, _evmAssetId, msg.sender);
    }

    function pauseDapp(bool _status, string memory _reason) public onlyOwner {
        appRunning = _status;
        pausedReason = _reason;
    }
    
    function dappStatus() public view returns (bool _status, string memory _message) {
      return (appRunning, pausedReason);
    }

    function setFeeInUsd(uint _fee) public onlyOwner {
        gatewayFee = _fee;
    }
    function setPairAddress(address _pairAddress) public onlyOwner {
        usd_eth_oracle = _pairAddress;
    }

    function getPrice() public view returns (uint256) { // return 1 usd in eth
        AggregatorV3Interface priceFeed = AggregatorV3Interface(usd_eth_oracle);
        (,int256 price,,,) = priceFeed.latestRoundData();
        return uint256(price);
    }

    // The following functions are overrides required by Solidity.

    function _authorizeUpgrade(address newImplementation) internal onlyOwner override {}

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721Upgradeable, ERC721URIStorageUpgradeable) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721Upgradeable, ERC721URIStorageUpgradeable) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC2981Upgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}