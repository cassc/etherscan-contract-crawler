/**
 *Submitted for verification at BscScan.com on 2023-04-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

interface ISTAKEv1 {
    function getUserMBPAmountStaked(address _addr) external view returns (uint256);
    function getUserDKSAmountStaked(address _addr) external view returns (uint256);
}

interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
}

contract MBP_IDO_STAKING_v3 is Context, IBEP20, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    // MBP Token address (The Native Token 1)
    address private MBP_TOKEN_ADDRESS = 0xaF2F53cc6cc0384aba52275b0f715851Fb5AFf94;
    // DKS Token address (The Native Token 2)
    address private DKS_TOKEN_ADDRESS = 0x121235cfF4c59EEC80b14c1d38B44e7de3A18287;

    address WITHDRAWAL_ADDRESS = 0x014c0fBf5E488cf81876EC350b2Aff32F35C4263;
    
    IBEP20  MBP_TOKEN = IBEP20(
        MBP_TOKEN_ADDRESS
    );
    IBEP20  DKS_TOKEN = IBEP20(
        DKS_TOKEN_ADDRESS
    );

    
    //----------- BEP20 Variables -----------//
    mapping(address => uint256) private _balances;
    uint256 private _totalSupply;
    uint256 private _maxSupply;
    uint8 private _decimals;
    string private _symbol;
    string private _name;
    //---------------------------------------//
    //---------------------------------------//

    constructor() {
        _name = "MobiPad IDO Stake";
        _symbol = "MBP_IDO_STAKE";
        _decimals = 18;
        _totalSupply = 1 * (10**18);
        _balances[msg.sender] = _totalSupply;

        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    //----------- BEP20 Functions -----------//

    function getOwner() external view override returns (address) {
        return owner();
    }
    function decimals() external view override returns (uint8) {
        return _decimals;
    }
    function symbol() external view override returns (string memory) {
        return _symbol;
    }
    function name() external view override returns (string memory) {
        return _name;
    }
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount)
        external
        pure
        override
        returns (bool)
    {
        require(recipient != address(0) && amount > 0, "MBP: Recipient and amount required");
        return false;
    }
    function transferFrom(address sender, address recipient, uint256 amount ) external pure override returns (bool) {
        require(sender != address(0), "MBP: Sender required");
        require(recipient != address(0) && amount > 0, "MBP: Recipient and amount required");
        return false;
    }
    function burn(uint256 amount) external onlyOwner returns (bool) {
        _burnStakeTokens(_msgSender(), amount);
        return true;
    }
    function _mintStakeTokens(address account, uint256 amount) internal {
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    function _burnStakeTokens(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: burn from the zero address");
        _balances[account] = _balances[account].sub(
            amount,
            "BEP20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    //---------------------------------------//
    //---------------------------------------//
    
    uint32 constant SECONDS_IN_DAY = 86400 seconds;

    mapping(address => uint256) private MBP_AMOUNT_STAKED;
    mapping(address => uint256) private DKS_AMOUNT_STAKED;

    mapping(address => uint256) private MBP_STAKE_DAYS;
    mapping(address => uint256) private DKS_STAKE_DAYS;

    mapping(address => bool) private MBP_STAKED;
    mapping(address => bool) private DKS_STAKED;

    uint256 private MBP_TOTAL_STAKERS = 0;

    uint256 private DKS_TOTAL_STAKERS = 0;
    
    uint256 private MINIMUM_MBP_STAKE = 50_000 * (10**18);
    uint256 private MINIMUM_DKS_STAKE = 50_000 * (10**18);

    uint64 private MINIMUM_DAYS_TO_UNSTAKE = 10;

    function getMinimum_MBP_Stake() external view returns (uint256) {
        return MINIMUM_MBP_STAKE;
    }

    function setMinimum_MBP_Stake(uint256 _minimum_MBP_Stake) external onlyOwner {
        MINIMUM_MBP_STAKE = _minimum_MBP_Stake;
    }

    function getMinimum_DKS_Stake() external view returns (uint256) {
        return MINIMUM_DKS_STAKE;
    }

    function setMinimum_DKS_Stake(uint256 _minimum_DKS_Stake) external onlyOwner {
        MINIMUM_DKS_STAKE = _minimum_DKS_Stake;
    }

    function getMinimumDaysToUnStake() external view returns (uint64) {
        return MINIMUM_DAYS_TO_UNSTAKE;
    }

    function setMinimumDaysToUnStake(uint64 _minimumDaysToUnstake) external onlyOwner {
        MINIMUM_DAYS_TO_UNSTAKE = _minimumDaysToUnstake;
    }

    function getWithdrawalAddress() external view returns (address) {
        return WITHDRAWAL_ADDRESS;
    }

    function setWithdrawalAddress(address _addr) external onlyOwner {
        WITHDRAWAL_ADDRESS = _addr;
    }



    //----------- Migration from previous stake contract -----------//
    // For MBP only
    function migrateState(address[] memory stakers) external onlyOwner {
        require(block.timestamp <= 1682578800, "MBP: Migration period over"); //TODO //time migration period

        address STAKEv1_ADDRESS = 0x80600645996f036A8F652dfff1754bAc91B921b4;
        ISTAKEv1  STAKEv1 = ISTAKEv1(
            STAKEv1_ADDRESS
        );
        
        for (uint256 i = 0; i < stakers.length; i++) {
            uint256 userStake = STAKEv1.getUserMBPAmountStaked(stakers[i]);
            if (userStake > 0) {
                migrationHelper(stakers[i], userStake);
            } else {
                continue;
            }
        }
    }
    function migrationHelper(address staker, uint256 _tokenAmount) internal {

        //hasn't staked before
        if(!MBP_STAKED[staker]){
            MBP_STAKE_DAYS[staker] = 1682230216; //TODO //fixed timestamp
            MBP_STAKED[staker] = true;
            MBP_TOTAL_STAKERS = MBP_TOTAL_STAKERS.add(1);
        }

        //add stake detials of user
        MBP_AMOUNT_STAKED[staker] = MBP_AMOUNT_STAKED[staker].add(_tokenAmount);

        //transfer stake token to user
        _mintStakeTokens(staker, _tokenAmount);
    }
    //---------------------------------------//
    //---------------------------------------//



    function stakeMBP(uint256 _tokenAmount) external nonReentrant {
        require(_tokenAmount >= MINIMUM_MBP_STAKE, "MBP: Stake amount too small. Please try a bigger amount");

        //Get user stake
        MBP_TOKEN.transferFrom(msg.sender, address(this), _tokenAmount);

        //hasn't staked before
        if(!MBP_STAKED[msg.sender]){
            MBP_STAKE_DAYS[msg.sender] = block.timestamp;
            MBP_STAKED[msg.sender] = true;
            MBP_TOTAL_STAKERS = MBP_TOTAL_STAKERS.add(1);
        }

        //add stake detials of user
        MBP_AMOUNT_STAKED[msg.sender] = MBP_AMOUNT_STAKED[msg.sender].add(_tokenAmount);

        //transfer stake token to user
        _mintStakeTokens(msg.sender, _tokenAmount);
    }

    function stakeDKS(uint256 _tokenAmount) external nonReentrant {
        require(_tokenAmount >= MINIMUM_DKS_STAKE, "MBP: Stake amount too small. Please try a bigger amount");

        //Get user stake
        DKS_TOKEN.transferFrom(msg.sender, address(this), _tokenAmount);

        //hasn't staked before
        if(!DKS_STAKED[msg.sender]){
            DKS_STAKE_DAYS[msg.sender] = block.timestamp;
            DKS_STAKED[msg.sender] = true;
            DKS_TOTAL_STAKERS = DKS_TOTAL_STAKERS.add(1);
        }

        //add stake detials of user
        DKS_AMOUNT_STAKED[msg.sender] = DKS_AMOUNT_STAKED[msg.sender].add(_tokenAmount);

        //transfer stake token to user
        _mintStakeTokens(msg.sender, _tokenAmount);
    }

    function unstakeMBP(uint256 _tokenAmount) external nonReentrant {
        require(MBP_STAKED[msg.sender], "MBP: You didn't stake MBP");
        require(_tokenAmount <= MBP_AMOUNT_STAKED[msg.sender], "MBP: Amount exceed stake");
        //can't unstake less than minimum
        require(_tokenAmount >= MINIMUM_MBP_STAKE, "MBP: Amount too small. Please try a bigger amount");
        //check for minimum day
        require(
            ((block.timestamp - MBP_STAKE_DAYS[msg.sender]) / SECONDS_IN_DAY) >= MINIMUM_DAYS_TO_UNSTAKE, 
            "MBP: Your stake days isn't up to minimum to unstake"
        );

        if((MBP_AMOUNT_STAKED[msg.sender] - _tokenAmount) < MINIMUM_MBP_STAKE){
            _tokenAmount = MBP_AMOUNT_STAKED[msg.sender];
        }

        if(_tokenAmount == MBP_AMOUNT_STAKED[msg.sender]){
            MBP_STAKE_DAYS[msg.sender] = 0;
            MBP_STAKED[msg.sender] = false;
            MBP_TOTAL_STAKERS = MBP_TOTAL_STAKERS.sub(1);
        }

        //update stake detials of user
        MBP_AMOUNT_STAKED[msg.sender] = MBP_AMOUNT_STAKED[msg.sender].sub(_tokenAmount);

        //send tokens to the investor
        MBP_TOKEN.transfer(msg.sender, _tokenAmount);

        //burn stake tokens
        _burnStakeTokens(msg.sender, _tokenAmount);
    }

    function unstakeDKS(uint256 _tokenAmount) external nonReentrant {
        require(DKS_STAKED[msg.sender], "MBP: You didn't stake DKS");
        require(_tokenAmount <= DKS_AMOUNT_STAKED[msg.sender], "MBP: Amount exceed stake");
        //can't unstake less than minimum
        require(_tokenAmount >= MINIMUM_DKS_STAKE, "MBP: Amount too small. Please try a bigger amount");
        //check for minimum day
        require(
            ((block.timestamp - DKS_STAKE_DAYS[msg.sender]) / SECONDS_IN_DAY) >= MINIMUM_DAYS_TO_UNSTAKE, 
            "MBP: Your stake days isn't up to minimum to unstake"
        );

        if((DKS_AMOUNT_STAKED[msg.sender] - _tokenAmount) < MINIMUM_DKS_STAKE){
            _tokenAmount = DKS_AMOUNT_STAKED[msg.sender];
        }

        if(_tokenAmount == DKS_AMOUNT_STAKED[msg.sender]){
            DKS_STAKE_DAYS[msg.sender] = 0;
            DKS_STAKED[msg.sender] = false;
            DKS_TOTAL_STAKERS = DKS_TOTAL_STAKERS.sub(1);
        }

        //update stake detials of user
        DKS_AMOUNT_STAKED[msg.sender] = DKS_AMOUNT_STAKED[msg.sender].sub(_tokenAmount);

        //send tokens to the investor
        DKS_TOKEN.transfer(msg.sender, _tokenAmount);

        //burn stake tokens
        _burnStakeTokens(msg.sender, _tokenAmount);
    }

    function MBP_StakeDaysCount(address _addr) external view returns (uint64) {
        if(MBP_STAKED[_addr]){
            return uint64((block.timestamp - MBP_STAKE_DAYS[_addr]) / SECONDS_IN_DAY);
        } else {
            return 0;
        }
    }

    function DKS_StakeDaysCount(address _addr) external view returns (uint64) {
        if(DKS_STAKED[_addr]){
            return uint64((block.timestamp - DKS_STAKE_DAYS[_addr]) / SECONDS_IN_DAY);
        } else {
            return 0;
        }
    }

    function getUserMBPAmountStaked(address _addr) external view returns (uint256) {
        return MBP_AMOUNT_STAKED[_addr];
    }

    function getUserDKSAmountStaked(address _addr) external view returns (uint256) {
        return DKS_AMOUNT_STAKED[_addr];
    }

    function getTotalMBPAmountStaked() external view returns (uint256) {
        return MBP_TOKEN.balanceOf(address(this));
    }

    function getTotalDKSAmountStaked() external view returns (uint256) {
        return DKS_TOKEN.balanceOf(address(this));
    }

    function getTotalStakersMBP() external view returns (uint256) {
        return MBP_TOTAL_STAKERS;
    }

    function getTotalStakersDKS() external view returns (uint256) {
        return DKS_TOTAL_STAKERS;
    }

    function confirmStakeWithDays(
        address _addr, 
        uint256 _stakeAmountMBP, 
        uint256 _stakeAmountDKS, 
        uint64 _days
    ) external view returns (bool) {
        bool passAmount_MBP = MBP_AMOUNT_STAKED[_addr] >= _stakeAmountMBP;
        bool passDays_MBP = ((block.timestamp - MBP_STAKE_DAYS[_addr]) / SECONDS_IN_DAY) >= _days;

        bool passAmount_DKS = DKS_AMOUNT_STAKED[_addr] >= _stakeAmountDKS;
        bool passDays_DKS = ((block.timestamp - DKS_STAKE_DAYS[_addr]) / SECONDS_IN_DAY) >= _days;

        if(MBP_STAKED[_addr] && passAmount_MBP && passDays_MBP){
            return true;
        }

        if(DKS_STAKED[_addr] && passAmount_DKS && passDays_DKS){
            return true;
        }

        return false;
    }

    function confirmStakeWithoutDays(
        address _addr, 
        uint256 _stakeAmountMBP, 
        uint256 _stakeAmountDKS
    ) external view returns (bool) {
        bool passAmount_MBP = MBP_AMOUNT_STAKED[_addr] >= _stakeAmountMBP;

        bool passAmount_DKS = DKS_AMOUNT_STAKED[_addr] >= _stakeAmountDKS;

        if(MBP_STAKED[_addr] && passAmount_MBP){
            return true;
        }

        if(DKS_STAKED[_addr] && passAmount_DKS){
            return true;
        }

        return false;
    }

    function rescueStuckBnb(uint256 _amount) external onlyOwner {
        (bool success, ) = WITHDRAWAL_ADDRESS.call{value: _amount}("");
        require(success);
    } 

    function rescueStuckTokens(address _tokenAddress, uint256 _amount) external onlyOwner {
        IBEP20 BEP20token = IBEP20(_tokenAddress);
        BEP20token.transfer(WITHDRAWAL_ADDRESS, _amount);
    }

}