// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721Enumerable.sol";
import "./JunkYardBones.sol";

contract JunkYardDogs is Ownable, ERC721Enumerable  {
    using SafeMath for uint256;

    bool public saleIsActive = false;
    string private baseURI = "https://api.junkyarddogs.io/dogs?tokenId=";
    uint public MAX_PURCHASE = 1;
    address public bonesAddress;
    uint256 public CURRENT_PRICE = 0.08 ether;
    uint256 public FIRST_BATCH = 888;
    uint256 public MAX_TOKENS = FIRST_BATCH;

    constructor(address _bonesAddress) ERC721("JunkYardDogs", "JYD") {
        bonesAddress = _bonesAddress;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function mintAsOwner(uint amount) public onlyOwner {
        uint i;
        uint tokenId;

        for (i = 1; i <= amount; i++) {
            tokenId = totalSupply().add(1);
            if (tokenId <= MAX_TOKENS) {
                _safeMint(msg.sender, tokenId);
            }
        }
    }

    function mint(uint numberOfTokens) public payable {
        require(saleIsActive, "Minting is not allowed right now");
        require(numberOfTokens <= MAX_PURCHASE, "Purchasing more than allowed per transaction");
        require(totalSupply().add(numberOfTokens) <= MAX_TOKENS, "Purchase would exceed max supply");
        require(CURRENT_PRICE.mul(numberOfTokens) <= msg.value, "ETH sent is less than correct price");

        JunkYardBones jyb = JunkYardBones(bonesAddress);
        uint tokenId;        
        for(uint i = 1; i <= numberOfTokens; i++) {
            tokenId = totalSupply().add(1);
            if (tokenId <= MAX_TOKENS) {
                _safeMint(msg.sender, tokenId);
                if (tokenId <= FIRST_BATCH) {
                    jyb.mint(msg.sender, tokenId);
                }
            }
        }
    }

    function setSecondPhase(uint256 maxTokens, uint256 maxPurchase, uint256 currentPrice) public onlyOwner {
        MAX_TOKENS = maxTokens;
        MAX_PURCHASE = maxPurchase;
        saleIsActive = true;
        CURRENT_PRICE = currentPrice;
    }

    function setMaxTokens(uint256 maxTokens) public onlyOwner {
        MAX_TOKENS = maxTokens;
    }

    function setMaxPurchase(uint256 maxPurchase) public onlyOwner {
        MAX_PURCHASE = maxPurchase;
    }

    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setCurrentPrice(uint256 currentPrice) public onlyOwner {
        CURRENT_PRICE = currentPrice;
    }

    function contractURI() public pure returns (string memory) {
        return "https://api.junkyarddogs.io/contract/";
    }
}