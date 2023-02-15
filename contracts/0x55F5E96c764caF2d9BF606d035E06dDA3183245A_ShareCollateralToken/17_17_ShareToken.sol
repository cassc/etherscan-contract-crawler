// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../interfaces/ISilo.sol";
import "../interfaces/IBaseSilo.sol";
import "../interfaces/IShareToken.sol";
import "../interfaces/INotificationReceiver.sol";


/// @title ShareToken
/// @notice Implements common interface for Silo tokens representing debt or collateral positions.
/// @custom:security-contact [email protected]
abstract contract ShareToken is ERC20, IShareToken {
    /// @dev minimal share amount will give us higher precision for shares calculation,
    /// that way losses caused by division will be reduced to acceptable level
    uint256 public constant MINIMUM_SHARE_AMOUNT = 1e5;

    /// @notice Silo address for which tokens was deployed
    ISilo public immutable silo;

    /// @notice asset for which this tokens was deployed
    address public immutable asset;

    /// @dev decimals that match the original asset decimals
    uint8 internal immutable _decimals;

    error OnlySilo();
    error MinimumShareRequirement();

    modifier onlySilo {
        if (msg.sender != address(silo)) revert OnlySilo();

        _;
    }

    /// @dev Token is always deployed for specific Silo and asset
    /// @param _silo Silo address for which tokens was deployed
    /// @param _asset asset for which this tokens was deployed
    constructor(address _silo, address _asset) {
        silo = ISilo(_silo);
        asset = _asset;
        _decimals = IERC20Metadata(_asset).decimals();
    }

    /// @inheritdoc IShareToken
    function mint(address _account, uint256 _amount) external onlySilo override {
        _mint(_account, _amount);
    }

    /// @inheritdoc IShareToken
    function burn(address _account, uint256 _amount) external onlySilo override {
        _burn(_account, _amount);
    }

    /// @inheritdoc IERC20Metadata
    function symbol() public view virtual override(IERC20Metadata, ERC20) returns (string memory) {
        return ERC20.symbol();
    }

    /// @return decimals that match original asset decimals
    function decimals() public view virtual override(IERC20Metadata, ERC20) returns (uint8) {
        return _decimals;
    }

    function _afterTokenTransfer(address _sender, address _recipient, uint256) internal override virtual {
        // fixing precision error on mint and burn
        if (_isTransfer(_sender, _recipient)) {
            return;
        }

        uint256 total = totalSupply();
        // we require minimum amount to be present from first mint
        // and after burning, we do not allow for small leftover
        if (total != 0 && total < MINIMUM_SHARE_AMOUNT) revert MinimumShareRequirement();
    }

    /// @dev Report token transfer to incentive contract if one is set
    /// @param _from sender
    /// @param _to recipient
    /// @param _amount amount that was transferred
    function _notifyAboutTransfer(address _from, address _to, uint256 _amount) internal {
        INotificationReceiver notificationReceiver =
            IBaseSilo(silo).siloRepository().getNotificationReceiver(address(silo));

        if (address(notificationReceiver) != address(0)) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool success,) = address(notificationReceiver).call(
                abi.encodeWithSelector(
                    INotificationReceiver.onAfterTransfer.selector,
                    address(this),
                    _from,
                    _to,
                    _amount
                )
            );

            emit NotificationSent(notificationReceiver, success);
        }
    }

    /// @dev checks if operation is "real" transfer
    /// @param _sender sender address
    /// @param _recipient recipient address
    /// @return bool true if operation is real transfer, false if it is mint or burn
    function _isTransfer(address _sender, address _recipient) internal pure returns (bool) {
        // in order this check to be true, is is required to have:
        // require(sender != address(0), "ERC20: transfer from the zero address");
        // require(recipient != address(0), "ERC20: transfer to the zero address");
        // on transfer. ERC20 has them, so we good.
        return _sender != address(0) && _recipient != address(0);
    }
}