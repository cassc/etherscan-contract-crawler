// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "prb-math/contracts/PRBMathUD60x18.sol";

import "./interfaces/ICollateralOracle.sol";
import "./interfaces/ILoanPriceOracle.sol";

/**
 * @title Loan Price Oracle
 */
contract LoanPriceOracle is AccessControl, ILoanPriceOracle {
    using EnumerableSet for EnumerableSet.AddressSet;

    /**************************************************************************/
    /* Constants */
    /**************************************************************************/

    /**
     * @notice Implementation version
     */
    string public constant IMPLEMENTATION_VERSION = "1.0";

    /**
     * @notice One in UD60x18
     */
    uint256 private constant ONE_UD60X18 = 1e18;

    /**************************************************************************/
    /* Access Control Roles */
    /**************************************************************************/

    /**
     * @notice Parameter admin role
     */
    bytes32 public constant PARAMETER_ADMIN_ROLE = keccak256("PARAMETER_ADMIN");

    /**************************************************************************/
    /* Errors */
    /**************************************************************************/

    /**
     * @notice Unsupported token decimals
     */
    error UnsupportedTokenDecimals();

    /**
     * @notice Invalid address (e.g. zero address)
     */
    error InvalidAddress();

    /**************************************************************************/
    /* Events */
    /**************************************************************************/

    /**
     * @notice Emitted when minimum loan duration is updated
     * @param duration New minimum loan duration in seconds
     */
    event MinimumLoanDurationUpdated(uint256 duration);

    /**
     * @notice Emitted when utilization parameters are updated
     */
    event UtilizationParametersUpdated();

    /**
     * @notice Emitted when collateral parameters are updated
     * @param collateralToken Address of collateral token
     */
    event CollateralParametersUpdated(address indexed collateralToken);

    /**
     * @notice Emitted when collateral oracle is updated
     * @param collateralOracle Address of collateral oracle
     */
    event CollateralOracleUpdated(address collateralOracle);

    /**************************************************************************/
    /* State */
    /**************************************************************************/

    /**
     * @notice Piecewise linear model parameters
     * @param offset Output value offset in UD4x18
     * @param slope1 Slope before kink in UD4x18
     * @param slope2 Slope after kink in UD4x18
     * @param target Input value of kink in UD11x18
     * @param max Max input value in UD11x18
     */
    struct PiecewiseLinearModel {
        uint72 offset;
        uint72 slope1;
        uint72 slope2;
        uint96 target;
        uint96 max;
    }

    /**
     * @notice Collateral parameters
     * @param active Collateral is supported
     * @param loanToValueRateComponent Rate component model for loan to value
     * @param durationRateComponent Rate component model for duration
     * @param rateComponentWeights Weights for rate components, each 0 to 10000
     */
    struct CollateralParameters {
        bool active;
        PiecewiseLinearModel loanToValueRateComponent;
        PiecewiseLinearModel durationRateComponent;
        uint16[3] rateComponentWeights; /* 0-10000 */
    }

    /**
     * @dev Rate component model for utilization
     */
    PiecewiseLinearModel private _utilizationParameters;

    /**
     * @dev Mapping of collateral token contract to collateral parameters
     */
    mapping(address => CollateralParameters) private _parameters;

    /**
     * @dev Set of supported collateral tokens
     */
    EnumerableSet.AddressSet private _collateralTokens;

    /**
     * @dev Collateral oracle
     */
    ICollateralOracle public collateralOracle;

    /**
     * @notice Minimum loan duration in seconds
     */
    uint256 public minimumLoanDuration;

    /**************************************************************************/
    /* Constructor */
    /**************************************************************************/

    /**
     * @notice LoanPriceOracle constructor
     * @param collateralOracle_ Collateral oracle
     */
    constructor(ICollateralOracle collateralOracle_) {
        if (IERC20Metadata(address(collateralOracle_.currencyToken())).decimals() != 18)
            revert UnsupportedTokenDecimals();

        collateralOracle = collateralOracle_;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PARAMETER_ADMIN_ROLE, msg.sender);
    }

    /**************************************************************************/
    /* Internal Helper Functions */
    /**************************************************************************/

    /**
     * @dev Compute the output of the specified piecewise linear model with
     * input x
     * @param model Piecewise linear model to compute
     * @param x Input value in UD60x18
     * @param index Parameter index (for error reporting)
     * @return Result in UD60x18
     */
    function _computeRateComponent(
        PiecewiseLinearModel storage model,
        uint256 x,
        uint256 index
    ) internal view returns (uint256) {
        if (x > uint256(model.max)) {
            revert ParameterOutOfBounds(index);
        }
        return
            (x <= uint256(model.target))
                ? uint256(model.offset) + PRBMathUD60x18.mul(x, uint256(model.slope1))
                : uint256(model.offset) +
                    PRBMathUD60x18.mul(uint256(model.target), uint256(model.slope1)) +
                    PRBMathUD60x18.mul(x - uint256(model.target), uint256(model.slope2));
    }

    /**
     * @dev Compute the weighted rate
     * @param weights Weights to apply, each 0 to 10000
     * @param components Components to weight, each UD60x18
     * @return Weighted rate in UD60x18
     */
    function _computeWeightedRate(uint16[3] storage weights, uint256[3] memory components)
        internal
        view
        returns (uint256)
    {
        return
            PRBMathUD60x18.div(
                PRBMathUD60x18.mul(components[0], PRBMathUD60x18.fromUint(weights[0])) +
                    PRBMathUD60x18.mul(components[1], PRBMathUD60x18.fromUint(weights[1])) +
                    PRBMathUD60x18.mul(components[2], PRBMathUD60x18.fromUint(weights[2])),
                PRBMathUD60x18.fromUint(10000)
            );
    }

    /**************************************************************************/
    /* Primary API */
    /**************************************************************************/

    /**
     * @inheritdoc ILoanPriceOracle
     */
    function priceLoan(
        address collateralToken,
        uint256 collateralTokenId,
        uint256 principal,
        uint256 repayment,
        uint256 duration,
        uint256 maturity,
        uint256 utilization
    ) external view returns (uint256) {
        /* Unused variables */
        duration;

        /* Validate minimum loan duration */
        if (block.timestamp > maturity - minimumLoanDuration) {
            revert InsufficientTimeRemaining();
        }

        /* Look up collateral parameters */
        CollateralParameters storage collateralParameters = _parameters[collateralToken];
        if (!collateralParameters.active) {
            revert UnsupportedCollateral();
        }

        /* Look up collateral value */
        uint256 collateralValue = collateralOracle.collateralValue(collateralToken, collateralTokenId);

        /* Calculate loan time remaining */
        uint256 loanTimeRemaining = PRBMathUD60x18.fromUint(maturity - block.timestamp);

        /* Calculate loan to value */
        uint256 loanToValue = PRBMathUD60x18.div(principal, collateralValue);

        /* Compute discount rate components for utilization, loan-to-value, and duration */
        uint256[3] memory rateComponents = [
            _computeRateComponent(_utilizationParameters, utilization, 0),
            _computeRateComponent(collateralParameters.loanToValueRateComponent, loanToValue, 1),
            _computeRateComponent(collateralParameters.durationRateComponent, loanTimeRemaining, 2)
        ];

        /* Calculate discount rate from components */
        uint256 discountRate = _computeWeightedRate(collateralParameters.rateComponentWeights, rateComponents);

        /* Calculate purchase price */
        /* Purchase Price = Loan Repayment Value / (1 + Discount Rate * t) */
        uint256 purchasePrice = PRBMathUD60x18.div(
            repayment,
            ONE_UD60X18 + PRBMathUD60x18.mul(discountRate, loanTimeRemaining)
        );

        return purchasePrice;
    }

    /**************************************************************************/
    /* Getters */
    /**************************************************************************/

    /**
     * @inheritdoc ILoanPriceOracle
     */
    function currencyToken() external view returns (IERC20) {
        return collateralOracle.currencyToken();
    }

    /**
     * @notice Get utilization parameters
     * @return Utilization rate component model
     */
    function getUtilizationParameters() external view returns (PiecewiseLinearModel memory) {
        return _utilizationParameters;
    }

    /**
     * @notice Get collateral parameters for token contract
     * @param collateralToken Collateral token contract
     * @return Collateral parameters
     */
    function getCollateralParameters(address collateralToken) external view returns (CollateralParameters memory) {
        return _parameters[collateralToken];
    }

    /**
     * @notice Get list of supported collateral tokens
     * @return List of collateral token addresses
     */
    function supportedCollateralTokens() external view returns (address[] memory) {
        return _collateralTokens.values();
    }

    /**************************************************************************/
    /* Setters */
    /**************************************************************************/

    /**
     * @notice Set minimum loan duration
     *
     * Emits a {MinimumLoanDurationUpdated} event.
     *
     * @param duration Minimum loan duration in seconds
     */
    function setMinimumLoanDuration(uint256 duration) external onlyRole(PARAMETER_ADMIN_ROLE) {
        minimumLoanDuration = duration;

        emit MinimumLoanDurationUpdated(duration);
    }

    /**
     * @notice Set utilization parameters
     *
     * Emits a {UtilizationParametersUpdated} event.
     *
     * @param packedUtilizationParameters Utilization rate component model, ABI-encoded
     */
    function setUtilizationParameters(bytes calldata packedUtilizationParameters)
        external
        onlyRole(PARAMETER_ADMIN_ROLE)
    {
        _utilizationParameters = abi.decode(packedUtilizationParameters, (PiecewiseLinearModel));

        emit UtilizationParametersUpdated();
    }

    /**
     * @notice Set collateral parameters
     *
     * Emits a {CollateralParametersUpdated} event.
     *
     * @param collateralToken Collateral token contract
     * @param packedCollateralParameters Collateral parameters, ABI-encoded
     */
    function setCollateralParameters(address collateralToken, bytes calldata packedCollateralParameters)
        external
        onlyRole(PARAMETER_ADMIN_ROLE)
    {
        if (collateralToken == address(0)) revert InvalidAddress();

        _parameters[collateralToken] = abi.decode(packedCollateralParameters, (CollateralParameters));

        /* Validate rate component weights sum to 10000 */
        if (
            _parameters[collateralToken].rateComponentWeights[0] +
                _parameters[collateralToken].rateComponentWeights[1] +
                _parameters[collateralToken].rateComponentWeights[2] !=
            10000
        ) revert ParameterOutOfBounds(4);

        if (_parameters[collateralToken].active) {
            _collateralTokens.add(collateralToken);
        } else {
            _collateralTokens.remove(collateralToken);
        }

        emit CollateralParametersUpdated(collateralToken);
    }

    /**
     * @notice Set collateral collateral oracle
     *
     * Emits a {CollateralOracleUpdated} event.
     *
     * @param collateralOracle_ Collateral oracle contract
     */
    function setCollateralOracle(address collateralOracle_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (IERC20Metadata(address(ICollateralOracle(collateralOracle_).currencyToken())).decimals() != 18)
            revert UnsupportedTokenDecimals();

        collateralOracle = ICollateralOracle(collateralOracle_);

        emit CollateralOracleUpdated(collateralOracle_);
    }
}