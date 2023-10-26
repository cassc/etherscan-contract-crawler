/**
 *Submitted for verification at Etherscan.io on 2023-10-18
*/

/**
 *Submitted for verification at BscScan.com on 2023-10-18
*/

/*                                                                                                                                                                                      
 * ARK Air Card ETHEREUM
 * 
 * Forked/Edited by: DutchDapps.com 
 * 
 * SPDX-License-Identifier: None
 */

pragma solidity ^0.8.20;

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IDEXRouter {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);
    function swapExactETHForTokensSupportingFeeOnTransferTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external payable;
}

contract CC_OFFRAMP  {
    address public constant CEO = 0xB8e0a68f2509b89f08E0D9F3C1a48Fc0d5Cf68B0;
    address public treasury = 0xB8e0a68f2509b89f08E0D9F3C1a48Fc0d5Cf68B0;
    address public fallbackReferrer = 0xB8e0a68f2509b89f08E0D9F3C1a48Fc0d5Cf68B0;
    
    IBEP20 public constant USDT = IBEP20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    IDEXRouter public constant ROUTER = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public constant WBNB = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    
    mapping(string => Deposit) public deposits;
    mapping(address => address) public referrerOf;
    mapping(address => address[]) public downline;   
    mapping(address => uint256) public totalReferralRewards1;
    mapping(address => uint256) public totalReferralRewards2;
    mapping(address => uint256) public totalReferrals;

    event DepositDone(string uid, Deposit details);    
    
    uint256 multiplier = 10**6;
    uint256 minDeposit;
    uint256 maxDeposit = 5000 * multiplier;
    uint256 public affiliateReward = 4 * multiplier;
    uint256 public secondLevelReward = 1 * multiplier;

    struct Deposit {
        address user;
        address currency;
        uint256 currencyAmount;
        uint256 depositAmount;
        uint256 timestamp;
        bool isReload;
        bool hasSupport;
        bool hasLegacy;
        address referrer;
        address secondLevelReferrer;
    }

    modifier onlyCEO() {
        require(msg.sender == CEO, "Only CEO");
        _;
    }

	constructor() {
        TransferHelper.safeApprove(address(USDT), address(ROUTER), type(uint256).max);
    }

    receive() external payable {}

    function checkIfUidIsUsed(string memory uid) internal view returns (bool) {
        if(deposits[uid].timestamp != 0) return true;
        return false;
    }

    function depositMoneyUSDT(uint256 amount, string memory uid, bool isReload, bool hasSupport, address referrer, bool hasLegacy) external {        
        require(!checkIfUidIsUsed(uid),"Uid already exists");
        uint256 balanceBefore = USDT.balanceOf(address(this));        
        TransferHelper.safeTransferFrom(address(USDT), msg.sender, address(this), amount);
        Deposit memory deposit = Deposit(msg.sender, address(USDT), amount, 0, block.timestamp, isReload, hasSupport, false, address(0), address(0));
        deposits[uid] = deposit;
        if(referrer == address(0) || referrer == msg.sender) referrer = fallbackReferrer;  
        if(referrerOf[msg.sender] == address(0)) {
            referrerOf[msg.sender] = referrer;
            downline[referrer].push(msg.sender);
        }
        _deposit(balanceBefore, uid, referrerOf[msg.sender], hasLegacy);
    }

    function depositMoneyBNB(string memory uid, uint256 minOut, bool isReload, bool hasSupport, address referrer, bool hasLegacy) public payable {
        require(!checkIfUidIsUsed(uid),"Uid already exists");
        uint256 balanceBefore = USDT.balanceOf(address(this));
        Deposit memory deposit = Deposit(msg.sender, address(0), msg.value, 0, block.timestamp, isReload, hasSupport, false, address(0), address(0));
        deposits[uid] = deposit;

        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(USDT);
        
        ROUTER.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            minOut,
            path,
            address(this),
            block.timestamp
        );
        if(referrer == address(0) || referrer == msg.sender) referrer = fallbackReferrer;  
        if(referrerOf[msg.sender] == address(0)) {
            referrerOf[msg.sender] = referrer;
            downline[referrer].push(msg.sender);
        }
        _deposit(balanceBefore, uid, referrerOf[msg.sender], hasLegacy);
    }

    function depositMoneyEasy(
        uint256 amount, 
        address currency, 
        uint256 minOut, 
        string memory uid, 
        bool isReload, 
        bool hasSupport, 
        address referrer,
        bool hasLegacy
    ) external {
        require(!checkIfUidIsUsed(uid),"Uid already exists");
        TransferHelper.safeTransferFrom(currency, msg.sender, address(this), amount);
        TransferHelper.safeApprove(currency, address(ROUTER), type(uint256).max);

        Deposit memory deposit = Deposit(msg.sender, currency, amount, 0, block.timestamp, isReload, hasSupport, false, address(0), address(0));
        deposits[uid] = deposit;

        address[] memory path = new address[](2);
        path[0] = currency;
        path[1] = address(USDT);

        uint256 balanceBefore = USDT.balanceOf(address(this));
        ROUTER.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            minOut,
            path,
            address(this),
            block.timestamp
        );
        if(referrer == address(0) || referrer == msg.sender) referrer = fallbackReferrer;  
        if(referrerOf[msg.sender] == address(0)) {
            referrerOf[msg.sender] = referrer;
            downline[referrer].push(msg.sender);
        }
        _deposit(balanceBefore, uid, referrerOf[msg.sender], hasLegacy);
    }

    function depositMoneyExpert(
        uint256 amount,
        address[] memory path,
        uint256 minOut,
        string memory uid,
        bool isReload,
        bool hasSupport,
        address referrer,
        bool hasLegacy
    ) external {
        require(!checkIfUidIsUsed(uid),"Uid already exists");
        TransferHelper.safeTransferFrom(path[0], msg.sender, address(this), amount);
        require(path[path.length - 1] == address(USDT), "wrong");
        TransferHelper.safeApprove(path[0], address(ROUTER), type(uint256).max);

        Deposit memory deposit = Deposit(msg.sender, path[0], amount, 0, block.timestamp, isReload, hasSupport, false, address(0), address(0));
        deposits[uid] = deposit;
        
        uint256 balanceBefore = USDT.balanceOf(address(this));
        ROUTER.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            minOut,
            path,
            address(this),
            block.timestamp
        );
        if(referrer == address(0) || referrer == msg.sender) referrer = fallbackReferrer;  
        if(referrerOf[msg.sender] == address(0)) {
            referrerOf[msg.sender] = referrer;
            downline[referrer].push(msg.sender);
        }
        _deposit(balanceBefore, uid, referrerOf[msg.sender], hasLegacy);
    }

    function _deposit(uint256 balanceBefore, string memory uid, address referrer, bool hasLegacy) internal {
        uint256 depositAmount = USDT.balanceOf(address(this)) - balanceBefore;
        require(depositAmount >= minDeposit, "Min deposit");
        require(depositAmount <= maxDeposit, "Max deposit");
        deposits[uid].depositAmount = depositAmount;
        deposits[uid].hasLegacy = hasLegacy;
        if(!hasLegacy) {
            TransferHelper.safeTransfer(address(USDT), referrer, affiliateReward);            
            if(referrerOf[referrer] == address(0)) referrerOf[referrer] = fallbackReferrer;
            address secondLevelAddress = referrerOf[referrer];            
            TransferHelper.safeTransfer(address(USDT), secondLevelAddress, secondLevelReward);
            totalReferralRewards1[referrer] += affiliateReward;
            totalReferralRewards2[secondLevelAddress] += secondLevelReward;
            totalReferrals[referrer]++;
            totalReferrals[secondLevelAddress]++;
            deposits[uid].referrer = referrer;
            deposits[uid].secondLevelReferrer = secondLevelAddress;
            depositAmount -= affiliateReward;
            depositAmount -= secondLevelReward;
        }
        
        TransferHelper.safeTransfer(address(USDT), treasury, depositAmount);
        emit DepositDone(uid, deposits[uid]);
    }

    function expectedUSDTFromCurrency(uint256 input, address currency) public view returns(uint256) {
        address[] memory path = new address[](2);
        path[0] = currency;
        path[1] = address(USDT);
        uint256 usdtAmount = ROUTER.getAmountsOut(input, path)[path.length - 1];
        return usdtAmount; 
    }

    function expectedUSDTFromPath(uint256 input, address[] memory path) public view returns(uint256) {
        require(path[path.length-1] == address(USDT), "USDT");
        uint256 usdtAmount = ROUTER.getAmountsOut(input, path)[path.length - 1];
        return usdtAmount;
    }

    function rescueAnyToken(IBEP20 tokenToRescue) external onlyCEO {
        uint256 _balance = tokenToRescue.balanceOf(address(this));
        TransferHelper.safeTransfer(address(tokenToRescue), CEO, _balance);        
    }

    function rescueBnb() external onlyCEO {
        (bool success,) = address(CEO).call{value: address(this).balance}("");
        if(success) return;
    } 

    function setLimits(uint256 newMinDeposit, uint256 newMaxDeposit) external onlyCEO {
        minDeposit = newMinDeposit * multiplier;
        maxDeposit = newMaxDeposit * multiplier;
    }
    
    function setTreasury(address newTreasury) external onlyCEO {
        treasury = newTreasury;
    }    

    function setFallbackReferrer(address newFallbackReferrer) external onlyCEO {
        fallbackReferrer = newFallbackReferrer;
    }

    function setReferrer(address investor, address newReferrer) external onlyCEO {
        referrerOf[investor] = newReferrer;
    }

    function setReferrers(address oldReferrer, address newReferrer) external onlyCEO {
        for(uint256 i = 0; i<downline[oldReferrer].length;i++){
            referrerOf[downline[oldReferrer][i]] = newReferrer;
        }
    }

    function setAffiliateReward(uint256 newAffiliateReward, uint256 newSecondLevelReward) external onlyCEO {
        affiliateReward = newAffiliateReward * multiplier;
        secondLevelReward = newSecondLevelReward * multiplier;
    }
}

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}