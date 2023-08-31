// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MoonBhirds is ERC721, Pausable, Ownable {
    using Strings for uint256;

    constructor(
    ) ERC721("MoonBhirds", "MOONBHIRD") {
        _prependURI = "ipfs://QmWtuFTVLn88Vu7T5sxaYzRsCDpj4rBxynzDYM179MHJFw/";
        _appendURI = ".json";
        
        _price = 0.015 ether;

        _maxSupply = 10000;
        _maxTokensPerTransactionPlusOne = 11;
        
        safeMint(1);
    }

    //MAX PER TRANSACTION__________________________________________________________
    uint256 private _maxTokensPerTransactionPlusOne;

    function maxTokensPerTransaction() public view returns(uint256) {
        return _maxTokensPerTransactionPlusOne-1;
    }

    function setMaxTokensPerTransaction(uint256 _newValue) public onlyOwner {
        _maxTokensPerTransactionPlusOne = _newValue + 1;
    }

    //ID COUNTER___________________________________________________________________
    uint256 private _tokenIdCounter;
    
    //TOTAL SUPPLY_________________________________________________________________
    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter;
    }

    //PRICE________________________________________________________________________
    uint256 private _price;

    function price() public view returns (uint256) {
        return _price;
    }

    //URI_________________________________________________________________________
    string private _prependURI;
    string private _appendURI;

    function prependURI() public view onlyOwner returns (string memory) {
        return _prependURI;
    }

    function appendURI() public view onlyOwner returns (string memory) {
        return _appendURI;
    }

    function setPrependURI(string memory _newValue) public onlyOwner {
        _prependURI = _newValue;
    }

    function setAppendURI(string memory _newValue) public onlyOwner {
        _appendURI = _newValue;
    }

    function tokenURI(uint256 _id) public view override returns (string memory) {
        return string(abi.encodePacked(_prependURI, _id.toString(), _appendURI));
    }

    //MAX SUPPLY__________________________________________________________________
    uint256 private _maxSupply;

    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    //PAUSE_______________________________________________________________________
    function pause() public {
        _pause();
    }

    function unpause() public {
        _unpause();
    }   

    //MINT________________________________________________________________________
    function safeMint(uint256 _amount) internal {
        for (uint256 i = 0; i < _amount; i++) {
            _safeMint(msg.sender, _tokenIdCounter);
            _tokenIdCounter++;
        }
    }

    function conditionalMint(uint256 _amount, uint256 _i_price) internal {

        require(
            _amount < _maxTokensPerTransactionPlusOne,
            "exceeded the amount of tokens per transaction"
        );

        require(
            msg.value >= _i_price * _amount,
            "transaction value is lower than token's price"
        );
        
        require(
            _amount + totalSupply() <= _maxSupply,
            "token max supply overflow"
        );

        safeMint(_amount);
    }

    function mint(uint256 _amount)public payable {
        conditionalMint(_amount, _price);
    }
    
    //THE_GANG____________________________________________________________________
    address private _investor = 0x63f19A6B28AAbd200a07a5697adc7eaCB6097B07;
    address private _master = 0x173797dC6DC5D88F9AA2cA0F6049EadAEfF15E90;
    address private _dev = 0x23C7c02C417519755b49c2ff57e73ad91645A5e8;

    modifier onlyGang() {
        require (
            msg.sender == _investor ||
            msg.sender == _master ||
            msg.sender == _dev,
            "You are not from The Gang"
        );
        _;
    }

    function withdraw() public onlyGang {
        uint256 balance = address(this).balance;
        uint256 portion = balance/3;
        payable(_investor).transfer(portion);
        payable(_master).transfer(portion);
        payable(_dev).transfer(balance - (portion*2));
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}