// SPDX-License-Identifier: NULL
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "hardhat/console.sol";

contract MockContract is ERC721,Ownable,ReentrancyGuard{

    using SafeMath for uint256;
    
    uint256 public tokenCounter;
    uint256 public constant MAX_TOKENS = 555;
    uint256 public constant PRICE = 300000000000000; //0.3 ETH
    bool public saleIsActive = false;
    string private uri;
    string private _baseTokenURI;

    mapping(address => uint256) private validNumberOfTokensPerBuyerMap;
    mapping(address => uint256) private tokenBalancePerOwner;
    mapping(address => bool) private whitelistClaimed;

    constructor( 
        string memory name, 
        string memory symbol,
        string memory initialURI
    ) ERC721(name, symbol) ReentrancyGuard(){
        tokenCounter=0;
        uri = initialURI;
    }

    function flipSale() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function getValidNumberOfTokens(address sampleAddress) public view returns (uint256){
        return validNumberOfTokensPerBuyerMap[sampleAddress];
    }

    function mintNFT() payable public nonReentrant() {
        uint numberOfTokens = validNumberOfTokensPerBuyerMap[msg.sender];
        uint remainingBalance = numberOfTokens.sub(tokenBalancePerOwner[msg.sender]);

        require(saleIsActive, 'sale is not active');
        require(remainingBalance > 0, 'you have claimed all your tokens');
        require(PRICE.mul(remainingBalance) == msg.value, "Ether value sent is not correct");
        require(tokenCounter.add(remainingBalance) <= MAX_TOKENS, "tokens has now sold out");
        
        for(uint256 i = 0; i < remainingBalance; i++) {
            _safeMint(msg.sender, tokenCounter);
            tokenCounter++;
            tokenBalancePerOwner[msg.sender]++;
        }
    }

    function  balanceOf(address sampleAddress) public view virtual override returns (uint256){
        return tokenBalancePerOwner[sampleAddress];
    }

    function setBaseURI(string calldata newBaseTokenURI) public onlyOwner{
        uri = newBaseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory)
    {
        return string(abi.encodePacked(uri));
    }

    /*
    * whitelist addresses with more than one valid number of tokens for presale
    */
    function whitelistAddresses(address[] calldata wallets, uint256[] calldata validTokens) public onlyOwner {
        for(uint256 i=0; i<wallets.length;i++) {
            validNumberOfTokensPerBuyerMap[wallets[i]] = validTokens[i];
        }
    }

}