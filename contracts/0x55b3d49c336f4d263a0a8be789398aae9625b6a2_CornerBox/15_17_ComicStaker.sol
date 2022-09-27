// SPDX-License-Identifier: MIT
// ComicStaker Contract v1.0.0
// Creator: Nothing Rhymes With Entertainment

/**

 * @title ComicStaker
 * @author Heath C. Michaels, (@heathcmichaels @wanderingme @wanderingheath)
 *
 * @notice Stakes NFT with no ERC20 reward. 
 *
 *   ===     =====================================      ================  ====================
 *   ==  ===  ===================================  ====  ===============  ====================
 *   =  =========================================  ====  ===  ==========  ====================
 *   =  =========   ===  =  = ===  ===   =========  =======    ===   ===  =  ===   ===  =   ==
 *   =  ========     ==        ======  =  ==========  ======  ===  =  ==    ===  =  ==    =  =
 *   =  ========  =  ==  =  =  ==  ==  ===============  ====  ======  ==   ====     ==  ======
 *   =  ========  =  ==  =  =  ==  ==  ==========  ====  ===  ====    ==    ===  =====  ======
 *   ==  ===  ==  =  ==  =  =  ==  ==  =  =======  ====  ===  ===  =  ==  =  ==  =  ==  ======
 *   ===     ====   ===  =  =  ==  ===   =========      ====   ===    ==  =  ===   ===  ======
 *
 */

pragma solidity >=0.8.9 <0.9.0;

import "./BaseERC721AMint.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract ComicStaker is ReentrancyGuard, IERC721Receiver{

        BaseERC721AMint public parentNFTContract;

        mapping(uint256 => Stake.data) public stakedMap;

        uint public START_TIMESTAMP;
        /**
        *   @dev const value of time for staking window since deployment of this contract
        */ 
        uint public constant ACTIVE_RANGE = 60 days;

        event NFTStaked(address owner,uint256 tokenId,uint256 value);
        event NFTUnstaked(address owner,uint256 tokenId,uint256 value);

        /**
        *   @dev constructor takes BaseERC721AMint contract address as parameter
        */ 
        constructor(address _parentNftContract){
            parentNFTContract = BaseERC721AMint(address(_parentNftContract));
            START_TIMESTAMP = block.timestamp;
        }
        /**
        *   @dev stake single NFT - caller address must be approved by msg.sender in parent NFT contract or will fail.
        */ 
        function stake(uint256 _tokenId) external nonReentrant{
            require(block.timestamp <= START_TIMESTAMP + ACTIVE_RANGE, "Window for staking has come to a close");
            require(parentNFTContract.getApproved(_tokenId) == address(this), "Staking contract address not approved for transfer");
            require(parentNFTContract.ownerOf(_tokenId) == msg.sender, "Address doesn't own token");
            require(stakedMap[_tokenId].staked == false, "Already staked"); 
            
            stakedMap[_tokenId] = Stake.data(msg.sender, uint(block.timestamp), uint(stakedMap[_tokenId].stakeTotalTime), true);
            parentNFTContract.safeTransferFrom(msg.sender, address(this), _tokenId);

            emit NFTStaked(msg.sender,_tokenId,block.timestamp);
        }
        /**
        *   @dev unstake single NFT and sets timestamp.
        */ 
        function unStake(uint256 _tokenId) external nonReentrant{
            require(stakedMap[_tokenId].owner == msg.sender, "Address doesn't own token or not currently staked");

            parentNFTContract.transferFrom(address(this),msg.sender,_tokenId);
            stakedMap[_tokenId].stakeTotalTime += uint(block.timestamp - stakedMap[_tokenId].timestamp);
            stakedMap[_tokenId].staked = false;

            emit NFTUnstaked(msg.sender,_tokenId,block.timestamp);
        }

        /**
        *   @dev returns time staked in seconds
        *
        *          86,400 seconds in a day
        *
        */ 
        function getCurrentStakedTime(uint256 _tokenId) view public returns (uint){
            if(stakedMap[_tokenId].staked == true){
                return uint(stakedMap[_tokenId].stakeTotalTime + uint(uint(block.timestamp) - stakedMap[_tokenId].timestamp));
            }else{
                return uint(stakedMap[_tokenId].stakeTotalTime);
            }
        }
        /**
        *   @dev Returns true if qualified token is staked for the full amount of time
        */
        function isAddressFullyStaked(uint _timeInSeconds, address _address, uint256 _tokenId) view external returns (bool){
            require(stakedMap[_tokenId].owner == _address, "Either never staked or doesn't belong to address");
            uint currentStakedTime = getCurrentStakedTime(_tokenId);
            if(currentStakedTime < _timeInSeconds){
                return false;
            }else{
                return true;
            }
        }
        /**
        *   @dev Returns true if qualified token is burned and matches provided address
        */
        function isAddressOwnerOfBurnedToken(address _address, uint256 _tokenId) view external returns (bool){
            if(parentNFTContract.getAddressFromBurnedTokenId(_tokenId) == _address){
                return true;
            }else{
                return false;
            }
        }

        // function getAttributeType(uint256 _tokenId) view external returns (calldata string){
            
        // }


        function onERC721Received( 
            address operator, 
            address from, 
            uint256 tokenId, 
            bytes calldata data 
        ) public pure override returns (bytes4) {
            operator;
            from;
            tokenId;
            data;
            return IERC721Receiver.onERC721Received.selector;
        }
}

library Stake {
  struct data {
        address owner;
        uint timestamp;
        uint stakeTotalTime;
        bool staked;
   }
}