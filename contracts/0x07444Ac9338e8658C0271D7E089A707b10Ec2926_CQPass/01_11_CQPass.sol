// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CQPass is ERC721, Ownable {

    uint256 constant public MAX_CHOSEN = 690;
    uint256 constant public MAX_HODLER = MAX_CHOSEN + 121;

    uint256 _chosenTokenId = 1;
    uint256 _hodlerTokenId = MAX_CHOSEN + 1;
    string _tokenBaseURI = "";

    constructor(address owner, string memory baseURI) ERC721("Cryptosquare Choos3n", "CSQ") {
        _tokenBaseURI = baseURI;
        // Premint pass tokens
        for (uint16 i = 0; i < 340; i++) {
            _safeMint(owner, _chosenTokenId);
            _chosenTokenId++;
        }
        for (uint16 i = 0; i < 51; i++) {
            _safeMint(owner, _hodlerTokenId);
            _hodlerTokenId++;
        }
        _transferOwnership(owner);
    }

    function mintChosen() public payable {
        require(_chosenTokenId <= MAX_CHOSEN, "All chosens have been minted");
        require(msg.value == getChosenPrice(), "Wrong ETH amount sent");
        _safeMint(msg.sender, _chosenTokenId);
        _chosenTokenId++;
    }

    function mintHodler() public payable {
        require(_hodlerTokenId <= MAX_HODLER, "All hodlers have been minted");
        require(msg.value == getHodlerPrice(), "Wrong ETH amount sent");
        _safeMint(msg.sender, _hodlerTokenId);
        _hodlerTokenId++;
    }

    function payout() public onlyOwner {
        address payable _owner = payable(owner());
        _owner.transfer(address(this).balance);
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _tokenBaseURI = baseURI;
    }

    function _baseURI() internal override(ERC721) view returns (string memory) {
        return _tokenBaseURI;
    }

    function getChosenPrice() public view returns (uint256) {
        if (block.timestamp < 1675119600) {
            return 0.2 ether;
        } else if (block.timestamp < 1688162400) {
            return 0.3 ether;
        } else {
            return 0.15 ether;
        }
    }

    function getHodlerPrice() public view returns (uint256) {
        if (block.timestamp < 1675119600) {
            return 0.8 ether;
        } else if (block.timestamp < 1690754400) {
            return 1 ether;
        } else {
            return 0.5 ether;
        }
    }

    // The following functions are overrides required by Solidity.

//    function _burn(uint256 tokenId) internal override(ERC721) {
//        super._burn(tokenId);
//    }

//    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
//        return super.tokenURI(tokenId);
//    }

}