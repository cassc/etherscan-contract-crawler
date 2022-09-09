// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721A.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract Forkers is Ownable, ERC721A, ReentrancyGuard {

    error MintedOutThisType();

    struct SupplyData {
        uint16 minerSupply;
        uint16 stakerSupply;
    }

    struct UserBalances {
        uint64 balanceOfMiners;
        uint64 balanceOfStakers;
    }

    address public gameContract;

    uint256 constant MAX_SUPPLY = 10000;

    string private URI;

    enum ChainType { STAKER, MINER }

    mapping(uint256 => ChainType) tokenType;

    mapping(address => UserBalances) customBalances;

    mapping(bytes32 => uint64) public attributePoints;
    
    bool public merged = false;
    bool public devMinted = false;

    ChainType thisChain;

    SupplyData supplyData = SupplyData({
        minerSupply: 0,
        stakerSupply: 0
    });


    constructor() ERC721A("Forkers", "FORK") {
        
    }

    modifier canMintType(ChainType typeOf) {
        if(typeOf == ChainType.MINER && supplyData.minerSupply >= 5000) revert MintedOutThisType();
        if(typeOf == ChainType.STAKER && supplyData.stakerSupply >= 5000) revert MintedOutThisType();
        _;
    }

    function mint(ChainType typeOf, bytes32 refCode) public canMintType(typeOf) nonReentrant {
        require(_getAux(msg.sender) == 0, "Wallet already minted");
        require(!merged, "Already merged");
        require(tx.origin == msg.sender, "No contracts");
        require(typeOf == ChainType.STAKER || typeOf == ChainType.MINER, "Wrong type");

        _setAux(msg.sender, 1);

        if(typeOf == ChainType.MINER) {
            supplyData.minerSupply++;

            //Only need to write when miner is minted because 0 will be default for staker.
            tokenType[_totalMinted() + 1] = typeOf;
        }

        if(typeOf == ChainType.STAKER)
            supplyData.stakerSupply++;

        _mint(msg.sender, 1, "", false);

        bytes32 myRefCode = getRefCode(msg.sender);

        if(myRefCode != refCode) {
            _addAttributePointsFor(refCode, 1);
            _addAttributePointsFor(myRefCode, 1);
        }


    }

    function canMint(address _address) external view returns (bool) {
        return _getAux(_address) == 0;
    }

    function getRefCode(address _address) public pure returns (bytes32) {
        return bytes32(keccak256(abi.encodePacked(_address)));
    }

    function getAttributePointsFor(address _address) public view returns (uint64) {
        bytes32 refCode = getRefCode(_address);

        return attributePoints[refCode];
    }

    function _addAttributePointsFor(bytes32 refCode, uint64 amount) internal {
        attributePoints[refCode] += amount;
    }

    function spendAttributePoints(address _address) public {
        require(msg.sender == gameContract, "Not game contract");

        bytes32 refCode = getRefCode(_address);
        attributePoints[refCode] = 0;
    }

    function DIEFORKER(uint256 token) public {
        require(msg.sender == gameContract, "Not game contract");

        _burn(token);
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        if(merged) {
            ChainType chainType = tokenType[tokenId];

            return chainType == thisChain ? super.ownerOf(tokenId) : address(0);
        }

        return super.ownerOf(tokenId);
    }

    function totalSupply() public view override returns (uint256) {
        if(merged) {

            if(thisChain == ChainType.MINER)
                return supplyData.minerSupply;

            if(thisChain == ChainType.STAKER)
                return supplyData.stakerSupply;
        }

        return super.totalSupply();
    }

    function _isSameChain(uint256 tokenId) internal view returns (bool) {
        ChainType chainType = tokenType[tokenId];
        
        return chainType == thisChain;
    }

    function _exists(uint256 tokenId) internal view override returns (bool) {

        if(merged && !_isSameChain(tokenId)) return false;

        return super._exists(tokenId);
    }

    function balanceOf(address owner) public view override returns (uint256) {

        if(merged) {

            UserBalances memory balances = customBalances[owner];
            
            if(thisChain == ChainType.MINER)
                return balances.balanceOfMiners;

            if(thisChain == ChainType.STAKER)
                return balances.balanceOfStakers;
    
        }
        
        return super.balanceOf(owner);
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override {
        if(merged) require(_isSameChain(startTokenId), "Wrong Chain");

        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override {

        ChainType chain = tokenType[startTokenId];

        UserBalances storage toBalances = customBalances[to];
        UserBalances storage fromBalances = customBalances[from];
        

        if(chain == ChainType.STAKER) {

            if(from != address(0))
                fromBalances.balanceOfStakers -= uint64(quantity);

            toBalances.balanceOfStakers += uint64(quantity);
        }

        if(chain == ChainType.MINER) {

            if(from != address(0))
                fromBalances.balanceOfMiners -= uint64(quantity);

            toBalances.balanceOfMiners += uint64(quantity);
        }

        super._afterTokenTransfers(from, to, startTokenId, quantity);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {

        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory cType = tokenType[tokenId] == ChainType.STAKER ? "staker/" : "miner/";

        return string(abi.encodePacked(URI, cType, Strings.toString(tokenId), ".json"));
    }

    function getMintData() external view returns (uint16, uint16) {
        return (supplyData.minerSupply, supplyData.stakerSupply);
    }

    function setThisChain(ChainType chain) public onlyOwner {
        require(!merged, "Already merged");
        thisChain = chain;
    }

    function devMint() public onlyOwner {
        require(!devMinted, "Already claimed");
        require(supplyData.stakerSupply + 200 <= 5000, "Too slow bro..");
        
        _mint(msg.sender, 200, "", false);
        supplyData.stakerSupply += 200;

        devMinted = true;
    }

    function setGameContract(address _contract) public onlyOwner {
        gameContract = _contract;
    }

    function setMerged(bool _state) public onlyOwner {
        merged = _state;
    }

    function setBaseURI(string memory base) public onlyOwner {
        URI = base;
    }

    function _startTokenId() internal view override virtual returns (uint256) {
        return 1;
    }

}