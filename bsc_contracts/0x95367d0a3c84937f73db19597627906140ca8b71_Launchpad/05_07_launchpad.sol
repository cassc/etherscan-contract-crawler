pragma solidity ^0.8.0;

import "./utils/IBEP20.sol";
import "./WKDCommit.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract Launchpad is Ownable {
    // // The offering token
    IBEP20 public offeringToken;
    // check initialized
    bool public isInitialized;
    // The block number when the IFO starts
    uint256 public StartBlock;
    // The block number when the IFO ends
    uint256 public EndBlock;
    // pecrcentage of offering token to be distributed for tier 1
    uint256 public tier1Percentage;
    // pecrcentage of offering token to be distributed for tier 2
    uint256 public tier2Percentage;
    // admin address
    address public admin;
    uint256 public raisedAmount;
    // WKDCommit contract
    WKDCommit public wkdCommit;
    // Participants
    address[] public participants;
    // Pools details
    LaunchpadDetails public launchPadInfo;
    // launchpads share in amount raised
    uint256 public launchPercentShare;
    // Project owner's address
    address public projectOwner;

    struct LaunchpadDetails {
        // amount to be raised in BNB
        uint256 raisingAmount;
        // amount of offering token to be offered in the pool
        uint256 offeringAmount;
        // amount of WKD commit for tier2
        uint256 minimumRequirementForTier2;
        // amount of offering token to be shared in tier1
        uint256 tier1Amount;
        // amount of offering token to be shared in tier2
        uint256 tier2Amount;
    }

    enum userTiers {
        Tier1,
        Tier2
    }

    struct userDetails {
        // amoount of BNB deposited by user
        uint256 amountDeposited;
        // user tier
        userTiers userTier;
        // if useer has claimed offering token
        bool hasClaimed;
    }

    mapping(address => userDetails) public user;

    event Deposit(address indexed user, uint256 amount);
    event AdminTokenRecovery(address tokenRecovered, uint256 amount);
    event init(
        address indexed offeringToken,
        uint256 StartBlock,
        uint256 EndBlock,
        address admin,
        address wkdCommit,
        uint256 raisingAmount,
        uint256 offeringAmount
    );
    event ProjectWithdraw(address indexed projectOwner, uint256 amount);
    event Claimed(address indexed user, uint256 offeringTokenAmount);
    event FinalWithdraw(address admin, uint256 BNBAmount, uint256 offeringTokenAmount);
    //  Custom errors

    error NotAllowed();
    error NotPermitted();
    error NotInitialized();
    error InvalidPercentage();
    error NotStarted();
    error NotEnded();
    error TargetCompleted();
    error AlreadyClaimed();
    error NotEnoughAmount();
    error NotDeposited();
    error NoWKDCommit();
    error NotEnoughOfferingToken();
    error InvalidAddress();
    error InvalidTime();

    function initialize(
        address _offeringToken,
        uint256 _startBlock,
        uint256 _endBlock,
        address _adminAddress,
        address _projectOwner,
        address _wkdCommit,
        uint256 _offeringAmount,
        uint256 _raisingAmount,
        uint256 _launchPercentShare,
        uint256 _tier2Percentage,
        uint256 _minimumRequirementForTier2
    ) public {
        if (msg.sender != owner()) revert NotPermitted();
        if (isInitialized) revert NotInitialized();
        if (_launchPercentShare > 100) revert InvalidPercentage();
        if (_tier2Percentage > 100) revert InvalidPercentage();
        if (_offeringToken == address(0)) revert InvalidAddress();
        if (_adminAddress == address(0)) revert InvalidAddress();
        if (_projectOwner == address(0)) revert InvalidAddress();
        if (_wkdCommit == address(0)) revert InvalidAddress();
        if (_startBlock <= block.number) revert InvalidTime();
        if (_endBlock <= _startBlock) revert InvalidTime();

        launchPadInfo.offeringAmount = _offeringAmount;
        launchPadInfo.raisingAmount = _raisingAmount;
        launchPercentShare = _launchPercentShare;
        launchPadInfo.minimumRequirementForTier2 = _minimumRequirementForTier2;
        tier2Percentage = _tier2Percentage;
        tier1Percentage = 100 - _tier2Percentage;
        launchPadInfo.tier2Amount = _offeringAmount * (_tier2Percentage) / 100;
        launchPadInfo.tier1Amount = (_offeringAmount * (100 - _tier2Percentage)) / 100;

        offeringToken = IBEP20(_offeringToken);
        isInitialized = true;
        StartBlock = _startBlock;
        EndBlock = _endBlock;
        admin = _adminAddress;
        projectOwner = _projectOwner;
        wkdCommit = WKDCommit(_wkdCommit);
        emit init(_offeringToken, _startBlock, _endBlock, _adminAddress, _wkdCommit, _raisingAmount, _offeringAmount);
    }

    function deposit() public payable {
        if (!isInitialized) revert NotInitialized();
        if (block.number < StartBlock) revert NotStarted();
        if (block.number > EndBlock) revert NotEnded();
        if (launchPadInfo.raisingAmount == raisedAmount) {
            revert TargetCompleted();
        }
        uint256 userCommit = wkdCommit.getUserCommit(msg.sender);
        if (userCommit == 0) revert NoWKDCommit();
        if (msg.value == 0) revert NotEnoughAmount();
        if (userCommit >= launchPadInfo.minimumRequirementForTier2) {
            user[msg.sender].userTier = userTiers.Tier2;
        } else {
            user[msg.sender].userTier = userTiers.Tier1;
        }
        participants.push(msg.sender);
        user[msg.sender].amountDeposited = user[msg.sender].amountDeposited + msg.value;
        raisedAmount += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function claimToken() public {
        if (!isInitialized) revert NotInitialized();
        if (block.number < StartBlock) revert NotStarted();
        if (block.number < EndBlock) revert NotEnded();
        if (user[msg.sender].amountDeposited == 0) revert NotDeposited();
        if (user[msg.sender].hasClaimed) revert AlreadyClaimed();
        if (user[msg.sender].userTier == userTiers.Tier1) {
            uint256 amount =
                (launchPadInfo.tier1Amount * user[msg.sender].amountDeposited) / launchPadInfo.raisingAmount;
            offeringToken.transfer(msg.sender, amount);
            user[msg.sender].hasClaimed = true;
            emit Claimed(msg.sender, amount);
        } else if (user[msg.sender].userTier == userTiers.Tier2) {
            uint256 amount =
                (launchPadInfo.tier2Amount * user[msg.sender].amountDeposited) / launchPadInfo.raisingAmount;
            offeringToken.transfer(msg.sender, amount);
            user[msg.sender].hasClaimed = true;
            emit Claimed(msg.sender, amount);
        }
    }

    function sendOfferingToken(uint256 _offeringAmount) public {
        if (!isInitialized) revert NotInitialized();
        if (msg.sender != admin) revert NotAllowed();
        // i+f(!offeringToken.balanceOf(address(this)) < _offeringAmount) revert NotEnoughOfferingToken();
        offeringToken.transfer(msg.sender, _offeringAmount);
    }

    function finalWithdraw() public {
        if (!isInitialized) revert NotInitialized();
        if (msg.sender != admin) revert NotAllowed();
        if (block.number < EndBlock) revert NotEnded();
        uint256 offeringTokenAmount = offeringToken.balanceOf(address(this));
        uint256 launchPadShare = (raisedAmount * launchPercentShare) / 100;
        uint256 adminShare = raisedAmount - launchPadShare;
        payable(admin).transfer(adminShare);
        payable(projectOwner).transfer(launchPadShare);
        offeringToken.transfer(msg.sender, offeringTokenAmount);
        emit FinalWithdraw(admin, adminShare, offeringTokenAmount);
    }

    function getLaunchPadInfo()
        public
        view
        returns (
            uint256 _offeringAmount,
            uint256 _raisingAmount,
            uint256 _tier1Amount,
            uint256 _tier2Amount,
            uint256 _minimumRequirementForTier2,
            uint256 _tier1Percentage,
            uint256 _tier2Percentage,
            uint256 _launchPercentShare
        )
    {
        _offeringAmount = launchPadInfo.offeringAmount;
        _raisingAmount = launchPadInfo.raisingAmount;
        _tier1Amount = launchPadInfo.tier1Amount;
        _tier2Amount = launchPadInfo.tier2Amount;
        _minimumRequirementForTier2 = launchPadInfo.minimumRequirementForTier2;
        _tier1Percentage = tier1Percentage;
        _tier2Percentage = tier2Percentage;
        _launchPercentShare = launchPercentShare;
    }

    // get the amount of offering token to be distributed to user
    function getOfferingTokenAmount(address _user) public view returns (uint256) {
        getUserTier(_user);
        return (user[_user].amountDeposited * launchPadInfo.offeringAmount) / launchPadInfo.raisingAmount;
    }

    function hasClaimed(address _user) public view returns (bool) {
        return user[_user].hasClaimed;
    }

    function getParticipantsLength() public view returns (uint256) {
        return participants.length;
    }

    function getUserTier(address _user) public view returns (userTiers) {
        return user[_user].userTier;
    }

    function getTier1Amount() public view returns (uint256) {
        return launchPadInfo.tier1Amount;
    }

    function getUserDeposit() public view returns (uint256) {
        return user[msg.sender].amountDeposited;
    }

    // Calculate amount of offering token to be distributed in tier2
    function getTier2Amount() public view returns (uint256) {
        return launchPadInfo.tier2Amount;
    }

    function getUserDetails(address _user) public view returns (uint256, uint256, bool, userTiers) {
        return (
            user[_user].amountDeposited, getOfferingTokenAmount(_user), user[_user].hasClaimed, user[_user].userTier
        );
    }

    /**
     * @notice Get current Time
     */
    function getCurrentTime() public view returns (uint256) {
        return block.timestamp;
    }

    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw (18 decimals)
     * @param _tokenAmount: the number of token amount to withdraw
     * @dev This function is only callable by admin.
     */
    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount) external {
        if (msg.sender != admin) revert NotAllowed();
        require(_tokenAddress != address(offeringToken), "Recover: Cannot be offering token");
        IBEP20(_tokenAddress).transfer(msg.sender, _tokenAmount);
        emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
    }
}