// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
// import "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";

contract FeeManagerUpgradeable is Initializable, ContextUpgradeable, AccessControlUpgradeable {
    struct Fees {
        uint256 _transferFee;
        uint256 _exchangeFee;
        bool accepted;
    }

    address private handler;

    // destinationChainID => feeTokenAddress => Fees
    mapping(uint8 => mapping(address => Fees)) private _fees;
    mapping(uint8 => mapping(address => bool)) private _feeTokenWhitelisted;
    mapping(uint8 => address[]) private _chainFeeTokens;

    struct WidgetFee {
        address ownerOfWidget;
        uint256 feePerTx;
        uint256 accumulatedFee;
    }

    // widgetId + feeToken => widget fee struct
    mapping(uint256 => mapping(address => WidgetFee)) private _widgetFeeStruct;

    modifier isHandler() {
        require(handler == _msgSender(), "Fee Manager : Only Router Handlers can set Fees");
        _;
    }

    function __FeeManagerUpgradeable_init(address handlerAddress) internal initializer {
        __AccessControl_init();
        __Context_init_unchained();

        __FeeManagerUpgradeable_init_unchained(handlerAddress);
    }

    function initialize(address handlerAddress) external initializer {
        __FeeManagerUpgradeable_init(handlerAddress);
    }

    function __FeeManagerUpgradeable_init_unchained(address handlerAddress) internal initializer {
        handler = handlerAddress;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    event FeeUpdated(
        uint8 destinationChainID,
        address feeTokenAddress,
        uint256 transferFee,
        uint256 exchangeFee,
        bool accepted
    );

    /// @notice Used to fetch handler address.
    /// @notice Only callable by admin or Fee Setter.
    function fetchHandler() public view returns (address) {
        return handler;
    }

    /// @notice Used to setup handler address.
    /// @notice Only callable by admin or Fee Setter.
    /// @param  _handler Address of the new handler.
    function setHandler(address _handler) public onlyRole(DEFAULT_ADMIN_ROLE) {
        handler = _handler;
    }

    /// @notice Used to setup widget fee.
    /// @notice Only callable by admin or Fee Setter.
    /// @param  _widgetId Widget Id.
    /// @param  _feeToken Fee token address.
    /// @param  _feePerTx Fee per tx.
    /// @param  _ownerOfWidget Address which can withdraw widget fees. If not changing owner, just send address(0) in its place.
    function setWidgetFee(
        uint256[] memory _widgetId,
        address[] memory _feeToken,
        uint256[] memory _feePerTx,
        address[] memory _ownerOfWidget
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            _widgetId.length == _feeToken.length &&
                _widgetId.length == _feePerTx.length &&
                _widgetId.length == _ownerOfWidget.length,
            "array length mismatch"
        );

        for (uint32 i = 0; i < _widgetId.length; i++) {
            _widgetFeeStruct[_widgetId[i]][_feeToken[i]].feePerTx = _feePerTx[i];
            _widgetFeeStruct[_widgetId[i]][_feeToken[i]].ownerOfWidget = _ownerOfWidget[i];
        }
    }

    /// @notice Used to set deposit fee.
    /// @notice Only callable by admin or Fee Setter.
    /// @param  destinationChainID id of the destination chain.
    /// @param  feeTokenAddress address of the fee token.
    /// @param  transferFee Value {_transferFee} will be updated to.
    /// @param  exchangeFee Value {_exchangeFee} will be updated to.
    /// @param  accepted accepted status of the token as fee.
    function setFee(
        uint8 destinationChainID,
        address feeTokenAddress,
        uint256 transferFee,
        uint256 exchangeFee,
        bool accepted
    ) public isHandler {
        require(feeTokenAddress != address(0), "setFee: address can't be null");
        _fees[destinationChainID][feeTokenAddress] = Fees(transferFee, exchangeFee, accepted);

        if (!_feeTokenWhitelisted[destinationChainID][feeTokenAddress]) {
            _feeTokenWhitelisted[destinationChainID][feeTokenAddress] = true;
            _chainFeeTokens[destinationChainID].push(feeTokenAddress);
        }

        emit FeeUpdated(destinationChainID, feeTokenAddress, transferFee, exchangeFee, accepted);
    }

    /// @notice Used to get deposit fee.
    /// @param  destinationChainID id of the destination chain.
    /// @param  feeTokenAddress address of the fee token.
    /// @param  widgetId widgetId.
    function getFee(
        uint8 destinationChainID,
        address feeTokenAddress,
        uint256 widgetId
    )
        public
        view
        virtual
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        Fees memory fees = _fees[destinationChainID][feeTokenAddress];
        require(fees.accepted, "FeeManager: fees not set for this token");
        uint256 widgetFee = _widgetFeeStruct[widgetId][feeTokenAddress].feePerTx;

        return (fees._transferFee, fees._exchangeFee, widgetFee);
    }

    /// @notice Used to get deposit fee.
    /// @param  destChainId id of the destination chain.
    /// @param  feeToken address of the fee token.
    /// @param  widgetId widgetId.
    function getFeeSafe(
        uint8 destChainId,
        address feeToken,
        uint256 widgetId
    )
        public
        view
        virtual
        returns (
            uint256,
            uint256,
            uint256,
            bool
        )
    {
        Fees memory fees = _fees[destChainId][feeToken];
        uint256 widgetFee = _widgetFeeStruct[widgetId][feeToken].feePerTx;

        return (fees._transferFee, fees._exchangeFee, widgetFee, fees.accepted);
    }

    function depositWidgetFee(
        uint256 widgetID,
        address feeTokenAddress,
        uint256 feeAmount
    ) external isHandler {
        _widgetFeeStruct[widgetID][feeTokenAddress].accumulatedFee += feeAmount;
    }

    /// @notice Used to get listed fee tokens for given chain.
    /// @param  destChainId id of the destination chain.
    function getChainFeeTokens(uint8 destChainId) public view virtual returns (address[] memory) {
        return _chainFeeTokens[destChainId];
    }

    /// @notice Used to withdraw fee
    /// @param tokenAddress Address of token to withdraw.
    /// @param recipient Address to withdraw tokens to.
    /// @param amount the amount of ERC20 tokens to withdraw.
    function withdrawFee(
        address tokenAddress,
        address recipient,
        uint256 amount
    ) external isHandler {
        IERC20Upgradeable(tokenAddress).transfer(recipient, amount);
    }

    /// @notice Used to fetch widget fee.
    /// @param widgetId WidgetID.
    /// @param feeTokenAddress Address of fee token.
    /// @return widgetFee struct
    function getWidgetFee(uint256 widgetId, address feeTokenAddress) external view returns (WidgetFee memory) {
        return _widgetFeeStruct[widgetId][feeTokenAddress];
    }

    /// @notice Used to withdraw widget fee.
    /// @dev Can only be withdrawn by widget owner.
    /// @param widgetId WidgetID.
    /// @param feeTokenAddress Address of fee token to withdraw.
    /// @param amount the amount of fee tokens to withdraw. If want to withdraw full amount, send 0 as amount.
    function withdrawWidgetFee(
        uint256 widgetId,
        address feeTokenAddress,
        uint256 amount
    ) external {
        WidgetFee memory widgetFee = _widgetFeeStruct[widgetId][feeTokenAddress];

        require(msg.sender == widgetFee.ownerOfWidget, "only owner of widget");
        require(amount <= widgetFee.accumulatedFee, "amount exceeds widget fee accumulated");

        uint256 amountToWithdraw;

        if (amount == 0) {
            amountToWithdraw = widgetFee.accumulatedFee;
        } else {
            amountToWithdraw = amount;
        }

        _widgetFeeStruct[widgetId][feeTokenAddress].accumulatedFee -= amountToWithdraw;
        IERC20Upgradeable(feeTokenAddress).transfer(widgetFee.ownerOfWidget, amountToWithdraw);
    }
}