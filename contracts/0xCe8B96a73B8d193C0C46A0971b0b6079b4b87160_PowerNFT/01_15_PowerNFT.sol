// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract PowerNFT is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter public _tokenIds;
    Counters.Counter public _typeIds;
    address public owner;
    mapping(uint256 => uint256) public powerOfNFTs;
    mapping(address => bool) public isMinter;

    struct NFTInfo {
        uint256 tid;
        uint256 price;
        uint256 power;
        bool isActive;
        string tokenURI;
        uint256 limit;
        uint256 totalMinted;
    }

    NFTInfo[] public nftTypes;
    mapping(uint256 => uint256) public typesOfAllNFTs;
    IERC20 public stableCoin;

    constructor(address _stableCoinAddress) ERC721("PowerNFT", "PNFT") {
        owner = msg.sender;
        isMinter[msg.sender] = true;
        stableCoin = IERC20(_stableCoinAddress);
        NFTInfo memory nftInfo = NFTInfo({
            tid: _typeIds.current(),
            price: 0,
            power: 0,
            tokenURI: "",
            isActive: false,
            limit: 0,
            totalMinted: 0
        });
        nftTypes.push(nftInfo);
    }

    event NFTMinted(uint256 nftId, uint256 nftType, address user);
    event NFTAdded(uint256 typeId, uint256 power, uint256 price, bool isActive);
    event NFTUpdated(uint256 typeId, uint256 power, uint256 price, bool isActive);

    modifier hasMinterRole {
        require(isMinter[msg.sender], "You are not the minter");
        _;
    }

    modifier onlyOwner {
        require(owner == msg.sender, "You are not the owner");
        _;
    }

    function setStableCoinAddress(address _stableCoinAddress) public onlyOwner {
        stableCoin = IERC20(_stableCoinAddress);
    }

    function transferOwnership(address _user) public onlyOwner {
        require(_user != address(0), "Zero address can't be owner");
        owner = _user;
    }

    function addNFTType(uint256 _price, uint256 _power, string memory _tokenURI, bool _isActive, uint256 _limit) public onlyOwner {
        _typeIds.increment();
        NFTInfo memory nftInfo = NFTInfo({
            tid: _typeIds.current(),
            price: _price,
            power: _power,
            tokenURI: _tokenURI,
            isActive: _isActive,
            limit: _limit,
            totalMinted: 0
        });
        nftTypes.push(nftInfo);
        emit NFTAdded(_typeIds.current(), _power, _price, _isActive);
    }

    function updateNFTType(uint256 _typeId, uint256 _price, uint256 _power, string memory _tokenURI, bool _isActive, uint256 _limit) public onlyOwner {
        NFTInfo memory _nftInfo = nftTypes[_typeId];
        NFTInfo memory nftInfo = NFTInfo({
            tid: _typeId,
            price: _price,
            power: _power,
            tokenURI: _tokenURI,
            isActive: _isActive,
            limit: _limit,
            totalMinted: _nftInfo.totalMinted
        });

        nftTypes[_typeId] = nftInfo;
        emit NFTUpdated(_typeId, _power, _price, _isActive);
    }

    function mint(address user, uint256 _nftType) hasMinterRole
        public
        returns (uint256)
    {
        NFTInfo memory _nftInfo = nftTypes[_nftType];
        require(_nftInfo.isActive, "NFT type is not available");
        require(_nftInfo.totalMinted < _nftInfo.limit, "NFT limited is reached");
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(user, newItemId);
        _setTokenURI(newItemId, _nftInfo.tokenURI);
        typesOfAllNFTs[newItemId] = _nftType;
        _nftInfo.totalMinted += 1;
        nftTypes[_nftType] = _nftInfo;
        emit NFTMinted(newItemId, _nftType, user);
        return newItemId;
    }

    function payAndBuy(address user, uint256 _nftType) public returns (uint256) {
        NFTInfo memory _nftInfo = nftTypes[_nftType];
        require(_nftInfo.isActive, "NFT type is not available");
        require(_nftInfo.totalMinted < _nftInfo.limit, "NFT limited is reached");
        SafeERC20.safeTransferFrom(stableCoin, msg.sender, address(this), _nftInfo.price);
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(user, newItemId);
        _setTokenURI(newItemId, _nftInfo.tokenURI);
        typesOfAllNFTs[newItemId] = _nftType;
        _nftInfo.totalMinted += 1;
        nftTypes[_nftType] = _nftInfo;
        emit NFTMinted(newItemId, _nftType, user);
        return newItemId;
    }

    function ControlMinter(address user, bool _isMinter) onlyOwner public {
        isMinter[user] = _isMinter;
    }

    function getNFTPrice(uint256 _nftType) view public returns(uint256) {
        return nftTypes[_nftType].price;
    } 

    function withDraw(uint256 _value) onlyOwner public {
        SafeERC20.safeTransfer(IERC20(stableCoin),msg.sender, _value);
    }

    function getNFTsOfUser(address _user) public view returns(NFTInfo[] memory){
        uint256 _total = balanceOf(_user);
        NFTInfo[] memory _nftsOfUser = new NFTInfo[](_total);
        uint256 cnt = 0;
        for(uint256 i=1;i<=_tokenIds.current();i++){
            if(ownerOf(i) == _user){
                _nftsOfUser[cnt] = nftTypes[typesOfAllNFTs[i]];
                cnt++;
            }
            if(cnt==_total){
                break;
            }
        }
        return _nftsOfUser;
    }

    function getNFTIdsOfUser(address _user) public view returns(uint256[] memory){
        uint256 _total = balanceOf(_user);
        uint256[] memory _tokens = new uint256[](_total);
        uint256 cnt = 0;
        for(uint256 i=1;i<=_tokenIds.current();i++){
            if(ownerOf(i) == _user){
                _tokens[cnt] = i;
                cnt++;
            }
            if(cnt==_total){
                break;
            }
        }
        return _tokens;
    }

    function getAllNFTS() public view returns(NFTInfo[] memory){
        uint256 _total = _typeIds.current();
        NFTInfo[] memory _nfts = new NFTInfo[](_total);
        for(uint256 i=1;i<=_total;i++){
            _nfts[i-1] = nftTypes[i];
        }
        return _nfts;
    }

}