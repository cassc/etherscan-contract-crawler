// SPDX-License-Identifier: MIT
/**
      _____                    _____                    _____                            _____                    _____                _____                    _____                _____                    _____                    _____          
     /\    \                  /\    \                  /\    \                          /\    \                  /\    \              /\    \                  /\    \              /\    \                  /\    \                  /\    \         
    /::\    \                /::\____\                /::\    \                        /::\    \                /::\    \            /::\    \                /::\    \            /::\    \                /::\    \                /::\    \        
    \:::\    \              /:::/    /               /::::\    \                      /::::\    \              /::::\    \           \:::\    \              /::::\    \           \:::\    \              /::::\    \              /::::\    \       
     \:::\    \            /:::/    /               /::::::\    \                    /::::::\    \            /::::::\    \           \:::\    \            /::::::\    \           \:::\    \            /::::::\    \            /::::::\    \      
      \:::\    \          /:::/    /               /:::/\:::\    \                  /:::/\:::\    \          /:::/\:::\    \           \:::\    \          /:::/\:::\    \           \:::\    \          /:::/\:::\    \          /:::/\:::\    \     
       \:::\    \        /:::/____/               /:::/__\:::\    \                /:::/__\:::\    \        /:::/__\:::\    \           \:::\    \        /:::/__\:::\    \           \:::\    \        /:::/__\:::\    \        /:::/__\:::\    \    
       /::::\    \      /::::\    \              /::::\   \:::\    \              /::::\   \:::\    \       \:::\   \:::\    \          /::::\    \      /::::\   \:::\    \          /::::\    \      /::::\   \:::\    \       \:::\   \:::\    \   
      /::::::\    \    /::::::\    \   _____    /::::::\   \:::\    \            /::::::\   \:::\    \    ___\:::\   \:::\    \        /::::::\    \    /::::::\   \:::\    \        /::::::\    \    /::::::\   \:::\    \    ___\:::\   \:::\    \  
     /:::/\:::\    \  /:::/\:::\    \ /\    \  /:::/\:::\   \:::\    \          /:::/\:::\   \:::\    \  /\   \:::\   \:::\    \      /:::/\:::\    \  /:::/\:::\   \:::\    \      /:::/\:::\    \  /:::/\:::\   \:::\    \  /\   \:::\   \:::\    \ 
    /:::/  \:::\____\/:::/  \:::\    /::\____\/:::/__\:::\   \:::\____\        /:::/__\:::\   \:::\____\/::\   \:::\   \:::\____\    /:::/  \:::\____\/:::/  \:::\   \:::\____\    /:::/  \:::\____\/:::/__\:::\   \:::\____\/::\   \:::\   \:::\____\
   /:::/    \::/    /\::/    \:::\  /:::/    /\:::\   \:::\   \::/    /        \:::\   \:::\   \::/    /\:::\   \:::\   \::/    /   /:::/    \::/    /\::/    \:::\  /:::/    /   /:::/    \::/    /\:::\   \:::\   \::/    /\:::\   \:::\   \::/    /
  /:::/    / \/____/  \/____/ \:::\/:::/    /  \:::\   \:::\   \/____/          \:::\   \:::\   \/____/  \:::\   \:::\   \/____/   /:::/    / \/____/  \/____/ \:::\/:::/    /   /:::/    / \/____/  \:::\   \:::\   \/____/  \:::\   \:::\   \/____/ 
 /:::/    /                    \::::::/    /    \:::\   \:::\    \               \:::\   \:::\    \       \:::\   \:::\    \      /:::/    /                    \::::::/    /   /:::/    /            \:::\   \:::\    \       \:::\   \:::\    \     
/:::/    /                      \::::/    /      \:::\   \:::\____\               \:::\   \:::\____\       \:::\   \:::\____\    /:::/    /                      \::::/    /   /:::/    /              \:::\   \:::\____\       \:::\   \:::\____\    
\::/    /                       /:::/    /        \:::\   \::/    /                \:::\   \::/    /        \:::\  /:::/    /    \::/    /                       /:::/    /    \::/    /                \:::\   \::/    /        \:::\  /:::/    /    
 \/____/                       /:::/    /          \:::\   \/____/                  \:::\   \/____/          \:::\/:::/    /      \/____/                       /:::/    /      \/____/                  \:::\   \/____/          \:::\/:::/    /     
                              /:::/    /            \:::\    \                       \:::\    \               \::::::/    /                                    /:::/    /                                 \:::\    \               \::::::/    /      
                             /:::/    /              \:::\____\                       \:::\____\               \::::/    /                                    /:::/    /                                   \:::\____\               \::::/    /       
                             \::/    /                \::/    /                        \::/    /                \::/    /                                     \::/    /                                     \::/    /                \::/    /        
                              \/____/                  \/____/                          \/____/                  \/____/                                       \/____/                                       \/____/                  \/____/         

 * @title EstatesStaking
 * EstatesStaking - a contract for staking The Estates ERC-721 Tokens
 */

