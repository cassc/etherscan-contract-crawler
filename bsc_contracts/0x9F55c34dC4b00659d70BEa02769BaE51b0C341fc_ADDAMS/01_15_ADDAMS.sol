// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "./interfaces/IDistribution.sol";

contract ADDAMS is IERC20Metadata, AccessControl {
    using SafeMath for uint256;

    mapping(address => uint256) private balances;

    mapping(address => mapping(address => uint256)) private allowances;

    uint256 public override totalSupply;

    string public override name;
    string public override symbol;
    uint8 public constant override decimals = 18;

    address public constant deadAddress = 0x000000000000000000000000000000000000dEaD;

    address public token1;
    IUniswapV2Router02 public router;
    address public pair;

    mapping(address => bool) public isLpToken;
    mapping(address => bool) public excludedFromFee;
    mapping(address => bool) public excludedFromSwap;

    IDistribution public distribution;

    bool private inSwap;

    uint256 public feeCounter = 0;
    uint256 public feeLimit = 8;

    uint256 public burnFeeBuyRate;
    uint256 public burnFeeSellRate;
    uint256 public burnFeeTransferRate;
    address[] public burnFeeReceivers;
    uint256[] public burnFeeReceiversRate;

    uint256 public liquidityFeeBuyRate;
    uint256 public liquidityFeeSellRate;
    uint256 public liquidityFeeTransferRate;
    address[] public liquidityFeeReceivers;
    uint256[] public liquidityFeeReceiversRate;
    uint256 public liquidityFeeAmount;

    uint256 public swapFeeBuyRate;
    uint256 public swapFeeSellRate;
    uint256 public swapFeeTransferRate;
    address[] public swapFeeReceivers;
    uint256[] public swapFeeReceiversRate;
    uint256 public swapFeeAmount;

    address immutable public rewardSwapAddress;
    uint256 public rewardSellAmount;
    uint256 public rewardSellRate;
    uint256 public rewardBuyAmount;
    uint256 public rewardBuyRate;
    address[] public rewardSwapReceivers;
    uint256[] public rewardSwapReceiversRate;

    bool public enabledSwapForSell = true;

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    event RouterAndPairUpdated(address _router, address _pair);
    event LpTokenUpdated(address _lpToken, bool _lp);
    event TokenRecovered(address _address, uint256 _amount);
    event ExcludedFromFee(address _address, bool _isExcludedFromFee);
    event ExcludedFromSwap(address _address, bool _isExcludedFromSwap);
    event RewardSwapReceiversUpdated(address[] _rewardSwapReceivers, uint256[] _rewardSwapReceiversRate);
    event RewardSellRateUpdated(uint256 _rewardSellRate);
    event RewardBuyRateUpdated(uint256 _rewardBuyRate);
    event RewardsAmountReseted();
    event BuyFeesUpdated(uint256 _burnFeeBuyRate, uint256 _liquidityFeeBuyRate, uint256 _swapFeeBuyRate);
    event SellFeesUpdated(uint256 _burnFeeSellRate, uint256 _liquidityFeeSellRate, uint256 _swapFeeSellRate);
    event TransferFeesUpdated(uint256 _burnFeeTransferRate, uint256 _liquidityFeeTransferRate, uint256 _swapFeeTransferRate);
    event FeeCounterReseted();
    event FeeLimitUpdated();
    event BurnFeeReceiversUpdated(address[] _burnFeeReceivers, uint256[] _burnFeeReceiversRate);
    event LiquidityFeeReceiversUpdated(address[] _liquidityFeeReceivers, uint256[] _liquidityFeeReceiversRate);
    event LiquidityFeeReseted();
    event SwapFeeReceiversUpdated(address[] _swapFeeReceivers, uint256[] _swapFeeReceiversRate);
    event SwapFeeReseted();
    event EnabledSwapForSellUpdated(bool _enabledSwapForSell);

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply,
        IDistribution _distribution,
        address _rewardSwapAddress,
        IUniswapV2Router02 _router,
        address _token1
    ) {
        name = _name;
        symbol = _symbol;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        _mint(msg.sender, _totalSupply * 10 ** 18);

        require(address(_distribution) != address(0), "zero distribution address");
        distribution = _distribution;

        require(_rewardSwapAddress != address(0), "zero reward swap address.");
        rewardSwapAddress = _rewardSwapAddress;

        updateRouterAndPair(_router, _token1);

        setExcludedFromFee(msg.sender, true);
        setExcludedFromSwap(msg.sender, true);

        setExcludedFromFee(address(this), true);
        setExcludedFromSwap(address(this), true);
    }

    function balanceOf(address _account) public view override returns (uint256) {
        return balances[_account];
    }

    function transfer(address _recipient, uint256 _amount) external override returns (bool) {
        _transfer(msg.sender, _recipient, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) public view override returns (uint256) {
        return allowances[_owner][_spender];
    }

    function approve(address _spender, uint256 _amount) external override returns (bool) {
        _approve(msg.sender, _spender, _amount);
        return true;
    }

    function transferFrom(address _sender, address _recipient, uint256 _amount) external override returns (bool) {
        _transfer(_sender, _recipient, _amount);

        uint256 currentAllowance = allowances[_sender][msg.sender];
        require(currentAllowance >= _amount, "ERC20: transfer amount exceeds allowance");
        _approve(_sender, msg.sender, currentAllowance.sub(_amount));

        return true;
    }

    function increaseAllowance(address _spender, uint256 _addedValue) external returns (bool) {
        _approve(msg.sender, _spender, allowances[msg.sender][_spender].add(_addedValue));
        return true;
    }

    function decreaseAllowance(address _spender, uint256 _subtractedValue) external returns (bool) {
        uint256 currentAllowance = allowances[msg.sender][_spender];
        require(currentAllowance >= _subtractedValue, "ERC20: decreased allowance below zero");
        _approve(msg.sender, _spender, currentAllowance.sub(_subtractedValue));

        return true;
    }

    function updateRouterAndPair(IUniswapV2Router02 _router, address _token1) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_token1 != address(0), "zero token1 address");

        address _pair = IUniswapV2Factory(_router.factory()).getPair(address(this), _token1);

        if (_pair == address(0)) {
            _pair = IUniswapV2Factory(_router.factory()).createPair(address(this), _token1);
        }

        router = _router;
        token1 = _token1;
        pair = _pair;
        isLpToken[pair] = true;

        emit RouterAndPairUpdated(address(_router), _token1);
    }

    function setLpToken(address _lpToken, bool _lp) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_lpToken != address(0), "BEP20: invalid LP address");
        require(_lpToken != pair, "ERC20: exclude default pair");

        isLpToken[_lpToken] = _lp;

        emit LpTokenUpdated(_lpToken, _lp);
    }

    function recoverTokens(address _address, uint256 _amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_address != address(this), "the token address can not be the current contract");
        IERC20(_address).transfer(msg.sender, _amount);

        emit TokenRecovered(_address, _amount);
    }

    function setExcludedFromFee(address _address, bool _isExcludedFromFee) public onlyRole(DEFAULT_ADMIN_ROLE) {
        excludedFromFee[_address] = _isExcludedFromFee;

        emit ExcludedFromFee(_address, _isExcludedFromFee);
    }

    function setExcludedFromSwap(address _address, bool _isExcludedFromSwap) public onlyRole(DEFAULT_ADMIN_ROLE) {
        excludedFromSwap[_address] = _isExcludedFromSwap;

        emit ExcludedFromSwap(_address, _isExcludedFromSwap);
    }

    function setRewardSwapReceivers(address[] calldata _rewardSwapReceivers, uint256[] calldata _rewardSwapReceiversRate) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_rewardSwapReceivers.length == _rewardSwapReceiversRate.length, "size");

        uint256 totalRate = 0;
        for (uint256 i = 0; i < _rewardSwapReceiversRate.length; i++) {
            totalRate = totalRate.add(_rewardSwapReceiversRate[i]);
        }
        require(totalRate == 10000, "rate");

        delete rewardSwapReceivers;
        delete rewardSwapReceiversRate;

        for (uint i = 0; i < _rewardSwapReceivers.length; i++) {
            rewardSwapReceivers.push(_rewardSwapReceivers[i]);
            rewardSwapReceiversRate.push(_rewardSwapReceiversRate[i]);
        }

        emit RewardSwapReceiversUpdated(_rewardSwapReceivers, _rewardSwapReceiversRate);
    }

    function setRewardSellRate(uint256 _rewardSellRate) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_rewardSellRate <= 3000, "_rewardSellRate");
        // min: 0%; max: 30%
        rewardSellRate = _rewardSellRate;

        emit RewardSellRateUpdated(_rewardSellRate);
    }

    function setRewardBuyRate(uint256 _rewardBuyRate) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_rewardBuyRate <= 3000, "_rewardBuyRate");
        // min: 0%; max: 30%
        rewardBuyRate = _rewardBuyRate;

        emit RewardBuyRateUpdated(_rewardBuyRate);
    }

    function resetRewardsAmount() external onlyRole(DEFAULT_ADMIN_ROLE) {
        rewardSellAmount = 0;
        rewardBuyAmount = 0;

        emit RewardsAmountReseted();
    }

    function updateBuyRates(uint256 _burnFeeBuyRate, uint256 _liquidityFeeBuyRate, uint256 _swapFeeBuyRate) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_burnFeeBuyRate.add(_liquidityFeeBuyRate).add(_swapFeeBuyRate) <= 900, "rate");

        burnFeeBuyRate = _burnFeeBuyRate;
        liquidityFeeBuyRate = _liquidityFeeBuyRate;
        swapFeeBuyRate = _swapFeeBuyRate;

        emit BuyFeesUpdated(_burnFeeBuyRate, _liquidityFeeBuyRate, _swapFeeBuyRate);
    }

    function updateSellRates(uint256 _burnFeeSellRate, uint256 _liquidityFeeSellRate, uint256 _swapFeeSellRate) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_burnFeeSellRate.add(_liquidityFeeSellRate).add(_swapFeeSellRate) <= 900, "rate");

        burnFeeSellRate = _burnFeeSellRate;
        liquidityFeeSellRate = _liquidityFeeSellRate;
        swapFeeSellRate = _swapFeeSellRate;

        emit SellFeesUpdated(_burnFeeSellRate, _liquidityFeeSellRate, _swapFeeSellRate);
    }

    function updateTransferRates(uint256 _burnFeeTransferRate, uint256 _liquidityFeeTransferRate, uint256 _swapFeeTransferRate) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_burnFeeTransferRate.add(_liquidityFeeTransferRate).add(_swapFeeTransferRate) <= 900, "rate");

        burnFeeTransferRate = _burnFeeTransferRate;
        liquidityFeeTransferRate = _liquidityFeeTransferRate;
        swapFeeTransferRate = _swapFeeTransferRate;

        emit TransferFeesUpdated(_burnFeeTransferRate, _liquidityFeeTransferRate, _swapFeeTransferRate);
    }

    function resetCounter() external onlyRole(DEFAULT_ADMIN_ROLE) {
        feeCounter = 0;

        emit FeeCounterReseted();
    }

    function setLimit(uint256 _feeLimit) external onlyRole(DEFAULT_ADMIN_ROLE) {
        feeLimit = _feeLimit;

        emit FeeLimitUpdated();
    }

    function updateBurnFeeReceivers(address[] calldata _burnFeeReceivers, uint256[] calldata _burnFeeReceiversRate) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_burnFeeReceivers.length == _burnFeeReceiversRate.length, "size");

        uint256 totalRate = 0;
        for (uint256 i = 0; i < _burnFeeReceiversRate.length; i++) {
            totalRate = totalRate.add(_burnFeeReceiversRate[i]);
        }
        require(totalRate == 10000, "rate");

        delete burnFeeReceivers;
        delete burnFeeReceiversRate;

        for (uint i = 0; i < _burnFeeReceivers.length; i++) {
            burnFeeReceivers.push(_burnFeeReceivers[i]);
            burnFeeReceiversRate.push(_burnFeeReceiversRate[i]);
        }

        emit BurnFeeReceiversUpdated(_burnFeeReceivers, _burnFeeReceiversRate);
    }

    function updateLiquidityFeeReceivers(address[] calldata _liquidityFeeReceivers, uint256[] calldata _liquidityFeeReceiversRate) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_liquidityFeeReceivers.length == _liquidityFeeReceiversRate.length, "size");

        uint256 totalRate = 0;
        for (uint256 i = 0; i < _liquidityFeeReceiversRate.length; i++) {
            totalRate = totalRate.add(_liquidityFeeReceiversRate[i]);
        }
        require(totalRate == 10000, "rate");

        delete liquidityFeeReceivers;
        delete liquidityFeeReceiversRate;

        for (uint i = 0; i < _liquidityFeeReceivers.length; i++) {
            liquidityFeeReceivers.push(_liquidityFeeReceivers[i]);
            liquidityFeeReceiversRate.push(_liquidityFeeReceiversRate[i]);
        }

        emit LiquidityFeeReceiversUpdated(_liquidityFeeReceivers, _liquidityFeeReceiversRate);
    }

    function resetLiquidityFee() external onlyRole(DEFAULT_ADMIN_ROLE) {
        liquidityFeeAmount = 0;

        emit LiquidityFeeReseted();
    }

    function updateSwapFeeReceivers(address[] calldata _swapFeeReceivers, uint256[] calldata _swapFeeReceiversRate) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_swapFeeReceivers.length == _swapFeeReceiversRate.length, "size");

        uint256 totalRate = 0;
        for (uint256 i = 0; i < _swapFeeReceiversRate.length; i++) {
            totalRate = totalRate.add(_swapFeeReceiversRate[i]);
        }
        require(totalRate == 10000, "rate");

        delete swapFeeReceivers;
        delete swapFeeReceiversRate;

        for (uint i = 0; i < _swapFeeReceivers.length; i++) {
            swapFeeReceivers.push(_swapFeeReceivers[i]);
            swapFeeReceiversRate.push(_swapFeeReceiversRate[i]);
        }

        emit SwapFeeReceiversUpdated(_swapFeeReceivers, _swapFeeReceiversRate);
    }

    function resetSwapFee() external onlyRole(DEFAULT_ADMIN_ROLE) {
        swapFeeAmount = 0;

        emit SwapFeeReseted();
    }

    function setEnabledSwapForSell(bool _enabledSwapForSell) external onlyRole(DEFAULT_ADMIN_ROLE) {
        enabledSwapForSell = _enabledSwapForSell;

        emit EnabledSwapForSellUpdated(_enabledSwapForSell);
    }

    function _transfer(address _sender, address _recipient, uint256 _amount) internal {
        require(_sender != address(0), "ERC20: transfer from the zero address");
        require(_recipient != address(0), "ERC20: transfer to the zero address");
        require(balances[_sender] >= _amount, "ERC20: transfer amount exceeds balance");

        uint256 calculatedAmount = _takeFees(_sender, _recipient, _amount);
        _transferAmount(_sender, _recipient, calculatedAmount);
    }

    function _takeFees(address _from, address _to, uint256 _amount) internal returns (uint256) {
        uint256 resultAmount = _amount;

        if (!inSwap) {

            if (
                !(excludedFromFee[_from] || excludedFromFee[_to])
            ) {

                feeCounter = feeCounter.add(1);

                uint256 burnFeeRes;
                uint256 liquidityFeeRes;
                uint256 swapFeeRes;

                if (_isBuy(_from, _to)) {
                    burnFeeRes = _calcFee(resultAmount, burnFeeBuyRate);
                    liquidityFeeRes = _calcFee(resultAmount, liquidityFeeBuyRate);
                    swapFeeRes = _calcFee(resultAmount, swapFeeBuyRate);

                    rewardBuyAmount = rewardBuyAmount.add(_calcFee(resultAmount, rewardBuyRate));
                } else if (_isSell(_from, _to)) {
                    burnFeeRes = _calcFee(resultAmount, burnFeeSellRate);
                    liquidityFeeRes = _calcFee(resultAmount, liquidityFeeSellRate);
                    swapFeeRes = _calcFee(resultAmount, swapFeeSellRate);

                    rewardSellAmount = rewardSellAmount.add(_calcFee(resultAmount, rewardSellRate));
                } else {
                    burnFeeRes = _calcFee(resultAmount, burnFeeTransferRate);
                    liquidityFeeRes = _calcFee(resultAmount, liquidityFeeTransferRate);
                    swapFeeRes = _calcFee(resultAmount, swapFeeTransferRate);
                }

                if (burnFeeRes > 0) {
                    if (burnFeeReceivers.length > 0) {
                        for (uint256 i = 0; i < burnFeeReceivers.length; i++) {
                            _transferAmount(_from, burnFeeReceivers[i], _calcFee(burnFeeRes, burnFeeReceiversRate[i]));
                        }
                    } else {
                        _transferAmount(_from, deadAddress, burnFeeRes);
                    }
                }

                if (liquidityFeeRes > 0 || swapFeeRes > 0) {
                    _transferAmount(_from, address(this), liquidityFeeRes.add(swapFeeRes));
                    liquidityFeeAmount = liquidityFeeAmount.add(liquidityFeeRes);
                    swapFeeAmount = swapFeeAmount.add(swapFeeRes);
                }

                resultAmount = resultAmount.sub(burnFeeRes).sub(liquidityFeeRes).sub(swapFeeRes);
            }

            if (
                !_isBuy(_from, _to) &&
            (!_isSell(_from, _to) || enabledSwapForSell) &&
            !(excludedFromSwap[_from] || excludedFromSwap[_to]) &&
            feeCounter >= feeLimit
            ) {
                uint256 amountToSwap = 0;


                uint256 liquidityFeeHalf = liquidityFeeAmount.div(2);
                uint256 liquidityFeeOtherHalf = liquidityFeeAmount.sub(liquidityFeeHalf);

                if (liquidityFeeOtherHalf > 0 && liquidityFeeHalf > 0) {
                    amountToSwap = amountToSwap.add(liquidityFeeHalf);
                }

                amountToSwap = amountToSwap.add(swapFeeAmount);

                uint256 rewardBuyToSwap = rewardBuyAmount.add(rewardSellAmount);
                if (
                    rewardBuyToSwap > 0 &&
                    balanceOf(rewardSwapAddress) >= rewardBuyToSwap
                ) {
                    _transferAmount(rewardSwapAddress, address(this), rewardBuyToSwap);
                    amountToSwap = amountToSwap.add(rewardBuyToSwap);
                }

                if (amountToSwap > 0) {
                    IERC20 _token1 = IERC20(token1);
                    uint256 oldToken1Balance = _token1.balanceOf(address(distribution));
                    _swapTokensForToken1(amountToSwap, address(distribution));
                    uint256 newToken1Balance = _token1.balanceOf(address(distribution));
                    uint256 token1Balance = newToken1Balance.sub(oldToken1Balance);


                    if (liquidityFeeOtherHalf > 0 && liquidityFeeHalf > 0) {
                        uint256 liquidityFeeToken1Amount = _calcFee(token1Balance, liquidityFeeHalf.mul(10000).div(amountToSwap));
                        distribution.recoverTokensFor(token1, liquidityFeeToken1Amount, address(this));

                        IERC20 _lp = IERC20(pair);
                        uint256 oldLpBalance = _lp.balanceOf(address(distribution));
                        if (liquidityFeeReceivers.length == 1) {
                            _addLiquidity(liquidityFeeOtherHalf, liquidityFeeToken1Amount, liquidityFeeReceivers[0]);
                        } else {
                            _addLiquidity(liquidityFeeOtherHalf, liquidityFeeToken1Amount, address(distribution));
                        }
                        uint256 newLpBalance = _lp.balanceOf(address(distribution));
                        uint256 lpBalance = newLpBalance.sub(oldLpBalance);

                        if (liquidityFeeReceivers.length > 1) {
                            for (uint256 i = 0; i < liquidityFeeReceivers.length; i++) {
                                distribution.recoverTokensFor(pair, _calcFee(lpBalance, liquidityFeeReceiversRate[i]), liquidityFeeReceivers[i]);
                            }
                        }
                    }

                    if (swapFeeAmount > 0) {
                        uint256 swapFeeToken1Amount = _calcFee(token1Balance, swapFeeAmount.mul(10000).div(amountToSwap));

                        for (uint256 i = 0; i < swapFeeReceivers.length; i++) {
                            distribution.recoverTokensFor(token1, _calcFee(swapFeeToken1Amount, swapFeeReceiversRate[i]), swapFeeReceivers[i]);
                        }
                    }

                    if (rewardBuyToSwap > 0) {
                        uint256 rewardToken1Amount = _calcFee(token1Balance, rewardBuyToSwap.mul(10000).div(amountToSwap));

                        for (uint256 i = 0; i < rewardSwapReceivers.length; i++) {
                            distribution.recoverTokensFor(token1, _calcFee(rewardToken1Amount, rewardSwapReceiversRate[i]), rewardSwapReceivers[i]);
                        }
                    }


                    feeCounter = 0;
                    liquidityFeeAmount = 0;
                    swapFeeAmount = 0;
                    rewardBuyAmount = 0;
                    rewardSellAmount = 0;
                }
            }
        }

        return resultAmount;
    }

    function _transferAmount(address _from, address _to, uint256 _amount) internal {
        balances[_from] = balances[_from].sub(_amount);
        balances[_to] = balances[_to].add(_amount);

        emit Transfer(_from, _to, _amount);
    }

    function _mint(address _account, uint256 _amount) internal {
        require(_account != address(0), "ERC20: mint to the zero address");

        totalSupply = totalSupply.add(_amount);
        balances[_account] = balances[_account].add(_amount);
        emit Transfer(address(0), _account, _amount);
    }

    function _burn(address _account, uint256 _amount) internal {
        require(_account != address(0), "ERC20: burn from the zero address");
        require(_account != deadAddress, "ERC20: burn from the dead address");
        require(balances[_account] >= _amount, "ERC20: burn amount exceeds balance");

        _transferAmount(_account, deadAddress, _amount);
    }

    function _approve(address _owner, address _spender, uint256 _amount) internal {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(_spender != address(0), "ERC20: approve to the zero address");

        allowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }

    function _calcFee(uint256 _amount, uint256 _rate) internal pure returns (uint256) {
        return _rate > 0 ? _amount.mul(_rate).div(10000) : 0;
    }

    function _isSell(address _from, address _to) internal view returns (bool) {
        return !isLpToken[_from] && isLpToken[_to];
    }

    function _isBuy(address _from, address _to) internal view returns (bool) {
        return isLpToken[_from] && !isLpToken[_to];
    }

    function _swapTokensForToken1(uint256 _tokenAmount, address _recipient) internal lockTheSwap {
        // generate the uniswap pair path of token -> token1
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = token1;

        _approve(address(this), address(router), _tokenAmount);
        // make the swap

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _tokenAmount,
            0, // accept any amount of token1
            path,
            _recipient,
            block.timestamp
        );
    }

    function _addLiquidity(uint256 _tokenAmount, uint256 _token1Amount, address _recipient) internal lockTheSwap {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(router), _tokenAmount);
        IERC20(token1).approve(address(router), _token1Amount);

        // add the liquidity
        router.addLiquidity(
            address(this),
            token1,
            _tokenAmount,
            _token1Amount,
            0,
            0,
            _recipient,
            block.timestamp
        );
    }

}