// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "../nft/HREANFT.sol";
import "../market/IMarketplace.sol";
import "../oracle/Oracle.sol";
import "../data/StructData.sol";
import "./IStaking.sol";

contract Staking is IStaking, Ownable, ERC721Holder {
    address public rewardToken;
    address public nft;
    address public marketplaceContract;
    address public oracleContract;
    bool private reentrancyGuardForStake = false;
    bool private reentrancyGuardForUnstake = false;
    bool private reentrancyGuardForClaim = false;
    uint256 public timeOpenStaking = 1681430400; // 2023-04-14 00:00:00

    // for network stats
    mapping(address => uint256) totalCrewInvesment;
    mapping(address => uint256) teamStakingValue;
    mapping(address => uint256) stakingCommissionEarned;

    // mapping to store staked NFT information
    mapping(address => mapping(uint256 => StructData.StakedNFT)) public stakedNFTs;
    // mapping to nftId to stake
    mapping(uint256 => uint256) public nftStakes;
    // mapping to store reward APY per staking period
    mapping(uint32 => uint16) public nftTierApys;
    // mapping to store commission percent
    mapping(uint8 => uint16) public comissionLevels;
    // mapping to store amount staked to get reweard
    mapping(uint8 => uint32) public amountConditions;
    // mapping to store total stake amount
    mapping(address => uint256) public amountStaked;
    // counter for stake
    using Counters for Counters.Counter;
    Counters.Counter public totalStakesCounter;

    constructor(address _rewardToken, address _nft, address _oracleContract, address _marketplace) {
        rewardToken = _rewardToken;
        nft = _nft;
        marketplaceContract = _marketplace;
        oracleContract = _oracleContract;
        initStakeApy();
        initComissionConditionUsd();
        initCommissionLevel();
    }

    modifier isTimeForStaking() {
        require(
            block.timestamp >= timeOpenStaking,
            "STAKING: THE STAKING PROGRAM HAS NOT YET STARTED."
        );
        _;
    }

    modifier validPeriod(uint256 _period) {
        require(_period == 24, "STAKING: INVALID STAKE PERIOD");
        _;
    }

    modifier validRefCode(uint256 _refCode) {
        require(_refCode >= 999, "STAKING: REF CODE MUST BE GREATER");
        require(
            IMarketplace(marketplaceContract).getAccountForReferralCode(_refCode) != msg.sender,
            "STAKING: CANNOT REF TO YOURSELF"
        );
        _;
    }

    /**
     * @dev set time open staking program
     */
    function setTimeOpenStaking(uint256 _timeOpening) public override onlyOwner {
        require(block.timestamp < _timeOpening, "STAKING: INVALID TIME OPENNING.");
        timeOpenStaking = _timeOpening;
    }

    /**
     * @dev init stake apy for each NFT ID
     */
    function initStakeApy() public onlyOwner {
        nftTierApys[1] = 10800;
        nftTierApys[2] = 10200;
        nftTierApys[3] = 9600;
        nftTierApys[4] = 9000;
        nftTierApys[5] = 8400;
        nftTierApys[6] = 7800;
        nftTierApys[7] = 7200;
        nftTierApys[8] = 6600;
        nftTierApys[9] = 3600;
        nftTierApys[10] = 3600;
    }

    /**
     * @dev init condition(staked amount) to get commision for each level
     */
    function initComissionConditionUsd() public onlyOwner {
        amountConditions[1] = 0;
        amountConditions[2] = 500;
        amountConditions[3] = 1000;
        amountConditions[4] = 2000;
        amountConditions[5] = 3000;
        amountConditions[6] = 3500;
        amountConditions[7] = 4000;
        amountConditions[8] = 4500;
        amountConditions[9] = 5000;
        amountConditions[10] = 8000;
    }

    /**
     * @dev init commission level in the system
     */
    function initCommissionLevel() public onlyOwner {
        comissionLevels[1] = 400;
        comissionLevels[2] = 300;
        comissionLevels[3] = 200;
        comissionLevels[4] = 100;
        comissionLevels[5] = 100;
        comissionLevels[6] = 100;
        comissionLevels[7] = 50;
        comissionLevels[8] = 50;
        comissionLevels[9] = 50;
        comissionLevels[10] = 50;
    }

    /**
     * @dev function to get stake apy for NFT ID
     * @param _nftTier NFT ID
     */
    function getStakeApyForTier(uint32 _nftTier) public view override returns (uint16) {
        return nftTierApys[_nftTier];
    }

    /**
     * @dev function to set stake apy for NFT ID
     * @param _nftTier NFT ID
     * @param _apy apy value want to set
     */
    function setStakeApyForTier(uint32 _nftTier, uint16 _apy) public override onlyOwner {
        require(_apy > 0, "STAKING: INVALID APY PERCENT");
        nftTierApys[_nftTier] = _apy;
    }

    /**
     * @dev function to get commission condition
     * @param _level commission level
     */
    function getComissionCondition(uint8 _level) public view override returns (uint32) {
        return amountConditions[_level];
    }

    /**
     * @dev function to set commission condition
     * @param _level commission level
     * @param _conditionInUsd threshold in USD that the commissioner must achieve
     */
    function setComissionCondition(uint8 _level, uint32 _conditionInUsd) public override onlyOwner {
        amountConditions[_level] = _conditionInUsd;
    }

    /**
     * @dev function to get commission condition
     * @param _level commission level
     */
    function getCommissionPercent(uint8 _level) public view override returns (uint16) {
        return comissionLevels[_level];
    }

    /**
     * @dev function to set commission percent
     * @param _level commission level
     * @param _percent commission percent value want to set (0-100)
     */
    function setCommissionPercent(uint8 _level, uint16 _percent) public override onlyOwner {
        require(_percent > 0, "STAKING: INVALID COMMISION PERCENT");
        comissionLevels[_level] = _percent;
    }

    function getTotalCrewInvesment(address _wallet) public view override returns (uint256) {
        return totalCrewInvesment[_wallet];
    }

    function getTeamStakingValue(address _wallet) public view override returns (uint256) {
        return teamStakingValue[_wallet];
    }

    function getStakingCommissionEarned(address _wallet) public view override returns (uint256) {
        return stakingCommissionEarned[_wallet];
    }

    function updateCrewInvesmentData(
        uint256 _refCode,
        uint256 _totalAmountStakeUsdWithDecimal
    ) internal {
        address payable currentRef;
        address payable nextRef = payable(
            IMarketplace(marketplaceContract).getAccountForReferralCode(_refCode)
        );
        uint8 index = 1;
        while (currentRef != nextRef && nextRef != address(0) && index <= 100) {
            // Update Team Staking Value ( 100 level)
            currentRef = nextRef;
            uint256 currentCrewInvesmentValue = totalCrewInvesment[currentRef];
            totalCrewInvesment[currentRef] = currentCrewInvesmentValue + _totalAmountStakeUsdWithDecimal;
            index++;
            nextRef = payable(
                IMarketplace(marketplaceContract).getReferralAccountForAccount(currentRef)
            );
        }
    }

    function updateTeamStakingValue(
        uint256 _refCode,
        uint256 _totalAmountStakeUsdWithDecimal
    ) internal {
        address payable currentRef;
        address payable nextRef = payable(
            IMarketplace(marketplaceContract).getAccountForReferralCode(_refCode)
        );
        uint8 index = 1;
        while (currentRef != nextRef && nextRef != address(0) && index <= 10) {
            // Update Team Staking Value ( 100 level)
            currentRef = nextRef;
            uint256 currentCrewInvesmentValue = teamStakingValue[currentRef];
            teamStakingValue[currentRef] =
                currentCrewInvesmentValue +
                _totalAmountStakeUsdWithDecimal;
            index++;
            nextRef = payable(
                IMarketplace(marketplaceContract).getReferralAccountForAccount(currentRef)
            );
        }
    }

    /**
     * @dev stake NFT function
     * @param _nftIds list NFT ID want to stake
     * @param _stakingPeriod staking period. Currently only 24 months option.
     * @param _refCode referral code of ref account
     * @param _data addition information. Default is 0x00
     */
    function stake(
        uint256[] memory _nftIds,
        uint256 _stakingPeriod,
        uint256 _refCode,
        bytes memory _data
    ) public override validPeriod(_stakingPeriod) validRefCode(_refCode) isTimeForStaking {
        require(_nftIds.length > 0, "STAKING: INVALID LIST NFT ID");
        require(_nftIds.length <= 20, "STAKING: TOO MANY NFT IN SINGLE STAKE ACTION");
        require(
            IMarketplace(marketplaceContract).checkValidRefCodeAdvance(msg.sender, _refCode),
            "MARKETPLACE: CHEAT REF DETECTED"
        );
        uint16 baseApy = nftTierApys[HREANFT(nft).getNftTier(_nftIds[0])];
        bool isValidNftArray = true;
        uint16 currentApy;
        uint index;
        for (index = 1; index < _nftIds.length; index++) {
            currentApy = nftTierApys[HREANFT(nft).getNftTier(_nftIds[index])];
            if (currentApy != baseApy) {
                isValidNftArray = false;
                break;
            }
        }
        require(isValidNftArray, "STAKING: ALL NFT'S TIERS MUST BE SAME");
        // Executing stake action
        stakeExecute(_nftIds, _stakingPeriod, baseApy, _refCode, _data);
    }

    function stakeExecute(
        uint256[] memory _nftIds,
        uint256 _stakingPeriod,
        uint16 _apy,
        uint256 _refCode,
        bytes memory _data
    ) internal {
        // Prevent re-entrancy
        require(!reentrancyGuardForStake, "STAKING: REENTRANCY DETECTED");
        reentrancyGuardForStake = true;
        // Increase amount stakes
        uint256 nextCounter = nextStakeCounter();
        uint256 effectDecimalCurrency = getEffectDecimalForCurrency();
        // Get total balance in usd staked for user
        uint256 totalAmountStakeUsd = estimateValueUsdForListNft(_nftIds);
        uint256 unlockTimeEstimate = block.timestamp + _stakingPeriod * 30 * 24 * 3600;
        uint256 totalAmountStakeUsdWithDecimal = totalAmountStakeUsd * effectDecimalCurrency;
        // Update struct data
        stakedNFTs[msg.sender][nextCounter].stakerAddress = msg.sender;
        stakedNFTs[msg.sender][nextCounter].startTime = block.timestamp;
        stakedNFTs[msg.sender][nextCounter].unlockTime = unlockTimeEstimate;
        stakedNFTs[msg.sender][nextCounter].totalValueStakeUsd = totalAmountStakeUsd;
        stakedNFTs[msg.sender][nextCounter].nftIds = _nftIds;
        stakedNFTs[msg.sender][nextCounter].apy = _apy;
        stakedNFTs[msg.sender][nextCounter].totalClaimedAmountUsdWithDecimal = 0;
        uint256 rewardUsdWithDecimal = calculateRewardInUsd(
            totalAmountStakeUsdWithDecimal,
            _stakingPeriod,
            _apy
        );
        stakedNFTs[msg.sender][nextCounter].totalRewardAmountUsdWithDecimal = rewardUsdWithDecimal;
        stakedNFTs[msg.sender][nextCounter].isUnstaked = false;
        // Update amount staked for user
        amountStaked[msg.sender] = amountStaked[msg.sender] + totalAmountStakeUsd;
        // Transfer NFT from user to contract
        require(
            HREANFT(nft).isApprovedForAll(msg.sender, address(this)),
            "STAKING: MUST APPROVE FIRST"
        );
        uint index;
        for (index = 0; index < _nftIds.length; index++) {
            require(
                HREANFT(nft).ownerOf(_nftIds[index]) == msg.sender,
                "MARKETPLACE: NOT OWNER THIS NFT ID"
            );
            try HREANFT(nft).safeTransferFrom(msg.sender, address(this), _nftIds[index], _data) {
                // Emit event
                emit Staked(nextCounter, msg.sender, _nftIds[index], unlockTimeEstimate, _apy);
            } catch (bytes memory _error) {
                reentrancyGuardForStake = false;
                emit ErrorLog(_error);
                revert("STAKING: NFT TRANSFER FAILED");
            }
        }
        // Update refferal data & fixed data
        IMarketplace(marketplaceContract).updateReferralData(msg.sender, _refCode);
        // Pay commissions
        address payable currentRef = payable(
            IMarketplace(marketplaceContract).getAccountForReferralCode(_refCode)
        );
        // Update stake value to marketplace contract
        IMarketplace(marketplaceContract).updateStakeValueData(
            msg.sender,
            totalAmountStakeUsdWithDecimal
        );
        // Pay stake commission
        bool paidSuccess = payCommisionMultiLevels(currentRef, totalAmountStakeUsdWithDecimal);
        require(paidSuccess == true, "STAKING: FAILD IN PAY COMMISSION FOR MULTIPLE LEVELS");
        // Update crew investment data
        updateCrewInvesmentData(_refCode, totalAmountStakeUsdWithDecimal);
        // Update team staking data
        updateTeamStakingValue(_refCode, totalAmountStakeUsdWithDecimal);
        // Rollback for next action
        reentrancyGuardForStake = false;
    }

    /**
     * @dev function to pay commissions in 10 level
     * @param _firstRef direct referral account wallet address
     * @param _totalAmountStakeUsdWithDecimal total amount stake in usd with decimal for this stake
     */
    function payCommisionMultiLevels(
        address payable _firstRef,
        uint256 _totalAmountStakeUsdWithDecimal
    ) internal returns (bool) {
        address payable currentRef = _firstRef;
        uint8 index = 1;
        while (currentRef != address(0) && index <= 10) {
            // Check if ref account is eligible to staked amount enough for commission
            bool totalStakeAmount = possibleForCommission(currentRef, index);
            if (totalStakeAmount) {
                // Transfer commission in token amount
                uint256 commisionPercent = getCommissionPercent(index);
                uint256 commissionInUsdWithDecimal = (_totalAmountStakeUsdWithDecimal *
                    commisionPercent) / 10000;
                uint256 totalCommissionInTokenDecimal = Oracle(oracleContract)
                    .convertUsdBalanceDecimalToTokenDecimal(commissionInUsdWithDecimal);
                require(
                    totalCommissionInTokenDecimal > 0,
                    "STAKING: INVALID TOKEN BALANCE COMMISSION"
                );
                require(
                    ERC20(rewardToken).balanceOf(address(this)) >= totalCommissionInTokenDecimal,
                    "STAKING: NOT ENOUGH TOKEN BALANCE TO PAY COMMISSION"
                );
                require(
                    ERC20(rewardToken).transfer(currentRef, totalCommissionInTokenDecimal),
                    "STAKING: UNABLE TO TRANSFER COMMISSION PAYMENT TO RECIPIENT"
                );
                // Update Commission Earned
                uint256 currentComissionEarned = stakingCommissionEarned[currentRef];
                uint256 addingComissionValue = (_totalAmountStakeUsdWithDecimal *
                    commisionPercent) / 10000;
                stakingCommissionEarned[currentRef] = currentComissionEarned + addingComissionValue;
                // emit Event
                emit PayCommission(msg.sender, currentRef, totalCommissionInTokenDecimal);
            }
            index++;
            currentRef = payable(
                IMarketplace(marketplaceContract).getReferralAccountForAccount(currentRef)
            );
        }
        return true;
    }

    /**
     * @dev stake NFT function for only admin
     * @param _nftIds list NFT ID want to stake
     * @param _stakingPeriod staking period. Currently only 24 months option.
     * @param _user user address
     * @param _fromTimestamp timestamp for this stake
     */
    function stakeOnlyAdmin(
        uint256[] memory _nftIds,
        uint256 _stakingPeriod,
        address _user,
        uint256 _fromTimestamp,
        uint256 _totalClaimedWithDecimal
    )
        public
        override
        onlyOwner
    {
        require(_user != address(0), "STAKING: INVALID STAKER");
        uint16 baseApy = nftTierApys[HREANFT(nft).getNftTier(_nftIds[0])];
        bool isValidNftArray = true;
        uint index;
        uint16 currentApy;
        for (index = 1; index < _nftIds.length; index++) {
            currentApy = nftTierApys[HREANFT(nft).getNftTier(_nftIds[index])];
            if (currentApy != baseApy) {
                isValidNftArray = false;
                break;
            }
        }

        require(isValidNftArray, "STAKING: ALL NFT'S TIERS MUST BE SAME");
        // Executing stake action
        stakeExecuteOnlyAdmin(_nftIds, _stakingPeriod, baseApy, _user, _fromTimestamp, _totalClaimedWithDecimal);
    }

    function stakeExecuteOnlyAdmin(
        uint256[] memory _nftIds,
        uint256 _stakingPeriod,
        uint16 _apy,
        address _user,
        uint256 _fromTimestamp,
        uint256 _totalClaimedWithDecimal
    ) internal {
        // Prevent re-entrancy
        require(!reentrancyGuardForStake, "STAKING: REENTRANCY DETECTED");
        reentrancyGuardForStake = true;

        // Increase amount stakes
        uint256 nextCounter = nextStakeCounter();
        uint256 unlockTimeEstimate = _fromTimestamp + _stakingPeriod * 30 * 24 * 3600;
        uint256 totalAmountStakeUsd = estimateValueUsdForListNft(_nftIds);
        uint256 totalAmountStakeUsdWithDecimal = totalAmountStakeUsd * getEffectDecimalForCurrency();
        // Get total balance in usd staked for user
        uint256 rewardUsdWithDecimal = calculateRewardInUsd(
            totalAmountStakeUsdWithDecimal,
            _stakingPeriod,
            _apy
        );
        // Update struct data
        stakedNFTs[_user][nextCounter].stakerAddress = _user;
        stakedNFTs[_user][nextCounter].startTime = _fromTimestamp;
        stakedNFTs[_user][nextCounter].unlockTime = unlockTimeEstimate;
        stakedNFTs[_user][nextCounter].totalValueStakeUsd = totalAmountStakeUsd;
        stakedNFTs[_user][nextCounter].nftIds = _nftIds;
        stakedNFTs[_user][nextCounter].apy = _apy;
        stakedNFTs[_user][nextCounter].totalClaimedAmountUsdWithDecimal = _totalClaimedWithDecimal;
        stakedNFTs[_user][nextCounter].totalRewardAmountUsdWithDecimal = rewardUsdWithDecimal;
        stakedNFTs[_user][nextCounter].isUnstaked = false;
        // Update amount staked for user
        amountStaked[_user] = amountStaked[_user] + totalAmountStakeUsd;

        uint index;
        for (index = 0; index < _nftIds.length; index++) {
            // Emit event
            emit Staked(nextCounter, _user, _nftIds[index], unlockTimeEstimate, _apy);
        }

        address refAddress = IMarketplace(marketplaceContract).getReferralAccountForAccount(_user);
        require(
            refAddress != address(0),
            "MARKETPLACE: USER'S REFERRAL NOT FOUND"
        );

        uint256 _refCode = IMarketplace(marketplaceContract).getReferralCodeForAccount(refAddress);
        bool paidSuccess = updateCommisionMultiLevelsOnly(refAddress, totalAmountStakeUsdWithDecimal);
        require(paidSuccess == true, "STAKING: FAILD IN UPDATE COMMISSION FOR MULTIPLE LEVELS");

        // Update crew investment data
        updateCrewInvesmentData(_refCode, totalAmountStakeUsdWithDecimal);
        // Update team staking data
        updateTeamStakingValue(_refCode, totalAmountStakeUsdWithDecimal);

        // Rollback for next action
        reentrancyGuardForStake = false;
    }

    /**
     * @dev function to update commissions in 10 level
     * @param _firstRef direct referral account wallet address
     * @param _totalAmountStakeUsdWithDecimal total amount stake in usd with decimal for this stake
     */
    function updateCommisionMultiLevelsOnly(
        address _firstRef,
        uint256 _totalAmountStakeUsdWithDecimal
    ) internal returns (bool) {
        address currentRef = _firstRef;
        uint8 index = 1;
        while (currentRef != address(0) && index <= 10) {
            // Check if ref account is eligible to staked amount enough for commission
            bool totalStakeAmount = possibleForCommission(currentRef, index);
            if (totalStakeAmount) {
                // Transfer commission in token amount
                uint256 commisionPercent = getCommissionPercent(index);
                uint256 commissionInUsdWithDecimal = (_totalAmountStakeUsdWithDecimal * commisionPercent) / 10000;
                uint256 totalCommissionInTokenDecimal = Oracle(oracleContract)
                    .convertUsdBalanceDecimalToTokenDecimal(commissionInUsdWithDecimal);
                require(
                    totalCommissionInTokenDecimal > 0,
                    "STAKING: INVALID TOKEN BALANCE COMMISSION"
                );
                // Update Commission Earned
                uint256 currentComissionEarned = stakingCommissionEarned[currentRef];
                uint256 addingComissionValue = (_totalAmountStakeUsdWithDecimal *
                    commisionPercent) / 10000;
                stakingCommissionEarned[currentRef] = currentComissionEarned + addingComissionValue;
            }
            index++;
            currentRef = IMarketplace(marketplaceContract).getReferralAccountForAccount(currentRef);
        }
        return true;
    }

    /**
     * @dev unstake NFT function
     * @param _stakeId stake counter index
     * @param _data addition information. Default is 0x00
     */
    function unstake(uint256 _stakeId, bytes memory _data) public override {
        // Prevent re-entrancy
        require(!reentrancyGuardForUnstake, "STAKING: REENTRANCY DETECTED");
        reentrancyGuardForUnstake = true;
        require(possibleUnstake(msg.sender, _stakeId) == true, "STAKING: STILL IN STAKING PERIOD");
        require(
            stakedNFTs[msg.sender][_stakeId].stakerAddress == msg.sender,
            "STAKING: NOT OWNER OF NFT STAKED"
        );
        address staker = stakedNFTs[msg.sender][_stakeId].stakerAddress;
        uint256[] memory nftIds = stakedNFTs[msg.sender][_stakeId].nftIds;
        // Set staking was unstaked for preventing Reentrancy
        stakedNFTs[msg.sender][_stakeId].isUnstaked = true;
        // Update total amount staked of user
        uint256 amountStakedUser = stakedNFTs[msg.sender][_stakeId].totalValueStakeUsd;
        amountStaked[msg.sender] = amountStaked[msg.sender] - amountStakedUser;
        // Transfer NFT from contract to claimer
        for (uint index = 0; index < nftIds.length; index++) {
            try HREANFT(nft).safeTransferFrom(address(this), staker, nftIds[index], _data) {
                // Emit event
                emit Unstaked(_stakeId, staker, nftIds[index]);
            } catch (bytes memory _error) {
                reentrancyGuardForUnstake = false;
                emit ErrorLog(_error);
                revert("STAKING: UNSTAKE FAILED");
            }
        }
        // Calculate & send reward in token
        uint256 tokenAmountWithDecimal = rewardUnstakeInTokenWithDecimal(msg.sender, _stakeId);
        require(
            ERC20(rewardToken).balanceOf(address(this)) >= tokenAmountWithDecimal,
            "STAKING: NOT ENOUGH TOKEN BALANCE TO PAY UNSTAKE REWARD"
        );
        require(
            ERC20(rewardToken).transfer(staker, tokenAmountWithDecimal),
            "STAKING: UNABLE TO TRANSFER COMMISSION PAYMENT TO RECIPIENT"
        );
        // Set total claimed full
        stakedNFTs[msg.sender][_stakeId].totalClaimedAmountUsdWithDecimal = stakedNFTs[msg.sender][
            _stakeId
        ].totalRewardAmountUsdWithDecimal;
        // Rollback for next action
        reentrancyGuardForUnstake = false;
    }

    /**
     * @dev claim reward function
     * @param _stakeId stake counter index
     */
    function claim(uint256 _stakeId) public override {
        // Prevent re-entrancy
        require(!reentrancyGuardForClaim, "STAKING: REENTRANCY DETECTED");
        reentrancyGuardForClaim = true;
        StructData.StakedNFT memory stakeInfo = stakedNFTs[msg.sender][_stakeId];
        require(stakeInfo.unlockTime > 0, "STAKING: ONLY CLAIM YOUR OWN STAKE");
        require(block.timestamp > stakeInfo.startTime, "STAKING: WRONG TIME TO CLAIM");
        require(!stakeInfo.isUnstaked, "STAKING: ALREADY UNSTAKED");
        uint256 claimableRewardInUsdWithDecimal = claimableForStakeInUsdWithDecimal(
            msg.sender,
            _stakeId
        );
        if (claimableRewardInUsdWithDecimal > 0) {
            stakedNFTs[msg.sender][_stakeId]
                .totalClaimedAmountUsdWithDecimal += claimableRewardInUsdWithDecimal;
            uint256 claimableRewardInTokenWithDecimal = Oracle(oracleContract)
                .convertUsdBalanceDecimalToTokenDecimal(claimableRewardInUsdWithDecimal);
            require(
                ERC20(rewardToken).balanceOf(address(this)) >= claimableRewardInTokenWithDecimal,
                "STAKING: NOT ENOUGH TOKEN BALANCE TO PAY REWARD"
            );
            require(
                ERC20(rewardToken).transfer(msg.sender, claimableRewardInTokenWithDecimal),
                "STAKING: UNABLE TO TRANSFER COMMISSION PAYMENT TO RECIPIENT"
            );
            // Rollback for next action
            reentrancyGuardForClaim = false;
            emit Claimed(_stakeId, msg.sender, claimableRewardInTokenWithDecimal);
        }
    }

    /**
     * @dev claim reward function
     * @param _stakeIds stake counter index
     */
    function claimAll(uint256[] memory _stakeIds) public override {
        require(_stakeIds.length > 0, "STAKING: INVALID STAKE LIST");
        for (uint i = 0; i < _stakeIds.length; i++) {
            claim(_stakeIds[i]);
        }
    }

    /**
     * @dev check unstake requesting is valid or not(still in locking)
     * @param _user user wallet address
     * @param _stakeId stake counter index
     */
    function possibleUnstake(address _user, uint256 _stakeId) public view returns (bool) {
        bool resultCheck = false;
        uint256 unlockTimestamp = stakedNFTs[_user][_stakeId].unlockTime;
        if (block.timestamp >= unlockTimestamp) {
            resultCheck = true;
        }
        return resultCheck;
    }

    /**
     * @dev estimate value in USD for a list of NFT
     * @param _nftIds user wallet address
     */
    function estimateValueUsdForListNft(uint256[] memory _nftIds) public view returns (uint256) {
        uint256 totalAmountStakeUsd = 0;
        for (uint index = 0; index < _nftIds.length; index++) {
            uint256 priceNftUsd = HREANFT(nft).getNftPriceUsd(_nftIds[index]);
            totalAmountStakeUsd += priceNftUsd;
        }
        return totalAmountStakeUsd;
    }

    /**
     * @dev function to calculate reward in USD based on staking time and period
     * @param _totalValueStakeUsd total value of stake (USD)
     * @param _stakingPeriod stake period
     * @param _apy apy
     */
    function calculateRewardInUsd(
        uint256 _totalValueStakeUsd,
        uint256 _stakingPeriod,
        uint16 _apy
    ) public pure override returns (uint256) {
        // Get years
        uint256 yearAmount = _stakingPeriod / 12;
        // Calculate to reward in token
        uint256 rewardInUsd = (_totalValueStakeUsd * _apy * yearAmount) / 10000;
        return rewardInUsd;
    }

    /**
     * @dev function to calculate claimable reward in Usd based on staking time and period
     * @param _staker staker wallet address
     * @param _stakeId stake counter index
     */
    function claimableForStakeInUsdWithDecimal(
        address _staker,
        uint256 _stakeId
    ) public view override returns (uint256) {
        StructData.StakedNFT memory stakeInfo = stakedNFTs[_staker][_stakeId];
        uint256 accumulateTimeStaked = block.timestamp - stakeInfo.startTime;
        uint256 totalDurationStaked = stakeInfo.unlockTime - stakeInfo.startTime;
        require(accumulateTimeStaked > 0, "STAKING: NOT TIME TO CLAIM");
        if (accumulateTimeStaked > totalDurationStaked) {
            accumulateTimeStaked = totalDurationStaked;
        }
        uint256 accumulateRewardInUsdWithDecimal = (stakeInfo.totalRewardAmountUsdWithDecimal *
            accumulateTimeStaked) / totalDurationStaked;
        uint256 remainRewardInUsd = accumulateRewardInUsdWithDecimal -
            stakeInfo.totalClaimedAmountUsdWithDecimal;
        return remainRewardInUsd;
    }

    /**
     * @dev function to calculate reward in Token based on staking time and period
     * @param _staker staker wallet address
     * @param _stakeId stake counter index
     */
    function rewardUnstakeInTokenWithDecimal(
        address _staker,
        uint256 _stakeId
    ) public view override returns (uint256) {
        uint256 rewardInUsdWithDecimal = stakedNFTs[_staker][_stakeId]
            .totalRewardAmountUsdWithDecimal -
            stakedNFTs[_staker][_stakeId].totalClaimedAmountUsdWithDecimal;
        uint256 rewardInTokenWithDecimal = Oracle(oracleContract)
            .convertUsdBalanceDecimalToTokenDecimal(rewardInUsdWithDecimal);
        return rewardInTokenWithDecimal;
    }

    /**
     * @dev function to get decimal multiple
     */
    function getEffectDecimalForCurrency() public view override returns (uint256) {
        address currencyAddress = IMarketplace(marketplaceContract).getCurrencyAddress();
        uint256 decimalCurrency = ERC20(currencyAddress).decimals();
        return 10 ** decimalCurrency;
    }

    /**
     * @dev function to get all stake information from an account & stake index
     * @param _staker staker wallet address
     * @param _stakeId stake index
     */
    function getDetailOfStake(
        address _staker,
        uint256 _stakeId
    ) public view returns (StructData.StakedNFT memory) {
        StructData.StakedNFT memory stakeInfo = stakedNFTs[_staker][_stakeId];
        return stakeInfo;
    }

    /**
     * @dev function to get total stake amount in usd
     * @param _staker staker wallet address
     */
    function getTotalStakeAmountUSD(address _staker) public view returns (uint256) {
        return amountStaked[_staker];
    }

    /**
     * @dev function to check the staked amount enough to get commission
     * @param _staker staker wallet address
     * @param _level commission level need to check condition
     */
    function possibleForCommission(address _staker, uint8 _level) public view returns (bool) {
        uint256 totalStakeAmount = getTotalStakeAmountUSD((_staker));
        uint32 conditionAmount = amountConditions[_level];
        bool resultCheck = false;
        if (totalStakeAmount >= conditionAmount) {
            resultCheck = true;
        }
        return resultCheck;
    }

    /**
     * @dev get & set stake counter
     */
    function nextStakeCounter() internal returns (uint256 _id) {
        totalStakesCounter.increment();
        return totalStakesCounter.current();
    }

    /**
     * @dev admin update apy
     * @param _user staker wallet address
     * @param _stakeIds list stakeId
     * @param _newApys list new-apy
     */
    function updateStakeApyEmergency(
        address _user,
        uint256[] memory _stakeIds,
        uint16[] memory _newApys
    ) public onlyOwner {
        require(_user != address(0), "STAKING: INVALID STAKER");
        require(_stakeIds.length == _newApys.length, "STAKING: ARRAYS MUST BE SAME LENGTH");
        uint256 totalAmountStakeUsd = 0;
        uint256 totalAmountStakeUsdWithDecimal = 0;
        uint256 rewardUsdWithDecimal = 0;
        uint256 decimalForCurrency = getEffectDecimalForCurrency();
        for (uint i = 0; i < _stakeIds.length; i++) {
            // Update struct data
            bool isUnstaked = stakedNFTs[_user][_stakeIds[i]].isUnstaked;
            require(!isUnstaked, "STAKING: CANNOT UPDATE FOR UNSTAKED ID");
            totalAmountStakeUsd = stakedNFTs[_user][_stakeIds[i]].totalValueStakeUsd;
            require(totalAmountStakeUsd > 0, "STAKING: INVALID STAKER ID");
            totalAmountStakeUsdWithDecimal = totalAmountStakeUsd * decimalForCurrency;
            require(_newApys[i] > 0, "STAKING: APY MUST BE A POSITIVE NUMBER");
            rewardUsdWithDecimal = calculateRewardInUsd(
                totalAmountStakeUsdWithDecimal,
                24, //only 24 months option
                _newApys[i]
            );
            stakedNFTs[_user][_stakeIds[i]].apy = _newApys[i];
            stakedNFTs[_user][_stakeIds[i]].totalRewardAmountUsdWithDecimal = rewardUsdWithDecimal;
        }
    }

    /**
     * @dev admin remove stake in emergency case
     * @param _user staker wallet address
     * @param _stakeIds list stakeId
     */
    function removeStakeEmergency(address _user, uint256[] memory _stakeIds) public onlyOwner {
        require(_user != address(0), "STAKING: INVALID STAKER");
        require(_stakeIds.length > 0, "STAKING: ARRAYS MUST NOT BE EMPTY");
        for (uint i = 0; i < _stakeIds.length; i++) {
            // Update struct data
            bool isUnstaked = stakedNFTs[_user][_stakeIds[i]].isUnstaked;
            require(!isUnstaked, "STAKING: CANNOT UPDATE FOR UNSTAKED ID");
            address staker = stakedNFTs[_user][_stakeIds[i]].stakerAddress;
            require(staker == _user, "STAKING: MISMATCH INFORMATION");
            //delete
            delete stakedNFTs[_user][_stakeIds[i]];
        }
    }

    function forceUpdateTotalCrewInvesment(address _user, uint256 _value) public override onlyOwner {
        totalCrewInvesment[_user] = _value;
    }

    function forceUpdateTeamStakingValue(address _user, uint256 _value) public override onlyOwner {
        teamStakingValue[_user] = _value;
    }

    function forceUpdateStakingCommissionEarned(address _user, uint256 _value) public override onlyOwner {
        stakingCommissionEarned[_user] = _value;
    }

    /**
     * @dev function to deposit ERC20 token as reward
     * @param _amount amount token want to deposit to contract
     */
    function depositToken(uint256 _amount) public payable override {
        require(_amount > 0, "STAKING: INVALID AMOUNT");
        require(
            ERC20(rewardToken).allowance(msg.sender, address(this)) >= _amount,
            "STAKING: MUST APPROVE FIRST"
        );
        require(
            ERC20(rewardToken).transferFrom(msg.sender, address(this), _amount),
            "STAKING: CANNOT DEPOSIT"
        );
    }

    /**
     * @dev function to withdraw all reward tokens
     */
    function withdrawTokenEmergency(uint256 _amount) public override onlyOwner {
        require(_amount > 0, "STAKING: INVALID AMOUNT");
        require(
            ERC20(rewardToken).balanceOf(address(this)) >= _amount,
            "STAKING: TOKEN BALANCE NOT ENOUGH"
        );
        require(ERC20(rewardToken).transfer(msg.sender, _amount), "STAKING: CANNOT WITHDRAW TOKEN");
    }

    /**
     * @dev withdraw some currency balance from contract to owner account
     */
    function withdrawCurrencyEmergency(
        address _currency,
        uint256 _amount
    ) public override onlyOwner {
        require(_amount > 0, "STAKING: INVALID AMOUNT");
        require(
            ERC20(_currency).balanceOf(address(this)) >= _amount,
            "STAKING: CURRENCY BALANCE NOT ENOUGH"
        );
        require(
            ERC20(_currency).transfer(msg.sender, _amount),
            "STAKING: CANNOT WITHDRAW CURRENCY"
        );
    }

    /**
     * @dev transfer a NFT from this contract to an account, only owner
     */
    function tranferNftEmergency(address _receiver, uint256 _nftId) public override onlyOwner {
        require(HREANFT(nft).ownerOf(_nftId) == address(this), "STAKING: NOT OWNER OF THIS NFT");
        try HREANFT(nft).safeTransferFrom(address(this), _receiver, _nftId, "") {} catch (
            bytes memory _error
        ) {
            emit ErrorLog(_error);
            revert("STAKING: NFT TRANSFER FAILED");
        }
    }

    /**
     * @dev transfer a list of NFT from this contract to a list of account, only owner
     */
    function tranferMultiNftsEmergency(
        address[] memory _receivers,
        uint256[] memory _nftIds
    ) public override onlyOwner {
        require(_receivers.length == _nftIds.length, "MARKETPLACE: MUST BE SAME SIZE");
        for (uint index = 0; index < _nftIds.length; index++) {
            tranferNftEmergency(_receivers[index], _nftIds[index]);
        }
    }

    /**
     * @dev set oracle address
     */
    function setOracleAddress(address _oracleAddress) public override onlyOwner {
        require(_oracleAddress != address(0), "MARKETPLACE: INVALID ORACLE ADDRESS");
        oracleContract = _oracleAddress;
    }

    /**
     * @dev possible to receive any ERC20 tokens
     */
    receive() external payable {}
}