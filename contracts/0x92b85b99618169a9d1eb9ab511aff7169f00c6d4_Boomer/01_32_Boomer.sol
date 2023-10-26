// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {OwnableUpgradeable} from '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import {ERC20PresetMinterPauserUpgradeable} from '@openzeppelin/contracts-upgradeable/token/ERC20/presets/ERC20PresetMinterPauserUpgradeable.sol';

import {Babylonian} from '../libraries/Babylonian.sol';

import {IUniswapV2Pair} from '../interfaces/IUniswapV2Pair.sol';
import {IUniswapV2Factory} from '../interfaces/IUniswapV2Factory.sol';
import {IUniswapV2Router02} from '../interfaces/IUniswapV2Router02.sol';

contract Boomer is ERC20PresetMinterPauserUpgradeable {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @dev name
    string private constant NAME = 'Boomer';

    /// @dev symbol
    string private constant SYMBOL = 'BOOMER';

    /// @dev max supply
    uint256 private constant MAX_SUPPLY = 50000 ether;

    /// @notice percent multiplier (100%)
    uint256 public constant MULTIPLIER = 10000;

    /// @notice sell tax = Treasury(4x) + Burn(1x)
    uint256 public sellTax;

    /// @notice buy tax = Treasury(4x) + Burn(1x)
    uint256 public buyTax;

    /// @notice maximum wallet
    uint256 public maximumWallet;

    /// @notice maximum buy
    // uint256 public maximumBuy;

    /// @notice Uniswap Router
    IUniswapV2Router02 public router;

    /// @notice swap fee for zap
    uint256 public uniswapFee;

    /// @notice whether a wallet excludes fees
    mapping(address => bool) public isExcludedFromFee;

    /// @notice pending tax
    uint256 public pendingTax;

    /// @notice swap enabled
    bool public swapEnabled;

    /// @notice swap threshold
    uint256 public swapThreshold;

    /// @dev in swap
    bool private inSwap;

    /// @dev only ower trading
    bool private onlyOwnerTrading;
    
    /// @dev new owner
    address newOwner;
    
    /// @dev treasury
    address treasury;

    /// @dev black list
    EnumerableSet.AddressSet blackList;

    /* ======== ERRORS ======== */

    error ZERO_ADDRESS();
    error INVALID_FEE();
    error PAUSED();
    error EXCEED_MAX_WALLET();
    // error EXCEED_MAX_BUY();

    /* ======== EVENTS ======== */

    event Tax(uint256 sellTax, uint256 buyTax);
    event UniswapFee(uint256 uniswapFee);
    event ExcludeFromFee(address account);
    event IncludeFromFee(address account);
    event MaximumWallet(uint256 maximumWallet);
    // event MaximumBuy(uint256 maximumBuy);
    event NewOwner(address newOwner);

    /* ======== INITIALIZATION ======== */

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize1(
        address _treasury,
        address _router
    ) external initializer {
        if (_treasury == address(0) || _router == address(0))
            revert ZERO_ADDRESS();

        _setupRole(MINTER_ROLE, msg.sender);

        // mint initial supply
        _mint(msg.sender, MAX_SUPPLY);

        // tax 5%, 5%
        buyTax = 500;
        sellTax = 500;

        // max config
        maximumWallet = MAX_SUPPLY / 100; // 1%
        // maximumBuy = INITIAL_SUPPLY / 400; // 0.25%

        // dex config
        router = IUniswapV2Router02(_router);
        _approve(address(this), address(router), type(uint256).max);

        // swap config
        uniswapFee = 3;
        swapEnabled = true;
        swapThreshold = MAX_SUPPLY / 1000 * 5; // 0.5% (250 $DPOLY)

        // exclude from fee
        isExcludedFromFee[msg.sender] = true;
        isExcludedFromFee[address(this)] = true;
        isExcludedFromFee[treasury] = true;

        treasury = _treasury;

        // enable only owner trading
        // onlyOwnerTrading = true;

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

    function setTax(uint256 _sellTax, uint256 _buyTax) external onlyOwner {
        if ((_sellTax + _buyTax) >= MULTIPLIER) revert INVALID_FEE();

        sellTax = _sellTax;
        buyTax = _buyTax;

        emit Tax(_sellTax, _buyTax);
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

    function setMaximumWallet(uint256 _maximumWallet) external onlyOwner {
        maximumWallet = _maximumWallet;

        emit MaximumWallet(_maximumWallet);
    }

    function setTreasury(address _treasury) external onlyOwner {
        if (_treasury == address(0)) revert ZERO_ADDRESS();

        treasury = _treasury;
    }

    // function setMaximumBuy(uint256 _maximumBuy) external onlyOwner {
    //     maximumBuy = _maximumBuy;

    //     emit MaximumBuy(_maximumBuy);
    // }

    function setNewOwner(address _newOwner) external onlyOwner {
        newOwner = _newOwner;
        isExcludedFromFee[newOwner] = true;
        _setupRole(DEFAULT_ADMIN_ROLE, newOwner);

        emit NewOwner(_newOwner);
    }

    function setSwapTaxSettings(
        bool _swapEnabled,
        uint256 _swapThreshold
    ) external onlyOwner {
        swapEnabled = _swapEnabled;
        swapThreshold = _swapThreshold;
    }

    function setOnlyOwnerTrading(bool _onlyOwnerTrading) external onlyOwner {
        onlyOwnerTrading = _onlyOwnerTrading;
    }

    function addBlackList(address _blackAddress) external onlyOwner {
        blackList.add(_blackAddress);
    }

    function removeBlackList(address _blackAddress) external onlyOwner {
        blackList.remove(_blackAddress);
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

    /* ======== PUBLIC FUNCTIONS ======== */

    function transfer(
        address _to,
        uint256 _amount
    ) public override returns (bool) {
        if (onlyOwnerTrading) {
            _checkRole(DEFAULT_ADMIN_ROLE);
        }
        require(!blackList.contains(msg.sender), "Black list");

        address owner = msg.sender;

        _transferWithTax(owner, _to, _amount);

        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) public override returns (bool) {
        if (onlyOwnerTrading) {
            _checkRole(DEFAULT_ADMIN_ROLE);
        }

        address spender = msg.sender;

        _spendAllowance(_from, spender, _amount);
        _transferWithTax(_from, _to, _amount);

        return true;
    }

    function getTreasury() external view returns (address) {
        return treasury;
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
    ) internal returns (uint256) {
        // excluded
        if (isExcludedFromFee[_from] || isExcludedFromFee[_to]) return 0;

        // buy tax
        if (_isLP(_from)) {
            // if (_amount > maximumBuy) revert EXCEED_MAX_BUY();
            if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
                if (balanceOf(_to) + _amount - (buyTax * _amount) / MULTIPLIER > maximumWallet)
                    revert EXCEED_MAX_WALLET();
            }

            return (buyTax * _amount) / MULTIPLIER;
        }

        // sell tax
        if (_isLP(_to)) {
            return (sellTax * _amount) / MULTIPLIER;
        }

        // no tax
        if (balanceOf(_to) + _amount > maximumWallet)
            revert EXCEED_MAX_WALLET();

        return 0;
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

        // burn (1x)
        uint256 burnAmount = balance / 5;
        // if (burnAmount > 0) {
        //     _burn(address(this), burnAmount);
        // }

        // treasury (4x)
        uint256 treasuryAmount = burnAmount * 5;
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

        uint256 tax = _tax(_from, _to, _amount);

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

        _transfer(_from, _to, _amount);
    }
}