/**
 *Submitted for verification at Etherscan.io on 2023-07-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
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

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {
  
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

error MinBuyError();
error MaxBuyError();
error maxRoundLimitReached();
error PresaleCompleted();
error RefundNotAvailableYet();
error PresaleNotCompleted();
error NoTokenAvailableForClaim();

contract EaglePresale is Ownable {

    using SafeMath for uint256;

    uint256 public usdRaised;

    uint256 public minBuy = 50000000;     //50 usdt
    uint256 public maxBuy = 1000000000;   //1000 usdt

    bool public refundEnable;

    bool public paused;  

    mapping (address => uint) public userTokens;
    mapping (address => uint) public userContribution;

    uint public tokenSold;
    uint public tokenForSale;

    uint256 public currentRound;

    IERC20 public currency;
    IERC20 public EagleToken;

    uint256 public price = 30;   //0.00003$ per token 

    uint256 public vestingLockPercentage = 50;
    uint256 public vestingPeriod = 180 days;    // days in 6 months
    uint256 public presaleStartAt;
    uint256 public presaleOverAt;

    address public paymentWallet = address(0x9c2DB4b4bEaEC3F8c7fd9804ee13D78d73BB938b);

    mapping (address => uint) public claimed;

    modifier validUser {
        require(msg.sender != address(0) ,"Invalid User Address!");
        _;
    }

    modifier checkPaused {
        require(!paused,"Presale Paused!");
        _;
    }

    event Deposit(address indexed _adr, uint _usdt ,uint _Sold, uint stamp);
    event withdraw(address indexed _adr,uint _usdt,uint stamp);
    event claimTrigger(address indexed _adr, uint _token, uint stamp);

    constructor() {
        currency = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);   // usdt
        EagleToken = IERC20(0xd90ed87680A805705d0BcA87470e1043E69D2c65);
        currentRound++;
        presaleStartAt = block.timestamp;
        tokenForSale = 10_000_000_000 * 1e18;         // started with 10B
    }

    function contribute(uint _amount) public validUser checkPaused {
        address user = msg.sender;
        uint _tokenSold = calculateAmount(_amount);
        chkvalidation(_amount,_tokenSold);

        (bool success, ) = address(currency).call(abi.encodeWithSignature('transferFrom(address,address,uint256)', user, address(paymentWallet), _amount));
        require(success, 'Token payment failed');

        usdRaised += _amount;
        tokenSold += _tokenSold;
        userTokens[user] += _tokenSold;
        userContribution[user] += _amount;

        emit Deposit(user,_amount,_tokenSold,block.timestamp);
    }

    function claim() public checkPaused {
        if(presaleOverAt == 0) revert PresaleNotCompleted();
        
        uint subtotal = userTokens[msg.sender];
        if(subtotal == 0) return;
        uint half = subtotal / 2;
        uint txable;
        uint available;

        if(presaleOverAt + vestingPeriod <= block.timestamp) {
            available += half;
        }
        
        if (subtotal > 0) {
            available += half;
        }

        txable = available - claimed[msg.sender];

        if(txable > 0) {
            claimed[msg.sender] += txable;
            EagleToken.transfer(msg.sender, txable);
        }
        else {
            revert NoTokenAvailableForClaim();
        }

        emit claimTrigger(msg.sender,txable,block.timestamp);
    }

    function withdrawContribution() public checkPaused {
        if(presaleOverAt != 0) revert PresaleCompleted();
        if(!refundEnable) revert RefundNotAvailableYet();

        uint usd = userContribution[msg.sender];
        require(usd > 0 , "Insufficient Funds");
        userTokens[msg.sender] = 0;
        userContribution[msg.sender] = 0;
        (bool success, ) = address(currency).call(abi.encodeWithSignature('transfer(address,uint256)',  msg.sender, usd));
        require(success, 'Token payment failed');

        emit withdraw(msg.sender,usd,block.timestamp);
    }

    function chkvalidation(uint _usd,uint _tobesold) internal view {
        if(presaleOverAt != 0) revert PresaleCompleted();
        if(tokenSold + _tobesold > tokenForSale) revert maxRoundLimitReached();
        if(_usd < minBuy) revert MinBuyError();
        if(_usd > maxBuy) revert MaxBuyError();
    }

    function claimable(address _user) public view returns (uint) {
        
        if(presaleOverAt == 0) return 0;

        uint subtotal = userTokens[_user];
        
        if(subtotal == 0) return 0;

        uint half = subtotal / 2;
        uint txable;
        uint available;

        if(presaleOverAt + vestingPeriod <= block.timestamp) {
            available += half;
        }
        
        if (subtotal > 0) {
            available += half;
        }

        txable = available - claimed[_user];

        if(txable > 0) {
            return txable;
        }
        else {
            return 0;
        }
    }

    function calculateAmount(uint _amount) public view returns (uint) {
        uint factor = 1e18 * _amount;
        return factor/price;
    }

    function enableRefund(bool _status) external onlyOwner {
        refundEnable = _status;   
    }

    function setPaused(bool _status) external onlyOwner {
        paused = _status;   
    }

    function startVesting() public onlyOwner {
        presaleOverAt = block.timestamp;
    }

    function setBuyLimit(uint _min, uint _max) external onlyOwner {
        minBuy = _min;
        maxBuy = _max;
    }

    function UpdateSettings(uint _tokenForSale, uint _round) external onlyOwner {
        tokenForSale = _tokenForSale;
        currentRound = _round;
    }

    function setCurrency(address _token) external onlyOwner {
        currency = IERC20(_token);
    }

    function setEagleToken(address _token) external onlyOwner {
        EagleToken = IERC20(_token);
    }

    function setPrice(uint _newPrice) external onlyOwner {
        price = _newPrice;
    }

    function setVestingPeriod(uint _time) external onlyOwner {
        vestingPeriod = _time;
    }

    function EmergencyWithdrawFunds() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setPaymentWallet(address _newWallet) external onlyOwner {
        paymentWallet = _newWallet;
    }

    function EmergencyWithdrawTokens(address _token, uint _amount) external onlyOwner {
        (bool success, ) = address(_token).call(abi.encodeWithSignature('transfer(address,uint256)',  msg.sender, _amount));
        require(success, 'Token payment failed');
    }

    receive() external payable {}

}