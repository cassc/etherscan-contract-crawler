// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

interface ITwistedTrippies 
{
    function mint(address to, uint256 tokenId) external;    
}

interface ITrippies
{
    function ownerOf(uint256 tokenId) external returns(address);
}

interface ITwistedBrew
{
    function burn(uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external returns(address);
}

contract Drink is Ownable
{
    using Counters for Counters.Counter;
    address public twistedTrippiesContractAddress = address(0);
    address public twistedBrewContractAddress = address(0);
    address public signerAddress = 0xd58aB967B405A8f7B5196727D565B1F9b8f5A5b9;
    address public trippiesContractAddress = 0x4cA4d3B5B01207FfCe9beA2Db9857d4804Aa89F3;
    ITrippies trippiesContract = ITrippies(trippiesContractAddress);
    Counters.Counter private titanIdCounter;

    constructor()  
    {        
        titanIdCounter.increment();
    }

    function setTwistedTrippiesContract(address a) public onlyOwner 
    {
        twistedTrippiesContractAddress = a;
    }

    function setBrewContract(address a) public onlyOwner 
    {
        twistedBrewContractAddress = a;
    }

    function setSignerAddress(address a) public onlyOwner 
    {
        signerAddress = a;
    }

    function drink(uint256 brewTokenId, uint256 trippieTokenId, bytes memory sig) public
    {
        ITwistedBrew brewContract = ITwistedBrew(twistedBrewContractAddress);
        ITwistedTrippies twistedContract = ITwistedTrippies(twistedTrippiesContractAddress);

        address ownerOfBrew = brewContract.ownerOf(brewTokenId);
        require(ownerOfBrew == msg.sender, "does not own brew");

        address ownerOfTrippie = trippiesContract.ownerOf(trippieTokenId);
        require(ownerOfTrippie == msg.sender, "does not own trippie");

        address messageSigner = VerifyMessage2(sig, brewTokenId, trippieTokenId);
        require(messageSigner == signerAddress, "Invalid message signer");

        brewContract.burn(brewTokenId);
        twistedContract.mint(msg.sender, trippieTokenId);
    }

    function drinkTitanBrew(uint256 brewTokenId, bytes memory sig) public
    {
        uint256 titanId = titanIdCounter.current() + 10000;
        require(titanId >= 10001 && titanId <= 10021);

        ITwistedBrew brewContract = ITwistedBrew(twistedBrewContractAddress);
        ITwistedTrippies twistedContract = ITwistedTrippies(twistedTrippiesContractAddress);

        address ownerOfBrew = brewContract.ownerOf(brewTokenId);
        require(ownerOfBrew == msg.sender, "does not own brew");

        address messageSigner = VerifyTitanMessage(sig, brewTokenId);
        require(messageSigner == signerAddress, "Invalid message signer");

        titanIdCounter.increment();
        brewContract.burn(brewTokenId);
        twistedContract.mint(msg.sender, titanId);
    }

    function VerifyTitanMessage(bytes memory sig, uint brewTokenId) private pure returns (address) 
    {
        (uint8 _v, bytes32 _r, bytes32 _s) = splitSignature(sig);
        bytes32 messageHash = keccak256(abi.encodePacked(brewTokenId));
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";         
        bytes32 prefixedHashMessage = keccak256(abi.encodePacked(prefix, messageHash));    
        address signer = ecrecover(prefixedHashMessage, _v, _r, _s);
        return signer;
    }

    function VerifyMessage2(bytes memory sig, uint brewTokenId, uint trippieTokenId) private pure returns (address) 
    {
        (uint8 _v, bytes32 _r, bytes32 _s) = splitSignature(sig);
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHashMessage = keccak256(abi.encodePacked(prefix, getMessageHash2(brewTokenId, trippieTokenId)));    
        address signer = ecrecover(prefixedHashMessage, _v, _r, _s);
        return signer;
    }

    function VerifyMessage(bytes memory sig, string memory msg1, uint amount, uint nonce) private pure returns (address) 
    {
        (uint8 _v, bytes32 _r, bytes32 _s) = splitSignature(sig);
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHashMessage = keccak256(abi.encodePacked(prefix, getMessageHash(msg1, amount, nonce)));    
        address signer = ecrecover(prefixedHashMessage, _v, _r, _s);
        return signer;
    }

    function splitSignature(bytes memory sig) private pure returns (uint8 v, bytes32 r, bytes32 s)
    {
        require(sig.length == 65, "invalid sig");
        assembly {
            // first 32 bytes, after the length prefix.
            r := mload(add(sig, 32))
            // second 32 bytes.
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes).
            v := byte(0, mload(add(sig, 96)))
        }
        return (v, r, s);
    }    

    function getMessageHash(string memory message, uint256 amount, uint256 nonce) private pure returns (bytes32) 
    {
        return keccak256(abi.encodePacked(message,amount,nonce)); 
    }   

    function getMessageHash2(uint256 amount, uint256 nonce) private pure returns (bytes32) 
    {
        return keccak256(abi.encodePacked(amount,nonce)); 
    } 

    function withdraw() public onlyOwner 
    {   
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }  
}