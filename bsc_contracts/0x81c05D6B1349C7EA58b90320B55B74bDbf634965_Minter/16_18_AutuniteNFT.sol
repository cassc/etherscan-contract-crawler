// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "./Ownable.sol";

contract AutuniteNFT is ERC721, ERC721Enumerable, ERC2981, Ownable {

    uint256 public counter = 10000;
    string public _baseURI_;
    address public minter;
    bool public singleNFT;

    modifier onlyMinter() {
        require(msg.sender == minter, "only Minter can call this function");
        _;
    }

    constructor(
        string memory _uri_,
        string memory _name_,
        string memory _symbol_,
        address _owner_,
        bool _singleNFT_
    ) ERC721(_name_, _symbol_) Ownable(_owner_) {
        _baseURI_ = _uri_;
        minter = msg.sender;
        singleNFT = _singleNFT_;
    }

    function userTokens(address userAddr) public view returns(uint256[] memory tokens) {
        uint256 len = balanceOf(userAddr);
        tokens = new uint256[](len);

        for(uint256 index; index < len; index++) {
            tokens[index] = tokenOfOwnerByIndex(userAddr, index);
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURI_;
    }

    function changeBaseURI(string memory _uri_) public onlyMinter {
        _baseURI_ = _uri_;
    }
    
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyMinter { 
        _setDefaultRoyalty(receiver, feeNumerator);
    }
    
    function deleteDefaultRoyalty() public onlyMinter { 
        _deleteDefaultRoyalty();
    }

    function safeMint(address to) public onlyMinter returns(uint256 tokenId) {
        tokenId = counter++;
        _safeMint(to, tokenId);
    }

    function changeSingleNFT() public onlyMinter {
        if(singleNFT){
            singleNFT = false;
        } else {
            singleNFT = true;
        }
    }

    function changeMinter(address newMinter) public onlyOwner {
        minter = newMinter;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        if(singleNFT) {
            require(balanceOf(to) == 0, "each address just one AUT");
        }
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}