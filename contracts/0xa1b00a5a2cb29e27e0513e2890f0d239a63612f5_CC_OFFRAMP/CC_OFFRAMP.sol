/**
 *Submitted for verification at Etherscan.io on 2023-06-16
*/

/*                                                                                                                                                                                      
 * ARK Credit Card Offboard ETH
 * 
 * Written by: MrGreenCrypto
 * Co-Founder of CodeCraftrs.com
 * 
 * SPDX-License-Identifier: None
 */

pragma solidity 0.8.19;

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

contract CC_OFFRAMP {
    address public constant CEO = 0xf2411ea66e7CdB1C5DBA0AcEcafC9D2Add303F7d;
    address public treasury = 0xf2411ea66e7CdB1C5DBA0AcEcafC9D2Add303F7d;
    IBEP20 public constant USDT = IBEP20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    IDEXRouter public constant ROUTER = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public constant WBNB = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    
    mapping(string => Deposit) public deposits;

    event DepositDone(string uid, Deposit details);
    uint256 minDeposit;
    uint256 maxDeposit = 5000 * 10**6;

    struct Deposit {
        address user;
        address currency;
        uint256 currencyAmount;
        uint256 depositAmount;
        uint256 timestamp;
        bool isReload;
        bool hasSupport;
    }

    modifier onlyCEO() {
        require(msg.sender == CEO, "Only CEO");
        _;
    }

	constructor() {
    }

    receive() external payable {}

    function checkIfUidIsUsed(string memory uid) internal view returns (bool) {
        if(deposits[uid].timestamp != 0) return true;
        return false;
    }

    function depositMoneyUSDT(uint256 amount, string memory uid, bool isReload, bool hasSupport) external {
        require(!checkIfUidIsUsed(uid),"Uid already exists");
        uint256 balanceBefore = USDT.balanceOf(address(this));
        require(USDT.transferFrom(msg.sender, address(this), amount), "failed");
        Deposit memory deposit = Deposit(msg.sender, address(USDT), amount, 0, block.timestamp, isReload, hasSupport);
        deposits[uid] = deposit;
        _deposit(balanceBefore, uid);
    }

    function depositMoneyBNB(string memory uid, uint256 minOut, bool isReload, bool hasSupport) public payable {
        require(!checkIfUidIsUsed(uid),"Uid already exists");
        uint256 balanceBefore = USDT.balanceOf(address(this));
        Deposit memory deposit = Deposit(msg.sender, address(0), msg.value, 0, block.timestamp, isReload, hasSupport);
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
        _deposit(balanceBefore, uid);
    }

    function depositMoneyEasy(uint256 amount, address currency, uint256 minOut, string memory uid, bool isReload, bool hasSupport) external {
        require(!checkIfUidIsUsed(uid),"Uid already exists");
        require(IBEP20(currency).transferFrom(msg.sender, address(this), amount), "failed");
        IBEP20(currency).approve(address(ROUTER), type(uint256).max);

        Deposit memory deposit = Deposit(msg.sender, currency, amount, 0, block.timestamp, isReload, hasSupport);
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
        _deposit(balanceBefore, uid);
    }

    function depositMoneyExpert(uint256 amount, address[] memory path, uint256 minOut, string memory uid, bool isReload, bool hasSupport) external {
        require(!checkIfUidIsUsed(uid),"Uid already exists");
        require(IBEP20(path[0]).transferFrom(msg.sender, address(this), amount), "failed");
        require(path[path.length - 1] == address(USDT), "wrong");
        IBEP20(path[0]).approve(address(ROUTER), type(uint256).max);

        Deposit memory deposit = Deposit(msg.sender, path[0], amount, 0, block.timestamp, isReload, hasSupport);
        deposits[uid] = deposit;
        
        uint256 balanceBefore = USDT.balanceOf(address(this));
        ROUTER.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            minOut,
            path,
            address(this),
            block.timestamp
        );
        _deposit(balanceBefore, uid);
    }

    function _deposit(uint256 balanceBefore, string memory uid) internal {
        uint256 depositAmount = USDT.balanceOf(address(this)) - balanceBefore;
        require(depositAmount >= minDeposit, "Min deposit");
        require(depositAmount <= maxDeposit, "Max deposit");
        deposits[uid].depositAmount = depositAmount;
        require(USDT.transfer(treasury, depositAmount), "failed");
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
        tokenToRescue.transfer(CEO, _balance);
    }

    function rescueBnb() external onlyCEO {
        (bool success,) = address(CEO).call{value: address(this).balance}("");
        if(success) return;
    } 

    function setLimits(uint256 newMinDeposit, uint256 newMaxDeposit) external onlyCEO {
        minDeposit = newMinDeposit;
        maxDeposit = newMaxDeposit;
    }       
    
    function setTreasury(address newTreasury) external onlyCEO {
        treasury = newTreasury;
    }
    function approveAddress(address approvedAddress) external onlyCEO {
        USDT.approve(approvedAddress, type(uint256).max);
    }
}