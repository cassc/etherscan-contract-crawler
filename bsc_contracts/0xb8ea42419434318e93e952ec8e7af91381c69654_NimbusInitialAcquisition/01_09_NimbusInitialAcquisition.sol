// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./NimbusInitialAcquisitionStorage.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract NimbusInitialAcquisition is Initializable, NimbusInitialAcquisitionStorage {
    address public target;

    mapping(address => uint) public unclaimedSponsorBonusNew;
    mapping(address => uint) public unclaimedSponsorBonusEquivalentNew;

    mapping(uint => bool) public isNewSponsorNft;

    IPancakeRouter public pancakeSwapRouter;

    uint256 public cashbackDisableTime;

    function initialize(address systemToken, address nftVestingAddress, address nftSmartLpAddress, address router, address nbuWbnb) public initializer {
        __Pausable_init();
        __Ownable_init();
        require(AddressUpgradeable.isContract(systemToken), "systemToken is not a contract");
        require(AddressUpgradeable.isContract(nftVestingAddress), "nftVestingAddress is not a contract");
        require(AddressUpgradeable.isContract(nftSmartLpAddress), "nftSmartLPAddress is not a contract");
        require(AddressUpgradeable.isContract(router), "router is not a contract");
        require(AddressUpgradeable.isContract(nbuWbnb), "nbuWbnb is not a contract");
        SYSTEM_TOKEN = IERC20Upgradeable(systemToken);
        nftVesting = IVestingNFT(nftVestingAddress);
        nftCashback = ISmartLP(nftSmartLpAddress);
        NBU_WBNB = nbuWbnb;
        sponsorBonus = 10;
        cashbackBonus = 12;
        swapRouter = INimbusRouter(router);
        recipient = address(this);
        allowAccuralMarketingReward = true;

        swapTokenAmountForCashbackBonusThreshold = 400 ether;
        swapTokenAmountForSponsorBonusThreshold = 5000 ether;

        vestingRedeemingAllowed = false;
    }

    receive() external payable {
    }

    function buyExactSystemTokenForTokensAndRegister(address token, uint systemTokenAmount, address systemTokenRecipient, uint stakingPoolId, uint sponsorId) external whenNotPaused {
        require(sponsorId >= 1000000001, "Sponsor id must be grater than 1000000000");
        referralProgramMarketing.registerUser(systemTokenRecipient, sponsorId);
        buyExactSystemTokenForTokens(token, systemTokenAmount, systemTokenRecipient, stakingPoolId);
    }

    function buyExactSystemTokenForTokensAndRegister(address token, uint systemTokenAmount, address systemTokenRecipient, uint stakingPoolId) external whenNotPaused {
        referralProgramMarketing.registerUser(systemTokenRecipient, 1000000001);
        buyExactSystemTokenForTokens(token, systemTokenAmount, systemTokenRecipient, stakingPoolId);
    }

    function buyExactSystemTokenForBnbAndRegister(uint systemTokenAmount, address systemTokenRecipient, uint stakingPoolId, uint sponsorId) payable external whenNotPaused {
        require(sponsorId >= 1000000001, "Sponsor id must be grater than 1000000000");
        referralProgramMarketing.registerUser(systemTokenRecipient, sponsorId);
        buyExactSystemTokenForBnb(systemTokenAmount, systemTokenRecipient, stakingPoolId);
    }

    function buyExactSystemTokenForBnbAndRegister(uint systemTokenAmount, address systemTokenRecipient, uint stakingPoolId) payable external whenNotPaused {
        referralProgramMarketing.registerUser(msg.sender, 1000000001);
        buyExactSystemTokenForBnb(systemTokenAmount, systemTokenRecipient, stakingPoolId);
    }

    function buySystemTokenForExactBnbAndRegister(address systemTokenRecipient, uint stakingPoolId, uint sponsorId) payable external whenNotPaused {
        require(sponsorId >= 1000000001, "Sponsor id must be grater than 1000000000");
        referralProgramMarketing.registerUser(systemTokenRecipient, sponsorId);
        buySystemTokenForExactBnb(systemTokenRecipient, stakingPoolId);
    }

    function buySystemTokenForExactBnbAndRegister(address systemTokenRecipient, uint stakingPoolId) payable external whenNotPaused {
        referralProgramMarketing.registerUser(systemTokenRecipient, 1000000001);
        buySystemTokenForExactBnb(systemTokenRecipient, stakingPoolId);
    }

    function buySystemTokenForExactTokensAndRegister(address token, uint tokenAmount, address systemTokenRecipient, uint stakingPoolId, uint sponsorId) external whenNotPaused {
        require(sponsorId >= 1000000001, "Sponsor id must be grater than 1000000000");
        referralProgramMarketing.registerUserBySponsorId(systemTokenRecipient, sponsorId, 0);
        buySystemTokenForExactTokens(token, tokenAmount, systemTokenRecipient, stakingPoolId);
    }

    function buySystemTokenForExactTokensAndRegister(address token, uint tokenAmount, address systemTokenRecipient, uint stakingPoolId) external whenNotPaused {
        referralProgramMarketing.registerUser(systemTokenRecipient, 1000000001);
        buySystemTokenForExactTokens(token, tokenAmount, systemTokenRecipient, stakingPoolId);
    }
    
    function buyExactSystemTokenForTokens(address token, uint systemTokenAmount, address systemTokenRecipient, uint stakingPoolId) public whenNotPaused {
        require(address(stakingPools[stakingPoolId]) != address(0), "No staking pool with provided id");
        require(allowedTokens[token], "Not allowed token");
        require(referralProgram.userIdByAddress(msg.sender) > 0, "Not part of referral program");
        uint tokenAmount = getTokenAmountForSystemToken(token, systemTokenAmount);
        _buySystemToken(token, tokenAmount, systemTokenAmount, systemTokenRecipient, stakingPoolId);
    }

    function buySystemTokenForExactTokens(address token, uint tokenAmount, address systemTokenRecipient, uint stakingPoolId) public whenNotPaused {
        require(address(stakingPools[stakingPoolId]) != address(0), "No staking pool with provided id");
        require(allowedTokens[token], "Not allowed token");
        require(referralProgram.userIdByAddress(msg.sender) > 0, "Not part of referral program");
        uint systemTokenAmount = getSystemTokenAmountForToken(token, tokenAmount);
        _buySystemToken(token, tokenAmount, systemTokenAmount, systemTokenRecipient, stakingPoolId);
    }

    function buySystemTokenForExactBnb(address systemTokenRecipient, uint stakingPoolId) payable public whenNotPaused {
        require(address(stakingPools[stakingPoolId]) != address(0), "No staking pool with provided id");
        require(allowedTokens[NBU_WBNB], "Not allowed purchase for BNB");
        require(referralProgram.userIdByAddress(msg.sender) > 0, "Not part of referral program");
        uint systemTokenAmount = getSystemTokenAmountForBnb(msg.value);
        _buySystemToken(NBU_WBNB, msg.value, systemTokenAmount, systemTokenRecipient, stakingPoolId);
    }

    function buyExactSystemTokenForBnb(uint systemTokenAmount, address systemTokenRecipient, uint stakingPoolId) payable public whenNotPaused {
        require(address(stakingPools[stakingPoolId]) != address(0), "No staking pool with provided id");
        require(allowedTokens[NBU_WBNB], "Not allowed purchase for BNB");
        require(referralProgram.userIdByAddress(msg.sender) > 0, "Not part of referral program");
        uint systemTokenAmountMax = getSystemTokenAmountForBnb(msg.value);
        require(systemTokenAmountMax >= systemTokenAmount, "Not enough BNB");
        uint bnbAmount = systemTokenAmountMax == systemTokenAmount ? msg.value : getBnbAmountForSystemToken(systemTokenAmount);
        _buySystemToken(NBU_WBNB, bnbAmount, systemTokenAmount, systemTokenRecipient, stakingPoolId);
        // refund dust bnb, if any
        if (systemTokenAmountMax > systemTokenAmount) TransferHelper.safeTransferBNB(msg.sender, msg.value - bnbAmount);
    }

    function claimSponsorBonuses(address user, bool isNew) public {
        (bool isAllowed,bool isAllowedNew,,) = isAllowedToRedeemVestingNFT(user);
        require(isAllowed && !isNew || isAllowedNew && isNew, "Not enough bonuses for claim");
        require(msg.sender == user, "Can mint only own Vesting NFT");
        // Mint Vesting NFT
        uint256 nftVestingAmount;
        if (isNew) {
            nftVestingAmount = unclaimedSponsorBonusEquivalentNew[user] * sponsorBonus / 100;
            unclaimedSponsorBonusEquivalentNew[user] = 0;
            unclaimedSponsorBonusNew[user] = 0;
        } else {
            nftVestingAmount = unclaimedSponsorBonusEquivalent[user] * sponsorBonus / 100;
            unclaimedSponsorBonusEquivalent[user] = 0;
            unclaimedSponsorBonus[user] = 0;
        }

        nftVesting.safeMint(user, nftVestingUri, nftVestingAmount, swapToken);
        uint256 nftTokenId = nftVesting.lastTokenId();

        isNewSponsorNft[nftTokenId] = isNew;

        emit ProcessSponsorBonus(user, address(nftVesting), nftTokenId, nftVestingAmount, block.timestamp);
    }

    function availableInitialSupply() external view returns (uint) {
        return SYSTEM_TOKEN.balanceOf(address(this));
    }

    function getSystemTokenAmountForToken(address token, uint tokenAmount) public view returns (uint) { 
        return getTokenAmountForToken(token, address(SYSTEM_TOKEN), tokenAmount, true);
    }

    function getSystemTokenAmountForBnb(uint bnbAmount) public view returns (uint) { 
        return getSystemTokenAmountForToken(NBU_WBNB, bnbAmount); 
    }

    function getTokenAmountForToken(address tokenSrc, address tokenDest, uint tokenAmount, bool isOut) public view returns (uint) { 
        if (tokenSrc == tokenDest) return tokenAmount;
        if (usePriceFeeds && address(priceFeed) != address(0)) {
            (uint256 rate, uint256 precision) = priceFeed.queryRate(tokenSrc, tokenDest);
            return isOut ? tokenAmount * rate / precision : tokenAmount * precision / rate;
        } 
        address[] memory path = new address[](2);
        path[0] = tokenSrc;
        path[1] = tokenDest;
        return isOut ? swapRouter.getAmountsOut(tokenAmount, path)[1] : swapRouter.getAmountsIn(tokenAmount, path)[0];
    }

    function getTokenAmountForSystemToken(address token, uint systemTokenAmount) public view returns (uint) { 
        return getTokenAmountForToken(token, address(SYSTEM_TOKEN), systemTokenAmount, false);
    }

    function getBnbAmountForSystemToken(uint systemTokenAmount) public view returns (uint) { 
        return getTokenAmountForSystemToken(NBU_WBNB, systemTokenAmount);
    }

    function currentBalance(address token) external view returns (uint) { 
        return IERC20Upgradeable(token).balanceOf(address(this));
    }

    function isAllowedToRedeemVestingNFT(address user) public view returns (bool isAllowed, bool isAllowedNew, uint256 unclaimedBonus, uint256 unclaimedBonusNew) { 
        unclaimedBonus = unclaimedSponsorBonusEquivalent[user];
        unclaimedBonusNew = unclaimedSponsorBonusEquivalentNew[user];
        isAllowed = unclaimedBonus > 0 && unclaimedBonus >= swapTokenAmountForSponsorBonusThreshold;
        isAllowedNew = unclaimedBonusNew > 0 && unclaimedBonusNew >= swapTokenAmountForSponsorBonusThreshold;
    }

    function _buySystemToken(address token, uint tokenAmount, uint systemTokenAmount, address systemTokenRecipient, uint stakingPoolId) private {
        stakingPools[stakingPoolId].stakeFor(systemTokenAmount, systemTokenRecipient);
        uint swapTokenAmount = getTokenAmountForToken(token, swapToken, tokenAmount, true);
        bool isFirstStaking = address(referralProgramMarketing) != address(0) && referralProgramMarketing.userPersonalTurnover(systemTokenRecipient) == 0;
        bool isFirstAP4Staking = userPurchases[systemTokenRecipient] == 0;
        if ((cashbackDisableTime == 0 || block.timestamp < cashbackDisableTime) && cashbackBonus > 0 && swapTokenAmount >= swapTokenAmountForCashbackBonusThreshold && isFirstStaking) {
            uint bonusGiveSystemTokenPurchaseToken = tokenAmount * cashbackBonus / 100;
            uint bonusGiveSystemToken = getTokenAmountForToken(token, NBU_WBNB, bonusGiveSystemTokenPurchaseToken, true); // BUSD->BNB
            // NFT Smart LP
            if (nftCashback.WBNB() != NBU_WBNB) {
                IWBNB(NBU_WBNB).withdraw(bonusGiveSystemToken);
                (bool success,) = address(nftCashback).call{value: bonusGiveSystemToken}(abi.encodeWithSignature("buySmartLPforBNB()"));
                require(success, "SmartLP::nftCashback purchase failed");
            } else {
                if(IERC20Upgradeable(NBU_WBNB).allowance(address(this), address(nftCashback)) < bonusGiveSystemToken) {
                    IERC20Upgradeable(NBU_WBNB).approve(address(nftCashback), type(uint256).max);
                }
                nftCashback.buySmartLPforWBNB(bonusGiveSystemToken);
            }
            
            uint256 nftTokenId = nftCashback.tokenCount();
            nftCashback.safeTransferFrom(address(this), systemTokenRecipient, nftTokenId);
            emit ProcessCashbackBonus(systemTokenRecipient, address(nftCashback), nftTokenId, token, bonusGiveSystemTokenPurchaseToken, block.timestamp);
        }
        userPurchases[systemTokenRecipient] += systemTokenAmount;
        userPurchasesEquivalent[systemTokenRecipient] += swapTokenAmount;

        if(allowAccuralMarketingReward && address(referralProgramMarketing) != address(0)) {
            referralProgramMarketing.updateReferralProfitAmount(systemTokenRecipient, swapTokenAmount);
        }
        emit BuySystemTokenForToken(token, stakingPoolId, tokenAmount, systemTokenAmount, swapTokenAmount, systemTokenRecipient);
        
        uint256 finalTokenAmount = tokenAmount;
        if (isFirstAP4Staking) {
            _processSponsor(systemTokenRecipient, systemTokenAmount, swapTokenAmount);
            if (token != NBU_WBNB) finalTokenAmount -= swapTokenAmount * sponsorBonus / 100;
            else {
                address[] memory path = new address[](2);
                path[0] = pancakeSwapRouter.WETH();
                path[1] = address(swapToken);
                (uint[] memory amountsBnbTokenSwap) = pancakeSwapRouter.swapETHForExactTokens{value: msg.value }(swapTokenAmount * sponsorBonus / 100, path, address(this), block.timestamp + 1200);
                finalTokenAmount -= amountsBnbTokenSwap[0];
            }
        }
        if (token != NBU_WBNB) {
            if (finalTokenAmount != tokenAmount) {
                TransferHelper.safeTransferFrom(token, msg.sender, address(this), tokenAmount);
                TransferHelper.safeTransfer(token, recipient, finalTokenAmount);
            } else TransferHelper.safeTransferFrom(token, msg.sender, recipient, tokenAmount);
        }
        else {
            IWBNB(NBU_WBNB).deposit{value: finalTokenAmount}();
        }
    }

    function _processSponsor(address systemTokenRecipient, uint systemTokenAmount, uint swapTokenAmount) private {
        address sponsorAddress = getUserSponsorAddress(systemTokenRecipient);
        if (sponsorAddress != address(0)) {
            unclaimedSponsorBonusNew[sponsorAddress] += systemTokenAmount;
            unclaimedSponsorBonusEquivalentNew[sponsorAddress] += swapTokenAmount;
            emit AddUnclaimedSponsorBonus(sponsorAddress, systemTokenRecipient, systemTokenAmount, swapTokenAmount);
        }
    }

    function getUserSponsorAddress(address user) public view returns (address) {
        if (address(referralProgram) == address(0)) {
            return address(0);
        } else {
            return referralProgram.userSponsorAddressByAddress(user);
        } 
    }

    function getAllNFTRewards() public {
        address user = msg.sender;
        uint[] memory nftCashbackIds = nftCashback.getUserTokens(user);
        uint[] memory nftSmartStakerIds = nftSmartStaker.getUserTokens(user);
        require(nftCashbackIds.length + nftSmartStakerIds.length > 0, "No NFT with rewards");
        for (uint256 index = 0; index < nftCashbackIds.length; index++) nftCashback.withdrawUserRewards(nftCashbackIds[index]);
        for (uint256 index = 0; index < nftSmartStakerIds.length; index++) nftSmartStaker.withdrawReward(nftSmartStakerIds[index]);
    }

    function getAllStakingRewards(uint256[] memory stakingIds) public {
        require(stakingIds.length > 0, "No staking IDs");
        address user = msg.sender;
        for (uint256 index = 0; index < stakingIds.length; index++) {
            if (address(stakingPools[stakingIds[index]]) != address(0))
            INimbusStakingPool(stakingPools[stakingIds[index]]).getRewardForUser(user);
        }
    }

    function redeemVestingNFT(uint256 tokenId) public {
        require(vestingRedeemingAllowed, "Not allowed to redeem yet");
        require(nftVesting.ownerOf(tokenId) == msg.sender, "Not owner of vesting NFT");
        IVestingNFT.Denomination memory denomination = nftVesting.denominations(tokenId);
        if (isNewSponsorNft[tokenId]) nftVesting.safeTransferFrom(msg.sender, address(this), tokenId);
        else nftVesting.burn(tokenId);
        TransferHelper.safeTransfer(denomination.token, msg.sender, denomination.value);
        emit VestingNFTRedeemed(address(nftVesting), tokenId, msg.sender, denomination.token, denomination.value);
    }

    //Admin functions
    function rescue(address payable to, uint256 amount) external onlyOwner {
        require(to != address(0), "Can't be zero address");
        require(amount > 0, "Should be greater than 0");
        TransferHelper.safeTransferBNB(to, amount);
        emit Rescue(to, amount);
    }

    function rescue(address to, address token, uint256 amount) external onlyOwner {
        require(to != address(0), "Can't be zero address");
        require(amount > 0, "Should be greater than 0");
        TransferHelper.safeTransfer(token, to, amount);
        emit RescueToken(token, to, amount);
    }

    function importSponsorBonuses(address user, uint amount, bool isEquivalent, bool isNew, bool addToExistent) external onlyOwner {
        _importSponsorBonuses(user, amount, isEquivalent, isNew, addToExistent);
    }

    function importSponsorBonuses(address[] memory users, uint[] memory amounts, bool isEquivalent, bool isNew, bool addToExistent) external onlyOwner {
        require(users.length == amounts.length, "Wrong lengths");

        for (uint256 i = 0; i < users.length; i++) {
            _importSponsorBonuses(users[i], amounts[i], isEquivalent, isNew, addToExistent);
        }
    }

    function updateAccuralMarketingRewardAllowance(bool isAllowed) external onlyOwner {
        allowAccuralMarketingReward = isAllowed;
    }

    function updateStakingPool(uint id, address stakingPool) public onlyOwner {
        _updateStakingPool(id, stakingPool);
    }

    function updateStakingPool(uint[] memory ids, address[] memory _stakingPools) external onlyOwner {
        require(ids.length == _stakingPools.length, "Ids and staking pools arrays have different size.");
        
        for(uint i = 0; i < ids.length; i++) {
            _updateStakingPool(ids[i], _stakingPools[i]);
        }
    }

    function updateAllowedTokens(address token, bool isAllowed) external onlyOwner {
        require (token != address(0), "Wrong addresses");
        allowedTokens[token] = isAllowed;
        emit AllowedTokenUpdated(token, isAllowed);
    }
    
    function updateRecipient(address recipientAddress) external onlyOwner {
        require(recipientAddress != address(0), "Address is zero");
        recipient = recipientAddress;
    } 

    function updateSponsorBonus(uint bonus) external onlyOwner {
        sponsorBonus = bonus;
    }

    function updateReferralProgramContract(address newReferralProgramContract) external onlyOwner {
        require(newReferralProgramContract != address(0), "Address is zero");
        referralProgram = INimbusReferralProgram(newReferralProgramContract);
    }

    function updateReferralProgramMarketingContract(address newReferralProgramMarketingContract) external onlyOwner {
        require(newReferralProgramMarketingContract != address(0), "Address is zero");
        referralProgramMarketing = INimbusReferralProgramMarketing(newReferralProgramMarketingContract);
    }

    function updateSwapRouter(address newSwapRouter) external onlyOwner {
        require(newSwapRouter != address(0), "Address is zero");
        swapRouter = INimbusRouter(newSwapRouter);
    }

    function updatePriceFeed(address newPriceFeed) external onlyOwner {
        require(newPriceFeed != address(0), "Address is zero");
        priceFeed = IPriceFeed(newPriceFeed);
    }

    function updateNFTVestingContract(address nftVestingAddress, string memory nftUri) external onlyOwner {
        require(AddressUpgradeable.isContract(nftVestingAddress), "NFTVestingContractAddress is not a contract");
        nftVesting = IVestingNFT(nftVestingAddress);
        nftVestingUri = nftUri;
        emit UpdateNFTVestingContract(nftVestingAddress, nftVestingUri);
    }

    function updateNFTCashbackContract(address nftCashbackAddress) external onlyOwner {
        require(AddressUpgradeable.isContract(nftCashbackAddress), "NFTCashbackContractAddress is not a contract");
        nftCashback = ISmartLP(nftCashbackAddress);
        emit UpdateNFTCashbackContract(nftCashbackAddress);
    }

    function updateNFTSmartStakerContract(address nftSmartStakerAddress) external onlyOwner {
        require(AddressUpgradeable.isContract(nftSmartStakerAddress), "NFTSmartStakerContractAddress is not a contract");
        nftSmartStaker = IStakingMain(nftSmartStakerAddress);
        emit UpdateNFTSmartStakerContract(nftSmartStakerAddress);
    }

    function updateSwapToken(address newSwapToken) external onlyOwner {
        require(newSwapToken != address(0), "Address is zero");
        swapToken = newSwapToken;
        emit SwapTokenUpdated(swapToken);
    }

    function updateSystemToken(address newSystemToken) external onlyOwner {
        require(newSystemToken != address(0), "Address is zero");
        SYSTEM_TOKEN = IERC20Upgradeable(newSystemToken);
    }

    function updatePancakeSwapRouter(address newSwapRouter) external onlyOwner {
        require(newSwapRouter != address(0), "Address is zero");
        pancakeSwapRouter = IPancakeRouter(newSwapRouter);
    }

    function updateSwapTokenAmountForSponsorBonusThreshold(uint threshold) external onlyOwner {
        swapTokenAmountForSponsorBonusThreshold = threshold;
        emit SwapTokenAmountForSponsorBonusThresholdUpdated(swapTokenAmountForSponsorBonusThreshold);
    }

    function updateSwapTokenAmountForCashbackBonusThreshold(uint threshold) external onlyOwner {
        swapTokenAmountForCashbackBonusThreshold = threshold;
        emit SwapTokenAmountForCashbackBonusThresholdUpdated(swapTokenAmountForCashbackBonusThreshold);
    }

    function toggleUsePriceFeeds() external onlyOwner {
        usePriceFeeds = !usePriceFeeds;
        emit ToggleUsePriceFeeds(usePriceFeeds);
    }

    function toggleVestingRedeemingAllowed() external onlyOwner {
        vestingRedeemingAllowed = !vestingRedeemingAllowed;
        emit ToggleVestingRedeemingAllowed(vestingRedeemingAllowed);
    }

    function _updateStakingPool(uint id, address stakingPool) private {
        require(id != 0, "Staking pool id cant be equal to 0.");
        require(stakingPool != address(0), "Staking pool address cant be equal to address(0).");

        stakingPools[id] = INimbusStakingPool(stakingPool);
        require(SYSTEM_TOKEN.approve(stakingPool, type(uint256).max), "Error on approving");
    }

    function _importSponsorBonuses(address user, uint amount, bool isEquivalent, bool isNew, bool addToExistent) private {
        require(user != address(0) && amount > 0, "Zero values");
        
        if (isNew)
        if (isEquivalent) {
            if (addToExistent) {
                unclaimedSponsorBonusEquivalentNew[user] += amount;
            } else {
                unclaimedSponsorBonusEquivalentNew[user] = amount;
            }    
        } else {
            if (addToExistent) {
                unclaimedSponsorBonusNew[user] += amount;
            } else {
                unclaimedSponsorBonusNew[user] = amount;
            }
        } else 
        if (isEquivalent) {
            if (addToExistent) {
                unclaimedSponsorBonusEquivalent[user] += amount;
            } else {
                unclaimedSponsorBonusEquivalent[user] = amount;
            }    
        } else {
            if (addToExistent) {
                unclaimedSponsorBonus[user] += amount;
            } else {
                unclaimedSponsorBonus[user] = amount;
            }
        }
        emit ImportSponsorBonuses(user, amount, isEquivalent, addToExistent);
    }

    function updateCashbackBonus(uint bonus) external onlyOwner {
        cashbackBonus = bonus;
        emit UpdateCashbackBonus(bonus);
    }

    function updateCashbackDisableTime(uint256 newTime) external onlyOwner {
        cashbackDisableTime = newTime;
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }

}