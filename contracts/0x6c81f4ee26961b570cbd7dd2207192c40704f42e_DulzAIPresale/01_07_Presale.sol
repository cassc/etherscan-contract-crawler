// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

pragma solidity =0.8.19;
abstract contract Whitelist is Ownable {
    mapping(address => bool) public _whitelist;

    function whitelistAddresses(address[] calldata _users) external onlyOwner {
        for (uint i = 0; i < _users.length; i++){
            _whitelist[_users[i]] = true;
        }
    }

    function removeAddresses(address[] calldata _users) external onlyOwner {
        for (uint i = 0; i < _users.length; i++){
            _whitelist[_users[i]] = false;
        }
    }
}

contract DulzAIPresale is Ownable, Whitelist, ReentrancyGuard {
    using Address for address payable;
    using SafeMath for uint;

    bool public isInit;
    bool public isRefund;
    bool public isFinish;
    bool public isWhitelist;
    address public creatorWallet;
    uint public ethRaised;

    struct Pool {
        uint startTime;
        uint endTime;
        uint hardCap;
        uint softCap;
        uint maxBuy;
        uint minBuy;
        uint percentageOnTge;
        uint vestingPeriod;
    }

    Pool public pool;
    IERC20 public token;

    mapping(address => uint) public ethContribution;
    mapping(address => uint) public tokensReleased;

    modifier onlyActive {
        require(block.timestamp >= pool.startTime, "Presale must be active.");
        require(block.timestamp <= pool.endTime, "Presale must be active.");
        _;
    }

    modifier onlyInactive {
        require(
            block.timestamp < pool.startTime || 
            block.timestamp > pool.endTime || 
            ethRaised >= pool.hardCap, "Presale must be inactive."
            );
        _;
    }

    modifier onlyRefund {
        require(
            isRefund == true || 
            (block.timestamp > pool.endTime && ethRaised < pool.softCap), "Refund unavailable."
        );
        _;
    }

    constructor() {
        isInit = false;
        isFinish = false;
        isRefund = false;
        ethRaised = 0;

        isWhitelist = false;
        creatorWallet = msg.sender;
    }

    function setToken(address _token) external onlyOwner{
        token = IERC20(_token);
    }

    receive() external payable {
        if (block.timestamp >= pool.startTime && block.timestamp <= pool.endTime) {
            purchase();
        } else {
            revert("Presale is closed");
        }
    }

    function purchase() public payable onlyActive {
        require(!isRefund, "Presale has been cancelled.");
        require(msg.value % pool.minBuy == 0, "Please only buy in increments of the minimum buy");

        uint weiAmount = msg.value;
        _checkSaleRequirements(msg.sender, weiAmount);
        ethRaised += weiAmount;
        ethContribution[msg.sender] += weiAmount;
        emit Bought(_msgSender(), weiAmount);
    }

    function refund() external onlyRefund {
        uint refundAmount = ethContribution[msg.sender];

        if (address(this).balance >= refundAmount) {
            if (refundAmount > 0) {
                ethContribution[msg.sender] = 0;
                Address.sendValue(payable(msg.sender), refundAmount);
                emit Refunded(msg.sender, refundAmount);
            }
        }
    }

    function claimTokens() external nonReentrant {
        require(isFinish, "Presale is not finished");
        (uint ethAmount, , uint vestedAmount) = getUserInfo(msg.sender);
        require(ethAmount > 0, "User did not contribute");

        if (vestedAmount > 0) {
            tokensReleased[msg.sender] += vestedAmount;
            token.transfer(msg.sender, vestedAmount);
        }
    }

    /** VIEW FUNCTIONS */

    function getUserInfo(address beneficiary) public view returns (uint ethAmount, uint tokenAmount, uint vestedAmount) {
        (ethAmount, tokenAmount) = _getUserInfo(beneficiary);
        vestedAmount = _getUserVested(beneficiary, tokenAmount);
    }

    /** INTERNAL FUNCTIONS */

    function _checkSaleRequirements(address _beneficiary, uint _amount) internal view { 
        if (isWhitelist) {
            require(_whitelist[_msgSender()], "User is not whitelisted.");
        }

        require(_beneficiary != address(0), "Transfer to 0 address.");
        require(_amount != 0, "Wei Amount is 0");
        require(_amount >= pool.minBuy, "Min buy is not met.");
        require(_amount + ethContribution[_beneficiary] <= pool.maxBuy, "Max buy limit exceeded.");
        require(ethRaised + _amount <= pool.hardCap, "HC Reached.");
        this;
    }

    function _getUserInfo(address _beneficiary) internal view returns (uint, uint) {
        uint ethAmount = ethContribution[_beneficiary];
        uint tokenAmount = uint((ethContribution[_beneficiary] * 1e18 / pool.minBuy) * 500);
        return (ethAmount, tokenAmount);
    }

    function _getUserVested(address beneficiary, uint tokenAmount) internal view returns (uint releasableAmount) {
        if (tokenAmount > 0) {
            uint tokensOnTge = tokenAmount * pool.percentageOnTge / 100;
            uint tokensToVest = tokenAmount - tokensOnTge;
            uint alreadyReleased = tokensReleased[beneficiary];
            if (tokensToVest > 0) {
                uint vestedAmount = _getVestedAmount(tokensToVest, block.timestamp);
                releasableAmount = tokensOnTge + vestedAmount - alreadyReleased;
            } else {
                if (alreadyReleased == 0) {
                    releasableAmount = tokensOnTge;
                } else {
                    releasableAmount = 0;
                }
            }
        } else {
            releasableAmount = 0;
        }
    }

    function _getVestedAmount(uint _totalAmount, uint _timestamp) internal view returns (uint) {
        if (_timestamp < pool.endTime) {
            return 0;
        } else if (_timestamp > pool.endTime + pool.vestingPeriod) {
            return _totalAmount;
        } else {
            return (_totalAmount * (_timestamp - pool.endTime)) / pool.vestingPeriod;
        }
    }

    /** RESTRICTED FUNCTIONS */

    function initSale(
        uint _startTime,
        uint _endTime,
        uint _hardCap,
        uint _softCap,
        uint _maxBuy,
        uint _minBuy,
        uint _percentageOnTge,
        uint _vestingPeriod
    ) external onlyOwner onlyInactive {        
        require(isInit == false, "Presale is not initialized");
        require(_startTime >= block.timestamp, "Invalid start time.");
        require(_endTime > block.timestamp, "Invalid end time.");
        require(_minBuy < _maxBuy, "Min buy must be greater than max buy.");
        require(_minBuy > 0, "Min buy must exceed 0.");

        Pool memory newPool = Pool(
            _startTime,
            _endTime, 
            _hardCap,
            _softCap, 
            _maxBuy, 
            _minBuy,
            _percentageOnTge,
            _vestingPeriod
        );

        pool = newPool;
        
        isInit = true;
    }

    function finishSale() external onlyOwner {
        isFinish = true;
        pool.endTime = block.timestamp;
        Address.sendValue(payable(creatorWallet), address(this).balance);
    }

    function recoverTokens(address _token) external onlyOwner {	
        IERC20(_token).transfer(owner(), IERC20(_token).balanceOf(address(this)));	
    }

    function cancelSale() external onlyOwner onlyActive {
        require(!isFinish, "Sale is finished.");
        pool.endTime = 0;
        isRefund = true;

        emit Cancelled(msg.sender, address(this));
    }

    function disableWhitelist() external onlyOwner {
        require(isWhitelist, "Whitelist is already disabled.");

        isWhitelist = false;
    }

    /** EVENTS */

    event Cancelled(
        address indexed _inititator, 
        address indexed _presale
    );

    event Bought(
        address indexed _buyer, 
        uint _ethAmount
    );

    event Refunded(
        address indexed _refunder, 
        uint _ethAmount
    );
}