/* SPDX-License-Identifier: UNLICENSED */

pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

interface IVault {
    function WETH() external view returns (address);

    function getPoolTokens(bytes32 poolId)
        external
        view
        returns (
            address[] memory tokens,
            uint256[] memory balances,
            uint256 lastChangeBlock
        );

    enum JoinKind {
        INIT,
        EXACT_TOKENS_IN_FOR_BPT_OUT,
        TOKEN_IN_FOR_EXACT_BPT_OUT,
        ALL_TOKENS_IN_FOR_EXACT_BPT_OUT
    }

    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external payable;

    struct JoinPoolRequest {
        address[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    enum ExitKind {
        EXACT_BPT_IN_FOR_ONE_TOKEN_OUT,
        EXACT_BPT_IN_FOR_TOKENS_OUT,
        BPT_IN_FOR_EXACT_TOKENS_OUT,
        MANAGEMENT_FEE_TOKENS_OUT // for InvestmentPool
    }

    function exitPool(
        bytes32 poolId,
        address sender,
        address payable recipient,
        ExitPoolRequest memory request
    ) external;

    struct ExitPoolRequest {
        address[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }

    enum SwapKind {
        GIVEN_IN,
        GIVEN_OUT
    }

    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        address assetIn;
        address assetOut;
        uint256 amount;
        bytes userData;
    }

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external returns (uint256 amountCalculated);
}

interface Bank {
    function addRewards(address token, uint256 amount) external;
}

interface IWETH {
    function deposit() external payable;
}

interface ISwapperPCS {
    function executeSwaps(
        uint256 toLiq,
        uint256 toGrowth,
        uint256 toBank,
        uint256 total
    ) external;
}

contract TokenV2 is Initializable, IERC20Upgradeable, OwnableUpgradeable {
    uint256 public override totalSupply;

    string public name;
    uint8 public decimals;
    string public symbol;

    bytes32 public POOL_ID;

    // [rewards, growth, bank]
    address[3] public feesReceivers;

    // [rewards, liqudity, growth, bank]
    uint8[4] buyFeesDistribution;
    uint8[4] saleFeesDistribution;
    uint8[4] transferFeesDistribution;

    // [rewards, liqudity, growth, total]
    uint256[5] public feesCounter;

    uint256 public swapThreshold;

    bool public executeSwapsActive;

    IVault public BAL_VAULT;

    address public FEE_BOT;

    struct Fees {
        uint8 buy;
        uint8 sale;
        uint8 transfer;
    }

    Fees public fees;

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowances;
    mapping(address => bool) public isLiquidityPair;
    mapping(address => bool) public isBlacklisted;
    mapping(address => bool) public isExcludedFromFee;

    ISwapperPCS public SWAPPER_PCS;
    IUniswapV2Router02 public ROUTER;
    bool public inSwap;

    event ExecSwap(
        uint256 toLiq,
        uint256 toGrowth,
        uint256 toBank,
        uint256 total
    );

    modifier inSwapLock() {
        inSwap = true;
        _;
        inSwap = false;
    }

    function initialize(
        uint256 _initialAmount,
        string memory _tokenName,
        uint8 _decimalUnits,
        string memory _tokenSymbol,
        address _vault,
        address _rewards,
        address _growth,
        address _bank,
        address _feeBot
    ) public initializer {
        __Ownable_init();
        balances[_msgSender()] = _initialAmount;
        totalSupply = _initialAmount;
        name = _tokenName;
        decimals = _decimalUnits;
        symbol = _tokenSymbol;

        BAL_VAULT = IVault(_vault);
        FEE_BOT = _feeBot;

        _approve(msg.sender, address(BAL_VAULT), type(uint256).max);
        _approve(address(this), address(BAL_VAULT), type(uint256).max);
        IERC20Upgradeable(BAL_VAULT.WETH()).approve(
            address(BAL_VAULT),
            type(uint256).max
        );

        isLiquidityPair[address(BAL_VAULT)] = true;

        isExcludedFromFee[address(this)] = true;
        isExcludedFromFee[_msgSender()] = true;
        isExcludedFromFee[_rewards] = true;
        isExcludedFromFee[_growth] = true;
        isExcludedFromFee[_bank] = true;
        isExcludedFromFee[_feeBot] = true;

        emit Transfer(address(0), _msgSender(), _initialAmount);
        emit OwnershipTransferred(address(0), _msgSender());

        fees = Fees({buy: 10, sale: 10, transfer: 10});
        feesReceivers = [_rewards, _growth, _bank];
        buyFeesDistribution = [10, 20, 50, 20];
        saleFeesDistribution = [10, 20, 50, 20];
        transferFeesDistribution = [10, 20, 50, 20];
        feesCounter = [0, 0, 0, 0, 0];
        swapThreshold = 100e18;
        executeSwapsActive = true;
        POOL_ID = 0x0000000000000000000000000000000000000000000000000000000000000000;
    }

    function _transferExcluded(
        address _from,
        address _to,
        uint256 _value
    ) private {
        balances[_from] -= _value;
        balances[_to] += _value;
        emit Transfer(_from, _to, _value);
    }

    function _transferNoneExcluded(
        address _from,
        address _to,
        uint256 _value
    ) private {
        balances[_from] -= _value;

        uint256 feeValue = 0;
        uint8[4] memory feesDistribution;

        if (isLiquidityPair[_from]) {
            // buy
            feeValue = (_value * fees.buy) / 100;
            feesDistribution = buyFeesDistribution;
        } else if (isLiquidityPair[_to]) {
            // sell
            feeValue = (_value * fees.sale) / 100;
            feesDistribution = saleFeesDistribution;
        } else {
            // transfer
            feeValue = (_value * fees.transfer) / 100;
            feesDistribution = transferFeesDistribution;
        }

        uint256 receivedValue = _value - feeValue;

        balances[_to] += receivedValue;
        emit Transfer(_from, _to, receivedValue);

        // REWARDS POOL
        uint256 rewardsFee = (feeValue * feesDistribution[0]) / 100;
        feesCounter[0] += rewardsFee;
        balances[feesReceivers[0]] += rewardsFee;
        emit Transfer(_from, feesReceivers[0], rewardsFee);

        // LIQUIDITY AND GROWTH
        for (uint8 i = 1; i < 4; i++) {
            feesCounter[i] += (feeValue * feesDistribution[i]) / 100;
        }
        balances[address(this)] += feeValue - rewardsFee;
        emit Transfer(_from, address(this), feeValue - rewardsFee);

        feesCounter[4] += feeValue - rewardsFee;
        if (
            feesCounter[4] >= swapThreshold &&
            executeSwapsActive &&
            !isLiquidityPair[_from] &&
            !inSwap
        ) _executeSwaps();
    }

    function _executeSwaps() private inSwapLock {
        uint256 toLiq = feesCounter[1];
        uint256 toGrowth = feesCounter[2];
        uint256 toBank = feesCounter[3];
        uint256 total = feesCounter[4];

        _approve(address(this), address(ROUTER), type(uint256).max);

        total -= toLiq / 2;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = ROUTER.WETH();

        ROUTER.swapExactTokensForETHSupportingFeeOnTransferTokens(
            total,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 bnbBalance = payable(address(this)).balance;

        ROUTER.addLiquidityETH{value: ((bnbBalance * toLiq) / 2) / total}(
            address(this),
            toLiq / 2,
            0,
            0,
            feesReceivers[1],
            block.timestamp
        );

        (bool success, ) = payable(feesReceivers[1]).call{
            value: payable(address(this)).balance
        }(new bytes(0));
        require(success, "EXECSWAP: ETH_TRANSFER_FAILED");

        feesCounter[1] = 0;
        feesCounter[2] = 0;
        feesCounter[3] = 0;
        feesCounter[4] = 0;
    }

    function _executeTransfer(
        address _from,
        address _to,
        uint256 _value
    ) private {
        if (isExcludedFromFee[_from] || isExcludedFromFee[_to])
            _transferExcluded(_from, _to, _value);
        else _transferNoneExcluded(_from, _to, _value);
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _value
    ) private {
        require(
            _from != address(0),
            "TRANSFER: Transfer from the dead address"
        );
        require(_to != address(0), "TRANSFER: Transfer to the dead address");
        require(_value > 0, "TRANSFER: Invalid amount");
        require(isBlacklisted[_from] == false, "TRANSFER: isBlacklisted");
        require(balances[_from] >= _value, "TRANSFER: Insufficient balance");
        _executeTransfer(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value)
        public
        override
        returns (bool success)
    {
        _transfer(_msgSender(), _to, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public override returns (bool success) {
        if (allowances[_from][_msgSender()] < type(uint256).max) {
            allowances[_from][_msgSender()] -= _value;
        }
        _transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner)
        public
        view
        override
        returns (uint256 balance)
    {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value)
        public
        override
        returns (bool success)
    {
        _approve(_msgSender(), _spender, _value);
        return true;
    }

    function _approve(
        address _sender,
        address _spender,
        uint256 _value
    ) private returns (bool success) {
        allowances[_sender][_spender] = _value;
        emit Approval(_sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender)
        public
        view
        override
        returns (uint256 remaining)
    {
        return allowances[_owner][_spender];
    }

    /***********************************|
    |         Owner Functions           |
    |__________________________________*/

    function setPoolid(bytes32 poolId) public onlyOwner {
        POOL_ID = poolId;
    }

    function setFeeBot(address feeBot) public onlyOwner {
        FEE_BOT = feeBot;
    }

    function setRouter(address router) public onlyOwner {
        ROUTER = IUniswapV2Router02(router);
        _approve(address(this), router, type(uint256).max);
        IERC20Upgradeable(ROUTER.WETH()).approve(router, type(uint256).max);
    }

    function setSwapperPCS(address value) public onlyOwner {
        SWAPPER_PCS = ISwapperPCS(value);
        isExcludedFromFee[value] = true;
    }

    function getPoolId() public view returns (bytes32) {
        return POOL_ID;
    }

    function setIsBlacklisted(address user, bool value) public onlyOwner {
        isBlacklisted[user] = value;
    }

    function setIsExcludedFromFee(address user, bool value) public onlyOwner {
        isExcludedFromFee[user] = value;
    }

    function setIsLiquidityPair(address user, bool value) public onlyOwner {
        isLiquidityPair[user] = value;
    }

    function setVault(address vault) public onlyOwner {
        BAL_VAULT = IVault(vault);
    }

    function approveOnRouter() public onlyOwner {
        _approve(address(this), address(BAL_VAULT), type(uint256).max);
    }

    function setFees(
        uint8 buy_,
        uint8 sale_,
        uint8 transfer_
    ) public onlyOwner {
        fees = Fees({buy: buy_, sale: sale_, transfer: transfer_});
    }

    function setFeesReceivers(address[3] memory value) public onlyOwner {
        feesReceivers = value;
    }

    function setBuyFeesDistribution(uint8[4] memory value) public onlyOwner {
        buyFeesDistribution = value;
    }

    function setSaleFeesDistribution(uint8[4] memory value) public onlyOwner {
        saleFeesDistribution = value;
    }

    function setTransferFeesDistribution(uint8[4] memory value)
        public
        onlyOwner
    {
        transferFeesDistribution = value;
    }

    function setSwapThreshold(uint256 value) public onlyOwner {
        swapThreshold = value;
    }

    function setExecuteSwapsActive(bool value) public onlyOwner {
        executeSwapsActive = value;
    }

    function withdrawTokens() public onlyOwner {
        _transferExcluded(address(this), owner(), balanceOf(address(this)));
    }

    function withdrawTokensFeebot() public onlyOwner {
        _transferExcluded(FEE_BOT, owner(), balanceOf(FEE_BOT));
    }

    receive() external payable {}
}