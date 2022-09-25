// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title ECOInTree NFT Project
import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./AggregatorV3Interface.sol";

contract ECOInTree is ERC721A, ERC721AQueryable, Ownable, ReentrancyGuard {


    //To concatenate the URL of an NFT
    using Strings for uint256;
    using SafeERC20 for ERC20;

    //Number of NFTs in the collection
    uint public constant MAX_SUPPLY = 100000000;
    //Maximum number of NFTs an address can mint
    uint public max_mint_allowed = 15000;
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
    ERC20 public usdt;
    AggregatorV3Interface internal priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419); 
    
    //Constructor of the collection
    constructor(address _usdtAddress) ERC721A("ECO-In Tree", "ECO-In Tree") {
        usdt = ERC20(_usdtAddress);
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
        require(addr != address(0), "addr should not be 0x0.");
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
        
        uint256 num1 = priceSale * amount * addr_rate1 / 100;
        uint256 num2 = priceSale * amount * addr_rate2 / 100;
        uint256 num3 = priceSale * amount * addr_rate3 / 100;
        payable(addr_1).transfer(num1);
        payable(addr_2).transfer(num2);
        payable(addr_3).transfer(num3);
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
        uint256 token_amount = priceSale * amount * ethPrice / 1e20;
        ERC20(usdt).safeTransferFrom(msg.sender, address(this), token_amount);
        uint256 num1 = token_amount * addr_rate1 / 100;
        uint256 num2 = token_amount * addr_rate2 / 100;
        uint256 num3 = token_amount - num1 - num2;

        ERC20(usdt).safeTransfer(addr_1, num1);
        ERC20(usdt).safeTransfer(addr_2, num2);
        ERC20(usdt).safeTransfer(addr_3, num3);

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
    function tokenURI(uint _nftId) public view override(IERC721A, ERC721A) returns (string memory) {
        require(_exists(_nftId), "This NFT doesn't exist.");
        return string(abi.encodePacked("https://econft.market/service/meta-eco-tree.php?id=",Strings.toString(_nftId)));
    }   

}