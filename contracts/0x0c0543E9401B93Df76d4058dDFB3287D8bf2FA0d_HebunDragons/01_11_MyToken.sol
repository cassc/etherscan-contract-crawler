// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "erc721a/contracts/ERC721A.sol";

contract HebunDragons is ERC721A, Ownable {
    bool public isPublicSaleActive = false;
    string private baseURI;
    uint public maxSupply = 333;
    uint public mintPrice = 0.003 ether;
    uint public maxPerWallet = 3;
    mapping(address => uint256) public quantityMinted; 

    constructor(string memory _baseNftURI) ERC721A("Hebun Dragons", "HDR") {
        baseURI = _baseNftURI;

        _safeMint(msg.sender, 1);
    }

    function setBaseUri(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }
    
    function publicMint(uint256 quantity) public payable {
        require(totalSupply() + quantity <= maxSupply);
        require(isPublicSaleActive == true);
        require(quantityMinted[msg.sender] + quantity <= maxPerWallet);
        require(msg.value == mintPrice * quantity);
        require(msg.sender == tx.origin);

        _safeMint(msg.sender, quantity);
        quantityMinted[msg.sender] += quantity;
    }

    
    function togglePublicSale() public onlyOwner {
        isPublicSaleActive = !isPublicSaleActive;
    }


    function withdrawMoney(address receiver) public onlyOwner {
        address payable _to = payable(receiver);
        address _thisContract = address(this);
        _to.transfer(_thisContract.balance);
    }
    

    function preMint(uint256 quantity) public onlyOwner {
        require(totalSupply() + quantity <= maxSupply, "All NFT have already been minted!");
        _safeMint(msg.sender, quantity);
    }

    function airdropNfts(uint256 quantity, address[] calldata addresses) public onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], quantity);
        }
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

    receive() external payable {} 
}