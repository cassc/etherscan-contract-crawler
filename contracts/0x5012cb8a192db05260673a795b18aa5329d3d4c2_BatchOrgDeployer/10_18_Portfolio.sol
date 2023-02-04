//SPDX-License-Identifier: BSD 3-Clause
pragma solidity >=0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {Registry} from "./Registry.sol";
import {Entity} from "./Entity.sol";
import {EndaomentAuth} from "./lib/auth/EndaomentAuth.sol";
import {RolesAuthority} from "./lib/auth/authorities/RolesAuthority.sol";
import {Math} from "./lib/Math.sol";

abstract contract Portfolio is ERC20, EndaomentAuth {
    using Math for uint256;

    Registry public immutable registry;
    uint256 public cap;
    uint256 public depositFee;
    uint256 public redemptionFee;
    address public immutable asset;
    bool public didShutdown;

    error InvalidSwapper();
    error TransferDisallowed();
    error DepositAfterShutdown();
    error DidShutdown();
    error NotEntity();
    error ExceedsCap();
    error PercentageOver100();
    error RoundsToZero();
    error CallFailed(bytes response);

    /// @notice `sender` has exchanged `assets` (after fees) for `shares`, and transferred those `shares` to `receiver`.
    /// The sender paid a total of `depositAmount` and was charged `fee` for the transaction.
    event Deposit(
        address indexed sender,
        address indexed receiver,
        uint256 assets,
        uint256 shares,
        uint256 depositAmount,
        uint256 fee
    );

    /// @notice `sender` has exchanged `shares` for `assets`, and transferred those `assets` to `receiver`.
    /// The sender received a net of `redeemedAmount` after the conversion of `assets` into base tokens
    /// and was charged `fee` for the transaction.
    event Redeem(
        address indexed sender,
        address indexed receiver,
        uint256 assets,
        uint256 shares,
        uint256 redeemedAmount,
        uint256 fee
    );

    /// @notice Event emitted when `cap` is set.
    event CapSet(uint256 cap);

    /// @notice Event emitted when `depositFee` is set.
    event DepositFeeSet(uint256 fee);

    /// @notice Event emitted when `redemptionFee` is set.
    event RedemptionFeeSet(uint256 fee);

    /// @notice Event emitted when management takes fees.
    event FeesTaken(uint256 amount);

    /// @notice Event emitted when admin forcefully swaps portfolio asset balance for baseToken.
    event Shutdown(uint256 assetAmount, uint256 baseTokenOut);

    /**
     * @param _registry Endaoment registry.
     * @param _name Name of the ERC20 Portfolio share tokens.
     * @param _symbol Symbol of the ERC20 Portfolio share tokens.
     * @param _cap Amount in baseToken that value of totalAssets should not exceed.
     * @param _depositFee Percentage fee as ZOC that will go to treasury on asset deposit.
     * @param _redemptionFee Percentage fee as ZOC that will go to treasury on share redemption.
     */
    constructor(
        Registry _registry,
        address _asset,
        string memory _name,
        string memory _symbol,
        uint256 _cap,
        uint256 _depositFee,
        uint256 _redemptionFee
    ) ERC20(_name, _symbol, ERC20(_asset).decimals()) {
        registry = _registry;
        if (_redemptionFee > Math.ZOC) revert PercentageOver100();
        depositFee = _depositFee;
        redemptionFee = _redemptionFee;
        cap = _cap;
        asset = _asset;
        __initEndaomentAuth(_registry, "portfolio");
    }

    /**
     * @notice Function used to determine whether an Entity is active on the registry.
     * @param _entity The Entity.
     */
    function _isEntity(Entity _entity) internal view returns (bool) {
        return registry.isActiveEntity(_entity);
    }

    /**
     * @notice Set the Portfolio cap.
     * @param _amount Amount, denominated in baseToken.
     */
    function setCap(uint256 _amount) external virtual requiresAuth {
        cap = _amount;
        emit CapSet(_amount);
    }

    /**
     * @notice Set deposit fee.
     * @param _pct Percentage as ZOC (e.g. 1000 = 10%).
     */
    function setDepositFee(uint256 _pct) external virtual requiresAuth {
        if (_pct > Math.ZOC) revert PercentageOver100();
        depositFee = _pct;
        emit DepositFeeSet(_pct);
    }

    /**
     * @notice Set redemption fee.
     * @param _pct Percentage as ZOC (e.g. 1000 = 10%).
     */
    function setRedemptionFee(uint256 _pct) external virtual requiresAuth {
        if (_pct > Math.ZOC) revert PercentageOver100();
        redemptionFee = _pct;
        emit RedemptionFeeSet(_pct);
    }

    /**
     * @notice Total amount of the underlying asset that is managed by the Portfolio.
     */
    function totalAssets() external view virtual returns (uint256);

    /**
     * @notice Takes some amount of assets from this portfolio as assets under management fee.
     * @param _amountAssets Amount of assets to take.
     */
    function takeFees(uint256 _amountAssets) external virtual;

    /**
     * @notice Exchange `_amountBaseToken` for some amount of Portfolio shares.
     * @param _amountBaseToken The amount of the Entity's baseToken to deposit.
     * @param _data Data that the portfolio needs to make the deposit. In some cases, this will be swap parameters.
     * @return shares The amount of shares that this deposit yields to the Entity.
     */
    function deposit(uint256 _amountBaseToken, bytes calldata _data) external virtual returns (uint256 shares);

    /**
     * @notice Exchange `_amountShares` for some amount of baseToken.
     * @param _amountShares The amount of the Entity's portfolio shares to exchange.
     * @param _data Data that the portfolio needs to make the redemption. In some cases, this will be swap parameters.
     * @return baseTokenOut The amount of baseToken that this redemption yields to the Entity.
     */
    function redeem(uint256 _amountShares, bytes calldata _data) external virtual returns (uint256 baseTokenOut);

    /**
     * @notice Calculates the amount of shares that the Portfolio should exchange for the amount of assets provided.
     * @param _amountAssets Amount of assets.
     */
    function convertToShares(uint256 _amountAssets) public view virtual returns (uint256);

    /**
     * @notice Calculates the amount of assets that the Portfolio should exchange for the amount of shares provided.
     * @param _amountShares Amount of shares.
     */
    function convertToAssets(uint256 _amountShares) public view virtual returns (uint256);

    /**
     * @notice Exit out all assets of portfolio for baseToken. Must persist a mechanism for entities to redeem their shares for baseToken.
     * @param _data Data that the portfolio needs to exit from asset. In some cases, this will be swap parameters.
     * @return baseTokenOut The amount of baseToken that this exit yielded.
     */
    function shutdown(bytes calldata _data) external virtual returns (uint256 baseTokenOut);

    /// @notice `transfer` disabled on Portfolio tokens.
    function transfer(
        address,
        /**
         * to
         */
        uint256
    )
        /**
         * amount
         */
        public
        pure
        override
        returns (bool)
    {
        revert TransferDisallowed();
    }

    /// @notice `transferFrom` disabled on Portfolio tokens.
    function transferFrom(
        address,
        /**
         * from
         */
        address,
        /**
         * to
         */
        uint256
    )
        /**
         * amount
         */
        public
        pure
        override
        returns (bool)
    {
        revert TransferDisallowed();
    }

    /// @notice `approve` disabled on Portfolio tokens.
    function approve(
        address,
        /**
         * to
         */
        uint256
    )
        /**
         * amount
         */
        public
        pure
        override
        returns (bool)
    {
        revert TransferDisallowed();
    }

    /// @notice `permit` disabled on Portfolio tokens.
    function permit(
        address, /* owner */
        address, /* spender */
        uint256, /* value */
        uint256, /* deadline */
        uint8, /* v */
        bytes32, /* r */
        bytes32 /* s */
    ) public pure override {
        revert TransferDisallowed();
    }

    /**
     * @notice Permissioned method that allows Endaoment admin to make arbitrary calls acting as this Portfolio.
     * @param _target The address to which the call will be made.
     * @param _value The ETH value that should be forwarded with the call.
     * @param _data The calldata that will be sent with the call.
     * @return _return The data returned by the call.
     */
    function callAsPortfolio(address _target, uint256 _value, bytes memory _data)
        external
        payable
        requiresAuth
        returns (bytes memory)
    {
        (bool _success, bytes memory _response) = payable(_target).call{value: _value}(_data);
        if (!_success) revert CallFailed(_response);
        return _response;
    }

    /// @dev Internal helper method to calculate the fee on a base token amount for a given fee multiplier.
    function _calculateFee(uint256 _amount, uint256 _feeMultiplier)
        internal
        pure
        returns (uint256 _netAmount, uint256 _fee)
    {
        if (_feeMultiplier > Math.ZOC) revert PercentageOver100();
        unchecked {
            // unchecked as no possibility of overflow with baseToken precision
            _fee = _amount.zocmul(_feeMultiplier);
            // unchecked as the _feeMultiplier check with revert above protects against overflow
            _netAmount = _amount - _fee;
        }
    }
}