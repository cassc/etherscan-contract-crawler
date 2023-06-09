// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import './ERC721A.sol';

contract ForgottenDog is Ownable, ERC721A, ReentrancyGuard {

    uint16 public immutable MAX_SUPPLY = 10000;
    uint16 public immutable MAX_TEAM_SUPPLY = 1000;
    uint public immutable PRICE_AFTER_8 = 0.002 ether;
    uint16 public teamCounter = 0;
    uint8 public saleStage; // 0: PAUSED | 1: SALE | 2: SOLDOUT
    string public baseTokenURI;

    address public immutable DEVELOPER_ADDRESS = 0x8306865FAb8dEC66a1d9927d9ffC4298500cF7Ed;
    address public immutable FINANCIER_ADDRESS = 0x682e5d1B097E55228F5E2B5D0f6212Ffa645cC02; 
    address public immutable DESIGNER_ADDRESS = 0xF416f708a855d65567a6456e3908Bba4b9229922;
    address public immutable MARKETER_ADDRESS = 0x600450fa4B0a108c1fcEc19Cb6a4E09514AEC9b8; 
    address public immutable VAULT_ADDRESS = 0x4D864d0B967D97A779Cd1b14ECb780c08b8aA3Dd; 

    constructor() ERC721A('forgottendog.wtf', 'FORGOTTENDOG', 20, 10000) {
        saleStage = 0;
    }

    // UPDATE SALESTAGE

    function setSaleStage(uint8 _saleStage) external onlyOwner {
        require(saleStage != 2, "Cannot update if already reached soldout stage.");
        saleStage = _saleStage;
    }

    // PUBLIC MINT 

    function publicMint(uint _quantity) external payable nonReentrant {
        require(saleStage == 1, "Public sale is not active.");
        require(_quantity <= 5, "Cannot mint more than 5 at once.");
        require(balanceOf(msg.sender) + _quantity <= 20, "You have reached the max mint amount per holder.");
        if (balanceOf(msg.sender) < 8 && balanceOf(msg.sender) + _quantity > 8) {
            require(msg.value == PRICE_AFTER_8 * (balanceOf(msg.sender) + _quantity - 8), "Insuficient funds.");
        }
        if (balanceOf(msg.sender) >= 8) {
            require(msg.value == PRICE_AFTER_8 * _quantity, "Insuficient funds.");
        }
        require(totalSupply() + _quantity + (MAX_TEAM_SUPPLY-teamCounter) <= MAX_SUPPLY, "Mint would exceed max supply.");

        _safeMint(msg.sender, _quantity);
        if (totalSupply() + (MAX_TEAM_SUPPLY-teamCounter) == MAX_SUPPLY) {
            saleStage = 2;
        }
    }

    // TEAM MINT

    function teamMint(address _to, uint16 _quantity) external onlyOwner {
        require(teamCounter + _quantity <= MAX_TEAM_SUPPLY, "Wouldl exceed max team supply.");
        require(_quantity % maxBatchSize == 0, "can only mint a multiple of the maxBatchSize");
        uint256 numChunks = _quantity / maxBatchSize;
        for (uint256 i = 0; i < numChunks; i++) {
            _safeMint(_to, maxBatchSize);
        }
        teamCounter += _quantity;
    }
    
    // METADATA URI

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseTokenUri(string calldata _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721A) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexisting token");
        string memory base = _baseURI();
        return bytes(base).length > 0 ? string(abi.encodePacked(base, Strings.toString(tokenId), ".json")) : "https://gateway.pinata.cloud/ipfs/QmfENk7ZpU4Q8zrGHoMLbC1HGk3u1bZUxUhC6s8KMhQ9rc";
    }

    // WITHDRAW

    function withdraw() external onlyOwner {
        uint256 ethBalance = address(this).balance;
        payable(FINANCIER_ADDRESS).transfer(ethBalance*20/100);
        payable(DESIGNER_ADDRESS).transfer(ethBalance*40/100);
        payable(VAULT_ADDRESS).transfer(ethBalance*10/100);
        payable(DEVELOPER_ADDRESS).transfer(ethBalance*15/100);
        payable(MARKETER_ADDRESS).transfer(ethBalance*15/100);
    }
}