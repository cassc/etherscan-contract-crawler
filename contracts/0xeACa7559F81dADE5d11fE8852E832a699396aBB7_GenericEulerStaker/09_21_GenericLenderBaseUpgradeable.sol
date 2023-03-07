// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "../../../external/AccessControlAngleUpgradeable.sol";

import "../../../interfaces/IGenericLender.sol";
import "../../../interfaces/IPoolManager.sol";
import "../../../interfaces/IStrategy.sol";

import "../../../utils/Errors.sol";

/// @title GenericLenderBaseUpgradeable
/// @author Forked from https://github.com/Grandthrax/yearnV2-generic-lender-strat/tree/master/contracts/GenericLender
/// @notice A base contract to build contracts that lend assets to protocols
abstract contract GenericLenderBaseUpgradeable is IGenericLender, AccessControlAngleUpgradeable {
    using SafeERC20 for IERC20;

    bytes32 public constant GUARDIAN_ROLE = 0x55435dd261a4b9b3364963f7738a7a662ad9c84396d64be3365284bb7f0a5041;
    bytes32 public constant STRATEGY_ROLE = 0x928286c473ded01ff8bf61a1986f14a0579066072fa8261442d9fea514d93a4c;
    bytes32 public constant KEEPER_ROLE = 0xfc8737ab85eb45125971625a9ebdb75cc78e01d5c1fa80c4c6e5203f47bc4fab;

    // ========================= REFERENCES AND PARAMETERS =========================

    /// @inheritdoc IGenericLender
    string public override lenderName;
    /// @notice Reference to the protocol's collateral poolManager
    IPoolManager public poolManager;
    /// @inheritdoc IGenericLender
    address public override strategy;
    /// @notice Reference to the token lent
    IERC20 public want;
    /// @notice Base of the asset handled by the lender
    uint256 public wantBase;
    /// @notice 1inch Aggregation router
    address internal _oneInch;

    uint256[44] private __gapBaseLender;

    // ================================ INITIALIZER ================================

    /// @notice Initializer of the `GenericLenderBase`
    /// @param _strategy Reference to the strategy using this lender
    /// @param _name Name of the lender
    /// @param governorList List of addresses with governor privilege
    /// @param guardian Address of the guardian
    /// @param keeperList List of keeper addresses
    function _initialize(
        address _strategy,
        string memory _name,
        address[] memory governorList,
        address guardian,
        address[] memory keeperList,
        address oneInch_
    ) internal initializer {
        _oneInch = oneInch_;
        strategy = _strategy;
        // The corresponding `PoolManager` is inferred from the `Strategy`
        poolManager = IPoolManager(IStrategy(strategy).poolManager());
        want = IERC20(poolManager.token());
        lenderName = _name;

        _setupRole(GUARDIAN_ROLE, address(poolManager));
        uint256 governorListLength = governorList.length;
        for (uint256 i; i < governorListLength; ++i) {
            _setupRole(GUARDIAN_ROLE, governorList[i]);
        }

        _setupRole(KEEPER_ROLE, guardian);
        uint256 keeperListLength = keeperList.length;
        for (uint256 i; i < keeperListLength; ++i) {
            _setupRole(KEEPER_ROLE, keeperList[i]);
        }

        _setRoleAdmin(KEEPER_ROLE, GUARDIAN_ROLE);

        _setupRole(GUARDIAN_ROLE, guardian);
        _setupRole(STRATEGY_ROLE, _strategy);
        _setRoleAdmin(GUARDIAN_ROLE, STRATEGY_ROLE);
        _setRoleAdmin(STRATEGY_ROLE, GUARDIAN_ROLE);
        wantBase = 10**IERC20Metadata(address(want)).decimals();
        want.safeApprove(_strategy, type(uint256).max);
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    // =============================== VIEW FUNCTIONS ==============================

    /// @inheritdoc IGenericLender
    function apr() external view override returns (uint256) {
        return _apr();
    }

    /// @inheritdoc IGenericLender
    function weightedApr() external view override returns (uint256) {
        uint256 a = _apr();
        return a * _nav();
    }

    /// @inheritdoc IGenericLender
    function nav() external view override returns (uint256) {
        return _nav();
    }

    /// @inheritdoc IGenericLender
    function hasAssets() external view virtual override returns (bool) {
        return _nav() > 10 * wantBase;
    }

    /// @notice See `nav`
    function _nav() internal view returns (uint256) {
        return want.balanceOf(address(this)) + underlyingBalanceStored();
    }

    /// @notice See `apr`
    function _apr() internal view virtual returns (uint256);

    /// @notice Returns the current balance invested in the lender and related staking contracts
    function underlyingBalanceStored() public view virtual returns (uint256 balance);

    // ================================= GOVERNANCE ================================

    /// @notice Override this to add all tokens/tokenized positions this contract
    /// manages on a *persistent* basis (e.g. not just for swapping back to
    /// want ephemerally).
    ///
    /// Example:
    /// ```
    ///    function _protectedTokens() internal override view returns (address[] memory) {
    ///      address[] memory protected = new address[](3);
    ///      protected[0] = tokenA;
    ///      protected[1] = tokenB;
    ///      protected[2] = tokenC;
    ///      return protected;
    ///    }
    /// ```
    function _protectedTokens() internal view virtual returns (address[] memory);

    /// @inheritdoc IGenericLender
    function sweep(address _token, address to) external override onlyRole(GUARDIAN_ROLE) {
        address[] memory __protectedTokens = _protectedTokens();
        uint256 protectedTokensLength = __protectedTokens.length;
        for (uint256 i; i < protectedTokensLength; ++i) if (_token == __protectedTokens[i]) revert ProtectedToken();

        IERC20(_token).safeTransfer(to, IERC20(_token).balanceOf(address(this)));
    }

    /// @notice Changes allowance of a set of tokens to addresses
    /// @param tokens Addresses of the tokens for which approvals should be made
    /// @param spenders Addresses to approve
    /// @param amounts Approval amounts for each address
    function changeAllowance(
        IERC20[] calldata tokens,
        address[] calldata spenders,
        uint256[] calldata amounts
    ) external onlyRole(GUARDIAN_ROLE) {
        if (tokens.length != spenders.length || tokens.length != amounts.length) revert IncompatibleLengths();
        uint256 tokensLength = tokens.length;
        for (uint256 i; i < tokensLength; ++i) {
            _changeAllowance(tokens[i], spenders[i], amounts[i]);
        }
    }

    /// @notice Changes oneInch contract address
    /// @param oneInch_ Addresses of the new 1inch api endpoint contract
    function set1Inch(address oneInch_) external onlyRole(GUARDIAN_ROLE) {
        _oneInch = oneInch_;
    }

    /// @notice Swap earned _stkAave or Aave for `want` through 1Inch
    /// @param minAmountOut Minimum amount of `want` to receive for the swap to happen
    /// @param payload Bytes needed for 1Inch API
    /// @dev In the case of a contract lending to Aave, tokens swapped should typically be: _stkAave -> `want` or Aave -> `want`
    function sellRewards(uint256 minAmountOut, bytes memory payload) external onlyRole(KEEPER_ROLE) {
        //solhint-disable-next-line
        (bool success, bytes memory result) = _oneInch.call(payload);
        if (!success) _revertBytes(result);

        uint256 amountOut = abi.decode(result, (uint256));
        if (amountOut < minAmountOut) revert TooSmallAmount();
    }

    /// @notice Internal function used for error handling
    function _revertBytes(bytes memory errMsg) internal pure {
        if (errMsg.length != 0) {
            //solhint-disable-next-line
            assembly {
                revert(add(32, errMsg), mload(errMsg))
            }
        }
        revert ErrorSwap();
    }

    /// @notice Changes allowance of a set of tokens to addresses
    /// @param token Address of the token for which approval should be made
    /// @param spender Address to approve
    /// @param amount Approval amount
    function _changeAllowance(
        IERC20 token,
        address spender,
        uint256 amount
    ) internal {
        uint256 currentAllowance = token.allowance(address(this), address(spender));
        if (currentAllowance < amount) {
            token.safeIncreaseAllowance(address(spender), amount - currentAllowance);
        } else if (currentAllowance > amount) {
            token.safeDecreaseAllowance(address(spender), currentAllowance - amount);
        }
    }
}