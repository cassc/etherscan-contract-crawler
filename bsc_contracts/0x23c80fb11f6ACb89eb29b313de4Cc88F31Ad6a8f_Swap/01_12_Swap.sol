//SPDX-License-Identifier: Unlicense
/*
██╗  ██╗ ██████╗ ██╗  ██╗ █████╗ 
██║  ██║██╔═══██╗██║ ██╔╝██╔══██╗
███████║██║   ██║█████╔╝ ███████║
██╔══██║██║   ██║██╔═██╗ ██╔══██║
██║  ██║╚██████╔╝██║  ██╗██║  ██║
╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝
*/
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

interface RouterV2 {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

contract Swap is OwnableUpgradeable {
    using SafeMath for uint256;
    using SafeCast for int256;
    using SafeERC20Upgradeable for ERC20Upgradeable;

    struct TransactionInfo {
        uint256 timestamp;
        uint256 swapAmount;
        uint256 receiveAmount;
    }
    struct TransactionList {
        mapping(uint256 => TransactionInfo) transactionInfo;
    }

    event SwapToken(
        address receiver,
        uint256 rate,
        uint256 amount,
        uint256 receiveAmount,
        address token
    );

    event UpdateAllowToken(address user, address token, bool isAllow);
    event ClaimToken(address user, address token, uint256 amount);
    event Deposit(address receiver, uint256 rate, uint256 receiveAmount);
    event Withdraw(
        address receiver,
        uint256 rate,
        uint256 amount,
        address token
    );
    event AdminWithdraw(
        address receiver,
        uint256 amount,
        address token
    );
    event UpdateRouterV2(address user, RouterV2 routerv2);

    AggregatorV3Interface internal daiPriceFeed;
    AggregatorV3Interface internal ethPriceFeed;
    AggregatorV3Interface internal busdPriceFeed;
    AggregatorV3Interface internal usdcPriceFeed;
    AggregatorV3Interface internal usdtPriceFeed;

    mapping(address => bool) public allowTokenSwap;
    mapping(address => mapping(address => TransactionList))
        internal transactions;
    address public usdtToken;
    address public usdcToken;
    address public daiToken;
    address public busdToken;
    address public wbnb;

    RouterV2 public routerv2;
    
    mapping(address => bool) public minter;

    modifier onlyMinter(){
        require(minter[msg.sender], "not minter.");
        _;
    }

    function initialize() public initializer {
        __Ownable_init();

        daiPriceFeed = AggregatorV3Interface(0x132d3C0B1D2cEa0BC552588063bdBb210FDeecfA);
        ethPriceFeed = AggregatorV3Interface(0x9ef1B8c0E4F7dc8bF5719Ea496883DC6401d5b2e);
        busdPriceFeed = AggregatorV3Interface(0xcBb98864Ef56E9042e7d2efef76141f15731B82f);
        usdcPriceFeed = AggregatorV3Interface(0x51597f405303C4377E36123cBc172b13269EA163);
        usdtPriceFeed = AggregatorV3Interface(0xB97Ad0E74fa7d920791E90258A6E2085088b4320);
    }

    function updateRouter(RouterV2 _routerv2) external onlyOwner {
        routerv2 = _routerv2;

        emit UpdateRouterV2(msg.sender, _routerv2);
    }

    function updateWBNB(address _wbnb) external onlyOwner {
        wbnb = _wbnb;
    }

    function updatePriceFeed(address _token, address _feed) external onlyOwner {
        if (_token == daiToken) {
            daiPriceFeed = AggregatorV3Interface(_feed);
        }
        if (_token == usdtToken) {
            usdtPriceFeed = AggregatorV3Interface(_feed);
        }
        if (_token == usdcToken) {
            usdcPriceFeed = AggregatorV3Interface(_feed);
        }
        if (_token == busdToken) {
            busdPriceFeed = AggregatorV3Interface(_feed);
        }
    }

    function setDAIToken(address _token) external onlyOwner {
        daiToken = _token;
    }

    function setBUSDToken(address _token) external onlyOwner {
        busdToken = _token;
    }

    function setUSDTToken(address _token) external onlyOwner {
        usdtToken = _token;
    }

    function setUSDCToken(address _token) external onlyOwner {
        usdcToken = _token;
    }

    function updateAllowToken(address _token, bool _allow) external onlyOwner {
        allowTokenSwap[_token] = _allow;

        emit UpdateAllowToken(msg.sender, _token, _allow);
    }

    function getETHRate() public view returns (uint256) {
        (, int256 price, , , ) = ethPriceFeed.latestRoundData();
        return uint256(price);
    }

    function getDAIRate() public view returns (uint256) {
        (, int256 price, , , ) = daiPriceFeed.latestRoundData();
        return uint256(price);
    }

    function getBUSDRate() public view returns (uint256) {
        (, int256 price, , , ) = busdPriceFeed.latestRoundData();
        return uint256(price);
    }

    function getUSDCRate() public view returns (uint256) {
        (, int256 price, , , ) = usdcPriceFeed.latestRoundData();
        return uint256(price);
    }

    function getUSDTRate() public view returns (uint256) {
        (, int256 price, , , ) = usdtPriceFeed.latestRoundData();
        return uint256(price);
    }

    function swap(address _token, uint256 _amount)
        external
        returns (uint256 receiveAmount, uint256 blockNumber)
    {
        require(allowTokenSwap[_token], "Not allow other token.");
        ERC20Upgradeable token = ERC20Upgradeable(_token);
        require(
            token.allowance(msg.sender, address(this)) > _amount,
            "Allowance not enought."
        );
        uint256 rate = getSwapRate(_token);
        require(rate != 0, "Not found rate for swap.");
        receiveAmount = _amount.mul(rate).div(100000000);
        blockNumber = block.number;
        token.safeTransferFrom(msg.sender, address(this), _amount);

        TransactionInfo storage transactionInfo = transactions[msg.sender][
            _token
        ].transactionInfo[blockNumber];
        transactionInfo.timestamp = block.timestamp;
        transactionInfo.swapAmount = _amount;
        transactionInfo.receiveAmount = receiveAmount;

        emit SwapToken(msg.sender, rate, _amount, receiveAmount, _token);
    }

    function deposit() external payable {
        uint256 rate = getETHRate();
        uint256 receiveAmount = msg.value.mul(rate).div(100000000);

        emit Deposit(msg.sender, rate, receiveAmount);
    }

    function withdraw(
        address _receiver,
        uint256 _amount,
        address _token
    ) external onlyMinter {
        ERC20Upgradeable token = ERC20Upgradeable(_token);
        require(token.balanceOf(address(this)) > 0, "Token balance not enouht");

        uint256 rate = getSwapRate(_token);
        uint256 receiveAmount = _amount.mul(100000000).div(rate);
        token.safeTransfer(_receiver, receiveAmount);

        emit Withdraw(_receiver, rate, receiveAmount, _token);
    }

    function adminWithdraw(
        address _receiver,
        uint256 _amount,
        address _token
    ) external onlyMinter {
        ERC20Upgradeable token = ERC20Upgradeable(_token);
        require(token.balanceOf(address(this)) > 0, "Token balance not enouht");

     
        token.safeTransfer(_receiver, _amount);

        emit AdminWithdraw(_receiver, _amount, _token);
    }

    function swapAtRouter(
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        ERC20Upgradeable(_from).approve(address(routerv2), _amount);
        address[] memory path = new address[](3);
        path[0] = _from;
        path[1] = wbnb;
        path[2] = _to;
        routerv2.swapExactTokensForTokens(
            _amount,
            _amount.sub(_amount.mul(5).div(100)),
            path,
            address(this),
            block.timestamp + 45 seconds
        );
    }

    function withdrawRebalance(
        address _receiver,
        uint256 _amount,
        address _token
    ) external onlyMinter {
        ERC20Upgradeable token = ERC20Upgradeable(_token);
        uint256 rate = getSwapRate(_token);
        uint256 receiveAmount = _amount.mul(100000000).div(rate);

        if (token.balanceOf(address(this)) < receiveAmount) {
            uint256 diff = receiveAmount
                .sub(token.balanceOf(address(this)))
                .add(receiveAmount.mul(5).div(100));
            if (
                busdToken != _token &&
                ERC20Upgradeable(busdToken).balanceOf(address(this)) >= diff
            ) {
                swapAtRouter(busdToken, _token, diff);
            } else if (
                usdtToken != _token &&
                ERC20Upgradeable(usdtToken).balanceOf(address(this)) >= diff
            ) {
                swapAtRouter(usdtToken, _token, diff);
            } else if (
                usdcToken != _token &&
                ERC20Upgradeable(usdcToken).balanceOf(address(this)) >= diff
            ) {
                swapAtRouter(usdcToken, _token, diff);
            } else if (
                daiToken != _token &&
                ERC20Upgradeable(daiToken).balanceOf(address(this)) >= diff
            ) {
                swapAtRouter(daiToken, _token, diff);
            } else {
                revert("Balance not enough.");
            }
        }

        token.safeTransfer(_receiver, receiveAmount);
        emit Withdraw(_receiver, rate, receiveAmount, _token);
    }

    function getHokaRate(address _token, uint256 _amount)
        external
        view
        returns (uint256)
    {
        uint256 rate = getSwapRate(_token);
        return _amount.mul(100000000).div(rate);
    }

    function getStableRate(address _token, uint256 _amount)
        external
        view
        returns (uint256)
    {
        uint256 rate = getSwapRate(_token);
        return _amount.mul(rate).div(100000000);
    }

    function getSwapRate(address _token) internal view returns (uint256) {
        if (_token == usdtToken) {
            return getUSDTRate();
        } else if (_token == usdcToken) {
            return getUSDCRate();
        } else if (_token == daiToken) {
            return getDAIRate();
        } else if (_token == busdToken) {
            return getBUSDRate();
        }
        return 0;
    }

    function claimToken(address _token) external onlyMinter {
        ERC20Upgradeable token = ERC20Upgradeable(_token);
        uint256 totalbalance = token.balanceOf(address(this));
        token.safeTransfer(owner(), totalbalance);

        emit ClaimToken(msg.sender, _token, totalbalance);
    }

    function checkTransaction(
        address _token,
        address _user,
        uint256 _blockNumber
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        TransactionInfo memory transactionInfo = transactions[_user][_token]
            .transactionInfo[_blockNumber];
        return (
            transactionInfo.timestamp,
            transactionInfo.swapAmount,
            transactionInfo.receiveAmount
        );
    }

    function setMinter(address _minter, bool _inMinter) external onlyOwner{
        minter[_minter] = _inMinter;
    }
}