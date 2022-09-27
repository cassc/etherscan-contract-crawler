// SPDX-License-Identifier: MIT
// VerifiableERC721AMint Contract v1.0.0
// Creator: Nothing Rhymes With Entertainment

pragma solidity >=0.8.9 <0.9.0;

import "./BaseERC721AMint.sol";
import "./library/ExternalContractManager.sol";

/**
 * @title VerifiableERC721AMint
 * @author Heath C. Michaels, (@heathcmichaels @wanderingme @wanderingheath) 
 * @dev Verifiable NFT contract extending BaseERC721AMint class
 *
 * @notice Allows for a way to verify ownership to "whitelist" owners for a mint in another contract
 *
 *
 */ 

contract VerifiableERC721AMint is BaseERC721AMint {
    using ExternalContractManager for ExternalContractManager.Data;
    
    /**
    *   @dev External contract manager used to track an enumerated struct of properties:
    *           1. _contract = External contract address (VerifiableERC721AMint type casting necessary)
    *           2. _isLive = Doubles for local Verifiable Mint Live bool
    *           3. _extraFlag = Checks for one-to-one mint. 
    *                   a. Set to TRUE if mint is 1 mint per 1 token owned. 
    *                   b. If FALSE, max per wallet is limit per token owned. 
    *           4. map = tracks burned tokens (tokenId => address)
    */     
    ExternalContractManager.Data private externalVerifiableContract;


     constructor(
            string memory _name, 
            string memory _symbol, 
            uint256 _maxSupply, 
            string memory _initBaseUri
    ) BaseERC721AMint(_name, _symbol, _maxSupply, _initBaseUri) {
                //mintPrice = 0.001 ether;
                //maxPerWallet = 5;
                /**
                *   @dev Set to TRUE if mint is 1 mint per 1 token owned. If FALSE, max per wallet is limit per token owned. 
                */ 
                externalVerifiableContract._extraFlag = false;
    }

    /**
     *
     *                           LOCAL 
     *
     */

        /**
        *   @dev mint for verfied tokens in an external contract
        *
        */ 
    function verifiedMint(uint256 _numberOfTokensRequestedForMint, uint256 _tokenId) public payable nonReentrant mintConform(_numberOfTokensRequestedForMint) nonOwnerMintConform(_numberOfTokensRequestedForMint){
        require(externalVerifiableContract._isLive, "Minting unavailable");
        require(!externalVerifiableContract._addressMap[_tokenId], "Already claimed");
        require(VerifiableERC721AMint(externalVerifiableContract._contract).isRemoteAddressVerified(msg.sender, _tokenId), "Not verified");
        //Extra flag checks for one-to-one, meaning for every token a single mint or not
        _numberOfTokensRequestedForMint = externalVerifiableContract._extraFlag? 1 : _numberOfTokensRequestedForMint;
        externalVerifiableContract._addressMap[_tokenId] = true;
        mintTokens(_numberOfTokensRequestedForMint, msg.sender);
    }

        /**
        *   @dev set verified mint live
        *
        */ 
    function setLocalVerifiedMintLive(bool val) external onlyOwner{
        externalVerifiableContract._isLive = val;
    }
     /**
        *   @dev get verified mint live bool - returns boolean
        *
        */ 
    function isVerifiedMintLive() external view returns (bool){
        return externalVerifiableContract._isLive;
    }
    
        /**
        *   @dev connect an external VerifiableERC721AMint contract address for the verified mint
        *
        */ 
    function addRemoteVerifiableContractAddress(address _address) external onlyOwner {
        externalVerifiableContract._contract = address(_address);
    }

    /**
     *
     *                           REMOTE
     *                              
     *
     */

      /**
        *   @dev returns true if tokenId belongs to address
        */ 
    function isRemoteAddressVerified(address _address, uint256 _tokenId) view external returns (bool){
        return ownerOf(_tokenId) == _address;
    }

   


}