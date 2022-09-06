// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract GoblinChestMintPass is ERC721A, Ownable{
    using Strings for uint256;
    string private  baseTokenUri;
    string public   placeholderTokenUri = "ipfs://QmbCMLVJXwbbdVjJmnwc2i5QMtCJLwMVUZ7hQ6t8jyUsus/";
    bool public isRevealed;
    

    constructor() ERC721A("Goblin Chest Mint Pass", "GCMP"){

    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Cannot be called by a contract");
        _;
    }
    function safeMintToBulk(address[500] memory _users) public onlyOwner
    {   
            for(uint i = 0; i < 500; i++) {
            _mint(_users[i], 1);
        }
    }
    
    function mintOne(address _receiver) external onlyOwner{
        _mint(_receiver, 1);
    }    

    function teamMint() external onlyOwner{
        _safeMint(msg.sender, 500);

    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenUri;
    }

    //return uri for certain token
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        uint256 trueId = tokenId + 1;

        if(!isRevealed){
            return placeholderTokenUri;
        }
        //string memory baseURI = _baseURI();
        return bytes(baseTokenUri).length > 0 ? string(abi.encodePacked(baseTokenUri, trueId.toString(), ".json")) : "";
    }

    function setTokenUri(string memory _baseTokenUri) external onlyOwner{
        baseTokenUri = _baseTokenUri;
    }
    function setPlaceHolderUri(string memory _placeholderTokenUri) external onlyOwner{
        placeholderTokenUri = _placeholderTokenUri;
    }

    function withdraw() external onlyOwner{
        payable(msg.sender).transfer(address(this).balance);
    }
}