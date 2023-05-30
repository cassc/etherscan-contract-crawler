// SPDX-License-Identifier: MIT

//███████╗ █████╗  ██████╗
//██╔════╝██╔══██╗██╔════╝
//███████╗███████║██║
//╚════██║██╔══██║██║
//███████║██║  ██║╚██████╗
//╚══════╝╚═╝  ╚═╝ ╚═════╝

// Advanced Triple-Power Staking System created by MisterSausage NFT Elite Consulting x SausageLabs.io for STONER APE CLUB

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

abstract contract SAC is ERC721Enumerable, Ownable {}

contract Staking is ERC721, ReentrancyGuard, Ownable {
	using SafeMath for uint256;
    using Strings for uint256;
    string baseTokenURI;
    constructor() ERC721("Staked SAC", "stSAC") {}
    SAC public sac;
    IERC20 public token;
    address private rewardWallet;
    bool public stakingFlag;
    uint256 public lockTime;


    struct BaseRewards {
        uint256 rewardsPerDay;
        uint256 updateTimestamp;
    }

    mapping(uint256 => BaseRewards) public baseRewardsData;
    uint256 baseRewardsIndex;
	uint256 public currentBaseReward;

    struct Bundle {
        uint256 rewardsEarned;
        uint256 tokensStaked;
        uint256 lastUpdateTimestamp;
        uint256 currentRewardsIndex;
    }

    mapping(uint256 => Bundle) public bundles;
    mapping(uint256 => uint256[]) public bundleTokenMap;
    uint256 public currentBundleId = 1;

    mapping(uint256 => uint256) tokenBundleMap;

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns(bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

	function setToken(address _addr) external onlyOwner {
		token = IERC20(_addr);
	}

    function setNFTContract(address _addr) external onlyOwner {
        sac = SAC(_addr);
    }

    function setLockTime(uint256 _lockTime) external onlyOwner {
		lockTime = _lockTime;
	}
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }


    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(),".json")) : "";
    }


    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function flipStakingFlag() external onlyOwner {
        stakingFlag = !stakingFlag;
    }

    function setRewardWallet(address _rewardWallet) external onlyOwner {
        rewardWallet = _rewardWallet;
    }

    function getBundleToToken(uint256 bundleId) public view returns(uint256[] memory) {
		return(bundleTokenMap[bundleId]);

	}


    function updateBaseRewards(uint256 _rewardsPerDay) external onlyOwner {
        BaseRewards storage baseRewards = baseRewardsData[baseRewardsIndex];
        baseRewards.rewardsPerDay = _rewardsPerDay;
		currentBaseReward = _rewardsPerDay;
        baseRewards.updateTimestamp = block.timestamp;
        baseRewardsIndex++;
    }

    function stakeNFT(uint256[] memory tokenIDs) public nonReentrant {
		require(stakingFlag,"Staking window not open");

        uint len = tokenIDs.length;

		for(uint i; i < len; i++) {
        require(msg.sender == sac.ownerOf(tokenIDs[i]), "Caller not owner of SAC tokenId.");
		}

        for(uint i; i < len; i++) {
            sac.safeTransferFrom(msg.sender, address(this), tokenIDs[i]);
			bundleTokenMap[currentBundleId].push(tokenIDs[i]);
            tokenBundleMap[tokenIDs[i]]	= currentBundleId;
        }

            Bundle storage bundle = bundles[currentBundleId];
            bundle.tokensStaked = len;
            bundle.lastUpdateTimestamp = block.timestamp;
            bundle.currentRewardsIndex = baseRewardsIndex -1;
			_safeMint(msg.sender, currentBundleId);

			currentBundleId++;
    }

    function calculateReward(uint256 bundleId) public view returns(uint256) {
        if (ownerOf(bundleId) == address(this)) {
            return 0;
        }
        else {
            uint256 currentIndex = bundles[bundleId].currentRewardsIndex;
            uint256 previousTimestamp = bundles[bundleId].lastUpdateTimestamp;
            uint256 totalRewardsTemp;
			uint256 totalRewards;
            //uint256 bonusTier = bundles[bundleId].tokensStaked<=2 ? 0 : (bundles[bundleId].tokensStaked>2 && bundles[bundleId].tokensStaked<=5) ? 10 : 25;
			uint256 bonusTier = bundles[bundleId].tokensStaked<6 ? 0 : (bundles[bundleId].tokensStaked>=6 && bundles[bundleId].tokensStaked<=11) ? 1 : (bundles[bundleId].tokensStaked>=12 && bundles[bundleId].tokensStaked<=23) ? 2 : (bundles[bundleId].tokensStaked>=24 && bundles[bundleId].tokensStaked<=49) ? 4 : (bundles[bundleId].tokensStaked>=50 && bundles[bundleId].tokensStaked<=74) ? 6 : (bundles[bundleId].tokensStaked>=75 && bundles[bundleId].tokensStaked<=99) ? 8 :  10;

            //Add rewards for past indices if necessary
            for(currentIndex; currentIndex < baseRewardsIndex - 1; currentIndex++)   {
                uint256 nextTimestamp = baseRewardsData[currentIndex+1].updateTimestamp;
				totalRewardsTemp = totalRewardsTemp.add(((nextTimestamp - previousTimestamp).div(86400)).mul(baseRewardsData[currentIndex].rewardsPerDay));
                previousTimestamp = nextTimestamp;
            }

            //Add rewards for current index
            totalRewardsTemp = bundles[bundleId].tokensStaked.mul(totalRewardsTemp.add(((block.timestamp - previousTimestamp).div(86400)).mul(baseRewardsData[currentIndex].rewardsPerDay)));
			totalRewards = totalRewardsTemp.add((totalRewardsTemp).mul(bonusTier).div(200));
            return totalRewards;
        }

    }

    function claimReward(uint256 bundleId) private {
        require(msg.sender == ownerOf(bundleId),"Caller not eligible to claim rewards");
		uint256 rewards = calculateReward(bundleId);
        bundles[bundleId].rewardsEarned += rewards;
        bundles[bundleId].lastUpdateTimestamp = block.timestamp;
        bundles[bundleId].currentRewardsIndex = baseRewardsIndex - 1;
    }


    function withdrawRewards(uint256 bundleId) public {
        require(msg.sender == ownerOf(bundleId),"Caller not eligible to claim rewards");
        claimReward(bundleId);
        uint256 claimedRewards = bundles[bundleId].rewardsEarned;
        if (claimedRewards > 0)  {
            bundles[bundleId].rewardsEarned = 0;
            token.transferFrom(rewardWallet, msg.sender, claimedRewards * 10 ** 18);
        }
    }

    function unstakeAll(uint256 bundleId) public nonReentrant {
        require(msg.sender == ownerOf(bundleId), "Caller not owner of bundleId.");
		require((block.timestamp - bundles[bundleId].lastUpdateTimestamp) > lockTime, "Min. stake duration not met");
        withdrawRewards(bundleId);
        _transfer(msg.sender,address(this),bundleId);

        for(uint i; i<bundleTokenMap[bundleId].length; i++) {
            tokenBundleMap[bundleTokenMap[bundleId][i]] = 0;
            bundles[bundleId].tokensStaked = 0;
            sac.safeTransferFrom(address(this),msg.sender,bundleTokenMap[bundleId][i]);
        }
    }

    function partialUnstake(uint256 bundleId, uint256[] memory keepTokenIds, uint256[] memory unstakeTokenIds) public nonReentrant {
        require(msg.sender == ownerOf(bundleId), "Caller not owner of bundleId.");
		require((block.timestamp - bundles[bundleId].lastUpdateTimestamp) > lockTime, "Min. stake duration not met");
        require(keepTokenIds.length + unstakeTokenIds.length == bundleTokenMap[bundleId].length,"Invalid call");

        withdrawRewards(bundleId);
        _transfer(msg.sender,address(this),bundleId);

        for(uint i; i<unstakeTokenIds.length; i++) {
            require(tokenBundleMap[unstakeTokenIds[i]] == bundleId,"Invalid");
            tokenBundleMap[unstakeTokenIds[i]] = 0;
            sac.safeTransferFrom(address(this),msg.sender,unstakeTokenIds[i]);
        }

        bundles[bundleId].tokensStaked = 0;

        for(uint i; i < keepTokenIds.length; i++) {
            require(tokenBundleMap[keepTokenIds[i]] == bundleId,"Invalid");
			bundleTokenMap[currentBundleId].push(keepTokenIds[i]);
            tokenBundleMap[keepTokenIds[i]]	= currentBundleId;
        }

            Bundle storage bundle = bundles[currentBundleId];
            bundle.tokensStaked = keepTokenIds.length;
            bundle.lastUpdateTimestamp = block.timestamp;
            bundle.currentRewardsIndex = baseRewardsIndex -1;
			_safeMint(msg.sender, currentBundleId);

			currentBundleId++;

    }

}