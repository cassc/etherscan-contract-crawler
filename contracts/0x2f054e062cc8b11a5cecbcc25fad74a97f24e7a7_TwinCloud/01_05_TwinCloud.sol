// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./erc721a/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TwinCloud is ERC721A, Ownable {

    address private _minter;
    uint256 public maxSupply;

    constructor(address minter_, uint256 maxSupply_)ERC721A('Twin cloud', 'TWINCLOUD'){
        _minter = minter_;
        maxSupply = maxSupply_;
    }
    
    function safeMint(address to, uint256 quantity) external onlyMinter{
        require((totalSupply() + quantity) <= maxSupply, "exceed Max supply");
        _safeMint(to, quantity);
    }

    //===============modifier======================
    modifier onlyMinter(){
        require(msg.sender == _minter, "minter:caller is not minter");
        _;
    }

    //===============admin function===================

    function setMinter(address newMinter) external onlyOwner {
        require(newMinter != address(0), "minter must not address zero");
        _minter = newMinter;
    }

    function setMaxSupply(uint256 newMaxSupply) external onlyOwner {
        require(newMaxSupply >= maxSupply, "new max supply invalid");
        maxSupply = newMaxSupply;
    }

    //================view function====================

    function minter() public view  returns (address) {
        return _minter;
    }

    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }
}