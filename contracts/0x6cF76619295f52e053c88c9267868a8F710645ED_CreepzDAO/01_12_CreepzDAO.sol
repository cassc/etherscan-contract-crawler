// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0; 

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";



contract CreepzDAO is ERC721, Ownable {

    uint256 public saleOpens = 1644775200;
    uint256 public TOKEN_PRICE = 0.04 ether;
    uint256 public totalTokens;
    uint256 public MAX_TOKENS_PER_WALLET = 5;
    uint256 public MAX_SUPPLY = 5000;

    address teamWallet = 0x419894cb1B4E04f4521fd79e470a379066F0149e;

    mapping(address => uint256) public walletMints;
    
    string private BASE_URI = "https://creepzdao.io/api/?token_id=";

    constructor() ERC721("CreepzDAO", "CreepzDAO") {}
    
    function mint(uint16 numberOfTokens) external payable  {
        require(block.timestamp >= saleOpens, "Sale not open");
        require(totalTokens + numberOfTokens <= MAX_SUPPLY, "Not enough");
        require(walletMints[msg.sender] + numberOfTokens <= MAX_TOKENS_PER_WALLET, "Max 3");
        require(TOKEN_PRICE * numberOfTokens <= msg.value, 'missing eth');

        for(uint256 i = 1; i <= numberOfTokens; i+=1) {
            _safeMint(msg.sender, totalTokens+i);
        }

        totalTokens += numberOfTokens;
        walletMints[msg.sender] += numberOfTokens;
    }

    function airdrop(uint16 numberOfTokens, address userAddress) external onlyOwner {
        for(uint256 i = 1; i <= numberOfTokens; i+=1) {
            _safeMint(userAddress, totalTokens+i);
        }
        totalTokens += numberOfTokens;
    }

    function setSaleStart(uint256 _time) external onlyOwner {
        saleOpens = _time;
    }

    function setTokenPrice(uint256 price) external onlyOwner {
        TOKEN_PRICE = price;
    }
    function setMaxSupply(uint256 maxTokens) external onlyOwner {
        MAX_SUPPLY = maxTokens;
    }
    function setMaxPerWallet(uint256 maxTokens) external onlyOwner {
        MAX_TOKENS_PER_WALLET = maxTokens;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        BASE_URI = baseURI;
    }
    
    function _baseURI() internal view override returns (string memory) {
        return BASE_URI;
    }

    function withdrawBalance() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(teamWallet).call{value: balance}("");
        delete balance;
    }

    function tokensOfOwner(address _owner) external view returns(uint[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 tokenid;
            uint256 index;
            for (tokenid = 0; tokenid < totalTokens; tokenid++) {
                if(_exists(tokenid)){
                    if(_owner == ownerOf(tokenid)){
                        result[index]=tokenid;
                        index+=1;
                    }
                }
            }
            delete tokenid;
            delete tokenCount;
            delete index;
            return result;
        }
    }

    function totalSupply() public view virtual returns(uint256){
        return totalTokens;
    }

}