pragma solidity ^0.8.11;

import "./IEstateStaking.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IEstate {
    function safeTransferFrom(address from,address to,uint256 tokenId) external;

    function balanceOf(address owner) external view returns (uint256);

	function estateGeneration(uint256 tokenId) external view returns (uint256);
}

interface IEquity {
    function grantEquity(address to, uint256 amount) external;
}

contract EstateStaking is IEstateStaking, Ownable, ERC721Holder {
    IEstate public estatesContract;
    IEquity public equityContract;

	// || ADMIN SWITCHES ||
	// Halt staking
	bool stakingEnabled = true;
	// Grant equity while staked
    bool grantEquity = true;
	// Minimum staking period of 7 days
    uint64 public LOCK_IN = 604800;

	// || YIELD ||
	// Daily rate of award per level 1 estate
    uint256 public BASE_RATE = 10 ether;
    // Yield tracking
    mapping(address => uint256) public unclaimedRewards;
    mapping(address => uint256) public lastUpdate;
	event RewardGranted(address user, uint256 amount);	

	// || USER BALANCES ||
    // NFT tokenId to time staked and owner's address.
    mapping(uint64 => StakedToken) public stakes;
	// Gen balances per owner (necessary as different gens give different rewards)
	struct genBalance {
		uint gen1;
		uint gen2;
		uint gen3;
		uint gen4;
	}
	mapping (address => genBalance) public generationBalance;

	// || BREED FROM STAKED ||
	event Upgraded(uint256 newEstate, uint256 parent1, uint256 parent2);

    constructor(
        address _estatesContract,
        address _equityContract,
        address _ownerAddress
    ) {
        require(_estatesContract != address(0),"nft contract cannot be 0x0");
        require(_equityContract != address(0),"equity contract cannot be 0x0");
        estatesContract = IEstate(_estatesContract);
        equityContract = IEquity(_equityContract);
        if (_ownerAddress != msg.sender) {
            transferOwnership(_ownerAddress);
        }
    }

	/** *********************************** **/
	/** ********* RewardFunctions ****** **/
	/** *********************************** **/

    function getPendingReward(address user) internal view returns (uint256) {
        // gen2 yields 2.4 gen1
		// gen3 yields 2.5 gen2
		// gen4 yields 2.6 gen3 
		uint dayrate = (generationBalance[user].gen1 + (generationBalance[user].gen2*12/5) + (generationBalance[user].gen3*6) + (generationBalance[user].gen4*78/5));
        // return weighted estates held * rate *days since last updated
        return (dayrate * BASE_RATE * (block.timestamp - lastUpdate[user])) / 86400;
    }

	// Update yield ledger
    function updateRewardAndTimestamp(address user) internal {
        if (user != address(0)) {
            unclaimedRewards[user] += getPendingReward(user);
            lastUpdate[user] = block.timestamp;
        }
    }

	function withdrawEquity() public {
		require(grantEquity, "Withdrawing equity has been paused.");
		uint256 reward = unclaimedRewards[msg.sender] +  getPendingReward(msg.sender);
		equityContract.grantEquity(msg.sender, reward);
		// reset rewards to zero
		unclaimedRewards[msg.sender] = 0;
		lastUpdate[msg.sender] = block.timestamp;
		emit RewardGranted(msg.sender,reward);
	}

	/** *********************************** **/
	/** ********* Staking Functions ****** **/
	/** *********************************** **/

    function setStake(uint64 tokenId, address user) external {	
		require(stakingEnabled, "Staking has been paused.");
        require(
            msg.sender == address(estatesContract),
            "Only estates contract set stake"
        );		
		updateRewardAndTimestamp(user);
		// assign owner and timestamp to this token
        stakes[tokenId] = StakedToken(user, uint64(block.timestamp));
		// update generation balance for user
		uint gen = estatesContract.estateGeneration(tokenId);
		// this is awkward I know...
		if (gen == 0){
			generationBalance[user].gen1 += 1;
		} else if (gen == 1){
			generationBalance[user].gen2 += 1;
		} else if (gen == 2){
			generationBalance[user].gen3 += 1;
		} else {
			generationBalance[user].gen4 += 1;
		}
		emit StartStake(user, tokenId);
    }

    function setGroupStake(uint64[] memory tokenIds, address user) external {	
		require(stakingEnabled, "Staking has been paused.");
        require(
            msg.sender == address(estatesContract),
            "Only estates contract set stake"
        );		
		updateRewardAndTimestamp(user);
		for (uint64 i = 0; i < tokenIds.length; ++i) {
			// assign owner and timestamp to this token
			stakes[tokenIds[i]] = StakedToken(user, uint64(block.timestamp));
			// update generation balance for user
			uint gen = estatesContract.estateGeneration(tokenIds[i]);
			// this is awkward I know...
			if (gen == 0){
				generationBalance[user].gen1 += 1;
			} else if (gen == 1){
				generationBalance[user].gen2 += 1;
			} else if (gen == 2){
				generationBalance[user].gen3 += 1;
			} else {
				generationBalance[user].gen4 += 1;
			}
			emit StartStake(user, tokenIds[i]);
		}
    }

	// slightly cheaper version of setStake that assumes the token has already been transferred to the staking contract and is gen1 
	function stakeMint(uint256 firstTokenId, address user, uint256 _vol) public {
        require(
            msg.sender == address(estatesContract),
            "Only estates contract can mint to stake"
        );
		updateRewardAndTimestamp(user);
		for (uint256 i=0; i<_vol; ++i) {
			stakes[uint64(firstTokenId+i)] = StakedToken(user, uint64(block.timestamp));
			emit StartStake(user, uint64(firstTokenId+i));
		}
		generationBalance[user].gen1 += _vol;	
	}

    function unstake(uint64 tokenId) internal {
        require(stakes[tokenId].user != address(0), "TokenId not staked");
        require(stakes[tokenId].user == msg.sender,"Sender didn't stake token");
        uint64 stakeLength = uint64(block.timestamp) - stakes[tokenId].timeStaked;
        require(stakeLength > LOCK_IN, "Can not remove token until lock-in period is over");

		// update gen balance
		uint gen = estatesContract.estateGeneration(tokenId);
		if (gen == 0){
			generationBalance[msg.sender].gen1 -= 1;
		} else if (gen == 1){
			generationBalance[msg.sender].gen2 -= 1;
		} else if (gen == 2){
			generationBalance[msg.sender].gen3 -= 1;
		} else {
			generationBalance[msg.sender].gen4 -= 1;
		}		
        
		delete stakes[tokenId];
        estatesContract.safeTransferFrom(address(this),msg.sender,uint256(tokenId));
		emit Unstake(msg.sender,tokenId,stakeLength);
    }

	function singleUnstake(uint64 tokenId) public override {
        // withdraw any unclaimed rewards
		if (grantEquity) {
            withdrawEquity();
        } else {
			updateRewardAndTimestamp(msg.sender);
		}
		unstake(tokenId);
	}

    function groupUnstake(uint64[] memory tokenIds) external override {
        // withdraw any unclaimed rewards
		if (grantEquity) {
            withdrawEquity();
        } else {
			updateRewardAndTimestamp(msg.sender);
		}		
        for (uint64 i = 0; i < tokenIds.length; ++i) {
            unstake(tokenIds[i]);
        }
    }

	/** *********************************** **/
	/** ********* View Functions ****** **/
	/** *********************************** **/

	function getTokenOwner(uint64 tokenId) external view returns (address) {
		return stakes[uint64(tokenId)].user;
	}	

	// NEVER CALL THIS ON CHAIN, VERY EXPENSIVE
    function viewStakes(address _address) public view returns (uint256[] memory)
    {
        uint256[] memory _tokens = new uint256[](18750);
        uint256 tookCount = 0;
        for (uint64 i = 0; i < 18750; i++) {
            if (stakes[i].user == _address) {
                _tokens[tookCount] = i;
                tookCount++;
            }
        }
        uint256[] memory trimmedResult = new uint256[](tookCount);
        for (uint256 j = 0; j < trimmedResult.length; j++) {
            trimmedResult[j] = _tokens[j];
        }
        return trimmedResult;
    }

	// Gets COMBINED balance of UNSTAKED and STAKED estates, useful for collabland etc
    function balanceOf(address _address) external view returns (uint256)
    {
        return estatesContract.balanceOf(_address) + viewStakes(_address).length;
    }

    function getTotalUnclaimed(address user)
        external
        view
        returns (uint256 unclaimed)	{
			return unclaimedRewards[user] + getPendingReward(user);
		}

	/** *********************************** **/
	/** ********* Owner Functions ****** **/
	/** *********************************** **/

	// Enable or disable staking
    function setStaking(bool _enable) external onlyOwner {
        stakingEnabled = _enable;
    }

	// Enable or disable equity granting
    function setGrantEquity(bool _grant) external onlyOwner {
        grantEquity = _grant;
    }

	// Set the lockin period for staking
    function setLockIn(uint64 _lockin) external onlyOwner {
        LOCK_IN = _lockin;
    }

	// Set the base rate for rewards
    function setBaseRate(uint256 _rate) external onlyOwner {
        BASE_RATE = 1 ether * _rate;
    } 

	// Set Estates contract
    function setEstatesContract(address _address) external onlyOwner {
        estatesContract = IEstate(_address);
    }

	// Set $Equity contract
    function setEquityContract(address _address) external onlyOwner {
        equityContract = IEquity(_address);
    }		    
}