// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {
    AccessControlEnumerable
} from "oz-custom/contracts/oz/access/AccessControlEnumerable.sol";

import {
    ERC20,
    ERC20Permit
} from "oz-custom/contracts/oz/token/ERC20/extensions/ERC20Permit.sol";

import {
    ERC20Burnable
} from "oz-custom/contracts/oz/token/ERC20/extensions/ERC20Burnable.sol";

import {
    Pausable,
    ERC20Pausable
} from "oz-custom/contracts/oz/token/ERC20/extensions/ERC20Pausable.sol";

import {
    Taxable,
    FixedPointMathLib
} from "oz-custom/contracts/internal/Taxable.sol";
import {Transferable} from "oz-custom/contracts/internal/Transferable.sol";
import {ProxyChecker} from "oz-custom/contracts/internal/ProxyChecker.sol";
import {Blacklistable} from "oz-custom/contracts/internal/Blacklistable.sol";

import {IWNT} from "oz-custom/contracts/presets/token/interfaces/IWNT.sol";

import {
    IUniswapV2Pair,
    IBountyKindsERC20
} from "./interfaces/IBountyKindsERC20.sol";
import {
    AggregatorV3Interface
} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import {ErrorHandler} from "oz-custom/contracts/libraries/ErrorHandler.sol";

contract BountyKindsERC20 is
    Taxable,
    ERC20Permit,
    Transferable,
    ProxyChecker,
    Blacklistable,
    ERC20Burnable,
    ERC20Pausable,
    IBountyKindsERC20,
    AccessControlEnumerable
{
    using ErrorHandler for bool;
    using FixedPointMathLib for uint256;

    bytes32 public constant PAUSER_ROLE =
        0x65d7a28e3265b37a6474929f336521b332c1681b933f6cb9f3376673440d862a;
    bytes32 public constant MINTER_ROLE =
        0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6;
    bytes32 public constant OPERATOR_ROLE =
        0x97667070c54ef182b0f5858b034beac1b6f3089aa2d3188bb1e8929f4fa9b929;

    IWNT public immutable wnt;
    AggregatorV3Interface public immutable priceFeed;

    IUniswapV2Pair public pool;

    constructor(
        string memory name_,
        string memory symbol_,
        address admin_,
        address beneficiary_,
        uint256 initialSupply_,
        IWNT wnt_,
        AggregatorV3Interface priceFeed_
    ) payable Pausable() Taxable(beneficiary_) ERC20Permit(name_, symbol_) {
        wnt = wnt_;
        priceFeed = priceFeed_;

        address operator = _msgSender();

        bytes32 pauserRole = PAUSER_ROLE;
        bytes32 minterRole = MINTER_ROLE;
        bytes32 operatorRole = OPERATOR_ROLE;

        _grantRole(pauserRole, operator);
        _grantRole(minterRole, operator);
        _grantRole(operatorRole, operator);

        _grantRole(pauserRole, admin_);
        _grantRole(minterRole, admin_);
        _grantRole(operatorRole, admin_);
        _grantRole(DEFAULT_ADMIN_ROLE, admin_);

        _mint(beneficiary_, initialSupply_ * 1 ether);
    }

    /// @inheritdoc IBountyKindsERC20
    function setPool(
        IUniswapV2Pair pool_
    ) external whenPaused onlyRole(OPERATOR_ROLE) {
        _setPool(pool_);
    }

    function setUserStatus(
        address account_,
        bool status_
    ) external onlyRole(OPERATOR_ROLE) {
        _setUserStatus(account_, status_);
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function toggleTax() external whenPaused onlyRole(PAUSER_ROLE) {
        _toggleTax();
    }

    function setTaxBeneficiary(
        address beneficiary_
    ) external onlyRole(OPERATOR_ROLE) {
        _setTaxBeneficiary(beneficiary_);
    }

    /// @inheritdoc IBountyKindsERC20
    function mint(address to_, uint256 amount_) external onlyRole(MINTER_ROLE) {
        _mint(to_, amount_);
    }

    /// @inheritdoc IBountyKindsERC20
    //  @dev minimal function to recover lost funds
    function execute(
        address target_,
        uint256 value_,
        bytes calldata calldata_
    ) external whenPaused onlyRole(OPERATOR_ROLE) {
        (bool success, bytes memory returnOrRevertData) = target_.call{
            value: value_
        }(calldata_);
        success.handleRevertIfNotSuccess(returnOrRevertData);

        emit Executed(
            _msgSender(),
            target_,
            value_,
            calldata_,
            returnOrRevertData
        );
    }

    function tax(
        address pool_,
        uint256 amount_
    ) public view override returns (uint256) {
        uint256 tokenReserve;
        uint256 nativeReserve;
        if (IUniswapV2Pair(pool_).token1() == address(this))
            (nativeReserve, tokenReserve, ) = IUniswapV2Pair(pool_)
                .getReserves();
        else
            (tokenReserve, nativeReserve, ) = IUniswapV2Pair(pool_)
                .getReserves();

        // amount token => amount native
        uint256 amtNative = amount_.mulDivUp(nativeReserve, tokenReserve);
        AggregatorV3Interface _priceFeed = priceFeed;
        (, int256 usd, , , ) = _priceFeed.latestRoundData();
        // amount native => amount usd
        uint256 amtUSD = amtNative.mulDivUp(
            uint256(usd),
            10 ** _priceFeed.decimals()
        );

        // usd tax amount
        uint256 usdTax = amtUSD.mulDivUp(
            taxFraction(address(0)),
            percentageFraction()
        );
        // native tax amount
        return usdTax.mulDivUp(1 ether, uint256(usd));
    }

    function taxEnabledDuration() public pure override returns (uint256) {
        return 20 minutes;
    }

    function taxFraction(address) public pure override returns (uint256) {
        return 2500;
    }

    function percentageFraction() public pure override returns (uint256) {
        return 10_000;
    }

    function _setPool(IUniswapV2Pair pool_) internal {
        if (address(pool_) == address(0) || !_isProxy(address(pool_)))
            revert BountyKindsERC20__InvalidArguments();

        emit PoolSet(_msgSender(), pool, pool_);
        pool = pool_;
    }

    function _beforeTokenTransfer(
        address from_,
        address to_,
        uint256 amount_
    ) internal override(ERC20, ERC20Pausable) {
        if (
            isBlacklisted(to_) ||
            isBlacklisted(from_) ||
            isBlacklisted(_msgSender())
        ) revert BountyKindsERC20__Blacklisted();

        if (isTaxEnabled()) {
            uint256 _tax = tax(address(pool), amount_);
            IWNT _wnt = wnt;

            if (msg.value != 0) {
                //  @dev will throw underflow error if msg.value < _tax
                uint256 refund = msg.value - _tax;
                _wnt.deposit{value: _tax}();

                address spender = _msgSender();
                if (refund != 0) {
                    _safeNativeTransfer(spender, refund, "");
                    emit Refunded(spender, refund);
                }
            }

            _safeERC20TransferFrom(_wnt, address(this), taxBeneficiary, _tax);
        }

        super._beforeTokenTransfer(from_, to_, amount_);
    }
}