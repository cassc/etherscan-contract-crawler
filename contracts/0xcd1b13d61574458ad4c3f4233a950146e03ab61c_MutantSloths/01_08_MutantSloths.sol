//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

error InvalidSerumId();

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";



contract MutantSloths is ERC721AQueryable, Ownable, ReentrancyGuard{

    SerumContract public serumContract = SerumContract(0x21819DA7aFA4089217C62F1D971fB1397b1f50e4);
    string public baseUri;
    string public uriSuffix = ".json";

    uint[4] public tokenIdToMutantFamily  = [0,0,0,0];
    constructor()
        ERC721A("Sleepy Sloth Mutants", "SSM")
    {

    }
    event MUTATION(uint indexed tokenId,uint indexed familyTokenId, uint indexed serumId);
    function burnMint(uint serumId) external nonReentrant{
        if(serumId>3) revert InvalidSerumId();
        emit MUTATION(_nextTokenId() ,tokenIdToMutantFamily[serumId],serumId);
        serumContract.burnOneForHolder(msg.sender,serumId);

        tokenIdToMutantFamily[serumId]++;
        _mint(msg.sender,1);
    }
   
    function batchBurn(uint amount,uint serumId) external nonReentrant{

        if(serumId>3) revert InvalidSerumId();
        for(uint i; i<amount;i++){

            emit MUTATION(_nextTokenId()+ i ,tokenIdToMutantFamily[serumId] + i,serumId);
            serumContract.burnOneForHolder(msg.sender,serumId);
        }
        tokenIdToMutantFamily[serumId] += amount;
        _mint(msg.sender,amount);
    }

    function setSerumAddress(address _serums) external onlyOwner{
        serumContract = SerumContract(_serums);
    }
    function setBaseUri(string memory newBaseUri) public onlyOwner{
        baseUri = newBaseUri;
    }
    function setUriSuffix(string memory newSuffix) public onlyOwner {
        uriSuffix = newSuffix;
    }

    function tokenURI(uint tokenId) public view override(ERC721A) 
    returns(string memory)
    {
        return string(abi.encodePacked(
            baseUri,
            _toString(tokenId),
            uriSuffix));
    }


}

interface SerumContract{

    function burnOneForHolder(address holder,uint serumId) external;
}