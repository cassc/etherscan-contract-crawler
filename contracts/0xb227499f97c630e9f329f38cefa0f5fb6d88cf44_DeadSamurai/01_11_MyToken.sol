// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "erc721a/contracts/ERC721A.sol";

contract DeadSamurai is ERC721A, Ownable {
    bool public isPublicSaleActive = false;
    bool public usedTeamMint = false;

    string private baseURI;
    uint public maxSupply = 333;
    uint public mintPrice = 0.003 ether;
    uint public maxPerWallet = 3;
    mapping(address => uint256) public usedMint; 

    constructor(string memory _baseNftURI) ERC721A("Dead Samurai", "DSA") {
        baseURI = _baseNftURI;

        _safeMint(msg.sender, 1);
    }

    function teamMint(uint256 quantity) public onlyOwner {
        require(totalSupply() + quantity <= maxSupply, "All NFT have already been minted!");
        _safeMint(msg.sender, quantity);
    }


    function setBaseUri(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }
    
    function publicMint(uint256 quantity) public payable {
        require(totalSupply() + quantity <= maxSupply, "All NFT have already been minted!");
        require(isPublicSaleActive == true, "Public sale is inactive!");
        require(quantity > 0, "The quantity must be greater than zero!");
        require(usedMint[msg.sender] + quantity <= maxPerWallet, "You've already minted!");
        require(msg.value == mintPrice * quantity, "Looks like you are trying to pay the wrong amount!");
        require(msg.sender == tx.origin, "Sry about that :(");

        _safeMint(msg.sender, quantity);
        usedMint[msg.sender] += quantity;
    }

    
    function togglePublicSale() public onlyOwner {
        isPublicSaleActive = !isPublicSaleActive;
    }


    function withdrawMoney(address receiver) public onlyOwner {
        address payable _to = payable(receiver);
        address _thisContract = address(this);
        _to.transfer(_thisContract.balance);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        return bytes(_baseURI()).length != 0 ? string(abi.encodePacked(_baseURI(), _toString(tokenId), ".json")) : '';
    }

    function _startTokenId() internal view override virtual returns (uint256) {
        return 1;
    }

    receive() external payable {
        
    } 
}