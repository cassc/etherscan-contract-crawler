// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721ACustom.sol";




contract CamouflageChameleons is ERC721ACustom, Ownable {

    using Strings for uint256;

    uint256 public immutable maxSupply;
    uint256 public maxMintAtOnce;
    uint256 public price = 0.0444 ether;
    bool public saleActive;
    string public baseTokenURI;



    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseTokenURI_,
        uint256 maxSupply_
    ) ERC721ACustom(name_, symbol_){
        baseTokenURI = baseTokenURI_;
        maxSupply = maxSupply_;
    }

    function mint (
        uint256 _quantity
    ) external payable {
        require(saleActive, "Sale Inactive");
        require(totalSupply() + _quantity <= maxSupply, "Mint exceed max supply");
        require(price * _quantity == msg.value, "Value sent is incorrect");

        _safeMint(msg.sender, _quantity);
    }


    // ADMIN

    function toggleSale() external onlyOwner {
    saleActive = !saleActive;
    }

    function _baseURI() internal view override returns (string memory) {
    return baseTokenURI;
    }

    function setBaseURI(
    string calldata _baseTokenURI
    ) external onlyOwner {
    baseTokenURI = _baseTokenURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
    return 1;
    }


    function transferFrom(address from_, address to_, uint256 tokenId_) public override {
    _transfer(from_, to_, tokenId_);
    }

    function safeTransferFrom(address from_, address to_, uint256 tokenId_, bytes memory data_) public override {
    ERC721ACustom.safeTransferFrom(from_, to_, tokenId_, data_);
    }



    function withdraw() public onlyOwner {
    address payable to = payable(msg.sender);
    to.transfer(address(this).balance);
    }



}