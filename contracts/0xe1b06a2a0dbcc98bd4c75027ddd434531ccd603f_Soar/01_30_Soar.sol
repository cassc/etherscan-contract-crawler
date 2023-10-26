// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {ERC20PresetMinterPauserUpgradeable} from '@openzeppelin/contracts-upgradeable/token/ERC20/presets/ERC20PresetMinterPauserUpgradeable.sol';

import {Babylonian} from '../libraries/Babylonian.sol';

import {IUniswapV2Pair} from '../interfaces/IUniswapV2Pair.sol';
import {IUniswapV2Factory} from '../interfaces/IUniswapV2Factory.sol';
import {IUniswapV2Router02} from '../interfaces/IUniswapV2Router02.sol';

contract Soar is ERC20PresetMinterPauserUpgradeable {
    using SafeERC20 for IERC20;

    /// @dev name
    string private constant NAME = 'Soar';

    /// @dev symbol
    string private constant SYMBOL = 'SOAR';

    /// @dev initial supply: 1 billion
    uint256 private constant INITIAL_SUPPLY = 1000000000 ether;

    /// @notice percent multiplier (100%)
    uint256 public constant MULTIPLIER = 10000;

    /// @notice treasury wallet
    address public treasury;

    /// @notice lp provider
    address public lpProvider;

    /// @notice sell tax = LP(3x) + Treasury(2x)
    uint256 public sellTax;

    /// @notice maximum buy
    uint256 public maximumBuy;

    /// @notice Uniswap Router
    IUniswapV2Router02 public router;

    /// @notice swap fee for zap
    uint256 public uniswapFee;

    /// @notice whether a wallet excludes fees
    mapping(address => bool) public isExcludedFromFee;

    /// @notice pending tax
    uint256 public pendingTax;

    /// @notice pending eth (for buyback)
    uint256 public pendingEth;

    /// @notice pending eth block
    uint256 public pendingEthBlock;

    /// @notice swap enabled
    bool public swapEnabled;

    /// @notice swap threshold
    uint256 public swapThreshold;

    /// @dev in swap
    bool private inSwap;

    /* ======== ERRORS ======== */

    error ZERO_ADDRESS();
    error INVALID_FEE();
    error PAUSED();
    error EXCEED_MAX_WALLET();
    error EXCEED_MAX_BUY();

    /* ======== EVENTS ======== */

    event Treasury(address treasury);
    event LPProvider(address lpProvider);
    event Tax(uint256 sellTax);
    event UniswapFee(uint256 uniswapFee);
    event ExcludeFromFee(address account);
    event IncludeFromFee(address account);
    event MaximumWallet(uint256 maximumWallet);
    event MaximumBuy(uint256 maximumBuy);

    /* ======== INITIALIZATION ======== */

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _treasury,
        address _lpProvider,
        address _router
    ) external initializer {
        if (
            _treasury == address(0) ||
            _lpProvider == address(0) ||
            _router == address(0)
        ) revert ZERO_ADDRESS();

        // set treasury
        treasury = _treasury;
        _setupRole(DEFAULT_ADMIN_ROLE, _treasury);

        // set lpProvider
        lpProvider = _lpProvider;

        // mint initial supply
        uint256 treasuryAmount = (INITIAL_SUPPLY * 3) / 10;
        _mint(_treasury, treasuryAmount);
        _mint(msg.sender, INITIAL_SUPPLY - treasuryAmount);

        // tax 10% (inital: 35%)
        sellTax = 3500;

        // max buy: 0.5%
        maximumBuy = INITIAL_SUPPLY / 200;

        // dex config
        router = IUniswapV2Router02(_router);
        _approve(address(this), _router, type(uint256).max);

        // swap config
        uniswapFee = 3;
        swapEnabled = true;
        swapThreshold = INITIAL_SUPPLY / 200000; // 0.0005%

        // exclude from fee
        isExcludedFromFee[msg.sender] = true;
        isExcludedFromFee[address(this)] = true;
        isExcludedFromFee[_treasury] = true;

        // init
        __ERC20PresetMinterPauser_init(NAME, SYMBOL);
    }

    receive() external payable {}

    /* ======== MODIFIERS ======== */

    modifier onlyOwner() {
        _checkRole(DEFAULT_ADMIN_ROLE);
        _;
    }

    modifier swapping() {
        inSwap = true;

        _;

        inSwap = false;
    }

    /* ======== POLICY FUNCTIONS ======== */

    function setTreasury(address _treasury) external onlyOwner {
        if (_treasury == address(0)) revert ZERO_ADDRESS();

        treasury = _treasury;

        emit Treasury(_treasury);
    }

    function setLPProvider(address _lpProvider) external onlyOwner {
        if (_lpProvider == address(0)) revert ZERO_ADDRESS();

        lpProvider = _lpProvider;

        emit LPProvider(_lpProvider);
    }

    function setTax(uint256 _sellTax) external onlyOwner {
        if (_sellTax >= MULTIPLIER / 2) revert INVALID_FEE();

        sellTax = _sellTax;

        emit Tax(_sellTax);
    }

    function setUniswapFee(uint256 _uniswapFee) external onlyOwner {
        uniswapFee = _uniswapFee;

        emit UniswapFee(_uniswapFee);
    }

    function excludeFromFee(address _account) external onlyOwner {
        isExcludedFromFee[_account] = true;

        emit ExcludeFromFee(_account);
    }

    function includeFromFee(address _account) external onlyOwner {
        isExcludedFromFee[_account] = false;

        emit IncludeFromFee(_account);
    }

    function setMaximumBuy(uint256 _maximumBuy) external onlyOwner {
        maximumBuy = _maximumBuy;

        emit MaximumBuy(_maximumBuy);
    }

    function setSwapTaxSettings(
        bool _swapEnabled,
        uint256 _swapThreshold
    ) external onlyOwner {
        swapEnabled = _swapEnabled;
        swapThreshold = _swapThreshold;
    }

    function recoverERC20(IERC20 token) external onlyOwner {
        if (address(token) == address(this)) {
            token.safeTransfer(
                msg.sender,
                token.balanceOf(address(this)) - pendingTax
            );
        } else {
            token.safeTransfer(msg.sender, token.balanceOf(address(this)));
        }
    }

    function recoverETH() external onlyOwner {
        uint256 balance = address(this).balance;

        if (balance > 0) {
            (bool success, ) = payable(msg.sender).call{value: balance}('');
            require(success);
        }
    }

    function resetPending() external onlyOwner {
        pendingEth = 0;
        pendingTax = 0;
    }

    /* ======== PUBLIC FUNCTIONS ======== */

    function transfer(
        address _to,
        uint256 _amount
    ) public override returns (bool) {
        _transferWithTax(msg.sender, _to, _amount);

        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) public override returns (bool) {
        _spendAllowance(_from, msg.sender, _amount);
        _transferWithTax(_from, _to, _amount);

        return true;
    }

    /* ======== INTERNAL FUNCTIONS ======== */

    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256
    ) internal virtual override {
        if (hasRole(DEFAULT_ADMIN_ROLE, _from)) return;
        if (_from == address(0) || _to == address(0)) return;
        if (paused()) revert PAUSED();
    }

    function _getPoolToken(
        address _pool,
        string memory _signature,
        function() external view returns (address) _getter
    ) internal returns (address) {
        (bool success, ) = _pool.call(abi.encodeWithSignature(_signature));

        if (success) {
            uint32 size;
            assembly {
                size := extcodesize(_pool)
            }
            if (size > 0) {
                return _getter();
            }
        }

        return address(0);
    }

    function _isLP(address _pool) internal returns (bool) {
        address token0 = _getPoolToken(
            _pool,
            'token0()',
            IUniswapV2Pair(_pool).token0
        );
        address token1 = _getPoolToken(
            _pool,
            'token1()',
            IUniswapV2Pair(_pool).token1
        );

        return token0 == address(this) || token1 == address(this);
    }

    function _tax(
        address _from,
        address _to,
        uint256 _amount
    ) internal returns (uint256 eth, uint256 tax) {
        // excluded
        if (isExcludedFromFee[_from] || isExcludedFromFee[_to]) return (0, 0);

        // buy back
        if (_isLP(_from)) {
            if (_amount > maximumBuy) revert EXCEED_MAX_BUY();

            IUniswapV2Pair pair = IUniswapV2Pair(
                IUniswapV2Factory(router.factory()).getPair(
                    address(this),
                    router.WETH()
                )
            );

            (uint256 rsv0, uint256 rsv1, ) = pair.getReserves();
            uint256 ethAmount = router.getAmountIn(
                _amount, // soar out
                pair.token0() == address(this) ? rsv1 : rsv0, // eth reserve
                pair.token0() == address(this) ? rsv0 : rsv1 // soar reserve
            );

            return (ethAmount, 0);
        }

        // sell tax
        if (_isLP(_to)) {
            return (0, (sellTax * _amount) / MULTIPLIER);
        }

        // no tax
        return (0, 0);
    }

    function _shouldBuyBack() internal view returns (bool) {
        return
            !inSwap &&
            swapEnabled &&
            pendingEth > 0 &&
            pendingEthBlock < block.number;
    }

    function _shouldSwapTax() internal view returns (bool) {
        return !inSwap && swapEnabled && pendingTax >= swapThreshold;
    }

    function _calculateSwapInAmount(
        uint256 reserveIn,
        uint256 userIn
    ) internal view returns (uint256) {
        return
            (Babylonian.sqrt(
                reserveIn *
                    ((userIn * (uint256(4000) - (4 * uniswapFee)) * 1000) +
                        (reserveIn *
                            ((uint256(4000) - (4 * uniswapFee)) *
                                1000 +
                                uniswapFee *
                                uniswapFee)))
            ) - (reserveIn * (2000 - uniswapFee))) / (2000 - 2 * uniswapFee);
    }

    function _swapTax() internal swapping {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        uint256 balance = pendingTax;
        delete pendingTax;

        // treasury (1x)
        uint256 treasuryAmount = balance / 5;
        if (treasuryAmount > 0) {
            uint256 balanceBefore = address(this).balance;

            // swap
            router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                treasuryAmount,
                0,
                path,
                address(this),
                block.timestamp
            );

            // eth to treasury
            uint256 amountETH = address(this).balance - balanceBefore;
            payable(treasury).call{value: amountETH}('');
        }

        // liquidity (4x)
        uint256 liquidityAmount = balance - treasuryAmount;
        if (liquidityAmount > 0) {
            IUniswapV2Pair pair = IUniswapV2Pair(
                IUniswapV2Factory(router.factory()).getPair(
                    address(this),
                    router.WETH()
                )
            );

            // zap amount
            (uint256 rsv0, uint256 rsv1, ) = pair.getReserves();
            uint256 sellAmount = _calculateSwapInAmount(
                pair.token0() == address(this) ? rsv0 : rsv1,
                liquidityAmount
            );

            // swap
            router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                sellAmount,
                0,
                path,
                address(this),
                block.timestamp
            );

            // add liquidity
            router.addLiquidityETH{value: address(this).balance}(
                address(this),
                liquidityAmount - sellAmount,
                0,
                0,
                lpProvider,
                block.timestamp
            );
        }
    }

    function _buyback() internal swapping {
        IUniswapV2Pair pair = IUniswapV2Pair(
            IUniswapV2Factory(router.factory()).getPair(
                address(this),
                router.WETH()
            )
        );

        // LP
        (uint256 rsv0, uint256 rsv1, ) = pair.getReserves();
        uint256 lp = (pendingEth * pair.totalSupply()) /
            (pair.token0() == address(this) ? rsv1 : rsv0);
        if (lp == 0) return;
        pair.transferFrom(lpProvider, address(this), lp);
        pair.approve(address(router), lp);

        // withdraw ETH & SOAR from LP
        uint256 ethBefore = address(this).balance;
        {
            uint256 soarBefore = balanceOf(address(this));

            router.removeLiquidityETHSupportingFeeOnTransferTokens(
                address(this),
                lp,
                0,
                0,
                address(this),
                block.timestamp
            );

            // burn SOAR
            uint256 soar = balanceOf(address(this)) - soarBefore;

            _burn(address(this), soar);
        }

        // buy SOAR
        {
            uint256 soarBefore = balanceOf(treasury);
            uint256 eth = address(this).balance - ethBefore;

            address[] memory path = new address[](2);
            path[0] = router.WETH();
            path[1] = address(this);

            router.swapExactETHForTokensSupportingFeeOnTransferTokens{
                value: eth
            }(0, path, treasury, block.timestamp);

            // burn SOAR
            uint256 soar = balanceOf(treasury) - soarBefore;

            _burn(treasury, soar);
        }
    }

    function _transferWithTax(
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        if (inSwap) {
            _transfer(_from, _to, _amount);
            return;
        }

        (uint256 eth, uint256 tax) = _tax(_from, _to, _amount);

        // buy back
        if (eth > 0) {
            pendingEth += eth / 10;
        } else if (
            !isExcludedFromFee[_from] &&
            !isExcludedFromFee[_to] &&
            _shouldBuyBack()
        ) {
            _buyback();
            pendingEth = 0;
        }
        pendingEthBlock = block.number;

        // sell tax
        if (tax > 0) {
            unchecked {
                _amount -= tax;
                pendingTax += tax;
            }
            _transfer(_from, address(this), tax);
        }

        if (_shouldSwapTax()) {
            _swapTax();
        }

        // transfer
        _transfer(_from, _to, _amount);
    }
}