/**
 *Submitted for verification at BscScan.com on 2023-05-10
*/

//SPDX-License-Identifier: No

pragma solidity  = 0.8.19;

//--- Context ---//
abstract contract Context {
    constructor() {
    }

    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}


//--- Pausable ---//
abstract contract Pausable is Context {

    event Paused(address account);

    event Unpaused(address account);

    bool private _paused;

    constructor() {
        _paused = false;
    }

    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    modifier whenPaused() {
        _requirePaused();
        _;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}


//--- Ownable ---//
abstract contract Ownable is Context {
    address private _owner;
    address private _multiSig;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event MultiSigTransferred(address indexed oldMultiSig, address indexed newMultiSig);

    constructor() {
        _setOwner(_msgSender());
        _setMultiSig(_msgSender());
    }

    function multisig() public view virtual returns (address) {
        return _multiSig;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender() || multisig() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    modifier onlyMultiSignature() {
        require(multisig() == _msgSender(), "Ownable: caller is not the multisig");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function transferMultiSig(address newMultiSig) public virtual onlyMultiSignature {
        require(newMultiSig != address(0), "Ownable: new owner is the zero address");
        _setMultiSig(newMultiSig);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function _setMultiSig(address newMultiSig) private {
        address oldMultiSig = _multiSig;
        _multiSig = newMultiSig;
        emit MultiSigTransferred(oldMultiSig, newMultiSig);
    }
}


//--- Interface for ERC20 ---//
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract Staking is Context, Pausable, Ownable {

    event staking(uint256 amount); 
    event WithdrawFromStaking(uint256 amount);
    event ClaimRewards(uint256 amount);

    uint256 public TokenDedicatiAlloStaking; // Modalità 1: Fixed amount of tokens staked.
    uint256 public safeSeconds = 15;
    uint256 public totalSupply; // amount of all token staked
    bool public isStakingLive = false;
    uint256 private dayzero;
    uint256 private preApproval;
    bool public Initalized = false;
    mapping(address => uint256) private rewardsGiaPagati;
    mapping(address => uint256) private rewards;
    mapping(address => uint256) private quandoStake;
    mapping(address => uint256) private quandoWithdraw;
    mapping(address => uint256) private lastTimeStaked;
    mapping(address => uint256) private holdingXstaking;
    mapping(address => uint256) private lastClaimRewards;

    mapping(address => bool) private AlreadyStaked;
    uint256 private interestperDay;

    constructor (

    ) {
        
    }
    
    IERC20 public Token;

    function setToken(address _token) external onlyMultiSignature {
        require(!Initalized);
        Token = IERC20(_token);
        Initalized = true;
    }

    function unPause() external onlyMultiSignature {
        _unpause();
    }

    function setTokenDedicatiAlloStaking(uint256 amount) external onlyOwner {
        uint256 tempBalance = Token.balanceOf(msg.sender);
        require(tempBalance >= amount,"Not enough tokens");
        Token.transferFrom(msg.sender, address(this), amount);
        TokenDedicatiAlloStaking += amount;
    }

    function setStakingLive() external onlyOwner {
        require(!isStakingLive,"Staking is already live");
        isStakingLive = true;
    }


    function reset() external onlyMultiSignature {
        uint256 tempBalance = Token.balanceOf(address(this));
        interestperDay = 0;
        TokenDedicatiAlloStaking = 0;
        isStakingLive = false;
        _pause();
        if(tempBalance > 0) {
            Token.transfer(msg.sender, tempBalance);
        }
    }

    function stakeprivate(uint256 amount) private {
        uint256 tempBalance = Token.balanceOf(msg.sender);
        require(isStakingLive,"Staking is not live");
        require(tempBalance >= amount,"Not enough tokens");
        Token.transferFrom(msg.sender, address(this), amount);
        holdingXstaking[msg.sender] += amount;
        totalSupply += amount;
        quandoStake[msg.sender] = block.timestamp; // Quando stake in secondi. https://www.site24x7.com/tools/time-stamp-converter.html
        AlreadyStaked[msg.sender] = true;
    }

    function canInteract() internal view {
        if(pend(msg.sender) >= holdingXstaking[msg.sender] / 1000) { revert("Claim Rewards, you have at least 0.1% rewards to claim"); }
    }

    function stake(uint256 amount) external whenNotPaused {
        require(msg.sender != address(0),"Freddy: Address zero");
        require(isStakingLive,"Staking is not live yet.");
        if(AlreadyStaked[msg.sender]) {
            canInteract();
        }

        stakeprivate(amount);

    emit staking(amount);

    }


    function withdraw(uint256 amount) external whenNotPaused {
        
        require(msg.sender != address(0),"Freddy: Address zero");
        require(amount > 0, "Amunt should be greater than 0");
        require(holdingXstaking[msg.sender] >= amount,"Not enough tokens");
        canInteract();
        safe();

            holdingXstaking[msg.sender] -= amount; 
            totalSupply -= amount;
            Token.transfer(msg.sender, amount);


        quandoWithdraw[msg.sender] = block.timestamp;
        bool goingtozero = holdingXstaking[msg.sender] == 0;
        if(goingtozero) {
        resetUser(); }

        emit WithdrawFromStaking(amount);
    }



    function resetUser() private {
            AlreadyStaked[msg.sender] = false;
            rewards[msg.sender] = 0;
            rewardsGiaPagati[msg.sender] = 0;
            lastClaimRewards[msg.sender] = 0;
            quandoStake[msg.sender] = 0;
            holdingXstaking[msg.sender] = 0;
    }

    
    function calculateRewards() private {
        interestperDay = 8219178083; uint256 interestPerSecond = interestperDay / 86400; uint256 interest =
        (block.timestamp - quandoStake[msg.sender]) * interestPerSecond;
        rewards[msg.sender] = (holdingXstaking[msg.sender] * interest);
        rewards[msg.sender] = checkZeroMath(msg.sender, rewards[msg.sender]);
    }
    
    function safe() private view whenNotPaused {
        require(block.timestamp > lastClaimRewards[msg.sender] + safeSeconds, "Cannot claim in the sameblock");
    }

    function staked() private view {
        if(!AlreadyStaked[msg.sender]) {
            safe();
        }

    }

    function claimReward() public whenNotPaused {
        require(msg.sender != address(0),"Freddy: Address zero");
        calculateRewards();
        staked();

        require(rewards[msg.sender] > 0, "Can't claim less than zero tokens");

        uint256 yourrewards = rewards[msg.sender];

        rewardsGiaPagati[msg.sender] += yourrewards;
        lastClaimRewards[msg.sender] = block.timestamp;
        require(TokenDedicatiAlloStaking > yourrewards,"Token Holders need to be able to get back 100% of the tokens allocated");
        TokenDedicatiAlloStaking -= yourrewards;

        Token.transfer(msg.sender, yourrewards);
        emit ClaimRewards(yourrewards);
    }

    function amountStaked(address holder) external view returns (uint256) {
        return holdingXstaking[holder];
    }

    function rewardsPaid(address holder) external view returns (uint256) {
        return rewardsGiaPagati[holder];
    }

    function whenStaking(address holder) external view returns (uint256) {
        return quandoStake[holder];
    }

    function lastTimeClaim(address holder) external view returns (uint256) {
        return lastClaimRewards[holder];
    }

    function _alreadyStaked(address holder) external view returns (bool) {
        return AlreadyStaked[holder];
    }

    function pend(address account) private view returns (uint256) {
        uint256 interestDailyView = 8219178083; uint256 interestPerSecond = interestDailyView / 86400; uint256 interest =
        
        (block.timestamp - quandoStake[account]) * interestPerSecond;
        uint256 preRewards;
        preRewards = (holdingXstaking[account] * interest);
        preRewards = checkZeroMath(account, preRewards);


        return preRewards;
    }

    function checkZeroMath(address account, uint256 a) internal view returns(uint256) {
        uint256 _return;
        if(((a / 100_000_000_000)) / 100 >= rewardsGiaPagati[account]) {
            _return = ((a / 100_000_000_000)) / 100 - rewardsGiaPagati[account];
        } else {
            _return = 0;
        }
        return _return;
    }
 
    function pendingRewards(address account) external view returns(uint256) {
        return pend(account);
    }


}