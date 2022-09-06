// SPDX-License-Identifier: MIT

pragma solidity =0.8.11;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract DraperNFT is ERC721("Draper Heroes NFT Token", "Utility"), ERC721Enumerable, Ownable, Pausable {
    using SafeMath for uint256;
    using Strings for uint256;

    string private blindURI;

    uint256 public BUY_LIMIT_PER_TX = 1;
    uint256 public MAX_NFT = 24;
    uint256 public NFTPrice; // = 1000000000000000;  // 0.001 ETH

    //0: No Utility, 1: Draper University Reunion/Secret meeting, 2: Draper Venture Network Summit, 3: Draper Startup House Franchise, 4: Meet the Drapers Accelerated Pass
    mapping(uint256 => uint256) public utility;
    mapping(uint256 => bool) public member_state;

    constructor() {}

    /*
     * Function to withdraw collected amount during minting
    */
    function withdraw(address _to) public onlyOwner {
        uint balance = address(this).balance;
        payable(_to).transfer(balance);
    }

    /*
     * Function to mint new NFTs
     * It is payable. Amount is calculated as per (NFTPrice*_numOfTokens)
    */
    function mintNFT(uint256 _numOfTokens, uint256 _utility) public payable whenNotPaused {
        require(_numOfTokens <= BUY_LIMIT_PER_TX, "Can't mint above limit");
        require(totalSupply().add(_numOfTokens) <= MAX_NFT, "Purchase would exceed max supply of NFTs");
        //require(NFTPrice.mul(_numOfTokens) == msg.value, "Ether value sent is not correct");

        for(uint i=0; i < _numOfTokens; i++) {
            uint256 id = totalSupply() + 1;
            _safeMint(msg.sender, id);
            utility[id] = _utility;
            member_state[id] = true;
        }
    }

    /*
     * Function to get token URI of given token ID
     * URI will be blank untill totalSupply reaches MAX_NFT
    */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
       
        return string(abi.encodePacked(blindURI, tokenId.toString(), ".json"));
    }

    /*
     * Function to set Base and Blind URI 
    */
    function setURIs(string memory _blindURI) external onlyOwner {
        blindURI = _blindURI;
    }

    /*
     *
     Function to update the NFT Mint Price
    */
    function updateNFTPrice(uint256 _newPrice) external onlyOwner {
        NFTPrice = _newPrice;
    }

    /*
     * Function to pause 
    */
    function pause() external onlyOwner {
        _pause();
    }

    /*
     * Function to unpause 
    */
    function unpause() external onlyOwner {
        _unpause();
    }

    /*
     * utility access lock
    */
    function lock(uint256 _id) public returns(bool){
        require(msg.sender == ownerOf(_id), "You are not owner!");
        member_state[_id] = false;
        return true;
    }

    /*
     * utility access unlock
    */
    function unlock(uint256 _id) public returns(bool){
        require(msg.sender == ownerOf(_id), "You are not owner!");
        member_state[_id] = true;
        return true;
    }

    // Standard functions to be overridden 
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, 
    ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}