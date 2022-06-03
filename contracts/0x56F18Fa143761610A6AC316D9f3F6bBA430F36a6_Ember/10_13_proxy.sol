//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./interfaces/IEmber.sol";


// Proxy contract deployed at run time for each unique borrower & NFT transffered to proxy
// it holds the all NFTs borrowed by a single borrower address
// it serve as msg.sender for games contract
// this contract delegates call to suitable adapters which further calls to game contract

 contract Proxy {

    // store borrower address as proxyOwner   
    address proxyOwner;

    // store staking contract address
    address stakingAddress;

    constructor(address _staking, address _proxyOwner){

        proxyOwner = _proxyOwner;  
        stakingAddress = _staking;
    }
    

    /**
     * @dev fallback function executed when no other function signature matches in this contract
     * for each function signature that exexuted using fallback must have type
     * uint256 lendingId as a last paramter of that function signature  
     * extract lendingId from msg.data to get NFT adapter & to pass through few require checks
     * returns the success value or error  
    */
    
    fallback () external payable {

        bytes calldata data = msg.data;
        bytes memory lendId =bytes(data[msg.data.length-32:]); //last parameter must be lendingId
        uint256 _lendingId = uint256(abi.decode(lendId,(uint256)));
        address adapter = IEmber(stakingAddress).getNFTAdapter(_lendingId);
        ensureCallable(_lendingId, msg.sender);

        assembly {
            
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the adapter
            //gas	addr	argsOffset	argsLength	retOffset	retLength	
            let result := delegatecall(gas(), adapter, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
                case 0 {
                    revert(0, returndatasize())
                }
                default {
                    return(0, returndatasize())
                }
            }
    }


    /**
     * @notice this function can be called uisng staking contract
     * @dev transfers the nft back to satking contract after passing through require
     * @param _nft - nft address
     * @param _tokenId - nft's tokenId
     * @param _lendingId - lendingId
    */


    function getNFT(address _nft, uint256 _tokenId, uint256 _lendingId) external {
        
        require(stakingAddress == msg.sender,"Invalid::Call");
        require(IEmber(stakingAddress).getRentedTill(_lendingId)< block.timestamp, "Rent duration not Expired");
        IERC721(_nft).transferFrom(address(this),stakingAddress,_tokenId);
    
    }

    /**
     * @notice this function called from above fallback function to ensure the valididity 
     * @param _lendingId - lendingId
     * @param msgSender - msg.sender address
    */

    function ensureCallable(uint256 _lendingId, address msgSender) internal view{
        
        (address _nft, uint256 _tokenId) = IEmber(stakingAddress).getNFTtokenID(_lendingId);
        require(_nft != address(0),"Invalid::ID");
        require(IERC721(_nft).ownerOf(_tokenId) == address(this),"NFT not in proxy");
        require(proxyOwner == msgSender,"caller must be owner");
        require(IEmber(stakingAddress).getRentedTill(_lendingId)> block.timestamp, "Rent duration Expired");
            
    }

    receive() external payable {}

    
}