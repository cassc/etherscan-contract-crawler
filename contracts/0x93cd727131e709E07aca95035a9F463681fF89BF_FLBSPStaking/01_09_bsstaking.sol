// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FLBSPStaking is ERC1155Holder, Ownable{
    IERC1155 public nft;
        

    constructor() {
        address nftAddress = 0x3546395057F96484b4377B143A2933DF90bcAD13; // Mainnet BS Pass NFT
        nft = IERC1155(nftAddress);
    }


    // mapping of a staker to its corresponding struct properties
    mapping(address => Staker) public stakers;
    // all addresses that have staked
    address[] public stakerAddresses;

    struct Staker {
        // tokenIds staked for this Staker and corresponding points in time staked
        uint256[] tokenIds;
        uint256[] timestamps;
        address tokenOwner;
        // boolean whether Staker object already has staked once
        bool created;
    }

    // stake single token specified by id
    function stake(uint256 tokenId) external {
        require(tokenId > 0 && tokenId < 4, "invalid ID");
        // transfer tokens
        nft.safeTransferFrom(msg.sender, address(this), tokenId, 1, "");
        // get staker struct
        Staker storage staker = stakers[msg.sender];
        if(!staker.created) {
            // set token owner
            staker.tokenOwner = msg.sender;
            // toggle boolean created
            staker.created = true;
            // add address to array of addresses
            stakerAddresses.push(msg.sender);
        }
        staker.tokenIds.push(tokenId);
        staker.timestamps.push(block.timestamp);
    }
    // stake multiple tokens of different ids in format ([id = 1, id = 2], [quantity = 1, quantity = 4])
    function batchStake(uint256[] memory tokenId, uint256[] memory quantity) external{
        nft.safeBatchTransferFrom(msg.sender, address(this), tokenId, quantity, "");
        Staker storage staker = stakers[msg.sender];
        for(uint256 i = 0; i < tokenId.length; i++)
        {
            for(uint256 j = 0; j < quantity[i]; j++) {
            // push newly staked token to array
            staker.tokenIds.push(tokenId[i]);
            // push current timestamp to array (stores down time when the token rewards were claimed last time)
            staker.timestamps.push(block.timestamp);
        }
        }
    }


    // unstake single token, specified by id and timestamp 
    function unstake(uint256 tokenId, uint256 timestamp) public {
       //require(_tokenId <= stakeNFT.totalSupply(), "invalid TokenId");
        require(tokenId > 0 && tokenId < 4, "invalid TokenId");
        // get staker struct
        Staker storage staker = stakers[msg.sender];
        
        // get last index of array
        uint256 lastIndex = staker.timestamps.length - 1;
        // get (key)value of last index
        uint256 lastIndexKeyTokenId = staker.tokenIds[lastIndex];
        uint256 lastIndexKeyTimestamp = staker.timestamps[lastIndex];
        // get index of token to unstake
        uint256 tokenIdIndex = getIndexForTokenId(tokenId, timestamp);


        // replace unstaked tokenId with last stored tokenId 
        // (order does not matter since timestamps have been updated during withdrawal)
        staker.tokenIds[tokenIdIndex] = lastIndexKeyTokenId;
        staker.timestamps[tokenIdIndex] = lastIndexKeyTimestamp;

        // pop last value of array tokenIds, timestamps 
        staker.tokenIds.pop();
        staker.timestamps.pop();
        // transfer single token back to user
        nft.safeTransferFrom(address(this), msg.sender, tokenId, 1, "");
        
    }


    function batchUnstake(
        uint256[] memory tokenId,
        uint256[] memory timestamps
        )
    public {
        for(uint256 i = 0; i < tokenId.length; i++) {
            unstake(tokenId[i], timestamps[i]);     
        }
    }

    function getIndexForTokenId(uint256 _tokenId, uint256 _timestamp) internal view returns(uint256) {
        require(_tokenId <= 3, "invalid TokenId");
        require(_tokenId > 0, "invalid TokenId");
        Staker storage _staker = stakers[msg.sender];
        for(uint256 i = 0; i < _staker.tokenIds.length; i++) {
            if(_staker.tokenIds[i] == _tokenId && _staker.timestamps[i] == _timestamp) {
                return i;
            }
        }
        revert();
    }



    // *--* read functions *---* //

    // // returns array with that format: [# of gold tokens, # of silver tokens, # of bronze tokens]
    function getQuantitiesForAddress(address user) public view returns(uint256[] memory){
        Staker storage staker = stakers[user];
        uint256[] memory staked = new uint256[](3);
        uint256 gold = 0;
        uint256 silver = 0;
        uint256 bronze = 0;
        for(uint256 i = 0; i < staker.tokenIds.length; i++) {
            if(staker.tokenIds[i] == 3) {
                bronze += 1;
            }
            else if(staker.tokenIds[i] == 2) {
                silver += 1;
            }
            else {
                gold += 1;
            }
        }
        staked[0] = gold;
        staked[1] = silver;
        staked[2] = bronze;
        return staked;
    }

    

    // returns 2 arrays, first an array of staked token ids (uint),
    // second an array of the corresponding timestamps (uint)
    function getInfoForAddress(address user) public view returns(uint256[] memory, uint256[] memory) {
        Staker storage staker = stakers[user];
        uint256 len = staker.tokenIds.length;
        // get tokens
        uint256[] memory tokens = new uint256[](len);
        for(uint256 i = 0; i < len; i++){
            tokens[i] = staker.tokenIds[i];
        }
        uint256[] memory timestamps = new uint256[](len);
        for(uint256 i = 0; i < len; i++){
            timestamps[i] = staker.timestamps[i];
        }
        // get timestamps

        return (tokens, timestamps);
    }
    // returns array amount of staked tokens in format [gold, silver, bronze]
    function amountStaked() public view returns(uint256[] memory) {
        uint256[] memory staked = new uint256[](3);
        staked[0] = nft.balanceOf(address(this),1);
        staked[1] = nft.balanceOf(address(this),2);
        staked[2] = nft.balanceOf(address(this),3);
        return staked;
    }

    
}