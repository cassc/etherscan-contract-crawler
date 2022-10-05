//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./interfaces/IRanceTreasury.sol";
import "hardhat/console.sol";

contract RanceProtocol is 
    Initializable, 
    UUPSUpgradeable, 
    OwnableUpgradeable, 
    ReentrancyGuardUpgradeable{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint;

    IUniswapV2Router02 public uniswapRouter;

    /**
    *  @dev Instance of the insurance treasury (used to handle insurance funds).
    */
    IRanceTreasury public treasury;

    /**
    *  @dev Instance of RANCE token
    */
    IERC20Upgradeable public RANCE;


    /** 
    * @dev list of package plan ids
    */
    bytes32[] public packagePlanIds;

    /** 
    * @dev array of payment token
    */

    string[] public paymentTokens;


    /** 
    * @dev array of insure coins
    */

    string[] public insureCoins;

    /** 
    * @dev referral percentage
    */

    uint public referralPercentage;


    /**
     * @dev data of Package Plan on the Insurance Protocol
     */
    struct PackagePlan {
        bytes32 planId;
        uint32 periodInSeconds;
        uint8 insuranceFee;
        uint uninsureFee;
        bool isActivated; 
    }


    /**
     * @dev data of Package on the Insurance Protocol
     */
    struct Package { 
        address user;
        bytes32 planId;
        bytes32 packageId;
        uint initialDeposit; 
        uint insureOutput;
        uint startTimestamp;
        uint endTimestamp;
        bool isCancelled;
        bool isWithdrawn;
        address insureCoin;
        address paymentToken;
    }


    /**
     * @dev data of ReferralReward on the Insurance Protocol
     */

    struct ReferralReward{
        bytes32 id;
        uint rewardAmount;
        uint timestamp;
        address token;
        address referrer;
        address user;
        bool claimed;
    }

    /**
     * @dev list of all package ids purchased per user
     */
    mapping(address => bytes32[]) public userToPackageIds; 

    /**
     *  @dev retrieve packagePlan with packagePlan id
     */
    mapping (bytes32 => PackagePlan) public planIdToPackagePlan;


    /**
     *  @dev retrieve package with package id
     */
    mapping (bytes32 => Package) public packageIdToPackage;


    /**
     * @dev retrieve payment token  with name
     */
    mapping(string => address) public paymentTokenNameToAddress;


    /**
     * @dev retrieve insure coin with name
     */
    mapping(string => address) public insureCoinNameToAddress;


    /**
     * @dev retrieve payment token total insurance locked  with address
     */
    mapping(address => uint) public totalInsuranceLocked;


    /**
     * @dev check if payment token is added
     */
    mapping(address => bool) public paymentTokenAdded;

    /**
     * @dev check if insure Coin is added
     */
    mapping(address => bool) public insureCoinAdded;

    /**
     * @dev list of all referral ids referred per user
     */
    mapping(address => bytes32[]) public userToReferralIds; 


    /**
     * @dev retrieve ReferralReward with referral id
     */
     mapping(bytes32 => ReferralReward) public referrals;


    /**
     * @dev Emitted when an insurance package is activated
     */
    event InsuranceActivated(
        bytes32 indexed _packageId,
        address indexed _user
    );


    /**
     * @dev Emitted when an insurance package is cancelled
     */
    event InsuranceCancelled(
        bytes32 indexed _packageId,
        address indexed _user
    );

    /**
     * @dev Emitted when a payment token is added
     */
    event PaymentTokenAdded(string paymentTokenName, address indexed paymentToken);


    /**
     * @dev Emitted when a payment token is removed
     */
    event PaymentTokenRemoved(address indexed paymentToken);


     /**
     * @dev Emitted when a insure coin is added
     */
    event InsureCoinAdded(string insureCoinName, address indexed insureCoin);


    /**
     * @dev Emitted when a insure coin is removed
     */
    event InsureCoinRemoved(address indexed insureCoin);


    /**
     * @dev Emitted when an insurance package is withdrawn
     */
    event InsuranceWithdrawn(
        bytes32 indexed _packageId, 
        address indexed _user
    );

    /**
     * @dev Emitted when a package plan is deactivated
     */
    event PackagePlanDeactivated(bytes32 indexed _id);

    /**
     * @dev Emitted when a package plan is added
     */
    event PackagePlanAdded(
        bytes32 indexed _id,
        uint indexed _uninsureFee,
        uint8 indexed _insuranceFee,
        uint32 _periodInSeconds
    );


    /**
     * @dev Emitted when the treasury address is set
     */
    event TreasuryAddressSet(address indexed _address);

    /**
     * @dev Emitted when the rance address is set
     */
    event RanceAddressSet(address indexed _address);


    /**
     * @dev Emitted when a user refer someone
     */
    event Referred(
        address indexed referrer, 
        address indexed user, 
        uint amount, 
        uint timestamp
    );


    /**
     * @dev Emitted when a user claim refferal rewards
     */
    event RewardClaimed(address indexed user, bytes32 indexed referralId, uint amount);

    /**
     * @dev Emitted when the referral percentage is set
     */
    event ReferralRewardUpdated(uint newPercentage);


    /**
     * @dev check that the address passed is not 0. 
     */
    modifier notAddress0(address _address) {
        require(_address != address(0), "Rance Protocol: Address 0 is not allowed");
        _;
    }


    /**
     * @notice Contract constructor
     * @param _treasuryAddress treasury contract address
     * @param _uniswapRouter mmfinance router address
     * @param _paymentToken BUSD token address
     */
    function initialize(
        address _treasuryAddress,
         address _uniswapRouter,
         address _paymentToken)
        public initializer { 
        __Ownable_init();
        treasury = IRanceTreasury(_treasuryAddress);
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        paymentTokenNameToAddress["BUSD"] = _paymentToken;
        paymentTokenAdded[_paymentToken] = true;
        totalInsuranceLocked[_paymentToken] = 0;
        paymentTokens.push("BUSD");
        uint32[3] memory periodInSeconds = [15780000, 31560000, 63120000];
        uint8[3] memory insuranceFees = [100, 50, 25];
        uint80[3] memory uninsureFees = [1000 ether, 2000 ether, 5000 ether];
        bytes32[3] memory ids = [
            keccak256(abi.encodePacked(periodInSeconds[0],insuranceFees[0],uninsureFees[0])),
            keccak256(abi.encodePacked(periodInSeconds[1],insuranceFees[1],uninsureFees[1])),
            keccak256(abi.encodePacked(periodInSeconds[2],insuranceFees[2],uninsureFees[2]))
        ];
        for (uint i = 0; i < 3; i = i + 1 ) {
            planIdToPackagePlan[ids[i]] = PackagePlan(
                ids[i],
                periodInSeconds[i],
                insuranceFees[i],
                uninsureFees[i],
                true);
            packagePlanIds.push(ids[i]);   
        }
        IERC20Upgradeable(_paymentToken).approve(address(uniswapRouter), type(uint256).max);

    }

    /**
     * @notice Authorizes upgrade allowed to only proxy 
     * @param newImplementation the address of the new implementation contract 
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner{}

    /**
     * @notice sets the address of the rance protocol treasury contract
     * @param _treasuryAddress the address of treasury
     */
    function setTreasuryAddress(address _treasuryAddress)
        external 
        onlyOwner notAddress0(_treasuryAddress)
    {
        treasury = IRanceTreasury(_treasuryAddress);
        emit TreasuryAddressSet(_treasuryAddress);
    }

    /**
     * @notice sets the address of the rance token
     * @param _token the rance token address 
     */
    function setRance(address _token)
        external 
        onlyOwner notAddress0(_token)
    {
        RANCE = IERC20Upgradeable(_token);
        emit RanceAddressSet(_token);
    }


    /**
     * @notice update the percentage of the referral fee
     * @param _percentage of the updated referral fee 
     */
    function updateReferralReward(uint _percentage)
        external onlyOwner
    {
        require(_percentage != 0, "Rance Protocol: percentage cannot be 0");
        referralPercentage = _percentage;
        emit ReferralRewardUpdated(_percentage);
    }


    /**
     * @notice get the totalinsurancelocked of a payment token
     * @param _token the address of treasury
     * @return totalInsuranceLocked the total insurance locked of a token
     */
    function getTotalInsuranceLocked(address _token)
        external view returns(uint)
    {
        return totalInsuranceLocked[_token];
    }

    function getPaymentTokensLength() external view returns (uint){
        return paymentTokens.length;
    }

    /**
     * @notice get the array of payment tokens
     * @return paymentTokens the array of payment token
     */
    function getPaymentTokens(uint cursor, uint length)
        external view returns(string[] memory)
    {
        string[] memory output = new string[](length);
        for (uint n = cursor;  n < length;  n = n + 1) {
            output[n] = paymentTokens[n];
        }
        return output;
    }

    function getInsureCoinsLength() external view returns (uint){
        return insureCoins.length;
    }


    /**
     * @notice get the array of  insure coins
     * @return insureCoins the array of insure coins
     */
    function getInsureCoins(uint cursor, uint length)
        external view returns(string[] memory)
    {
        string[] memory output = new string[](length);
        for (uint n = cursor;  n < length;  n = n + 1) {
            output[n] = insureCoins[n];
        }

        return output;
    }

   


    /**
     * @notice deactivate package plan
     * @param _planId the package plan id
     */
    function deactivatePackagePlan(bytes32 _planId) external onlyOwner{
        require(planIdToPackagePlan[_planId].planId == _planId, "Rance Protocol: PackagePlan does not exists");

        PackagePlan storage packagePlan = planIdToPackagePlan[_planId];
        packagePlan.isActivated = false;
        
        emit PackagePlanDeactivated(_planId);
    }


    /**
     * @notice adds package plan
     * @param _periodInSeconds the periods of the package in Seconds
     * @param _insuranceFee the insurance fee for the package in percentage
     * @param _uninsureFee the penalty amount for insurance cancellation
     */
    function addPackagePlan(
        uint32 _periodInSeconds,
        uint8 _insuranceFee,
        uint _uninsureFee) external onlyOwner returns(bytes32){

        bytes32 _planId = keccak256(abi.encodePacked(
            _periodInSeconds,
            _insuranceFee,
            _uninsureFee));
        
        require(planIdToPackagePlan[_planId].planId != _planId, "Rance Protocol: PackagePlan already exists");

        planIdToPackagePlan[_planId] = PackagePlan(
            _planId,
            _periodInSeconds, 
            _insuranceFee, 
            _uninsureFee,
            true
        );

        packagePlanIds.push(_planId); 


        emit PackagePlanAdded(
            _planId,
            _uninsureFee, 
            _insuranceFee, 
            _periodInSeconds
        );

        return _planId;
    }


    /**
    @notice Method for adding payment token
    @dev Only admin
    @param _tokenName ERC20 token name
    @param _token ERC20 token address
    */
    function addPaymentToken(string memory _tokenName,address _token) external onlyOwner {
        require(!paymentTokenAdded[_token], "Rance Protocol:paymentToken already added");
        paymentTokenAdded[_token] = true;
        paymentTokenNameToAddress[_tokenName] = _token;
        totalInsuranceLocked[_token] = 0;
        paymentTokens.push(_tokenName);
        IERC20Upgradeable(_token).approve(address(uniswapRouter), type(uint256).max);

        emit PaymentTokenAdded(_tokenName, _token);
    }

    /**
    @notice Method for removing payment token
    @dev Only admin
    @param _tokenName ERC20 token address
    */
    function removePaymentToken(string memory _tokenName) external onlyOwner {
        address _token = paymentTokenNameToAddress[_tokenName];
        require(paymentTokenAdded[_token], "Rance Protocol:paymentToken does not exist");
        paymentTokenAdded[_token] = false;
        for (uint i = 0; i < paymentTokens.length; i = i + 1) {
            if(keccak256(abi.encodePacked(paymentTokens[i])) == keccak256(abi.encodePacked(_tokenName))){
                paymentTokens[i] = paymentTokens[paymentTokens.length -1];
                paymentTokens.pop();
            }
        }
        IERC20Upgradeable(_token).approve(address(uniswapRouter), 0);

        emit PaymentTokenRemoved(_token);
    }


    /**
    @notice Method for adding insure coins
    @dev Only admin
    @param _tokenNames array of ERC20 token name
    @param _tokens array of  ERC20 token address
    */
    function addInsureCoins(string[] memory _tokenNames, address[] memory _tokens) external onlyOwner {
        for (uint i = 0; i < _tokenNames.length; i = i + 1) {
            require(!insureCoinAdded[_tokens[i]], "Rance Protocol:insureCoin already added");
            insureCoinAdded[_tokens[i]] = true;
            insureCoinNameToAddress[_tokenNames[i]] = _tokens[i];
            insureCoins.push(_tokenNames[i]);

            emit InsureCoinAdded(_tokenNames[i], _tokens[i]);
        }
    }

    /**
    @notice Method for removing insure coins
    @dev Only admin
    @param _tokenNames array of ERC20 token address
    */
    function removeInsureCoins(string[] memory _tokenNames) external onlyOwner {
        for (uint i = 0; i < _tokenNames.length; i = i + 1) {
            address _token = insureCoinNameToAddress[_tokenNames[i]];
            require(insureCoinAdded[_token], "Rance Protocol:insureCoin does not exist");
            insureCoinAdded[_token] = false;
            if(keccak256(abi.encodePacked(insureCoins[i])) == keccak256(abi.encodePacked(_tokenNames[i]))){
                insureCoins[i] = insureCoins[insureCoins.length -1];
                insureCoins.pop();
            }

            emit InsureCoinRemoved(_token);
        }
    }

    function getPackagePlansLength() external view returns (uint){
        return packagePlanIds.length;
    }


    /**
     * @notice get all package plans
     * @return packagePlans return array of package plans
     */
    function getAllPackagePlans(uint cursor, uint length) external view returns(PackagePlan[] memory){
        PackagePlan[] memory output = new PackagePlan[](length);
        for (uint n = cursor;  n < length;  n = n + 1) {
            output[n] = planIdToPackagePlan[packagePlanIds[n]];
        }
        return output;
    }
    

    /**
     * @notice purchases an insurance package 
     * @param _planId      id of the package plan 
     * @param _amount the amount deposited
     * @param _insureCoin the insureCoin choosen by the user
     * @param _paymentToken the payment token deposited
     */
    function insure
    (
        bytes32 _planId,
        uint _amount,
        address[] memory path,
        string memory _insureCoin,
        string memory _paymentToken
        ) public{
        require(planIdToPackagePlan[_planId].isActivated, "Rance Protocol: PackagePlan not active");
        require(insureCoinAdded[insureCoinNameToAddress[_insureCoin]], "Rance Protocol:insureCoin not supported");
        require(paymentTokenAdded[paymentTokenNameToAddress[_paymentToken]], "Rance Protocol:paymentToken not supported");
        uint insureAmount = getInsureAmount(_planId, _amount);
        uint insuranceFee = _amount.sub(insureAmount);
        address paymentToken = paymentTokenNameToAddress[_paymentToken];
        address insureCoin = insureCoinNameToAddress[_insureCoin];

        totalInsuranceLocked[paymentToken] += insureAmount;
        uint startTimestamp = block.timestamp;
        uint endTimestamp = (block.timestamp).add(uint(planIdToPackagePlan[_planId].periodInSeconds));
        bytes32 _packageId = keccak256(abi.encodePacked(
            msg.sender,
            insureAmount,
            startTimestamp,
            endTimestamp,
            paymentToken,
            insureCoin));

        require(packageIdToPackage[_packageId].packageId != _packageId, "Rance Protocol: Package exist");

        Package memory package = Package({
            user: msg.sender,
            planId: _planId,
            packageId: _packageId,
            initialDeposit: insureAmount,
            insureOutput: uniswapRouter.getAmountsOut(insureAmount, path)[path.length - 1],
            startTimestamp: startTimestamp,
            endTimestamp: endTimestamp,
            isCancelled: false,
            isWithdrawn: false,
            insureCoin: insureCoin,
            paymentToken: paymentToken
        });

        packageIdToPackage[_packageId] = package;
        userToPackageIds[msg.sender].push(_packageId);
        
        IERC20Upgradeable(paymentToken).safeTransferFrom(msg.sender, address(this), _amount);
        IERC20Upgradeable(paymentToken).approve(address(treasury), insuranceFee);
        IERC20Upgradeable(paymentToken).safeTransfer(address(treasury), insuranceFee);
        _swap(msg.sender, path, insureAmount);

        emit InsuranceActivated(
            _packageId,
            msg.sender
        );
    }


    /**
     * @notice purchases an insurance package with referrer
     * @param _planId id of the package plan 
     * @param _amount the amount deposited
     * @param _insureCoin the insureCoin choosen by the user
     * @param _paymentToken the payment token deposited
     * @param _referrer the referrer address
     */
    function insureWithReferrer(
        bytes32 _planId,
        uint _amount,
        address[] memory path,
        string memory _insureCoin,
        string memory _paymentToken,
        address _referrer
    ) external {
        require(_referrer != address(0), "Rance Protocol: Address 0 is not allowed");
        require(getUserPackagesLength(msg.sender) == 0 && _referrer != msg.sender, "Rance Protocol: Not Referrable");
        address _token = paymentTokenNameToAddress[_paymentToken];
        bytes32 _referralId = keccak256(abi.encodePacked(
            msg.sender,
            _referrer,
            _token,
            block.timestamp
        ));

        require(referrals[_referralId].id != _referralId, "Rance Protocol: Referral exist");
        uint insureAmount = getInsureAmount(_planId, _amount);
        uint insuranceFee = _amount.sub(insureAmount);
        uint referralReward = (insuranceFee.mul(referralPercentage)).div(100);

        ReferralReward memory referral = ReferralReward({
            id: _referralId,
            rewardAmount: referralReward,
            timestamp: block.timestamp,
            token: _token,
            referrer: _referrer,
            user: msg.sender,
            claimed: false
        });

        referrals[_referralId] = referral;
        userToReferralIds[_referrer].push(_referralId);
        insure(_planId, _amount, path, _insureCoin, _paymentToken);
        
        emit Referred(_referrer, msg.sender, referralReward, block.timestamp);
    }

    

    function getUserPackagesLength(address _user) public view returns (uint){
        return userToPackageIds[_user].length;
    }


    function getUserReferralsLength(address _user) external view returns (uint){
        return userToReferralIds[_user].length;
    }

    /**
     * @notice get all user packages
     * @return Package return array of user packages
     */
    function getAllUserPackages(address _user, uint cursor, uint length) external view returns(Package[] memory) {
        Package[] memory output = new Package[](length);
        for (uint n = cursor;  n < length;  n = n + 1) {
            output[n] = packageIdToPackage[userToPackageIds[_user][n]];
        }
        
        return output;
    }


    /**
     * @notice get all user referrals
     * @return Package return array of user referrals
     */
    function getAllUserReferrals(address _user, uint cursor, uint length) external view returns(ReferralReward[] memory) {
        ReferralReward[] memory output = new ReferralReward[](length);
        for (uint n = cursor;  n < length;  n = n + 1) {
            output[n] = referrals[userToReferralIds[_user][n]];
        }
        
        return output;
    }



    /**
     * @notice cancel insurance package
     * @param _packageId id of package to cancel
     */
    function cancel(bytes32 _packageId) external nonReentrant{
        require(packageIdToPackage[_packageId].packageId == _packageId, "Rance Protocol: Package does not exist");

        Package storage userPackage = packageIdToPackage[_packageId];
        require(isPackageActive(userPackage) && 
        !userPackage.isCancelled, "Rance Protocol: Package Not Cancellable");

        userPackage.isCancelled = true;
        userPackage.isWithdrawn = true;
        totalInsuranceLocked[userPackage.paymentToken] -= userPackage.initialDeposit;

        IERC20Upgradeable(userPackage.insureCoin).safeTransferFrom(
            msg.sender,
            address(treasury),
            userPackage.insureOutput
        );

        RANCE.safeTransferFrom(
            msg.sender,
            address(treasury), 
            planIdToPackagePlan[userPackage.planId].uninsureFee
        );

        treasury.withdrawToken(
            userPackage.paymentToken, 
            msg.sender, 
            userPackage.initialDeposit
        );     

       
        emit InsuranceCancelled(
            _packageId, 
            msg.sender
        );
    }


    /**
     * @notice withdraw insurance package
     * @param _packageId id of package to withdraw
     */
    function withdraw(bytes32 _packageId) external nonReentrant{
        require(packageIdToPackage[_packageId].packageId == _packageId, "Rance Protocol: Package does not exist");

        Package storage userPackage = packageIdToPackage[_packageId];
        require(!isPackageActive(userPackage) && 
        !userPackage.isWithdrawn && !userPackage.isCancelled && 
        block.timestamp <= userPackage.endTimestamp.add(30 days),
         "Rance Protocol: Package Not Withdrawable");

        userPackage.isWithdrawn = true;
        totalInsuranceLocked[userPackage.paymentToken] -= userPackage.initialDeposit;

        IERC20Upgradeable(userPackage.insureCoin).safeTransferFrom(
            msg.sender,
            address(treasury),
            userPackage.insureOutput
        );

        treasury.withdrawToken(
            userPackage.paymentToken, 
            msg.sender, 
            userPackage.initialDeposit
        );     

        emit InsuranceWithdrawn(
            _packageId, 
           msg.sender
        );
    } 


    /**
     * @notice claim referral reward
     * @param _referralIds ids of referrals to claim
     */
    function claimReferralReward(bytes32[] memory _referralIds) external nonReentrant{

        for(uint i; i < _referralIds.length; i++){
            require(referrals[_referralIds[i]].id == _referralIds[i], "Rance Protocol: Package does not exist");

            ReferralReward storage referral = referrals[_referralIds[i]];
            require(!referral.claimed && referral.referrer == msg.sender , "Rance Protocol: Referral reward Not Claimable");

            referral.claimed = true;

            treasury.withdrawToken(
                referral.token, 
                msg.sender, 
                referral.rewardAmount
            );     

            emit RewardClaimed(msg.sender, _referralIds[i], referral.rewardAmount);
        }
    } 


    /**
     * @notice get the calculated insure Amount
     * @param _planId id of the package plan
     * @param _amount amount to be calculate
     * @return insureAmount return the insure Amount from amount 
     */
    function getInsureAmount(
        bytes32 _planId, 
        uint _amount) public view returns(uint){
        require(planIdToPackagePlan[_planId].planId == _planId, "RanceProtocol: Plan does not exist");
        PackagePlan memory packagePlan = planIdToPackagePlan[_planId];
        uint percentage = packagePlan.insuranceFee; 
        uint numerator = _amount.mul(100);
        uint denominator = percentage.add(100);
        uint insureAmount = numerator.div(denominator);
        return insureAmount;
    }

    

    function _swap(
        address _to,
        address[] memory path,
        uint _amount
    ) private{
        uint deadline = block.timestamp;
        uint amountOutMin = uniswapRouter.getAmountsOut(_amount, path)[path.length - 1];
        uniswapRouter.swapExactTokensForTokens(_amount, amountOutMin, path, _to, deadline);
    }


    function isPackageActive(Package memory package) public view returns(bool){
        return block.timestamp <= package.endTimestamp;
    }

}