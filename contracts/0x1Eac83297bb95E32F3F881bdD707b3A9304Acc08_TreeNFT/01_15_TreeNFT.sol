// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/token/ERC721/ERC721.sol";
import "@openzeppelin/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/utils/Counters.sol";
import "@openzeppelin/access/Ownable.sol";

contract TreeNFT is ERC721, ERC721Enumerable, Ownable {

    using Counters for Counters.Counter;

    uint256 public TREE_SUPPLY = 100;
    uint256 public TREE_PRICE = 5 ether;

    bool public mintable = false;
    bool public treelistMint = false;

    mapping(address => bool) public treelist;
    
    mapping(address => bool) private _treelistClaimed;
    Counters.Counter private _tokenIds;
    string private BASE_URI;

    constructor() ERC721("TreeNFT", "TREE") Ownable() {

    }

    function addToTreelist(address[] calldata _addrs) external onlyOwner {
        for (uint i = 0; i < _addrs.length; i++) {
            treelist[_addrs[i]] = true;
        }
    }

    function removeFromTreelist(address[] calldata _addrs) external onlyOwner {
        for (uint i = 0; i < _addrs.length; i++) {
            delete treelist[_addrs[i]];
        }
    }

    function checkTreelist(address _addr) external view returns (bool) {
        return treelist[_addr];
    }

    function togglePublicMint() external onlyOwner {
        mintable = !mintable;
    }

    function toggleTreelistMint() external onlyOwner {
        treelistMint = !treelistMint;
    }

    function changePrice(uint256 _price) external onlyOwner {
        TREE_PRICE = _price;
    }

    function setSupply(uint256 _newSupply) external onlyOwner {
        require(totalSupply() < _newSupply);
        TREE_SUPPLY = _newSupply;
    }


    function mint() external payable {
        require(mintable, "Public minting not allowed");
        require(!treelistMint, "Mint through treelist"); // If treelistMint is active, then don't allow public mint
        require(totalSupply() < TREE_SUPPLY, "All tokens have been minted for now");
        require(TREE_PRICE == msg.value, "Pay up");

        uint256 tokenId = _tokenIds.current();
        _tokenIds.increment();
        _safeMint(msg.sender, tokenId);

    }

    function mintTreelist() external payable {
        require(treelistMint, "Treelist is not active");
        require(treelist[msg.sender], "You're not on the treelist");
        require(totalSupply() < TREE_SUPPLY, "All tokens have been minted for now");
        require(TREE_PRICE == msg.value, "Pay up");
        require(!_treelistClaimed[msg.sender], "You've already minted through the treelist");

        uint256 tokenId = _tokenIds.current();
        _tokenIds.increment();
        _treelistClaimed[msg.sender] = true;
        _safeMint(msg.sender, tokenId);

    }


    function privateMint(address to) public onlyOwner {
        require(totalSupply() < TREE_SUPPLY, "All tokens have been minted for now");
        uint256 tokenId = _tokenIds.current();
        _tokenIds.increment();
        _safeMint(to, tokenId);
    }

   // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal override(ERC721, ERC721Enumerable)
     {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
        public view override(ERC721, ERC721Enumerable) returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view override(ERC721) returns (string memory) {
        return BASE_URI;
    }

    function setBaseURI(string calldata URI) external onlyOwner {
        BASE_URI = URI;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = address(owner()).call{value: balance}("");
        require(success);
    }

}