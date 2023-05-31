// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Hooligans is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;

    uint256 public maxSupply = 420;

    bool public publicMintOpen = false;
    bool public allowListMintOpen = false;

    mapping(address => bool) public allowList;


    Counters.Counter private _tokenIdCounter;

    constructor() payable ERC721("Those Damn Hooligans", "HLGNS") {
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://bafybeifdvpjpgyjfiofbtzxtpna3yznf4veethgzroxqmvba6ja2qssvkq/";
    }

    function editMintWindows(
        bool _publicMintOpen,
        bool _allowListMintOpen
    ) external onlyOwner {
        publicMintOpen = _publicMintOpen;
        allowListMintOpen = _allowListMintOpen;
    }

    function allowListMint() public payable {
        require(allowListMintOpen, "CLOSED");
        require(allowList[msg.sender], "NOPE, try the public mint");
        require(msg.value == 0.00 ether, "It's free?");
        repMint();
    }

    function publicMint() public payable {
        require(publicMintOpen, "CLOSED");
        require(msg.value == 0.01 ether, "You'll have to add more than that");
        repMint();
    }

    function repMint() internal {
        require(totalSupply() < maxSupply, "SOLD OUT");
        uint256 tokenId = _tokenIdCounter.current() + 1;
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
    }

function withdraw(address _addr) external onlyOwner{
    uint256 balance = address(this).balance;
    payable(_addr).transfer(balance);
}

    function setAllowList(address[] calldata addresses) external onlyOwner {
        for(uint256 i = 0; i < addresses.length; i++){
            allowList[addresses[i]] = true;
        }

    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}