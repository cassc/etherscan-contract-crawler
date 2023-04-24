// SPDX-License-Identifier: MIT

/*


 
 ██████   ██████      ███    ██ ███████ ████████     ███████ ████████  █████  ██   ██ ██ ███    ██  ██████  
██       ██           ████   ██ ██         ██        ██         ██    ██   ██ ██  ██  ██ ████   ██ ██       
██   ███ ██   ███     ██ ██  ██ █████      ██        ███████    ██    ███████ █████   ██ ██ ██  ██ ██   ███ 
██    ██ ██    ██     ██  ██ ██ ██         ██             ██    ██    ██   ██ ██  ██  ██ ██  ██ ██ ██    ██ 
 ██████   ██████      ██   ████ ██         ██        ███████    ██    ██   ██ ██   ██ ██ ██   ████  ██████  
                                                                                                            
                                                                                                        

*/

pragma solidity ^0.8.17;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */


contract GGStaking is Ownable {
    struct TokenInfo {
        bool isLegendary;
        uint8 squadId; //Adventure, Bling, Business, Chill, Love, Misfit, Party, Space
    }
    //Info each user
    struct UserInfo {
        uint256 totalNFTCountForHolder;
        bool isLegendaryStaker;
        uint256 stakedLegendaryCountForHolder;
        bool isAllSquadStaker;
        bool commonNFTHolder;
        uint256 commonNFTCountForHolder;
        uint256 pendingRewards;
        uint256 rewardDebt;
        uint256 depositNumber;
    }
    IERC721 public immutable nftToken;      //NFT contract address
    IERC20 public immutable egToken;       //EG token contract address
    uint256 public constant REWARD_DECIMAL = (1e12); // decimals of token
    uint256 public constant SQUAD_FEATURE_NUMBER = 8;  // number of squad features
    //ClaimFee
    uint256 public claimFee;
    address public claimFeeWallet;    
    //accxxxPerShare
    uint256 public accLegendaryPerShare;
    uint256 public accAllSquadPerShare;
    uint256 public accCommonNFTPerShare;
    //currentxxxReward
    uint256 public currentLegendaryReward; // the number of EG tokens given to each Legendary Holder after latest Admin Drop
    uint256 public currentAllSquadReward; // the number of EG tokens given to each All-Squad Holder after latest Admin Drop
    uint256 public currentCommonNFTReward; // the number of EG tokens given to each Common NFT Holder after latest Admin Drop
    uint256 public totalStakedGators;   //number of total staked NFTs
    uint256 public totalLegendaryStaked;    //number of total staked legendary NFTs
    uint256 public totalAllSquadHolders;    //number of total All-Squad Holder
    uint256 public totalCommonNFTsStaked;   //number of total staked common NFTs
    uint256 public totalDepositCount;   //number of total deposit
    uint256 public lastDepositTime;     //last Admin Drop deposit time
    uint256 public unusedRewardPot;     //unused reward amount
    uint256 public legendaryRewardsPercent;     //percent of legendary rewards
    uint256 public allSquadRewardsPercent;      //percent of all squad rewards
    uint256 public commonRewardsPercent;        //percent of common rewards

    uint256 private _totalRewardBalance;    //total deposited EG token amount 
    
    mapping(uint256 => TokenInfo) public tokenInfos;    //information for every GG NFT
    mapping(address => mapping(uint256 => uint256)) public ownedTokens;     //user address and owned index for NFT Id
    mapping(address => UserInfo) public userInfos;      //information for every user
    mapping(uint256 => bool) public stakedNFTs;    //staked NFTs flag
    mapping(uint256 => uint256) private _ownedTokensIndex;  //owned token index with ownedTokens
    
    mapping (uint256 => bool) public squadTokenFeatures;     //squad token features

    event Staked(address indexed staker, uint256[] tokenId);    
    event UnStaked(address indexed staker, uint256[] tokenId);
    event Claim(address indexed staker, uint256 amount);
    event SetRewardsPercent(
        uint256 _legendaryPercent,
        uint256 _allSquadPercent,
        uint256 _commonPercent
    );
    event DepositReward(address indexed user, uint256 amount);
    event SetClaimFee(uint256 _claimFee);
    event SetClaimFeeWallet(address indexed _claimFeeWallet);
    event WithdrawUnusedRewardPot(uint256 unusedRewardPot);

    /**
     * @param _nftToken GG NFT address
     * @param _egToken EG Token address
     */
    constructor(IERC721 _nftToken, IERC20 _egToken) {
        require(
            address(_nftToken) != address(0) && address(_egToken) != address(0), 
            "Zero address of token"
        );
        nftToken = _nftToken;
        egToken = _egToken;
        for (uint256 i = 0; i < SQUAD_FEATURE_NUMBER; i++) {
            squadTokenFeatures[i] = true;
        }
    }
    /**
     * @dev This function is called when user withdraws their EG token balance
     */
    function claim() external {
        UserInfo storage user = userInfos[msg.sender];
        uint256 pending = _getPending(msg.sender);
        uint256 amount = user.pendingRewards;
        if (user.depositNumber < totalDepositCount) {
            amount = amount + pending - user.rewardDebt;
        }
        require(
            amount > 0,
            "claim: the pending amount should be greater that 0"
        );
        uint256 contractBalance = egToken.balanceOf(address(this));
        if (contractBalance < amount) {
            user.pendingRewards = amount - contractBalance;
            amount = contractBalance;
        } else {
            user.pendingRewards = 0;
        }
        user.rewardDebt = pending;
        if(claimFee > 0) {
            uint256 feeAmount = amount * claimFee / 100;
            egToken.transfer(claimFeeWallet, feeAmount);
            amount = amount - feeAmount;
        }
        egToken.transfer(msg.sender, amount);
        emit Claim(msg.sender, amount);
    }
    /**
     * @param tokenIds Id of NFTs to stake by user
     * @dev This function is called when user stakes GG NFTs
     */
    function stake(uint256[] calldata tokenIds) external {
        require(tokenIds.length > 0, "NFT Stake: Empty Array");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                nftToken.ownerOf(tokenIds[i]) == msg.sender,
                "NFT Stake: only Owner of NFT can stake it"
            );
            require(
                !stakedNFTs[tokenIds[i]],
                "NFT Stake: duplicate token ids in input parameters"
            );
            stakedNFTs[tokenIds[i]] = true;
        }

        UserInfo storage user = userInfos[msg.sender];
        uint256 pending;
        if (user.depositNumber < totalDepositCount) {
            pending = _getPending(msg.sender);
            user.pendingRewards =
                user.pendingRewards +
                pending -
                user.rewardDebt;
        }
        uint256 lastTokenIndex;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            lastTokenIndex = user.totalNFTCountForHolder + i;
            ownedTokens[msg.sender][lastTokenIndex] = tokenIds[i];
            _ownedTokensIndex[tokenIds[i]] = lastTokenIndex;
            nftToken.transferFrom(msg.sender, address(this), tokenIds[i]);
        }
        user.totalNFTCountForHolder =
            user.totalNFTCountForHolder +
            tokenIds.length;
        totalStakedGators = totalStakedGators + tokenIds.length;
        uint256 requireStakeLegendaryCount;
        uint256 requireStakeCommonNFTCount;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            TokenInfo storage token = tokenInfos[tokenIds[i]];
            if (token.isLegendary) {
                if (!user.isLegendaryStaker) user.isLegendaryStaker = true;
                requireStakeLegendaryCount++;
            } else {
                if (!user.commonNFTHolder) user.commonNFTHolder = true;
            }
        }
        requireStakeCommonNFTCount =
            tokenIds.length -
            requireStakeLegendaryCount;
        if (requireStakeLegendaryCount > 0) {
            if (!user.isLegendaryStaker) {
                user.isLegendaryStaker = true;
            }
            user.stakedLegendaryCountForHolder =
                user.stakedLegendaryCountForHolder +
                requireStakeLegendaryCount;
            totalLegendaryStaked =
                totalLegendaryStaked +
                requireStakeLegendaryCount;
        }
        if (requireStakeCommonNFTCount > 0) {
            bool freeCommonSumFlag = true;
            if (
                !user.isAllSquadStaker &&
                (user.commonNFTCountForHolder + requireStakeCommonNFTCount) >=
                SQUAD_FEATURE_NUMBER
            ) {
                bool allSquadStatus = checkAllSquadStaker();
                if (allSquadStatus) {
                    freeCommonSumFlag = false;
                }
            }
            if (freeCommonSumFlag) {
                user.commonNFTCountForHolder =
                    user.commonNFTCountForHolder +
                    requireStakeCommonNFTCount;
                totalCommonNFTsStaked =
                    totalCommonNFTsStaked +
                    requireStakeCommonNFTCount;
            } else {
                user.isAllSquadStaker = true;
                user.commonNFTCountForHolder =
                    user.commonNFTCountForHolder +
                    requireStakeCommonNFTCount -
                    SQUAD_FEATURE_NUMBER;
                totalAllSquadHolders++;
                totalCommonNFTsStaked =
                    totalCommonNFTsStaked +
                    requireStakeCommonNFTCount -
                    SQUAD_FEATURE_NUMBER;
            }
        }
        pending = _getPending(msg.sender);
        user.rewardDebt = pending;
        user.depositNumber = totalDepositCount;
        emit Staked(msg.sender, tokenIds);
    }
    /**
     * @param tokenIds Id of NFTs to unstake by user
     * @dev This function is called when user unstakes GG NFTs
     */
    function unstake(uint256[] calldata tokenIds) external {
        require(tokenIds.length > 0, "NFT unstake: Empty Array");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                ownedTokens[msg.sender][_ownedTokensIndex[tokenIds[i]]] ==
                    tokenIds[i],
                "NFT unstake: token not staked or incorrect token owner"
            );
            require(
                stakedNFTs[tokenIds[i]],
                "NFT unstake: duplicate token ids in input params"
            );
            stakedNFTs[tokenIds[i]] = false;
        }
        UserInfo storage user = userInfos[msg.sender];
        uint256 pending;
        if (user.depositNumber < totalDepositCount) {
            pending = _getPending(msg.sender);
            user.pendingRewards =
                user.pendingRewards +
                pending -
                user.rewardDebt;
        }
        uint256 lastTokenIndex;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            lastTokenIndex = user.totalNFTCountForHolder - i - 1;
            if (_ownedTokensIndex[tokenIds[i]] != lastTokenIndex) {
                ownedTokens[msg.sender][
                    _ownedTokensIndex[tokenIds[i]]
                ] = ownedTokens[msg.sender][lastTokenIndex];
                _ownedTokensIndex[
                    ownedTokens[msg.sender][lastTokenIndex]
                ] = _ownedTokensIndex[tokenIds[i]];
            }
            delete _ownedTokensIndex[tokenIds[i]];
            delete ownedTokens[msg.sender][lastTokenIndex];
            nftToken.transferFrom(address(this), msg.sender, tokenIds[i]);
        }
        user.totalNFTCountForHolder =
            user.totalNFTCountForHolder -
            tokenIds.length;
        totalStakedGators = totalStakedGators - tokenIds.length;
        uint256 requireUnStakeLegendaryCount = 0;
        uint256 requireUnStakeCommonNFTCount = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            TokenInfo storage token = tokenInfos[tokenIds[i]];
            if (token.isLegendary) {
                requireUnStakeLegendaryCount++;
            }
        }
        requireUnStakeCommonNFTCount =
            tokenIds.length -
            requireUnStakeLegendaryCount;
        if (requireUnStakeLegendaryCount > 0) {
            if (
                user.stakedLegendaryCountForHolder ==
                requireUnStakeLegendaryCount
            ) {
                user.isLegendaryStaker = false;
                user.stakedLegendaryCountForHolder = 0;
            } else {
                user.stakedLegendaryCountForHolder =
                    user.stakedLegendaryCountForHolder -
                    requireUnStakeLegendaryCount;
            }
            totalLegendaryStaked =
                totalLegendaryStaked -
                requireUnStakeLegendaryCount;
        }
        if (requireUnStakeCommonNFTCount > 0) {
            if (user.commonNFTCountForHolder < requireUnStakeCommonNFTCount) {
                if (user.isAllSquadStaker) {
                    user.isAllSquadStaker = false;
                    totalAllSquadHolders--;
                    user.commonNFTCountForHolder =
                        user.commonNFTCountForHolder +
                        SQUAD_FEATURE_NUMBER -
                        requireUnStakeCommonNFTCount;
                    totalCommonNFTsStaked =
                        totalCommonNFTsStaked +
                        SQUAD_FEATURE_NUMBER -
                        requireUnStakeCommonNFTCount;
                }
            } else {
                bool freeCommonSubFlag = true;
                if (user.isAllSquadStaker) {
                    bool allSquadStatus = checkAllSquadStaker();
                    if (!allSquadStatus) {
                        freeCommonSubFlag = false;
                    }
                }

                if (freeCommonSubFlag) {
                    user.commonNFTCountForHolder =
                        user.commonNFTCountForHolder -
                        requireUnStakeCommonNFTCount;
                    totalCommonNFTsStaked =
                        totalCommonNFTsStaked -
                        requireUnStakeCommonNFTCount;
                } else {
                    user.isAllSquadStaker = false;
                    totalAllSquadHolders--;
                    user.commonNFTCountForHolder =
                        user.commonNFTCountForHolder +
                        SQUAD_FEATURE_NUMBER -
                        requireUnStakeCommonNFTCount;
                    totalCommonNFTsStaked =
                        totalCommonNFTsStaked +
                        SQUAD_FEATURE_NUMBER -
                        requireUnStakeCommonNFTCount;
                }
            }

            if (user.commonNFTCountForHolder == 0 && user.commonNFTHolder) {
                user.commonNFTHolder = false;
            } else if (
                user.commonNFTCountForHolder > 0 && !user.commonNFTHolder
            ) {
                user.commonNFTHolder = true;
            }
        }

        pending = _getPending(msg.sender);
        user.rewardDebt = pending;
        user.depositNumber = totalDepositCount;
        emit UnStaked(msg.sender, tokenIds);
    }
    /**
     * @dev withdraw unused rewards
     */
    function withdrawUnusedRewardPot() external onlyOwner {
        require(
            unusedRewardPot > 0,
            "withdrawUnusedRewardPot: unusedRewardPot should be greater than 0"
        );
        egToken.transfer(owner(), unusedRewardPot);
        uint256 tmpUnusedRewardPot = unusedRewardPot;
        unusedRewardPot = 0;
        emit WithdrawUnusedRewardPot(tmpUnusedRewardPot);
    }
    /**
     * @param _claimFee percent of claim fee
     * @dev set claim fee
     */
    function setClaimFee(uint256 _claimFee) external onlyOwner {
        require(
            _claimFee <= 10,
            "setClaimFee: amount should be smaller than 10"
        );
        claimFee = _claimFee;
        emit SetClaimFee(_claimFee);
    }
    /**
     * @param _claimFeeWallet wallet address of claim fee
     * @dev set claim fee wallet address
     */
    function setClaimFeeWallet(address _claimFeeWallet) external onlyOwner {
        require(
            _claimFeeWallet != address(0),
            "setClaimFeeWallet: the claimFeeWallet must have a valid address"
        );
        claimFeeWallet = _claimFeeWallet;
        emit SetClaimFeeWallet(_claimFeeWallet);
    }
    /**
     * @param _ids Id array of GG NFTs
     * @param _isLegendaries  legendary flag for every GGNFT
     * @param _squadIds squad feature Id
     * @dev set GG NFTs information
     */
    function setTokenInfo(
        uint256[] calldata _ids,
        uint8[] calldata _isLegendaries,
        uint8[] calldata _squadIds
    ) external onlyOwner {
        require(_ids.length > 0, "setTokenInfo: Empty array");
        require(
            (_ids.length == _isLegendaries.length) &&
                (_ids.length == _squadIds.length),
            "setTokenInfo: the array lengths should match"
        );
        for (uint256 i = 0; i < _ids.length; i++) {
            require(
                squadTokenFeatures[_squadIds[i]],
                "setTokenInfo: the squadId should be less than squadTokenFeature length"
            );
            TokenInfo storage tokenInfo = tokenInfos[_ids[i]];
            tokenInfo.isLegendary = _isLegendaries[i] == 0 ? false : true;
            tokenInfo.squadId = _squadIds[i];
        }
    }
    /**
     * @param _amount amount of deposit
     * @dev set deposit EG amount
     */
    function depositReward(uint256 _amount) external onlyOwner {
        require(
            _amount > 0,
            "depositReward: the amount should be greater than 0"
        );
        require(
            legendaryRewardsPercent +
            allSquadRewardsPercent +
            commonRewardsPercent ==
            100,
            "depositReward: the total rewards percent should be 100"
        );
        require(
            totalStakedGators > 0,
            "depositReward: the totalStakedGators should be greater than 0"
        );
        _totalRewardBalance = _totalRewardBalance + _amount;
        uint256 legendaryRewards = (_amount * legendaryRewardsPercent) / 100;
        uint256 allSquadRewards = (_amount * allSquadRewardsPercent) / 100;
        uint256 commonNFTRewards = (_amount * commonRewardsPercent) / 100;
        if (totalLegendaryStaked > 0) {
            currentLegendaryReward = legendaryRewards / totalLegendaryStaked;
            accLegendaryPerShare =
                accLegendaryPerShare +
                ((legendaryRewards * (REWARD_DECIMAL)) / totalLegendaryStaked);
        } else {
            unusedRewardPot = unusedRewardPot + legendaryRewards;
            currentLegendaryReward = legendaryRewards;
        }
        if (totalAllSquadHolders > 0) {
            currentAllSquadReward = allSquadRewards / totalAllSquadHolders;
            accAllSquadPerShare =
                accAllSquadPerShare +
                ((allSquadRewards * REWARD_DECIMAL) / totalAllSquadHolders);
        } else {
            unusedRewardPot = unusedRewardPot + allSquadRewards;
            currentAllSquadReward = allSquadRewards;
        }
        if (totalCommonNFTsStaked > 0) {
            currentCommonNFTReward = commonNFTRewards / totalCommonNFTsStaked;
            accCommonNFTPerShare =
                accCommonNFTPerShare +
                ((commonNFTRewards * (REWARD_DECIMAL)) / totalCommonNFTsStaked);
        } else {
            unusedRewardPot = unusedRewardPot + commonNFTRewards;
            currentCommonNFTReward = commonNFTRewards;
        }
        totalDepositCount++;
        lastDepositTime = block.timestamp;
        egToken.transferFrom(msg.sender, address(this), _amount);
        emit DepositReward(msg.sender, _amount);
    }
    /**
     * @param _legendaryRewardsPercent percent of legendary rewards 
     * @param _allSquadRewardsPercent percent of all squad rewards
     * @param _commonRewardsPercent percent of common rewards
     * @dev set percent of NFTs
     */
    function setRewardsPercent(
        uint256 _legendaryRewardsPercent,
        uint256 _allSquadRewardsPercent,
        uint256 _commonRewardsPercent
    ) external onlyOwner {
        require(
            _legendaryRewardsPercent +
                _allSquadRewardsPercent +
                _commonRewardsPercent ==
                100,
            "setRewardsPercent: the total rewards percent should be 100"
        );
        legendaryRewardsPercent = _legendaryRewardsPercent;
        allSquadRewardsPercent = _allSquadRewardsPercent;
        commonRewardsPercent = _commonRewardsPercent;
        emit SetRewardsPercent(
            _legendaryRewardsPercent,
            _allSquadRewardsPercent,
            _commonRewardsPercent
        );
    }
    /**
     * @param _user user address
     * @dev get pending rewards for user
     */
    function getPending(address _user) external view returns (uint256) {
        UserInfo storage user = userInfos[_user];
        uint256 pending = user.pendingRewards;
        if (user.depositNumber < totalDepositCount) {
            pending += _getPending(_user) - user.rewardDebt;
        }
        return pending;
    }
    /**
     * @param _user user address
     * @dev get staked NFTs Id for user
     */
    function userStakedNFTs(address _user) external view returns (uint256[] memory) {
        UserInfo memory user = userInfos[_user];
        uint256[] memory userNFTs = new uint256[](user.totalNFTCountForHolder);
        for(uint256 i = 0; i < user.totalNFTCountForHolder; i++){
            userNFTs[i] = ownedTokens[_user][i];
        }
        return userNFTs;
    }
    /**
     * @dev check _totalRewardBalance
     */
    function totalRewardBalance() external view returns (uint256) {
        return _totalRewardBalance;
    }
    /**
     * @param _user  user address
     * @dev get pending between depositNumber and totalDepositNumber
     */
    function _getPending(address _user) private view returns (uint256) {
        UserInfo storage user = userInfos[_user];
        uint256 pending;
        if (user.isLegendaryStaker) {
            pending =
                (user.stakedLegendaryCountForHolder * accLegendaryPerShare);
        }
        if (user.isAllSquadStaker) {
            pending += accAllSquadPerShare;
        }
        if (user.commonNFTHolder) {
            pending += (user.commonNFTCountForHolder * accCommonNFTPerShare);
        }
        return pending / (REWARD_DECIMAL);
    }
    /**
     * @dev check is all squad user
     */
    function checkAllSquadStaker() private view returns (bool) {
        UserInfo storage user = userInfos[msg.sender];
        uint8[] memory userSquadTokenFeatures = new uint8[](
            SQUAD_FEATURE_NUMBER
        );
        uint8 userSquadTokenFeaturesSum;
        for (uint256 i = 0; i < user.totalNFTCountForHolder; i++) {
            uint256 tokenId = ownedTokens[msg.sender][i];
            if (tokenId == 0) continue; // check if the tokenId is valid
            TokenInfo storage tokenInfo = tokenInfos[
                tokenId
            ];
            if (tokenInfo.isLegendary) continue;
            userSquadTokenFeaturesSum = 0;
            userSquadTokenFeatures[tokenInfo.squadId] = 1;
            for (uint256 j = 0; j < SQUAD_FEATURE_NUMBER; j++) {
                userSquadTokenFeaturesSum =
                    userSquadTokenFeaturesSum +
                    userSquadTokenFeatures[j];
            }
            if (userSquadTokenFeaturesSum == userSquadTokenFeatures.length) {
                return true;
            }
        }
        for (uint8 squadId = 0; squadId < userSquadTokenFeatures.length; squadId++) {
            if (userSquadTokenFeatures[squadId] == 0) {
                return false;
            }
        }
        return true;
    }
}