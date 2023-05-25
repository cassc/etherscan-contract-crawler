//SPDX-License-Identifier: None

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IFX1SportsToken.sol";

/// @title FX1 Sports Token
/// @title https://fx1.io/
/// @title https://t.me/fx1_sports_portal
/// @author https://PROOFplatform.io
/// @author https://5thWeb.io

contract FX1SportsToken is Ownable2Step, IFX1SportsToken {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public bots;
    mapping(address => bool) public excludedFromFees;
    mapping(address => bool) public excludedFromMaxTransfer;
    mapping(address => bool) public excludedFromMaxWallet;
    mapping(address => bool) public whitelists;

    uint256 private _totalSupply = 250_000_000 * 10 ** _decimals;
    uint256 public launchTime;
    uint256 public whitelistPeriod;
    uint256 public swapThreshold;
    uint256 public maxTransferAmount;
    uint256 public maxWalletAmount;
    uint256 private accLiquidityAmount;
    uint256 private accMarketingAmount;
    uint256 private accPROOFAmount;

    address public marketingTaxRecv;
    address public proofRevenue;
    address public proofRewards;
    address public proofAdmin;
    address public pair;
    address constant DEAD = 0x000000000000000000000000000000000000dEaD;

    bool private inSwapLiquidity;

    string private _name = "FX1 Sports";
    string private _symbol = "FX1";

    uint16 public immutable FIXED_POINT = 1000;
    uint8 private constant _decimals = 18;

    IUniswapV2Router02 public dexRouter;
    BuyFeeRate public buyfeeRate;
    SellFeeRate public sellfeeRate;

    modifier onlyPROOFAdmin() {
        require(
            proofAdmin == _msgSender(),
            "Ownable: caller is not the proofAdmin"
        );
        _;
    }

    constructor(Param memory _param) {
        require(
            _param.proofRevenue != address(0),
            "invalid PROOF Revenue address"
        );
        require(
            _param.proofRewards != address(0),
            "invalid PROOF Rewards address"
        );
        require(
            _param.proofAdmin != address(0),
            "invalid PROOF Rewards address"
        );
        require(
            _param.marketingTaxRecv != address(0),
            "invalid MarketingTaxRecv address"
        );
        require(
            _param.teamAllocator_1 != address(0),
            "invalid teamAllocator_1 address"
        );
        require(
            _param.teamAllocator_2 != address(0),
            "invalid teamAllocator_2 address"
        );
        require(_param.dexRouter != address(0), "invalid dexRouter adddress");
        require(_param.whitelistPeriod > 0, "invalid whitelistPeriod");
        require(_param.proofFeeDuration > 0, "invalid proofFeeDuration");
        require(
            _param.highPROOFFeeRate > 0 &&
                _param.highPROOFFeeRate > _param.normalPROOFFeeRate,
            "invalid highPROOFFeeRate"
        );
        require(_param.normalPROOFFeeRate > 0, "invalid normalPROOFFeeRate");
        require(
            _param.totalTeamAllocationRate > 0,
            "invalid totalTeamAllocationRate"
        );
        require(
            _param.totalTeamAllocationRate ==
                _param.teamAllocationRate_1 + _param.teamAllocationRate_2,
            "invalid teamAllocationRates"
        );

        address sender = msg.sender;
        proofRevenue = _param.proofRevenue;
        proofRewards = _param.proofRewards;
        proofAdmin = _param.proofAdmin;
        marketingTaxRecv = _param.marketingTaxRecv;
        dexRouter = IUniswapV2Router02(_param.dexRouter);
        whitelistPeriod = _param.whitelistPeriod;
        buyfeeRate.highPROOFFeeRate = _param.highPROOFFeeRate;
        buyfeeRate.normalPROOFFeeRate = _param.normalPROOFFeeRate;
        buyfeeRate.liquidityFeeRate = _param.liquidityFeeRate;
        buyfeeRate.marketingFeeRate = _param.marketingFeeRate;
        buyfeeRate.proofFeeDuration = _param.proofFeeDuration;
        buyfeeRate.highTotalFeeRate =
            _param.marketingFeeRate +
            _param.liquidityFeeRate +
            _param.highPROOFFeeRate;
        buyfeeRate.normalTotalFeeRate =
            _param.marketingFeeRate +
            _param.liquidityFeeRate +
            _param.normalPROOFFeeRate;

        sellfeeRate.highPROOFFeeRate = _param.highPROOFFeeRate;
        sellfeeRate.normalPROOFFeeRate = _param.normalPROOFFeeRate;
        sellfeeRate.liquidityFeeRate = _param.liquidityFeeRate;
        sellfeeRate.marketingFeeRate = _param.marketingFeeRate;
        sellfeeRate.proofFeeDuration = _param.proofFeeDuration;
        sellfeeRate.highTotalFeeRate =
            _param.marketingFeeRate +
            _param.liquidityFeeRate +
            _param.highPROOFFeeRate;
        sellfeeRate.normalTotalFeeRate =
            _param.marketingFeeRate +
            _param.liquidityFeeRate +
            _param.normalPROOFFeeRate;

        pair = IUniswapV2Factory(dexRouter.factory()).createPair(
            dexRouter.WETH(),
            address(this)
        );

        excludedFromFees[sender] = true;
        excludedFromMaxTransfer[sender] = true;
        excludedFromMaxTransfer[pair] = true;
        excludedFromMaxTransfer[address(this)] = true;
        excludedFromMaxWallet[sender] = true;
        excludedFromMaxWallet[pair] = true;
        excludedFromMaxWallet[address(this)] = true;
        excludedFromMaxWallet[proofRevenue] = true;
        excludedFromMaxWallet[proofRewards] = true;
        excludedFromMaxWallet[proofAdmin] = true;
        excludedFromMaxWallet[marketingTaxRecv] = true;
        whitelists[sender] = true;
        whitelists[pair] = true;
        whitelists[address(this)] = true;

        uint256 totalTeamAllocationAmount = (_totalSupply *
            _param.totalTeamAllocationRate) / FIXED_POINT;
        uint256 teamAllocationAmount_1 = (_totalSupply *
            _param.teamAllocationRate_1) / FIXED_POINT;
        uint256 teamAllocationAmount_2 = totalTeamAllocationAmount -
            teamAllocationAmount_1;
        uint256 amountForDeployer = _totalSupply - totalTeamAllocationAmount;
        _balances[_param.teamAllocator_1] += teamAllocationAmount_1;
        _balances[_param.teamAllocator_2] += teamAllocationAmount_2;
        _balances[msg.sender] += amountForDeployer;
        emit Transfer(address(0), msg.sender, amountForDeployer);
        emit Transfer(
            address(0),
            _param.teamAllocator_1,
            teamAllocationAmount_1
        );
        emit Transfer(
            address(0),
            _param.teamAllocator_2,
            teamAllocationAmount_2
        );
        swapThreshold = _totalSupply / 10000; // 0.01%
        maxTransferAmount = (_totalSupply * 5) / 1000; // 0.5%
        maxWalletAmount = (_totalSupply * 1) / 100; // 1%
    }

    // !---------------- functions for ERC20 token ----------------!
    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(
        address _recipient,
        uint256 _amount
    ) external override returns (bool) {
        _transfer(msg.sender, _recipient, _amount);
        return true;
    }

    function allowance(
        address _owner,
        address _spender
    ) external view override returns (uint256) {
        return _allowances[_owner][_spender];
    }

    function approve(
        address _spender,
        uint256 _amount
    ) external override returns (bool) {
        _approve(msg.sender, _spender, _amount);
        return true;
    }

    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) external override returns (bool) {
        uint256 currentAllowance = _allowances[_sender][msg.sender];
        require(currentAllowance >= _amount, "Transfer > allowance");
        _approve(_sender, msg.sender, currentAllowance - _amount);
        _transfer(_sender, _recipient, _amount);
        return true;
    }

    // !---------------- functions for ERC20 token ----------------!

    /// @inheritdoc IFX1SportsToken
    function updatePROOFAdmin(
        address _newAdmin
    ) external override onlyPROOFAdmin {
        require(_newAdmin != address(0), "invalid proofAdmin address");
        proofAdmin = _newAdmin;
    }

    /// @inheritdoc IFX1SportsToken
    function setBots(address[] memory _bots) external override onlyPROOFAdmin {
        uint256 length = _bots.length;
        require(length > 0, "invalid array length");
        for (uint256 i = 0; i < _bots.length; i++) {
            bots[_bots[i]] = true;
        }
    }

    /// @inheritdoc IFX1SportsToken
    function cancelToken() external override onlyPROOFAdmin {
        excludedFromFees[address(dexRouter)] = true;
        excludedFromMaxTransfer[address(dexRouter)] = true;
        excludedFromMaxWallet[address(dexRouter)] = true;
        excludedFromMaxTransfer[owner()] = true;
        excludedFromMaxWallet[owner()] = true;
        _transferOwnership(proofAdmin);
    }

    /// @inheritdoc IFX1SportsToken
    function formatPROOFFee() external override onlyPROOFAdmin {
        require(buyfeeRate.normalPROOFFeeRate != 0, "already reduced");
        require(buyfeeRate.highPROOFFeeRate != 0, "already reduced");
        require(sellfeeRate.normalPROOFFeeRate != 0, "already reduced");
        require(sellfeeRate.highPROOFFeeRate != 0, "already reduced");
        buyfeeRate.highTotalFeeRate =
            buyfeeRate.highTotalFeeRate +
            0 -
            buyfeeRate.highPROOFFeeRate;
        buyfeeRate.highPROOFFeeRate = 0;
        buyfeeRate.normalTotalFeeRate =
            buyfeeRate.normalTotalFeeRate +
            0 -
            buyfeeRate.normalPROOFFeeRate;
        buyfeeRate.normalPROOFFeeRate = 0;

        sellfeeRate.highTotalFeeRate =
            sellfeeRate.highTotalFeeRate +
            0 -
            sellfeeRate.highPROOFFeeRate;
        sellfeeRate.highPROOFFeeRate = 0;
        sellfeeRate.normalTotalFeeRate =
            sellfeeRate.normalTotalFeeRate +
            0 -
            sellfeeRate.normalPROOFFeeRate;
        sellfeeRate.normalPROOFFeeRate = 0;
    }

    /// @inheritdoc IFX1SportsToken
    function delBot(address _notbot) external override {
        address sender = _msgSender();
        require(
            sender == proofAdmin || sender == owner(),
            "Ownable: caller doesn't have permission"
        );
        bots[_notbot] = false;
    }

    /// @inheritdoc IFX1SportsToken
    function setLaunchBegin() external override onlyOwner {
        require(launchTime == 0, "already launched");
        launchTime = block.timestamp;
    }

    /// @inheritdoc IFX1SportsToken
    function addWhitelists(
        address[] memory _accounts,
        bool _add
    ) external override onlyOwner {
        uint256 length = _accounts.length;
        require(length > 0, "invalid accounts length");

        for (uint256 i = 0; i < length; i++) {
            whitelists[_accounts[i]] = _add;
        }
    }

    /// @inheritdoc IFX1SportsToken
    function excludeWalletsFromMaxTransfer(
        address[] memory _accounts,
        bool _add
    ) external override onlyOwner {
        uint256 length = _accounts.length;
        require(length > 0, "invalid length array");
        for (uint256 i = 0; i < length; i++) {
            excludedFromMaxTransfer[_accounts[i]] = _add;
        }
    }

    /// @inheritdoc IFX1SportsToken
    function excludeWalletsFromMaxWallets(
        address[] memory _accounts,
        bool _add
    ) external override onlyOwner {
        uint256 length = _accounts.length;
        require(length > 0, "invalid length array");
        for (uint256 i = 0; i < length; i++) {
            excludedFromMaxWallet[_accounts[i]] = _add;
        }
    }

    /// @inheritdoc IFX1SportsToken
    function excludeWalletsFromFees(
        address[] memory _accounts,
        bool _add
    ) external override onlyOwner {
        uint256 length = _accounts.length;
        require(length > 0, "invalid length array");
        for (uint256 i = 0; i < length; i++) {
            excludedFromFees[_accounts[i]] = _add;
        }
    }

    /// @inheritdoc IFX1SportsToken
    function setMaxTransferAmount(
        uint256 newLimit
    ) external override onlyOwner {
        require(newLimit >= (_totalSupply * 5) / 1000, "Min 0.5% limit");
        maxTransferAmount = newLimit;
    }

    /// @inheritdoc IFX1SportsToken
    function setMaxWalletAmount(uint256 newLimit) external override onlyOwner {
        require(newLimit >= (_totalSupply * 10) / 1000, "Min 1% limit");
        maxWalletAmount = newLimit;
    }

    /// @inheritdoc IFX1SportsToken
    function setMarketingTaxWallet(
        address _marketingTaxWallet
    ) external override onlyOwner {
        require(
            _marketingTaxWallet != address(0),
            "invalid marketingTaxWallet address"
        );
        marketingTaxRecv = _marketingTaxWallet;
    }

    /// @inheritdoc IFX1SportsToken
    function reducePROOFFeeRate() external override onlyOwner {
        require(
            block.timestamp > launchTime + buyfeeRate.proofFeeDuration,
            "You must wait 72 hrs"
        );
        buyfeeRate.highTotalFeeRate =
            buyfeeRate.highTotalFeeRate +
            10 -
            buyfeeRate.highPROOFFeeRate;
        buyfeeRate.highPROOFFeeRate = 10;
        buyfeeRate.normalTotalFeeRate =
            buyfeeRate.normalTotalFeeRate +
            10 -
            buyfeeRate.normalPROOFFeeRate;
        buyfeeRate.normalPROOFFeeRate = 10;
        sellfeeRate.highTotalFeeRate =
            sellfeeRate.highTotalFeeRate +
            10 -
            sellfeeRate.highPROOFFeeRate;
        sellfeeRate.highPROOFFeeRate = 10;
        sellfeeRate.normalTotalFeeRate =
            sellfeeRate.normalTotalFeeRate +
            10 -
            sellfeeRate.normalPROOFFeeRate;
        sellfeeRate.normalPROOFFeeRate = 10;
    }

    /// @inheritdoc IFX1SportsToken
    function setMarketingFeeRate(
        uint16 _marketingBuyFeeRate,
        uint16 _marketingSellFeeRate
    ) external override onlyOwner {
        uint16 maxRateSet = 100;
        require(
            _marketingBuyFeeRate <= maxRateSet &&
                _marketingSellFeeRate <= maxRateSet,
            "Max Rate exceeded, please lower value"
        );
            buyfeeRate.highTotalFeeRate =
                buyfeeRate.highTotalFeeRate +
                _marketingBuyFeeRate -
                buyfeeRate.marketingFeeRate;
            buyfeeRate.normalTotalFeeRate =
                buyfeeRate.normalTotalFeeRate +
                _marketingBuyFeeRate -
                buyfeeRate.marketingFeeRate;
        buyfeeRate.marketingFeeRate = _marketingBuyFeeRate;
            sellfeeRate.highTotalFeeRate =
                sellfeeRate.highTotalFeeRate +
                _marketingSellFeeRate -
                sellfeeRate.marketingFeeRate;
            sellfeeRate.normalTotalFeeRate =
                sellfeeRate.normalTotalFeeRate +
                _marketingSellFeeRate -
                sellfeeRate.marketingFeeRate;
        sellfeeRate.marketingFeeRate = _marketingSellFeeRate;
    }

    /// @inheritdoc IFX1SportsToken
    function setLiquidityFeeRate(
        uint16 _liquidityBuyFeeRate,
        uint16 _liquiditySellFeeRate
    ) external override onlyOwner {
        uint16 maxRateSet = 100;
        require(
            _liquidityBuyFeeRate <= maxRateSet &&
                _liquiditySellFeeRate <= maxRateSet,
            "Max Rate exceeded, please lower value"
        );
            buyfeeRate.highTotalFeeRate =
                buyfeeRate.highTotalFeeRate +
                _liquidityBuyFeeRate -
                buyfeeRate.liquidityFeeRate;
            buyfeeRate.normalTotalFeeRate =
                buyfeeRate.normalTotalFeeRate +
                _liquidityBuyFeeRate -
                buyfeeRate.liquidityFeeRate;
        buyfeeRate.liquidityFeeRate = _liquidityBuyFeeRate;
            sellfeeRate.highTotalFeeRate =
                sellfeeRate.highTotalFeeRate +
                _liquiditySellFeeRate -
                sellfeeRate.liquidityFeeRate;
            sellfeeRate.normalTotalFeeRate =
                sellfeeRate.normalTotalFeeRate +
                _liquiditySellFeeRate -
                sellfeeRate.liquidityFeeRate;
        sellfeeRate.liquidityFeeRate = _liquiditySellFeeRate;
    }

    /// @inheritdoc IFX1SportsToken
    function setSwapThreshold(
        uint256 _swapThreshold
    ) external override onlyOwner {
        require(_swapThreshold > 0, "invalid swapThreshold");
        swapThreshold = _swapThreshold;
    }

    receive() external payable {}

    function _transfer(
        address _sender,
        address _recipient,
        uint256 _amount
    ) internal {
        require(_sender != address(0), "transfer from zero address");
        require(!bots[_sender] || !bots[_recipient], "no bots allowed");
        require(_recipient != address(0), "transfer to zero address");
        require(_amount > 0, "zero amount");
        require(_balances[_sender] >= _amount, "not enough amount to transfer");
        require(_sender == owner() || launchTime != 0, "not launched yet");
        if (block.timestamp < launchTime + whitelistPeriod) {
            require(whitelists[_recipient], "only whitelist");
        }
        require(
            excludedFromMaxTransfer[_sender] ||
                _amount <= maxTransferAmount + (10 * 10 ** _decimals),
            "exceeds to maxTransferAmount"
        );
        require(
            excludedFromMaxWallet[_recipient] ||
                _balances[_recipient] + _amount <=
                maxWalletAmount + (10 * 10 ** _decimals),
            "exceeds to maxWalletAmount"
        );

        if (
            inSwapLiquidity ||
            excludedFromFees[_recipient] ||
            excludedFromFees[_sender]
        ) {
            _basicTransfer(_sender, _recipient, _amount);
            emit Transfer(_sender, _recipient, _amount);
            return;
        }

        if (_sender == pair) {
            // buy
            _taxonBuyTransfer(_sender, _recipient, _amount);
        } else {
            _swapBack();
            if (_recipient == pair) {
                // sell
                _taxonSellTransfer(_sender, _recipient, _amount);
            } else {
                _basicTransfer(_sender, _recipient, _amount);
            }
        }

        emit Transfer(_sender, _recipient, _amount);
    }

    function _approve(
        address _owner,
        address _spender,
        uint256 _amount
    ) private {
        require(_owner != address(0), "Approve from zero");
        require(_spender != address(0), "Approve to zero");
        _allowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }

    function _swapBack() internal {
        uint256 accTotalAmount = accPROOFAmount +
            accLiquidityAmount +
            accMarketingAmount;
        if (accTotalAmount <= swapThreshold) {
            return;
        }
        inSwapLiquidity = true;
        uint256 swapAmountForLiquidity = accLiquidityAmount / 2;
        uint256 swapAmount = accTotalAmount - swapAmountForLiquidity;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();
        _approve(address(this), address(dexRouter), swapAmount);
        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            swapAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
        uint256 swappedETHAmount = address(this).balance;
        require(swappedETHAmount > 0, "too small token for swapBack");
        uint256 ethForLiquidity = (swappedETHAmount * swapAmountForLiquidity) /
            swapAmount;

        if (ethForLiquidity > 0) {
            uint256 amountForLiquidity = accLiquidityAmount -
                swapAmountForLiquidity;
            _approve(address(this), address(dexRouter), amountForLiquidity);
            dexRouter.addLiquidityETH{value: ethForLiquidity}(
                address(this),
                amountForLiquidity,
                0,
                0,
                0x000000000000000000000000000000000000dEaD,
                block.timestamp
            );
            swappedETHAmount -= ethForLiquidity;
        }

        uint256 ethForPROOF = (swappedETHAmount * accPROOFAmount) / swapAmount;
        uint256 ethForPROOFRevenue = ethForPROOF / 2;
        uint256 ethForPROOFRewards = ethForPROOF - ethForPROOFRevenue;
        uint256 ethForMarketing = swappedETHAmount - ethForPROOF;
        _transferETH(proofRevenue, ethForPROOFRevenue);
        _transferETH(proofRewards, ethForPROOFRewards);
        _transferETH(marketingTaxRecv, ethForMarketing);

        accLiquidityAmount = 0;
        accMarketingAmount = 0;
        accPROOFAmount = 0;
        inSwapLiquidity = false;
    }

    function _taxonSellTransfer(
        address _sender,
        address _recipient,
        uint256 _amount
    ) internal {
        (
            uint16 totalFeeRate,
            uint16 proofFeeRate,
            ,
            uint16 liquidityFeeRate
        ) = _getSellFeeRate();

        uint256 feeAmount = (_amount * totalFeeRate) / FIXED_POINT;
        uint256 proofFeeAmount = (_amount * proofFeeRate) / FIXED_POINT;
        uint256 liquidityFeeAmount = (_amount * liquidityFeeRate) / FIXED_POINT;
        uint256 marketingFeeAmount = feeAmount -
            proofFeeAmount -
            liquidityFeeAmount;
        uint256 recvAmount = _amount - feeAmount;

        _balances[_sender] -= _amount;
        _balances[_recipient] += recvAmount;
        _balances[address(this)] += feeAmount;
        accPROOFAmount += proofFeeAmount;
        accLiquidityAmount += liquidityFeeAmount;
        accMarketingAmount += marketingFeeAmount;
    }

    function _taxonBuyTransfer(
        address _sender,
        address _recipient,
        uint256 _amount
    ) internal {
        (
            uint16 totalFeeRate,
            uint16 proofFeeRate,
            ,
            uint16 liquidityFeeRate
        ) = _getBuyFeeRate();

        uint256 feeAmount = (_amount * totalFeeRate) / FIXED_POINT;
        uint256 proofFeeAmount = (_amount * proofFeeRate) / FIXED_POINT;
        uint256 liquidityFeeAmount = (_amount * liquidityFeeRate) / FIXED_POINT;
        uint256 marketingFeeAmount = feeAmount -
            proofFeeAmount -
            liquidityFeeAmount;
        uint256 recvAmount = _amount - feeAmount;

        _balances[_sender] -= _amount;
        _balances[_recipient] += recvAmount;
        _balances[address(this)] += feeAmount;
        accPROOFAmount += proofFeeAmount;
        accLiquidityAmount += liquidityFeeAmount;
        accMarketingAmount += marketingFeeAmount;
    }

    function _basicTransfer(
        address _sender,
        address _recipient,
        uint256 _amount
    ) internal {
        _balances[_sender] -= _amount;
        _balances[_recipient] += _amount;
    }

    function _getSellFeeRate()
        internal
        view
        returns (
            uint16 _totalFeeRate,
            uint16 _proofFeeRate,
            uint16 _marketingFeeRate,
            uint16 _liquidityFeeRate
        )
    {
        if (block.timestamp < launchTime + sellfeeRate.proofFeeDuration) {
            return (
                sellfeeRate.highTotalFeeRate,
                sellfeeRate.highPROOFFeeRate,
                sellfeeRate.marketingFeeRate,
                sellfeeRate.liquidityFeeRate
            );
        } else {
            return (
                sellfeeRate.normalTotalFeeRate,
                sellfeeRate.normalPROOFFeeRate,
                sellfeeRate.marketingFeeRate,
                sellfeeRate.liquidityFeeRate
            );
        }
    }

    function _getBuyFeeRate()
        internal
        view
        returns (
            uint16 _totalFeeRate,
            uint16 _proofFeeRate,
            uint16 _marketingFeeRate,
            uint16 _liquidityFeeRate
        )
    {
        if (block.timestamp < launchTime + buyfeeRate.proofFeeDuration) {
            return (
                buyfeeRate.highTotalFeeRate,
                buyfeeRate.highPROOFFeeRate,
                buyfeeRate.marketingFeeRate,
                buyfeeRate.liquidityFeeRate
            );
        } else {
            return (
                buyfeeRate.normalTotalFeeRate,
                buyfeeRate.normalPROOFFeeRate,
                buyfeeRate.marketingFeeRate,
                buyfeeRate.liquidityFeeRate
            );
        }
    }

    function _transferETH(address _recipient, uint256 _amount) internal {
        if (_amount == 0) return;
        (bool sent, ) = _recipient.call{value: _amount}("");
        require(sent, "sending ETH failed");
    }
}