//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../accessControl/AccessProtectedUpgradable.sol";
import "../tokens/MBLKToken.sol";
import "../tokens/IUSDT.sol";
import "../utils/AddressPrefix.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

contract MBLKIDOV2 is PausableUpgradeable,ReentrancyGuardUpgradeable,AccessProtectedUpgradable, AddressPrefix{
    
    IERC20 public ZOGI;
    IERC20 public USDT;

    bool    private initialized;
    bool    private finalized;
    bool    public  whiteListEnabled;
    uint256 public  totalAllocated;
    uint256 public  currentStage;
    bytes32 public  merkleRoot;
    address public  collectionWallet;
    uint256 public  totalTiers;

    // three extra decimals added in this rate
    uint256 public ethUsdRate;
    uint256 public zogiUsdRate;

    mapping(uint256 => uint256) public usdtRate;
    mapping(uint256 => uint256) public ethRate;
    mapping(uint256 => uint256) public zogiRate;

    mapping(address => bool) public whiteListClaimed;

    mapping(address => uint256) public userAllocation;
    mapping(uint256 => uint256) public stageLimit;

    mapping(string => uint256) public ethRefferal;
    mapping(string => uint256) public zogiRefferal;
    mapping(string => uint256) public usdtRefferal;
    mapping(string => uint256) public totalReffered;
    mapping(string => address) public customRefId;

    mapping(uint256 => uint256) public tierLimit;
    mapping(uint256 => uint256) public tierReward; // has one decimals (2.5% = 25)

    using SafeERC20Upgradeable for ERC20Upgradeable;
    IUSDT public USDTV2; 

    event RateUpdated(uint256 usdtRate_, uint256 ethRate_, uint256 zogiRate_, uint256 stage);
    event MBLKAllocated(address user, uint256 mblkAmount, uint256 paymentType, uint256 paymentAmount);
    event RewardClaimed(address user, uint256 ethAmount, uint256 zogiAmount, uint256 usdtAmount, string refId);
    event RefIdCreated(address user, string refId);

    function init(address zogiToken_,address usdtAddress_, uint256[]calldata stageLimits, uint256 totalTiers_) external initializer
    {
       require(!initialized);
       ZOGI = IERC20(zogiToken_);
       USDT = IERC20(usdtAddress_);
       __Ownable_init();
       __Pausable_init();
       updateStageLimits(stageLimits);
       totalTiers = totalTiers_;
       currentStage = 1;
       initialized = true;
    }

    function addUSDTAddress(address usdt_)external onlyOwner{
        require(usdt_ != address(0), "Invalid address");
        USDTV2 = IUSDT(usdt_);
    }

    function updateWhiteListStatus(bool status_)external onlyOwner{
        whiteListEnabled = status_;
    }

    function updateIDOStatus(bool status_)external onlyOwner{
        finalized = status_;
    }

    function setMerkleRoot(bytes32 merkleRoot_)external onlyOwner{
        merkleRoot = merkleRoot_;
    }

    function setCollectionWallet(address wallet)external onlyOwner{
        require(wallet!= address(0), "Invalid address");
        collectionWallet = wallet;
    }

    function updateStageLimits(uint256[]calldata stageLimits) public onlyAdmin{
        for (uint256 i = 1; i <= stageLimits.length; i++) {
            stageLimit[i] = stageLimits[i-1];
        }
    }

    function upadateRates(uint256 usdtRate_, uint256 ethRate_, uint256 zogiRate_, uint256 stage,
            uint256 ethUsdRate_, uint256 zogiUsdRate_)external onlyAdmin
    {
       usdtRate[stage] = usdtRate_;
       ethRate[stage] = ethRate_;
       ethUsdRate = ethUsdRate_;
       zogiUsdRate = zogiUsdRate_;
  
        if (stage < 3){
         zogiRate[stage] = zogiRate_;
        }

        emit RateUpdated(usdtRate_, ethRate_, zogiRate_, stage);
    }

    function setUSDTRate(uint256[]calldata rates, uint256[]calldata stages) public onlyAdmin {
        for (uint256 i = 0; i < stages.length; i++) {
        usdtRate[stages[i]] = rates[i];
        }
    }

    function setEthRate(uint256[]calldata rates, uint256 ethUsdRate_, uint256[]calldata stages) public onlyAdmin {
        ethUsdRate = ethUsdRate_;
        for (uint256 i = 0; i < stages.length; i++) {
          ethRate[stages[i]] = rates[i];
        }
    }

    function setZogiRate(uint256[]calldata rates, uint256 zogiUsdRate_, uint256[]calldata stages) public onlyAdmin {
        zogiUsdRate = zogiUsdRate_;
        for (uint256 i = 0; i < stages.length; i++) {
          zogiRate[stages[i]] = rates[i];
        }
    }

    function setTier(uint256 tierId_, uint256 tierLimit_, uint256 tierReward_)public onlyOwner{
        tierLimit[tierId_] = tierLimit_;
        tierReward[tierId_] = tierReward_;
    }

    function whiteListGetMBLKAllocation(uint8 paymentType, bytes32[] calldata _merkleProof, uint256 amount_, string memory refId) external payable whenNotPaused nonReentrant
    {
        require(whiteListEnabled, "Whitelisting closed");
        require(!whiteListClaimed[msg.sender], "Claimed already");
        require((paymentType > 0 && paymentType <=4),"Invalid paymentType");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid proof");

        whiteListClaimed[msg.sender] = true;
        uint256 mblkAllocation = 0;
        uint256 collectionAmount = 0;

        if (paymentType == 1){
            require(amount_ == msg.value, "Invalid amount enterred");
            require((ethUsdRate * amount_)/1000 <= 2500*10**18 , "Can not buy more than whiteList limit");
            mblkAllocation = (msg.value * ethRate[currentStage])/ 1000;

            ethRefferal[refId] += amount_;
            totalReffered[refId] += (ethUsdRate * amount_ )/1000;

            collectionAmount = getCollectionAmount(amount_);
            transferEth(collectionAmount, collectionWallet);
        }
        if (paymentType == 2){
            require((zogiUsdRate * amount_)/1000 <= (2500*10**18) , "Can not buy more than whiteList limit");

            mblkAllocation = (amount_ * zogiRate[currentStage])/ 1000;

            zogiRefferal[refId] += amount_;
            totalReffered[refId] += (zogiUsdRate * amount_)/1000;
        
            collectionAmount = getCollectionAmount(amount_);
            require(ZOGI.transferFrom(msg.sender, collectionWallet ,collectionAmount), "Transfer failed");
            require(ZOGI.transferFrom(msg.sender, address(this) , (amount_ - collectionAmount)), "Transfer failed");
        }
        if (paymentType == 3){
            require(amount_ <= 2500000000, "Can not buy more than whiteList limit");

            mblkAllocation = ((amount_ * 10**12) * usdtRate[currentStage])/ 1000;

            usdtRefferal[refId] += amount_;
            totalReffered[refId] +=  ((amount_) * 10**12);

            collectionAmount = getCollectionAmount(amount_);
            ERC20Upgradeable(address(USDTV2)).safeTransferFrom(msg.sender, collectionWallet ,collectionAmount);
            ERC20Upgradeable(address(USDTV2)).safeTransferFrom(msg.sender, address(this),  amount_ - collectionAmount);
        }


        userAllocation[msg.sender] += mblkAllocation;        
        totalAllocated += mblkAllocation;

        emit MBLKAllocated(msg.sender, mblkAllocation, paymentType, amount_);
    }

    function getMBLKAllocation(uint8 paymentType, address beneficiary, uint256 amount, string memory refId)public payable whenNotPaused nonReentrant returns(bool)
    {
        require(!whiteListEnabled, "Can not buy during whitelisting stage");
        require(!finalized, "IDO closed");
        require(currentStage <= 4, "IDO closed");
        require((paymentType > 0 && paymentType <=4),"Invalid paymentType");
        verifyRefId(beneficiary, refId);
        verifyRefId(msg.sender, refId);

        if (paymentType == 2 && currentStage >= 3){
            revert("Can not use Zogi as payment after round 2");
        }

        uint256 mblkAllocation;
        uint256 refundAmount;
        uint256 collectionAmount;

        if (paymentType == 1){
            require(amount == msg.value, "Invalid amount enterred");

            mblkAllocation = (msg.value * ethRate[currentStage])/ 1000;
            if (mblkAllocation + totalAllocated > stageLimit[currentStage]){
                (mblkAllocation, refundAmount) = nextRoundAllocation(msg.sender, paymentType,mblkAllocation, ethRate[currentStage], ethRate[currentStage +1]);
            }
            collectionAmount = getCollectionAmount(amount - refundAmount);
            ethRefferal[refId] += amount - refundAmount;
            totalReffered[refId] += (ethUsdRate * (amount - refundAmount))/1000;
            transferEth(collectionAmount, collectionWallet);
        }

        if (paymentType == 2){
            mblkAllocation = (amount * zogiRate[currentStage])/ 1000;
            
            if (mblkAllocation + totalAllocated > stageLimit[currentStage]){
                (mblkAllocation, refundAmount) = nextRoundAllocation(msg.sender, paymentType,mblkAllocation, zogiRate[currentStage], zogiRate[currentStage +1]);
            }
            collectionAmount = getCollectionAmount(amount - refundAmount);
            zogiRefferal[refId] += amount - refundAmount;
            totalReffered[refId] += (zogiUsdRate * (amount - refundAmount))/1000;

            require(ZOGI.transferFrom(msg.sender, collectionWallet ,collectionAmount), "Transfer failed");
            require(ZOGI.transferFrom(msg.sender, address(this), (amount - refundAmount) - collectionAmount), "Transfer failed");
        }

        if (paymentType == 3){

            mblkAllocation = ((amount * 10**12) * usdtRate[currentStage])/ 1000;

            if (mblkAllocation + totalAllocated > stageLimit[currentStage]){
                (mblkAllocation, refundAmount) = nextRoundAllocation(msg.sender, paymentType, mblkAllocation, usdtRate[currentStage], usdtRate[currentStage +1]);
            }
            if (refundAmount > 0){
                refundAmount = refundAmount / (1* 10**12);
            }
            
            collectionAmount = getCollectionAmount(amount - refundAmount);
            usdtRefferal[refId] += amount - refundAmount;
            totalReffered[refId] +=  ((amount * 10**12) - refundAmount);

            ERC20Upgradeable(address(USDTV2)).safeTransferFrom(msg.sender, collectionWallet ,collectionAmount);
            ERC20Upgradeable(address(USDTV2)).safeTransferFrom(msg.sender, address(this), (amount - refundAmount) - collectionAmount);

        }

        userAllocation[beneficiary] += mblkAllocation;        
        totalAllocated += mblkAllocation;

        if (totalAllocated >= stageLimit[currentStage]){
            currentStage +=1;
        }

        emit MBLKAllocated(beneficiary, mblkAllocation, paymentType, amount);
        return true;
    }

    function nextRoundAllocation(address user, uint256 paymentType,uint256 mblkAllocation, uint256 currentRate, uint256 nextRate)
        internal  returns(uint256, uint256){

        uint256 overAllocated = (mblkAllocation + totalAllocated) - stageLimit[currentStage];
        uint256 overAllocatedAmount = overAllocated / currentRate;
        bool refund = false;
        uint256 refundAmount = 0;

        if (paymentType == 1 && currentStage == 4){
            refund = true;
            transferEth(overAllocatedAmount, user);
        }
        if (paymentType == 2 && currentStage == 2){
            refund = true;
            ZOGI.transfer(user, overAllocatedAmount);
        }
        if (paymentType == 3 && currentStage == 4){
            refund = true;
            USDT.transfer(user, overAllocatedAmount/(1*10**12));
        }

        if (refund){
            refundAmount = overAllocatedAmount;
        }

        uint256 nextRoundAllocationAmount = overAllocatedAmount * nextRate;
        mblkAllocation = (mblkAllocation - overAllocated) + nextRoundAllocationAmount;
        return (mblkAllocation, refundAmount);
    }
    
    function claimRefReward(string memory refId_, bool customId_)public whenNotPaused nonReentrant{
        require(finalized, "Can not claim during IDO");
        require(totalReffered[refId_] > 0 , "Can not claim zero value");

        if (customId_){
            require(customRefId[refId_] == msg.sender, "Only owner can claim ref reward");
        }else{
            require(compareStrings(refId_, refIdfromAdd(msg.sender)), "Only owner can claim ref reward");
        }

        uint256 userTier = 0;

        if (totalReffered[refId_] < tierLimit[0]){
            userTier = 0;
        }

        if (totalReffered[refId_] > tierLimit[totalTiers-1]){
            userTier = totalTiers-1;
        }

        for(uint256 i =1; i <= totalTiers -1 ; i++){
            if (totalReffered[refId_] > tierLimit[i-1] && totalReffered[refId_] < tierLimit[i]){
                userTier = i;
            }
        }

        uint256 rewardPercentage = tierReward[userTier];  

        uint256 ethVal = (ethRefferal[refId_] * rewardPercentage) / 1000;
        uint256 usdtVal = (usdtRefferal[refId_] * rewardPercentage) / 1000;
        uint256 zogiVal = (zogiRefferal[refId_] * rewardPercentage) / 1000;

        totalReffered[refId_] = 0;

        transferEth(ethVal, msg.sender);
        USDTV2.transfer(msg.sender, usdtVal);
        require(ZOGI.transfer(msg.sender, zogiVal), "ZOGI transfer failed");

        emit RewardClaimed(msg.sender, ethVal, zogiVal, usdtVal, refId_);
    }

    function increaseAllocation(uint256 allocationAmount, address user)external onlyAdmin returns(bool){
        userAllocation[user] += allocationAmount;
        return true;
    }
    
    function decreaseAllocation(uint256 allocationAmount, address user)external onlyAdmin returns(bool){
        require(userAllocation[user] >= allocationAmount);
        userAllocation[user] -= allocationAmount;
        return true;
    }

    function setCustomRefId(string memory refId_)external {
        require(getStringLength(refId_) != 10, "ref id should be greater or less than 10 characters");
        require(customRefId[refId_] == address(0), "ref Id already in use");
        customRefId[refId_] = msg.sender;

        emit RefIdCreated(msg.sender, refId_);
    }
    
    function compareStrings(string memory a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b)));
    }

    function verifyRefId(address beneficiary, string memory refId)private view{
        require(!compareStrings(refId, AddressPrefix.refIdfromAdd(beneficiary)), "Can not use your own ref id");
        require(customRefId[refId] != beneficiary, "Can not use your own ref id");
    }

    function withdrawEth(uint256 amount, address wallet)external onlyOwner{
        transferEth(amount, wallet);
    }

    function withdrawZogi(uint256 amount, address wallet)external onlyOwner{
        ZOGI.transfer(wallet, amount);
    }

    function withdrawUsdt(uint256 amount,  address wallet)external onlyOwner{
        USDTV2.transfer(wallet, amount);
    }

    function transferEth(uint256 amount, address to)private {
        (bool sent,) = to.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    function getCollectionAmount(uint256 amount_) private pure returns(uint256){
        return (amount_ * 85)/100;
    }

    function renounceOwnership() public view override onlyOwner {
        revert("can't renounceOwnership here");
    }

    function getStringLength(string memory str) private pure returns (uint256) {
        bytes memory strBytes = bytes(str);
        return strBytes.length;
    }

    function pause()external onlyOwner{
        _pause();
    }

    function unpause()external onlyOwner{
        _unpause();
    }

}