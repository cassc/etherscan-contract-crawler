// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/****************************************
 * A GOLDENX CONTRACT
 * @author: hammm.eth                     
 ****************************************/

import './ERC721B/ERC721EnumerableLite.sol';
import './ERC721B/Delegated.sol';
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract FierceModels is ERC721EnumerableLite, Delegated, PaymentSplitter {
    using Strings for uint;

    uint public PRICE = 0.07 ether;
    uint public MAX_TOKENS_PER_TRANSACTION = 20;
    uint public MAX_SUPPLY = 10000;

    string public _baseTokenURI = 'https://gateway.pinata.cloud/ipfs/QmbatFYBtMYFZtT4kx6G5wXy2GSYa7ehpVChqEq5XSKz9T/'; 
    string public _baseTokenSuffix = '.json';

    bool public paused = false;

    // Withdrawal addresses
    address dev = 0xB7edf3Cbb58ecb74BdE6298294c7AAb339F3cE4a;
    address art = 0xF7aDD17E99F097f9D0A6150D093EC049B2698c60;
    address fierce = 0x9aF1757A18E3b3ea25c46331509279e4B6c5e0A6;
    address f1 = 0x7ca64429125EC529f13E07cEa1a7Ce55B54875F0;
    address f2 = 0x16624b589419012a2817C47432762369c859B6e4;
    address f3 = 0xbdD2668D938fD4cD146C533361d11FbC5371d424;

    address[] addressList = [dev, art, fierce, f1, f2, f3];
    uint[] shareList = [100, 40, 151, 425, 142, 142];

    constructor()
    ERC721B("Fierce Models", "FM")
    PaymentSplitter(addressList, shareList)  {
    }

    function mint(uint _count) external payable {
        require( _count <= MAX_TOKENS_PER_TRANSACTION, "Count exceeded max tokens per transaction." );
        require( !paused, "Sale is currently paused." );

        uint supply = totalSupply();
        require( supply + _count <= MAX_SUPPLY,        "Exceeds max Fierce Model supply." );
        require( msg.value >= PRICE * _count,         "Ether sent is not correct." );

        for(uint i = 0; i < _count; ++i){
            _safeMint( msg.sender, supply + i, "" );
        }
    }

    function mintTo(uint[] calldata quantity, address[] calldata recipient) external payable onlyDelegates{
        require(quantity.length == recipient.length, "Must provide equal quantities and recipients" );

        uint totalQuantity;
        uint supply = totalSupply();
        for(uint i; i < quantity.length; ++i){
            totalQuantity += quantity[i];
        }
        require( supply + totalQuantity < MAX_SUPPLY, "Mint/order exceeds supply" );

        for(uint i; i < recipient.length; ++i){
            for(uint j; j < quantity[i]; ++j){
                _safeMint( recipient[i], supply++, "" );
            }
        }
    }

    function setPrice(uint _newPrice) external onlyDelegates {
        PRICE = _newPrice;
    }

    function setMaxSupply (uint _newMaxSupply) external onlyDelegates { 
        require( MAX_SUPPLY >= totalSupply(), "Specified supply is lower than current balance" );
        MAX_SUPPLY = _newMaxSupply;
    }

    function setmaxMintAmount(uint _newMaxTokensPerTransaction) public onlyDelegates {
        MAX_TOKENS_PER_TRANSACTION = _newMaxTokensPerTransaction;
    }

    function pause(bool _updatePaused) public onlyDelegates {
        require( paused != _updatePaused, "New value matches old" );
        paused = _updatePaused;
    }

    function setBaseURI(string calldata _newBaseURI, string calldata _newSuffix) external onlyDelegates {
        _baseTokenURI = _newBaseURI;
        _baseTokenSuffix = _newSuffix;
    }

    function tokenURI(uint tokenId) external override view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseTokenURI;
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), _baseTokenSuffix)) : "";
    }
}