// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";


interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}


contract NullishFaucet is Ownable {

    /////////////////////////////////////////////////////////////////////////////////////////
    //// 
    ////    Nullish Ordinal Faucet
    ////    - Adding all three Nullish ERC-721 collections to list of eligible contracts.
    ////
    /////////////////////////////////////////////////////////////////////////////////////////    
    
    constructor() {
        eligible721Contracts[0x48E934457D3082CD4068d10C80DaacE98378409f] = true; // On the Edge of Oblivion
        eligible721Contracts[0x205A10c241cA38918d3790C89F16675cC46D10a9] = true; // Distortion
        eligible721Contracts[0x2290995bB9C481306F83Bd8f549D9F1C41357444] = true; // Celestial
        maximumRequestsPerRound = 25;
        faucetState = true;
    }

    bool public faucetState;
    uint256 public currentRound;
    uint256 public maximumRequestsPerRound;


    mapping(address => bool) public eligible721Contracts;
    mapping(uint256 => uint256) public requestsPerRound;
    mapping(uint256 => mapping(address => mapping(uint256 => bool))) public usedTokensPerRound;


    /////////////////////////////////////////////////////////////////////////////////////////
    //// 
    ////    Faucet Administration Functions & dApp Functions
    ////
    /////////////////////////////////////////////////////////////////////////////////////////    

    function editEligibleContracts(address _address, bool _eligible) external onlyOwner {
       eligible721Contracts[_address] = _eligible;
    }

    function initiateNextRound() external onlyOwner {
        currentRound++;
    }

    function setRound(bool _incrementRound, uint256 _setOptionalRoundId) external onlyOwner {
        if (_incrementRound) currentRound++;
        else currentRound = _setOptionalRoundId;
    }

    function setMaxRequestsPerRound(uint256 _amount) external onlyOwner {
        maximumRequestsPerRound = _amount;
    }

    function changeFaucetState(bool _open) external onlyOwner {
        faucetState = _open;
    }

    function getMaximumRequestsPerRound() public view returns (uint256) {
        return maximumRequestsPerRound;
    }

    function getCurrentRoundRequestsMade() public view returns (uint256) {
        return requestsPerRound[currentRound];
    }


    /////////////////////////////////////////////////////////////////////////////////////////
    //// 
    ////    Token-Gated Requests for Inscriptions from the Faucet
    ////    - Each token has access to one test inscription per round.
    ////    - There can be a maximum of requests per round.
    ////
    /////////////////////////////////////////////////////////////////////////////////////////  

    event bridgeEvent(uint256 indexed _round, string indexed _btcAddress, uint256 _timestamp);

    function requestInscription(address _contract, uint256 _tokenId, string memory _btcAddress) external {
        require(faucetState, "The faucet is currently closed.");
        require(eligible721Contracts[_contract], "Contract must be part of the allowed contracts.");
        require(IERC721(_contract).ownerOf(_tokenId) == msg.sender, "Must own the token you are using to request an inscription.");
        require(!usedTokensPerRound[currentRound][_contract][_tokenId], "You can only use each token once per round.");
        require(requestsPerRound[currentRound] < maximumRequestsPerRound, "This round has reached the maximum amount of requests.");
        requestsPerRound[currentRound]++;
        usedTokensPerRound[currentRound][_contract][_tokenId] = true;
        emit bridgeEvent(currentRound, _btcAddress, block.timestamp);
    }

}