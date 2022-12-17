// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import {DefaultOperatorFilterer} from "./DefaultOperatorFilterer.sol";

contract NFT_Goose is Ownable, ERC721A, DefaultOperatorFilterer {
    string public uriPrefix = '';
    string public uriSuffix = '.json';
    uint256 public max_supply = 5000;
    address public castleAddress;
    address public wolfAddress;

    uint256 public amountMintPerAccount = 1;
    bool public mintEnabled;
    uint256 public price = 0;
    uint256 public burnAmount;

    event MintSuccessful(address user);

    constructor() ERC721A("Goose", "GOOSE") { }

    function mintForUser(address _user) external {
        require(msg.sender == castleAddress, "Only the castle can mint a Goose!");
        require(totalSupply() + 1 < max_supply, 'Cannot mint more than max supply');
        _mint(_user, 1);
        
        emit MintSuccessful(msg.sender);
    }

    function mint(uint256 _quantity) external payable {
        require(mintEnabled, 'Minting is not enabled');
        require(totalSupply() + _quantity < max_supply, 'Cannot mint more than max supply');
        require(balanceOf(msg.sender) + _quantity <= amountMintPerAccount, 'Each address may only mint x NFTs!');
        require(msg.value >= getPrice() * _quantity, "Not enough ETH sent; check price!");

        _mint(msg.sender, _quantity);

        emit MintSuccessful(msg.sender);
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, Strings.toString(_tokenId), uriSuffix))
            : '';
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://QmQFUfzErTD75SZ8oapZbwShyz2Li51G6oXstfb3wbzwHr/";
    }
    
    function baseTokenURI() public pure returns (string memory) {
        return _baseURI();
    }

    function contractURI() public pure returns (string memory) {
        return "ipfs://QmdjBLs56SuQvsDCXD1aKRkQsYgtGWMY9k4RLA8sborkrw/";
    }

    function setAmountMintPerAccount(uint _amountMintPerAccount) public onlyOwner {
        amountMintPerAccount = _amountMintPerAccount;
    }

    function getPrice() view public returns(uint) {
        return price;
    }

    function setPrice(uint _price) public onlyOwner {
        price = _price;
    }

    function setMintEnabled(bool _state) public onlyOwner {
        mintEnabled = _state;
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
    
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
    
    function _startTokenId() internal view override returns (uint256) {
        return 1;
    }

    function setCastleAddress(address _address) public onlyOwner {
        castleAddress = _address;
    }

    function setWolfAddress(address _address) public onlyOwner {
        wolfAddress = _address;
    }

    function burn(uint256 _tokenId) public {
        require(wolfAddress == msg.sender, "Only the Wolf smart contract can burn this NFT.");
        _burn(_tokenId);
        burnAmount += 1;
    }
}