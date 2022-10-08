// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IPYESwapRouter.sol";
import "./interfaces/IApple.sol";

contract ModClaimV3 is Ownable, ReentrancyGuard {

    using SafeERC20 for IERC20;
    using SafeMath for uint;

    IPYESwapRouter public PYESwapRouterInterface;
    IApple public AppleInterface;
    address public PYESwapRouterAddress = 0x98Cc2Cd55Ca2092034146EBD8eb043F9f976623a;
    address public AppleAddress = 0xF65Ae63D580EDe49589992b6E772b48E61EaDed2;
    address public WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    bool public paymentsEnabled;

    struct Moderator {
        address modAddress; // address is added to struct to easily prevent duplicates (see first require check in addMod()), or if mod requests to change wallets.
        uint startTime; // when their mod service begins
        uint lastClaim; // last timestamp mod was paid
        uint paymentMultiplier; // USD value intended for mod
        bool applePaymentEnabled;
        bool BUSDPaymentEnabled;
        bool activeModerator; // temporairly or permanently disable a mod. If false, mod cannot get paid.
    }

    mapping(address => Moderator) public Moderators;

    event AppleClaimed(address _claimer, uint _amount);
    event BUSDClaimed(address _claimer, uint _amount);
    event ModeratorAdded(address _moderator, uint _paymentMultiplier, uint _timestamp);
    event ModeratorDisabled(address _moderator, uint _timestamp);
    event ModeratorReactivated(address _moderator, uint _timestamp);
    event PaymentMethodSwitched(address _moderator, uint _timestamp);
    event PaymentAmountChanged(address _moderator, uint _timestamp);

    constructor() {
        PYESwapRouterInterface = IPYESwapRouter(PYESwapRouterAddress);
        AppleInterface = IApple(AppleAddress);
        paymentsEnabled = true;
    }

    modifier zeroAddressCheck(address _address) {
        require(_address != address(0) , "Cannot enter zero address!");
        require(Moderators[_address].modAddress != address(0) , "Mod has not been set yet!");
        _;
    }

    modifier isMod(address _address) {
        require(Moderators[_address].activeModerator , 
        "Error: not an active mod");
        _;
    }

    modifier isNotMod(address _address) {
        require(!Moderators[_address].activeModerator , 
        "Error: member is an active mod!");
        _;
    }

    modifier timeCheck() {
        require((block.timestamp.sub(Moderators[msg.sender].startTime).div(604800)) >= 1 , "Must be a mod for 1 week");
        require(block.timestamp.sub(Moderators[msg.sender].lastClaim) >= 604800 , "Must wait 1 week between payments");
        _;
    }

    function addMod(
        address _newModerator,
        uint _startTime,
        uint _paymentMultiplier,
        bool _applePaymentEnabled,
        bool _BUSDPaymentEnabled,
        bool _activeModerator
    ) external onlyOwner {

        require(_newModerator != address(0));
        require(_startTime != 0 , "Cannot enter zero start date");
        require(_paymentMultiplier != 0 , "Cannot enter zero payment multiplier");
        require(Moderators[_newModerator].modAddress == address(0) , 
        "This address has already been set as a mod!");
        require(_applePaymentEnabled || _BUSDPaymentEnabled, "Must set one payment method as true!");
        require(_applePaymentEnabled != _BUSDPaymentEnabled , "Cannot set both payment methods as true!");
        
        Moderators[_newModerator].modAddress = _newModerator;
        Moderators[_newModerator].startTime = _startTime;
        Moderators[_newModerator].lastClaim = _startTime;
        Moderators[_newModerator].paymentMultiplier = _paymentMultiplier;
        Moderators[_newModerator].applePaymentEnabled = _applePaymentEnabled;
        Moderators[_newModerator].BUSDPaymentEnabled = _BUSDPaymentEnabled;
        Moderators[_newModerator].activeModerator = _activeModerator;

        emit ModeratorAdded(_newModerator, _paymentMultiplier, block.timestamp);
    }

    function disableMod(address _currentMod) external onlyOwner zeroAddressCheck(_currentMod) isMod(_currentMod) {
        Moderators[_currentMod].activeModerator = false;
        emit ModeratorDisabled(_currentMod, block.timestamp);
    }

    function reactivateMod(address _disabledMod) external onlyOwner zeroAddressCheck(_disabledMod) isNotMod(_disabledMod) {
        Moderators[_disabledMod].activeModerator = true;
        emit ModeratorReactivated(_disabledMod, block.timestamp);
    }

    // functions like a binary switch
    function switchModPaymentMethod(address _moderator) external onlyOwner zeroAddressCheck(_moderator) isMod(_moderator) {

        if (Moderators[_moderator].applePaymentEnabled) {
            Moderators[_moderator].applePaymentEnabled = false;
            Moderators[_moderator].BUSDPaymentEnabled = true;
            emit PaymentMethodSwitched(_moderator, block.timestamp);
        } else if (Moderators[_moderator].BUSDPaymentEnabled) {
            Moderators[_moderator].BUSDPaymentEnabled = false;
            Moderators[_moderator].applePaymentEnabled = true;
            emit PaymentMethodSwitched(_moderator, block.timestamp);
        }
    }

    function setModeratorWallet(address _currentWallet, address _newWallet) external onlyOwner zeroAddressCheck(_currentWallet) isMod(_currentWallet) {
        require(_currentWallet != _newWallet && _newWallet != address(0), 
        "New wallet is the same as the old one, or you entered zero address");

        uint currentStartTime = Moderators[_currentWallet].startTime;
        uint currentLastClaim = Moderators[_currentWallet].lastClaim;
        uint currentPaymentMultiplier = Moderators[_currentWallet].paymentMultiplier;
        bool currentApplePaymentStatus = Moderators[_currentWallet].applePaymentEnabled;
        bool currentBUSDPaymentStatus = Moderators[_currentWallet].BUSDPaymentEnabled;
        bool currentActiveModStatus = Moderators[_currentWallet].activeModerator;
            
        Moderators[_currentWallet].activeModerator = false;
        Moderators[_newWallet].modAddress = _newWallet;
        Moderators[_newWallet].startTime = currentStartTime;
        Moderators[_newWallet].lastClaim = currentLastClaim;
        Moderators[_newWallet].paymentMultiplier = currentPaymentMultiplier;
        Moderators[_newWallet].applePaymentEnabled = currentApplePaymentStatus;
        Moderators[_newWallet].BUSDPaymentEnabled = currentBUSDPaymentStatus;
        Moderators[_newWallet].activeModerator = currentActiveModStatus;
    }

    function adjustPaymentMultiplier(address _moderator, uint _paymentMultiplier) external onlyOwner zeroAddressCheck(_moderator) isMod(_moderator) {
        Moderators[_moderator].paymentMultiplier = _paymentMultiplier;
        emit PaymentAmountChanged(_moderator, block.timestamp);
    }

    function setStartTime(address _moderator, uint _startTime) external onlyOwner zeroAddressCheck(_moderator) isMod(_moderator) {
        Moderators[_moderator].startTime = _startTime;        
    }

    function setLastClaim(address _moderator, uint _lastClaim) external onlyOwner zeroAddressCheck(_moderator) isMod(_moderator) {
        Moderators[_moderator].lastClaim = _lastClaim;        
    }

    function withdrawBUSD() external onlyOwner {
        uint bal = IERC20(BUSD).balanceOf(address(this));
        IERC20(BUSD).safeTransfer(msg.sender, bal);
    }

    function setBUSD(address _BUSD) external onlyOwner {
        BUSD = _BUSD;
    }

    function setAppleAndPair(address _Apple, address _PYESwapRouter) external onlyOwner {
        AppleAddress = _Apple;
        PYESwapRouterAddress = _PYESwapRouter;
        AppleInterface = IApple(_Apple);
        PYESwapRouterInterface = IPYESwapRouter(_PYESwapRouter);
    }

    function disableAllPayments() external onlyOwner {
        require(paymentsEnabled , "Payments are already disabled");
        paymentsEnabled = false;
    }

    function enableAllPayments() external onlyOwner {
        require(!paymentsEnabled , "Payments are already enabled");
        paymentsEnabled = true;
    }

    // ------------------------- PAYMENT FUNCTIONS --------------------------------------

    function calculateAppleTokens(address _moderator) internal view returns (uint) {
        
        uint multiplier = Moderators[_moderator].paymentMultiplier * 10**18;
        uint finalPayment;

        address[] memory path = new address[](3);
        path[0] = AppleAddress;
        path[1] = WBNB;
        path[2] = BUSD;

        finalPayment = PYESwapRouterInterface.getAmountsIn(multiplier, path, 0)[0];
        return (finalPayment);
    }

    function getPaid() external nonReentrant isMod(msg.sender) timeCheck() {

        require(paymentsEnabled , "Payments are turned off!");
        uint timeMultiple = (block.timestamp.sub(Moderators[msg.sender].lastClaim)).div(604800);

        if (Moderators[msg.sender].applePaymentEnabled && !Moderators[msg.sender].BUSDPaymentEnabled) {
            uint payment = calculateAppleTokens(msg.sender);
            AppleInterface.mint(msg.sender, (payment * timeMultiple));
            Moderators[msg.sender].lastClaim = Moderators[msg.sender].lastClaim.add(604800 * timeMultiple);
            emit AppleClaimed(msg.sender, payment * timeMultiple);
        } else if (!Moderators[msg.sender].applePaymentEnabled && Moderators[msg.sender].BUSDPaymentEnabled) {
            uint payment = (Moderators[msg.sender].paymentMultiplier) * 10**18 * timeMultiple;
            require(IERC20(BUSD).balanceOf(address(this)) >= payment , "Amt exceeds contract BUSD");
            IERC20(BUSD).safeTransfer(msg.sender, payment);
            Moderators[msg.sender].lastClaim = Moderators[msg.sender].lastClaim.add(604800 * timeMultiple);
            emit BUSDClaimed(msg.sender, payment);
        }
    }
}