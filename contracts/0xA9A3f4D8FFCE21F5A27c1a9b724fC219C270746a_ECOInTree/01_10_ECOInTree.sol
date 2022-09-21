// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title ECOInTree NFT Project
import "./ERC721A.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./EIP20Interface.sol";
import "./AggregatorV3Interface.sol";

contract ECOInTree is ERC721A, Ownable, ReentrancyGuard {


    //To concatenate the URL of an NFT
    using Strings for uint256;

    //Number of NFTs in the collection
    uint public constant MAX_SUPPLY = 100000000;
    //Maximum number of NFTs an address can mint
    uint public max_mint_allowed = 1000000;
    //Price of one NFT in sale
    uint public priceSale = 0.0038 ether;

    uint256 addr_rate1 = 5;
    uint256 addr_rate2 = 10;
    uint256 addr_rate3 = 85;
    address addr_1 = 0x90a84Fc95380aEcF3F6fd0933647418690f2a84c;
    address addr_2 = 0x9AEFf3996E54D5661a209bE2fd571141A363D68d;
    address addr_3 = 0x165a4fe9172Ad154b37A97aDb5a96293747C5546;
    uint256 addr_num1;
    uint256 addr_num2;
    uint256 addr_num3;

    /// @notice USDT token
    EIP20Interface public usdt;
    AggregatorV3Interface internal priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
    
    //Constructor of the collection
    constructor(address _usdtAddress) ERC721A("ECO-In Tree", "ECO-In Tree") {
        usdt = EIP20Interface(_usdtAddress);
    }

    /** 
    * @notice Change the number of NFTs that an address can mint
    *
    * @param _maxMintAllowed The number of NFTs that an address can mint
    **/
    function changeMaxMintAllowed(uint _maxMintAllowed) external onlyOwner {
        max_mint_allowed = _maxMintAllowed;
    }

    function changePriceSale(uint _priceSale) external onlyOwner {
        priceSale = _priceSale;
    }

    /**
    * @notice Allows to mint NFTs
    *
    * @param _amount The amount of NFTs the owner wants to mint
    **/
    function saleMint(address addr, uint256 _amount) external onlyOwner nonReentrant {  
        require(_amount <= max_mint_allowed, "Exceeded the limit"); 
        //Get the number of NFT sold
        uint numberNftSold = totalSupply();
        //If the user try to mint any non-existent token
        require(numberNftSold + _amount <= MAX_SUPPLY, "Sale is almost done and we don't have enought NFTs left.");
        _safeMint(addr, _amount);
    }

    function buyNFTWithETH(uint256 amount) external payable nonReentrant {
        require(amount <= max_mint_allowed, "Exceeded the limit"); 
        uint256 numberNftSold = totalSupply();
        require(numberNftSold + amount <= MAX_SUPPLY, "Sale is almost done and we don't have enought NFTs left.");
        require(msg.value >= priceSale * amount, "Not enough ether sent");
        
        addr_num1 = priceSale * amount * addr_rate1 / 100;
        addr_num2 = priceSale * amount * addr_rate2 / 100;
        addr_num3 = priceSale * amount * addr_rate3 / 100;
        payable(addr_1).transfer(addr_num1);
        payable(addr_2).transfer(addr_num2);
        payable(addr_3).transfer(addr_num3);
        if(msg.value > priceSale * amount){
            payable(msg.sender).transfer(msg.value - priceSale * amount);
        }

        _safeMint(msg.sender, amount);
    }

    function buyNFTWithERC20(uint256 amount) external nonReentrant {
        require(amount <= max_mint_allowed, "Exceeded the limit"); 
        uint256 numberNftSold = totalSupply();
        require(numberNftSold + amount <= MAX_SUPPLY, "Sale is almost done and we don't have enought NFTs left.");
        uint256 ethPrice = getLatestPrice(); 
        addr_num1 = priceSale * amount * ethPrice * (10 ** usdt.decimals()) * addr_rate1 / 100 / 1e8 / 1e18;
        addr_num2 = priceSale * amount * ethPrice * (10 ** usdt.decimals()) * addr_rate2 / 100 / 1e8 / 1e18;
        addr_num3 = priceSale * amount * ethPrice * (10 ** usdt.decimals()) * addr_rate3 / 100 / 1e8 / 1e18;
        usdt.transferFrom(msg.sender, addr_1, addr_num1);
        usdt.transferFrom(msg.sender, addr_2, addr_num2);
        usdt.transferFrom(msg.sender, addr_3, addr_num3);

        _safeMint(msg.sender, amount);
    }

    function getLatestPrice() public view returns (uint256) {
        (, int price, , ,) = priceFeed.latestRoundData();
        return uint256(price);
    }

    /**
    * @notice Allows to get the complete URI of a specific NFT by his ID
    *
    * @param _nftId The id of the NFT
    *
    * @return The token URI of the NFT which has _nftId Id
    **/
    function tokenURI(uint _nftId) public view override(ERC721A) returns (string memory) {
        require(_exists(_nftId), "This NFT doesn't exist.");
        return string(abi.encodePacked("https://econft.market/service/meta-eco-tree.php?id=",Strings.toString(_nftId)));
    }   

}