// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

contract AjiraPayAirdropDistributor is Ownable, AccessControl, ReentrancyGuard{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    bytes32 constant public MANAGER_ROLE = keccak256('MANAGER_ROLE');

    IERC20 public rewardToken;

    bool public isAirdropActive = false;
    bool public isClaimOpen = false;

    mapping(address => uint) public userRewards;
    mapping(address => bool) public isExistingWinner;
    mapping(address => bool) public hasClaimedRewards;

    uint public maxRewardCapPerUser;
    uint public minRewardCapPerUser;
    uint public tokenDecimals;
    uint public totalRewardsClaimed;
    uint public totalRewardsToBeClaimed;

    address payable public treasury;

    event AirdropActivated(address indexed caller, IERC20 indexed token, uint indexed timestamp);
    event AirdropDeActivated(address indexed caller, IERC20 indexed token, uint indexed timestamp);
    event RewardTokenSet(address indexed caller, IERC20 indexed token, uint timestamp);
    event RewardTokenUpdated(address indexed caller, IERC20 indexed prevToken,IERC20 indexed newToken, uint timestamp);
    event NewWinner(address indexed caller, address indexed winner, uint indexed amount, uint timestamp);
    event ClaimFor(address indexed caller, address indexed beneciary, uint indexed amount, uint timestamp);
    event Claim(address indexed beneficiary, uint indexed amount, uint timestamp);
    event UserRewardUpdated(address indexed caller, address indexed beneficiary, uint prevRewardAmount, uint indexed newRewardAmount, uint timestamp);
    event ClaimsOpened(address indexed caller, uint indexed timestamp);
    event ClaimsClosed(address indexed caller, uint indexed timestamp);
    event UserRewardCancelled(address indexed caller, address indexed beneficiary, uint indexed rewardAmount, uint timestamp);
    event BNBRecovered(address indexed caller, address indexed destinationAccount, uint indexed amount, uint timestamp);
    event ERC20Recovered(address indexed caller, address indexed destinationAccount, uint indexed _amount, IERC20 token, uint timestamp);
    event TreasuryUpdated(address indexed caller, address indexed prevTreasury, address indexed newTreasury, uint timestamp);
    event MinRewardCapUpdated(address indexed caller, uint indexed prevMinRewardCapPerUser, uint indexed newMinRewardCapPerUser, uint timestamp);
    event MaxRewardCapUpdated(address indexed caller, uint indexed prevMaxRewardCapPerUser, uint indexed newMaxRewardCapPerUser, uint timestamp);
    event UnclaimableTokensRecovered(address indexed caller, address indexed destinationAddress, uint indexed tokenAmount, uint timestamp);
    event ClaimBackUnClaimedTokens(address indexed caller, address indexed destinationAddress, uint indexed claimedBalance, uint timestamp);

    modifier isActive(){
        require(isAirdropActive == true,"Airdrop not active");
        _;
    }

    modifier isNotActive(){
        require(isAirdropActive == false,"Airdrop is active");
        _;
    }

    modifier nonZeroAddress(address _account){
        require(_account != address(0),"Invalid Account");
        _;
    }

    modifier isExistingWinnerAccount(address _account){
        require(isExistingWinner[_account] == true,"Not a beneficiary");
        _;
    }

    modifier isNotAnExistingWinnerAccount(address _account){
        require(isExistingWinner[_account] == false,"Account is a beneficiary");
        _;
    }

    modifier hasNotClaimedReward(address _account){
        require(hasClaimedRewards[_account] == false,"Rewards claimed already");
        _;
    }

    modifier claimOpen(){
        require(isClaimOpen == true,"Claim Not Active");
        _;
    }

    modifier claimClosed(){
        require(isClaimOpen == false,"Claim Active");
        _;
    }

    constructor(address _token, address payable _treasury, uint _minRewardCap, uint _maxRewardCap, uint _tokenDecimals){
        require(_tokenDecimals > 0 && _tokenDecimals <= 18,"Invalid Decimals");
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MANAGER_ROLE, _msgSender());
        
        rewardToken = IERC20(_token);
        tokenDecimals = _tokenDecimals;

        minRewardCapPerUser = _minRewardCap.mul(10 ** tokenDecimals);
        maxRewardCapPerUser = _maxRewardCap.mul(10 ** tokenDecimals);
        
        treasury = _treasury;
        totalRewardsClaimed = 0;
        totalRewardsToBeClaimed = 0;
    }

    function activateAirdrop() public onlyRole(MANAGER_ROLE) isNotActive{
        isAirdropActive = true;
        emit AirdropActivated(_msgSender(), rewardToken, block.timestamp);
    }

    function deactivateAirdrop() public onlyRole(MANAGER_ROLE) isActive{
        isAirdropActive = false;
        emit AirdropDeActivated(_msgSender(), rewardToken, block.timestamp);
    }

    function addWinner(address _winner, uint _amount) public nonZeroAddress(_winner) onlyRole(MANAGER_ROLE) isNotAnExistingWinnerAccount(_winner){
        require(_amount > 0,"Amount is zero");
        require(_amount < rewardToken.balanceOf(address(this)) && _amount <= maxRewardCapPerUser,"Cap Reached");
        userRewards[_winner] = userRewards[_winner].add(_amount);
        isExistingWinner[_winner] = true;
        totalRewardsToBeClaimed = totalRewardsToBeClaimed.add(_amount);
        emit NewWinner(_msgSender(), _winner, _amount, block.timestamp);
    }

    function updateWinnerReward(address _winner, uint _newRewardAmount) public nonZeroAddress(_winner) isExistingWinnerAccount(_winner) onlyRole(MANAGER_ROLE) nonReentrant {
        require(_newRewardAmount > 0,"Amount is zero");
        uint256 rewardBefore = userRewards[_winner];
        uint256 totalRewards = rewardBefore.add(_newRewardAmount);
        require(_newRewardAmount < rewardToken.balanceOf(address(this)) && _newRewardAmount <= maxRewardCapPerUser,"Cap Reached");
        require(totalRewards <= rewardToken.balanceOf(address(this)) && totalRewards <= maxRewardCapPerUser,"Cap Reached");
        userRewards[_winner] = rewardBefore.add(_newRewardAmount);
        totalRewardsToBeClaimed = totalRewardsToBeClaimed.add(_newRewardAmount);
        uint256 rewardAfter = userRewards[_winner];
        if(hasClaimedRewards[_winner] == true && rewardAfter >0){
            hasClaimedRewards[_winner] = false;
        } 
        emit UserRewardUpdated(_msgSender(), _winner, rewardBefore, rewardAfter, block.timestamp);
    }

    function claimAirdrop() public{
        (uint256 _claimedRewardAmount) = _performClaim(_msgSender());
        emit Claim(_msgSender(), _claimedRewardAmount, block.timestamp);
    }

    function claimAirdropFor(address _beneficiary) public onlyRole(MANAGER_ROLE) {
        (uint256 _claimedRewardAmount) = _performClaim(_beneficiary);
        emit ClaimFor(_msgSender(),_beneficiary, _claimedRewardAmount, block.timestamp);
    }

    function setRewardToken(address _token) public nonZeroAddress(_token) onlyRole(MANAGER_ROLE) isNotActive{
        rewardToken = IERC20(_token);
        emit RewardTokenSet(_msgSender(), rewardToken, block.timestamp);
    }

    function updateRewardToken(address _token) public nonZeroAddress(_token) onlyRole(MANAGER_ROLE) isNotActive{
        if(IERC20(_token) == rewardToken){ return;}
        IERC20 prevRewardToken = rewardToken;
        rewardToken = IERC20(_token);
        emit RewardTokenUpdated(_msgSender(), prevRewardToken, rewardToken, block.timestamp);
    }

    function updateMinRewardCap(uint _amount) public onlyRole(MANAGER_ROLE) isActive{
        require(_amount > 0,"Invalid Cap Value");
        (uint256 oldMinRewardCap, ) = _getRewardAmountByType();
        oldMinRewardCap = _amount.mul(10 ** tokenDecimals);
        (uint256 updatedMinRewardCap, ) = _getRewardAmountByType();
        emit MinRewardCapUpdated(_msgSender(), oldMinRewardCap, updatedMinRewardCap, block.timestamp);
    }

    function updateMaxRewardCap(uint _amount) public onlyRole(MANAGER_ROLE) isActive{
        require(_amount > 0,"Invalid Cap Value");
        (, uint256 oldMaxRewardCap) = _getRewardAmountByType();
        oldMaxRewardCap = _amount.mul(10 ** tokenDecimals);
        (, uint256 updatedMaxRewardCap) = _getRewardAmountByType();
        emit MaxRewardCapUpdated(_msgSender(), oldMaxRewardCap, updatedMaxRewardCap, block.timestamp);
    }

    function activateClaims() public onlyRole(MANAGER_ROLE) isActive claimClosed{
        isClaimOpen = true;
        emit ClaimsOpened(_msgSender(), block.timestamp);
    }

    function deActivateClaims() public onlyRole(MANAGER_ROLE) isActive claimOpen{
        isClaimOpen = false;
        emit ClaimsClosed(_msgSender(), block.timestamp);
    }

    function getAirdropTotalSupply() public view returns(uint256){
        return _getRewardDistributorBalance();
    }

    function cancelUserRewards(address _account) public onlyRole(MANAGER_ROLE) isExistingWinnerAccount(_account) isActive returns(address, uint256){
        isExistingWinner[_account] = false;
        userRewards[_account] = 0;
        emit UserRewardCancelled(_msgSender(),_account, userRewards[_account], block.timestamp);
        return (_account, userRewards[_account]);
    }

    receive() external payable{}

    function recoverBNB() public onlyRole(MANAGER_ROLE) nonZeroAddress(_msgSender()) nonReentrant{
        treasury.transfer(address(this).balance);
        emit BNBRecovered(_msgSender(), treasury, address(this).balance, block.timestamp);
    }

    function recoverLostTokensForInvestor(address _token, address _account, uint _amount) public onlyRole(MANAGER_ROLE) nonReentrant nonZeroAddress(_account){
        require(_amount > 0, "Invalid Amount");
        IERC20 token = IERC20(_token);
        require(token != rewardToken,"Invalid Token");
        token.safeTransfer(_account, _amount);
        emit ERC20Recovered(_msgSender(), _account, _amount, token, block.timestamp);
    }

    function recoverTokensNotClaimable() public onlyRole(MANAGER_ROLE) isActive nonReentrant{
        uint256 amount = _getRewardDistributorBalance();
        uint256 unClaimedTokensBeforeClaims = amount.sub(totalRewardsToBeClaimed).mul(10 ** tokenDecimals);
        require(rewardToken.transfer(treasury, unClaimedTokensBeforeClaims),"Token Recovery Failed");
        emit UnclaimableTokensRecovered(_msgSender(), treasury, amount, block.timestamp);
    }

    function recoverUnclaimedTokens() public onlyRole(MANAGER_ROLE) isActive claimClosed{
        uint256 contractTokenBalance = _getRewardDistributorBalance();
        uint256 claimableBalance = contractTokenBalance.sub(totalRewardsToBeClaimed);
        require(claimableBalance > 0,"Insufficient Claimable Balance");
        require(rewardToken.transfer(treasury, claimableBalance),"Total Claims Failed");
        emit ClaimBackUnClaimedTokens(_msgSender(), treasury, claimableBalance, block.timestamp);
    }

    function updateTreasury(address payable _newTreasury) public onlyRole(MANAGER_ROLE) nonZeroAddress(_newTreasury){
        if(payable(_newTreasury) == treasury){ return;}
        address payable prevTreasury = treasury;
        treasury = _newTreasury;
        emit TreasuryUpdated(_msgSender(), prevTreasury, _newTreasury, block.timestamp);
    }

    //Internal functions
    function _performClaim(address _beneficiary) private nonZeroAddress(_beneficiary) isExistingWinnerAccount(_beneficiary) hasNotClaimedReward(_beneficiary) isActive claimOpen nonReentrant returns(uint256){
        uint256 rewardAmount = userRewards[_beneficiary];
        uint256 rewardAmountInWei = rewardAmount.mul(10 ** tokenDecimals);
        require(rewardToken.transfer(_beneficiary,rewardAmountInWei),"Failed to send reward");
        userRewards[_beneficiary] = 0;
        hasClaimedRewards[_beneficiary] = true;
        totalRewardsToBeClaimed = totalRewardsToBeClaimed.sub(rewardAmount);
        totalRewardsClaimed = totalRewardsClaimed.add(rewardAmount);
        return rewardAmount;
    }

    function _getRewardAmountByType() private view returns(uint256, uint256){
        return (minRewardCapPerUser, maxRewardCapPerUser);
    }

    function _getRewardDistributorBalance() private view returns(uint256){
        return rewardToken.balanceOf(address(this));
    }
}