// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./MalibuCoinI.sol";
import "./ERC721AI.sol";
                              
//     ______  ______  ______  ______  __  __       __  __  __  __  ______             
//    /\  == \/\  ___\/\  __ \/\  ___\/\ \_\ \     /\ \_\ \/\ \/\ \/\__  _\            
//    \ \  __<\ \  __\\ \  __ \ \ \___\ \  __ \    \ \  __ \ \ \_\ \/_/\ \/            
//     \ \_____\ \_____\ \_\ \_\ \_____\ \_\ \_\    \ \_\ \_\ \_____\ \ \_\            
//      \/_____/\/_____/\/_/\/_/\/_____/\/_/\/_/     \/_/\/_/\/_____/  \/_/            
//     __    __  ______  __    __  ______  ______  ______  ______  __  __  __  ______  
//    /\ "-./  \/\  ___\/\ "-./  \/\  == \/\  ___\/\  == \/\  ___\/\ \_\ \/\ \/\  == \ 
//    \ \ \-./\ \ \  __\\ \ \-./\ \ \  __<\ \  __\\ \  __<\ \___  \ \  __ \ \ \ \  _-/ 
//     \ \_\ \ \_\ \_____\ \_\ \ \_\ \_____\ \_____\ \_\ \_\/\_____\ \_\ \_\ \_\ \_\   
//      \/_/  \/_/\/_____/\/_/  \/_/\/_____/\/_____/\/_/ /_/\/_____/\/_/\/_/\/_/\/_/   

contract BeachHutMembership is ERC1155Supply, Ownable, ReentrancyGuard {

    string collectionURI = "";
    string private name_;
    string private symbol_; 
    uint256 public tokenPrice;
    uint256 public tokenDiscount;
    uint256 public salesPrice;
    uint256 public tokenQty;
    uint256 public maxMintQty;
    uint256 public currentTokenId;
    bool public paused;
    address public CoinContract;
    address public BABHContract;

    mapping(address => uint256) private lastRewardOfCoins;
    mapping(address => uint256) private retroActiveReward;

    MalibuCoinI public coin;
    ERC721AI public babh;

    constructor() ERC1155(collectionURI) {
        name_ = "Beach Hut Membership";
        symbol_ = "MBHM";
        tokenPrice = 0.15 ether;
        tokenDiscount = 0.05 ether;
        tokenQty = 50;
        maxMintQty = 1;
        currentTokenId = 1;
        paused = true;
    }
    
    function name() public view returns (string memory) {
      return name_;
    }

    function symbol() public view returns (string memory) {
      return symbol_;
    }

    function mint(uint256 amount)
        public
        payable
        nonReentrant
    {
        require(paused == false, "Minting is paused");
        require(totalSupply(currentTokenId) < tokenQty, "Memberships all minted");
        require(amount <= maxMintQty, "Mint quantity is too high");
        require(tx.origin == _msgSender(), "The caller is another contract");

        salesPrice = tokenPrice;
        if(babh.balanceOf(_msgSender()) > 0) {
            salesPrice = salesPrice - tokenDiscount;
            if(babh.balanceOf(_msgSender()) >= 10) {
                salesPrice = salesPrice - tokenDiscount;
            }
        } 

        require(amount * salesPrice == msg.value, "You have not sent the correct amount of ETH");
        _mint(_msgSender(), currentTokenId, amount, "");
    }

    //=============================================================================
    // Reward Functions
    //=============================================================================

    function getLastRewarded(address account) external view returns (uint256) {
        return lastRewardOfCoins[account];
    }

    function setLastRewarded(address account) external {
        require(_msgSender() == CoinContract, "Only callable from custom ERC20 contract");
        lastRewardOfCoins[account] = block.timestamp;
    }

    function getRetroActiveRewards(address account) external view returns (uint256) {
        return retroActiveReward[account];
    }

    function resetRetroActiveRewards(address account) external {
        require(_msgSender() == CoinContract, "Only callable from custom ERC20 contract");
        retroActiveReward[account] = 0;
    }

    //=============================================================================
    // Admin Functions
    //=============================================================================

    function adminMintOverride(address account, uint256 id, uint256 amount) public onlyOwner {
        _mint(account, id, amount, "");
    }

    function setCollectionURI(string memory newCollectionURI) public onlyOwner {
        collectionURI = newCollectionURI;
    }

    function getCollectionURI() public view returns(string memory) {
        return collectionURI;
    }

    function setTokenPrice(uint256 price) public onlyOwner {
        tokenPrice = price;
    }

    function setTokenDiscount(uint256 price) public onlyOwner {
        tokenDiscount = price;
    }

    function setTokenQty(uint256 qty) public onlyOwner {
        tokenQty = qty;
    }

    function setMaxMintQty(uint256 qty) public onlyOwner {
        maxMintQty = qty;
    }

    function setCurrentTokenId(uint256 id) public onlyOwner {
        currentTokenId = id;
    }

    function togglePaused() public onlyOwner {
        paused = !paused;
    }

    function setBABHContract(address _contract) external onlyOwner {
        require(_contract != address(0), "Can not be address 0");
        babh = ERC721AI(_contract);
        BABHContract = _contract;
    }

    function setMalibuCoin(address _contract) external onlyOwner {
        require(_contract != address(0), "Can not be address 0");
        coin = MalibuCoinI(_contract);
        CoinContract = _contract;
    }

    function withdrawETH() public onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
    }

    //=============================================================================
    // Override Functions
    //=============================================================================
    
    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal override(ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (getMembershipTokenCount(to) == 0) { 
            lastRewardOfCoins[to] = block.timestamp;
        } else {
            if (coin.getUnclaimedMalibuCoins(to) > 0) {
                retroActiveReward[to] = coin.getUnclaimedMalibuCoins(to);
                lastRewardOfCoins[to] = block.timestamp;
            }
        }
    }

    function getMembershipTokenCount(address account) public view returns (uint256) {

        uint256 membershipTokenId = 0;
        uint256 membershipTokenCount = 0;

        do {
            membershipTokenId++;
            if (balanceOf(account, membershipTokenId) >= 1) {

                membershipTokenCount += balanceOf(account, membershipTokenId);
            }
        } while (exists(membershipTokenId));

        return membershipTokenCount;
    }

    function uri(uint256 _tokenId) public override view returns (string memory) {
        return string(abi.encodePacked(collectionURI, Strings.toString(_tokenId), ".json"));
    }    
}