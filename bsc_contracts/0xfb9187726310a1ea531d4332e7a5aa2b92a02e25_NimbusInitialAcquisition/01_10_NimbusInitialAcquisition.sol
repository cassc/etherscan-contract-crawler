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

    mapping(uint256 => mapping(address => mapping(uint256 => bool))) public usedRestakings;

    uint256 private constant PRICE_IMPACT_DECIMALS = 18;  // for integer math
    
    uint256 public maxPriceImpact;

    INimbProxy public nimbProxy;

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

    function buyExactSystemTokenForBnbAndRegister(uint systemTokenAmount, address systemTokenRecipient, uint stakingPoolId, uint sponsorId) payable external whenNotPaused {
        require(sponsorId >= 1000000001, "Sponsor id must be grater than 1000000000");
        referralProgramMarketing.registerUser(systemTokenRecipient, sponsorId);
        buyExactSystemTokenForBnb(systemTokenAmount, systemTokenRecipient, stakingPoolId);
    }

    function buySystemTokenForExactBnbAndRegister(address systemTokenRecipient, uint stakingPoolId, uint sponsorId) payable external whenNotPaused {
        require(sponsorId >= 1000000001, "Sponsor id must be grater than 1000000000");
        referralProgramMarketing.registerUser(systemTokenRecipient, sponsorId);
        buySystemTokenForExactBnb(systemTokenRecipient, stakingPoolId);
    }

    function buySystemTokenForExactTokensAndRegister(address token, uint tokenAmount, address systemTokenRecipient, uint stakingPoolId, uint sponsorId) external whenNotPaused {
        require(sponsorId >= 1000000001, "Sponsor id must be grater than 1000000000");
        referralProgramMarketing.registerUserBySponsorId(systemTokenRecipient, sponsorId, 0);
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

    function restake(uint systemTokenAmount, uint stakingPoolId, uint newStakingPoolId, uint currentStakeNonce) public {
        address user = msg.sender;
        require(address(stakingPools[stakingPoolId]) != address(0) && address(stakingPools[newStakingPoolId]) != address(0), "No staking pool with provided id");
        INimbusStakingPool curStaking = INimbusStakingPool(stakingPools[stakingPoolId]);
        require(referralProgram.userIdByAddress(user) > 0, "Not part of referral program");
        require(currentStakeNonce < curStaking.stakeNonces(user), "Wrong staking nonce");
        INimbusStakingPool.StakeNonceInfo memory stakeInfo = INimbusStakingPool(stakingPools[stakingPoolId]).stakeNonceInfos(user, currentStakeNonce);
        require(stakeInfo.stakingTokenAmount == 0, "Staking not withdrawn yet");
        require(!usedRestakings[stakingPoolId][user][currentStakeNonce], "Already restaked");

        TransferHelper.safeTransferFrom(address(SYSTEM_TOKEN), user, address(this), systemTokenAmount);
        _buySystemToken(address(SYSTEM_TOKEN), systemTokenAmount, systemTokenAmount, user, newStakingPoolId);
        usedRestakings[stakingPoolId][user][currentStakeNonce] = true;
        
        emit Restake(stakingPoolId, newStakingPoolId, currentStakeNonce, systemTokenAmount, user);
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

    function getSwapSystemTokenAmountForToken(address token, uint tokenAmount) public view returns (uint) { 
        return getSwapRate(token, address(SYSTEM_TOKEN), tokenAmount, false);
    }

    function getSwapSystemTokenAmountForBnb(uint bnbAmount) public view returns (uint) { 
        return getSwapRate(swapRouter.NBU_WBNB(), address(SYSTEM_TOKEN), bnbAmount, false);
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

    function getSwapRate(address tokenSrc, address tokenDest, uint tokenAmount, bool noImpact) public view returns (uint256 resultSwap) { 
        if (tokenSrc == tokenDest) return tokenAmount;
        address[] memory path = new address[](2);
        if (tokenSrc == address(swapToken)) {
            path[0] = address(swapToken);
            path[1] = pancakeSwapRouter.WETH();
            uint[] memory amountsBNBBusd = IPancakeRouter(pancakeSwapRouter)
                .getAmountsOut(tokenAmount, path);
            tokenAmount = amountsBNBBusd[1];
            path[0] = swapRouter.NBU_WBNB();
        } else path[0] = tokenSrc;
        path[1] = tokenDest;

        uint256 systemTokenAddPart = 0;
        if (!noImpact && tokenDest == address(SYSTEM_TOKEN)) {
            (,uint256 swapPartBnb, uint256 impactRate) = getMaxSystemTokenImpact();

            if (tokenAmount > swapPartBnb) {
                // part to swap with price impact
                uint256 fixedPriceSwap = tokenAmount - swapPartBnb; // part to swap with fixed price
                systemTokenAddPart = fixedPriceSwap * 10 ** 18 / impactRate;  // to add NIMB
                
                tokenAmount = swapPartBnb;
            }
        }
        resultSwap = swapRouter.getAmountsOut(tokenAmount, path)[1] + systemTokenAddPart;
    }

    function getMaxSystemTokenImpact() public view returns(uint256 nimb, uint256 bnb, uint256 rate) {
        require(maxPriceImpact < 10**PRICE_IMPACT_DECIMALS, "maxPriceImpact too many decimals");
        
        // get reserves
        INimbusPair sysPair = swapRouter.pairFor(address(SYSTEM_TOKEN), swapRouter.NBU_WBNB());
        (uint256 reserve0, uint256 reserve1, ) = sysPair.getReserves();
        uint256 reserveIn;
        uint256 reserveOut;

        if (sysPair.token0() == address(SYSTEM_TOKEN)) {
            reserveIn = reserve0;
            reserveOut = reserve1;
        } else {
            reserveIn = reserve1;
            reserveOut = reserve0;
        }
        uint256 p = 10**(PRICE_IMPACT_DECIMALS*2)/(maxPriceImpact * 2 + 10**PRICE_IMPACT_DECIMALS);
        
        uint256 temp = 9*p*p + 4*1000*997*p*(10**PRICE_IMPACT_DECIMALS);
        uint256 sqrt = MathUpgradeable.sqrt(temp);
        
        nimb = (sqrt - 1997*p)*reserveIn/(2*997*p);
        bnb = (sqrt - 1997*p)*reserveOut/(2*997*p);
        rate = bnb * 10**PRICE_IMPACT_DECIMALS / nimb;
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

    function _purchaseFromSwap(address token, uint tokenAmount) private returns(uint systemTokenAmount) {
        address[] memory path = new address[](2);
        require(token == address(swapToken) || token == NBU_WBNB, "Wrong purchase token");

        if (token != NBU_WBNB) {
            TransferHelper.safeTransferFrom(address(swapToken), msg.sender, address(this), tokenAmount);
            // Swap with pancakeswap from BUSD to BNB
            if(IERC20Upgradeable(token).allowance(address(this), address(pancakeSwapRouter)) < tokenAmount) {
                IERC20Upgradeable(token).approve(address(pancakeSwapRouter), type(uint256).max);
            }
            path[0] = address(swapToken);
            path[1] = pancakeSwapRouter.WETH();
            (uint[] memory amountsBnbTokenSwap) = pancakeSwapRouter.swapExactTokensForETH(tokenAmount, 0, path, address(this), block.timestamp + 1200);
            tokenAmount = amountsBnbTokenSwap[1];
        }

        uint256 requiredSystemTokenAmount = getSwapSystemTokenAmountForBnb(tokenAmount);

        // Swap with nimbus from BNB to NIMB
        path[0] = swapRouter.NBU_WBNB();
        path[1] = address(SYSTEM_TOKEN);
        (uint[] memory amountsBNBNimb) = swapRouter.swapExactBNBForTokens{value: tokenAmount }(0, path, address(this), block.timestamp + 1200);
        systemTokenAmount = amountsBNBNimb[1];

        if (requiredSystemTokenAmount > systemTokenAmount) {
            uint256 systemTokenAddPart = requiredSystemTokenAmount - systemTokenAmount; // to add NIMB
            nimbProxy.mint(address(this), systemTokenAddPart);
            
            emit SwapPriceImpact(systemTokenAddPart, tokenAmount, requiredSystemTokenAmount);
            systemTokenAmount = requiredSystemTokenAmount;
        }
    }

    function _buySystemToken(address token, uint tokenAmount, uint systemTokenAmount, address systemTokenRecipient, uint stakingPoolId) private {
        if (token != address(SYSTEM_TOKEN)) {
            systemTokenAmount = _purchaseFromSwap(token, tokenAmount);
        }
        stakingPools[stakingPoolId].stakeFor(systemTokenAmount, systemTokenRecipient);
        uint swapTokenAmount = getTokenAmountForToken(token, swapToken, tokenAmount, true);

        bool isFirstAP4Staking = userPurchases[systemTokenRecipient] == 0;
        userPurchases[systemTokenRecipient] += systemTokenAmount;
        userPurchasesEquivalent[systemTokenRecipient] += swapTokenAmount;

        if(allowAccuralMarketingReward && address(referralProgramMarketing) != address(0)) {
            referralProgramMarketing.updateReferralProfitAmount(systemTokenRecipient, swapTokenAmount);
        }
        emit BuySystemTokenForToken(token, stakingPoolId, tokenAmount, systemTokenAmount, swapTokenAmount, systemTokenRecipient);
        
        if (isFirstAP4Staking) {
            _processSponsor(systemTokenRecipient, systemTokenAmount, swapTokenAmount);
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

    function importSponsorBonuses(address[] memory users, uint[] memory amounts, bool isEquivalent, bool isNew, bool addToExistent) external onlyOwner {
        require(users.length == amounts.length, "Wrong lengths");

        for (uint256 i = 0; i < users.length; i++) {
            _importSponsorBonuses(users[i], amounts[i], isEquivalent, isNew, addToExistent);
        }
    }

    function updateStakingPool(uint id, address stakingPool) public onlyOwner {
        _updateStakingPool(id, stakingPool);
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

    function updateSwapRouter(address newSwapRouter, address newPancakeSwapRouter) external onlyOwner {
        require(newSwapRouter != address(0) && newPancakeSwapRouter != address(0), "Address is zero");
        swapRouter = INimbusRouter(newSwapRouter);
        pancakeSwapRouter = IPancakeRouter(newPancakeSwapRouter);
    }

    function updatePriceFeed(address newPriceFeed) external onlyOwner {
        require(newPriceFeed != address(0), "Address is zero");
        priceFeed = IPriceFeed(newPriceFeed);
    }

    function updateNFTContracts(address nftVestingAddress, address nftCashbackAddress, address nftSmartStakerAddress) external onlyOwner {
        require(AddressUpgradeable.isContract(nftVestingAddress) && AddressUpgradeable.isContract(nftCashbackAddress) && AddressUpgradeable.isContract(nftSmartStakerAddress), "Address is not a contract");
        nftVesting = IVestingNFT(nftVestingAddress);
        nftCashback = ISmartLP(nftCashbackAddress);
        nftSmartStaker = IStakingMain(nftSmartStakerAddress);
        emit UpdateNFTVestingContract(nftVestingAddress, nftVestingUri);
        emit UpdateNFTCashbackContract(nftCashbackAddress);
        emit UpdateNFTSmartStakerContract(nftSmartStakerAddress);
    }

    function updateSwapToken(address newSwapToken) external onlyOwner {
        require(newSwapToken != address(0), "Address is zero");
        swapToken = newSwapToken;
        emit SwapTokenUpdated(swapToken);
    }

    function updateSystemToken(address newSystemToken, address newNimbProxy, uint256 _maxPriceImpact) external onlyOwner {
        require(newSystemToken != address(0), "Address is zero");
        SYSTEM_TOKEN = IERC20Upgradeable(newSystemToken);
        nimbProxy = INimbProxy(newNimbProxy);
        require(_maxPriceImpact < 10**PRICE_IMPACT_DECIMALS, "maxPriceImpact too many decimals");

        maxPriceImpact = _maxPriceImpact;
    }

    function updateSwapTokenAmountForSponsorBonusThreshold(uint threshold) external onlyOwner {
        swapTokenAmountForSponsorBonusThreshold = threshold;
        emit SwapTokenAmountForSponsorBonusThresholdUpdated(swapTokenAmountForSponsorBonusThreshold);
    }

    function toggleUsePriceFeeds() external onlyOwner {
        usePriceFeeds = !usePriceFeeds;
        emit ToggleUsePriceFeeds(usePriceFeeds);
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

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }

}