// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./ERC721A.sol";

contract AMIL is ERC721A, Ownable {
    bool public SaleIsActive;

    uint8 public constant MaxPerTransaction = 30;
    uint16 public constant MaxFreeTokens = 1000;
    uint16 public constant MaxTokens = 10000;
    uint256 public TokenPrice = 0.015 ether;

    string private _baseTokenURI;
    
    constructor() ERC721A("Anti-Miladies", "AMIL", MaxPerTransaction, MaxTokens) {

    }

    function withdraw() external onlyOwner {
        (bool success,) = msg.sender.call{value: address(this).balance}("");
        require(success);
    }

    function mint(uint256 numTokens) external payable {
        require(SaleIsActive, "Sale must be active in order to mint");
        require(numTokens <= MaxPerTransaction, "Higher than max per transaction");
        require(totalSupply() + numTokens <= MaxTokens, "Purchase more than max supply");

        if (totalSupply() >= MaxFreeTokens)
            require(msg.value >= numTokens * TokenPrice, "Ether too low");
            
        _safeMint(_msgSender(), numTokens);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function getTokensOfUser(address user) external view returns (uint256[] memory) {
        uint256 balance = balanceOf(user);
        uint256[] memory tokens = new uint256[](balance);

        for (uint256 i = 0; i < balance; i++) {
            tokens[i] = tokenOfOwnerByIndex(user, i);
        }

        return tokens;
    }

    function toggleSaleState() external onlyOwner {
        SaleIsActive = !SaleIsActive;
    }

    function setTokenPrice(uint256 tokenPrice) external onlyOwner {
        TokenPrice = tokenPrice;
    }
           
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }
}