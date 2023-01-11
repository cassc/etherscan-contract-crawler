// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract TheRisingLight is ERC721Enumerable, Ownable {
    using Strings for uint256;

    uint256 constant public MAX_SUPPLY = 555;

    uint256 public salePhase;

    address public withdrawer;

    uint256 public mintPrice = 0.025 ether;
    
    string private baseURI;

    mapping(address => bool) public isWhitelisted;

    constructor() ERC721 ("TheRisingLight", "TRL") {
        salePhase = 2;
        baseURI = "https://maroon-elegant-marmoset-533.mypinata.cloud/ipfs/QmT7ZA77TYhPRQVAto92PGozWFtrFigZiSWUQaurfGomzX/";
        withdrawer = 0x451a69da1924B95Adfca1f57F903F57dCd524487;
    }
    
    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function tokenURI(uint256 tokenId) public override view returns(string memory) {
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    function setPrice(uint256 price) external onlyOwner {
        mintPrice = price;
    }

    function setSalePhase(uint256 salePhase_) external onlyOwner {
        salePhase = salePhase_;
    }

    function setWithdrawer(address withdrawer_) external onlyOwner {
        withdrawer = withdrawer_;
    }

    function addToWhitelist(address[] memory _whitelistAddresses) public onlyOwner {
        for(uint256 i=0; i<_whitelistAddresses.length; i++){
            isWhitelisted[_whitelistAddresses[i]]=true;
        } 
    }

    function mint(uint256 numberOfTokens) external payable {
        require(salePhase != 0, "sale not active");
        if(salePhase == 1){
            require(isWhitelisted[msg.sender], "address not whitelisted"); 
        }
        require(numberOfTokens > 0 && numberOfTokens <= 5, "can only mint between 1 and 5 tokens at a time");
        require(msg.value >= mintPrice * numberOfTokens, "eth sent not valid");
        require(totalSupply() + numberOfTokens < MAX_SUPPLY, "exceed max supply");

        for(uint256 i = 0; i < numberOfTokens; i ++){
            _safeMint(msg.sender, totalSupply());
        }
    }

    function withdraw() external onlyOwner {
        uint256 _balance = address(this).balance;
        payable(withdrawer).transfer(_balance);
    }
}