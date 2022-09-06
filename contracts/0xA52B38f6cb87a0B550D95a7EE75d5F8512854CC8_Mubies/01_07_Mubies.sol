// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract Mubies is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    address public  royalties;
    uint64  public  immutable maxSupply = 6003;
    uint256 public  price = 0.1 ether;
    string  public  baseTokenURI;
    bool    public  paused = true;
    uint64  public  immutable maxMintAmountPerTx = 4;
    uint256 private reserved = 200;

    constructor(string memory _baseTokenURI)ERC721A("Interstellar Odyssey - Mubies", "MUB") {
        setBaseURI(_baseTokenURI);
    }

    // MINTING

    function publicMint(uint256 _q) payable public {
        // check before every mint
        require( !paused, "Sale paused" );
        require(msg.value == price * _q, "Incorrect payment");
        require(_q <= maxMintAmountPerTx, "Mint limit exceeded");
        require(totalSupply() + _q <= maxSupply - reserved, "Maximum supply exceeded");

        // mint
        _safeMint(msg.sender, _q);
    }

    function giveaway(address _to, uint256 _q) public onlyOwner {
        require(_q <= maxMintAmountPerTx, "Mint limit exceeded");
        require(_q <= reserved, "Maximum supply exceeded");

        // mint
        _safeMint(_to, _q);

        reserved -= _q;
    }

    // METADATA

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function tokenURI(uint _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(baseTokenURI, '/', (1 + _tokenId).toString(), '.json'));
    }

    // WITHDRAW
    function setRoyalties(address _royalties) public onlyOwner {
        royalties = _royalties;
    }

    function withdrawFunds() public payable onlyOwner {
        require(payable(royalties).send(address(this).balance));
    }

    // GENERAL
    function pause(bool _p) public onlyOwner {
        paused = _p;
    }

    function setPrice(uint256 _p) public onlyOwner {
        price = _p;
    }

}