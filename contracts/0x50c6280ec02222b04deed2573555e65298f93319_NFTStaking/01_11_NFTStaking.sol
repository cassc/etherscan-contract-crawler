// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract NFTStaking is Ownable{
    using SafeMath for uint256;
	using SafeERC20 for IERC20;
	using EnumerableSet for EnumerableSet.UintSet;
	
    IERC721 public nftCollection;
	IERC20 public DigiToads;
	
	uint256 public precisionFactor;
	uint256 public accTokenPerShare;
	uint256 public totalStaked;
	
	struct StakingInfo {
       address owner;
	   uint256 rewardDebt;
	   bool staked;
    }
	
	mapping(address => EnumerableSet.UintSet) private _deposits;
	mapping(uint256 => StakingInfo) public stakingInfo;
	
	constructor() {
	   nftCollection = IERC721(0x8f393E46Ac410118Fd892011B1432bb7D0fD1A54);
       DigiToads = IERC20(0x817497E83684E07F5963BdBa33DF8A9A81386B37);
	   precisionFactor = 1 * 10**18;
	}
	
	function stake(uint256[] calldata tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
			require(
                nftCollection.ownerOf(tokenIds[i]) == msg.sender,
                "Can't stake tokens you don't own!"
            );
			
			nftCollection.transferFrom(msg.sender, address(this), tokenIds[i]);
            _deposits[msg.sender].add(tokenIds[i]);
			
			stakingInfo[tokenIds[i]].rewardDebt = accTokenPerShare / precisionFactor;
			stakingInfo[tokenIds[i]].owner = msg.sender;
			stakingInfo[tokenIds[i]].staked = true;
			totalStaked++;
        }
    }
	
	function withdraw(uint256[] calldata tokenIds) external {
        for (uint256 i; i < tokenIds.length; i++) {
           require(
			 stakingInfo[tokenIds[i]].staked == true,
			 "This token has not been deposited"
		   );
		   require(
			 stakingInfo[tokenIds[i]].owner == address(msg.sender),
			 "Incorrect request submitted"
		   );
		   
		   uint256 pending = pendingReward(tokenIds[i]);
		   DigiToads.safeTransfer(address(msg.sender), pending);
		   
           _deposits[msg.sender].remove(tokenIds[i]);
           nftCollection.transferFrom(address(this), msg.sender, tokenIds[i]);
		   stakingInfo[tokenIds[i]].staked = false;
		   totalStaked--;
        }
    }
	
	function withdrawReward(uint256[] calldata tokenIds) external {
	   for (uint256 i; i < tokenIds.length; i++) {
           require(
			 stakingInfo[tokenIds[i]].staked == true,
			 "This token has not been deposited"
		   );
		   require(
			 stakingInfo[tokenIds[i]].owner == address(msg.sender),
			 "Incorrect request submitted"
		   );
		   
		   uint256 pending = pendingReward(tokenIds[i]);
		   DigiToads.safeTransfer(address(msg.sender), pending);
		   stakingInfo[tokenIds[i]].rewardDebt += pending;
        }
	}
	
	function depositsOf(address owner) external view returns (uint256[] memory) {
        EnumerableSet.UintSet storage depositSet = _deposits[owner];
        uint256[] memory tokenIds = new uint256[](depositSet.length());
        for (uint256 i; i < depositSet.length(); i++) {
            tokenIds[i] = depositSet.at(i);
        }
        return tokenIds;
    }
	
	function pendingReward(uint256 id) public view returns (uint256) {
	   require(
		 stakingInfo[id].staked == true,
		 "This token has not been deposited"
	   );
	   uint256 pending = (accTokenPerShare / precisionFactor) - stakingInfo[id].rewardDebt;
	   return pending;
    }
	
	function updatePool(uint256 amount) external{
		require(address(msg.sender) == address(DigiToads), "Request source is not valid");
		if(totalStaked > 0) 
		{
		   accTokenPerShare = accTokenPerShare + (amount * precisionFactor / totalStaked);
		}
		else
		{
		   DigiToads.safeTransfer(owner(), amount);  
		}
    }
}