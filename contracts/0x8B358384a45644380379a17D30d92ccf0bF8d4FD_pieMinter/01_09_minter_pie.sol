// SPDX-License-Identifier: MIT
// Copyright (c) 2023 Keisuke OHNO

/*

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*/

pragma solidity >=0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

interface iNFTCollection {
    function externalMint(address _address , uint256 _amount) external payable ;
}

contract pieMinter is Ownable , AccessControl{

    constructor(){
        //Role initialization
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        grantRole( MINTER_ROLE       , msg.sender);
        grantRole( ADMIN             , msg.sender);
        grantRole( MINTER_ROLE       , 0x421E534EF93F6680f9955DA95af7E6d3a05eDFB0);
        setWithdrawAddress( 0xb22E01eC55D6Af246221e73cDc6f8e6e22119446 );
        setNFTCollection( 0x2027f645a51cD219b954f567160573a2322467E1 );//Crypto Japan Agri
    }

    bytes32 public constant ADMIN = keccak256("ADMIN");
    bytes32 public constant MINTER_ROLE  = keccak256("MINTER_ROLE");

    iNFTCollection public NFTCollection;

    //onlyowner
    function setNFTCollection(address _address) public onlyRole(ADMIN) {
        NFTCollection = iNFTCollection(_address);
    }


    //
    //withdraw section
    //
    address public withdrawAddress = 0xdEcf4B112d4120B6998e5020a6B4819E490F7db6;

    function setWithdrawAddress(address _withdrawAddress) public onlyOwner {
        withdrawAddress = _withdrawAddress;
    }

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(withdrawAddress).call{value: address(this).balance}('');
        require(os);
    }


    //
    //mint section
    //
    //https://eth-converter.com/
    uint256 public cost = 8000000000000000;
    uint256 public mintedAmount = 0;
    uint256 public maxSupply = 100;
    uint256 public maxMintAmountPerTransaction = 10;
    bool public paused = true;
 
    function mint(uint256 _mintAmount , address _receiver ) public payable onlyRole(MINTER_ROLE){
        require( !paused, "the contract is paused");
        require( 0 < _mintAmount, "need to mint at least 1 NFT");
        require(_mintAmount <= maxMintAmountPerTransaction, "max mint amount per session exceeded");
        require( cost * _mintAmount <= msg.value, "insufficient funds");
        require( mintedAmount + _mintAmount <= maxSupply, "max supply exceeded");

        mintedAmount += _mintAmount;
        NFTCollection.externalMint( _receiver , _mintAmount );

        (bool os, ) = payable( withdrawAddress ).call{value: address(this).balance}('');
        require(os);  
    }

    function setCost(uint256 _newCost) public onlyRole(ADMIN) {
        cost = _newCost;
    }

    function setPause(bool _state) public onlyRole(ADMIN) {
        paused = _state;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyRole(ADMIN) {
        maxSupply = _maxSupply;
    }

    function setMaxMintAmountPerTransaction(uint256 _maxMintAmountPerTransaction) public onlyRole(ADMIN) {
        maxMintAmountPerTransaction = _maxMintAmountPerTransaction;
    }
}