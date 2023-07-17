// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {Ownership} from "./libraries/Ownership.sol";
import "./Vault.sol";

/**
 * @dev
 * Strategies have to implement the following virtual functions:
 *
 * totalAssets()
 * _withdraw(uint256, address)
 * _harvest()
 * _invest()
 */
abstract contract Strategy is Ownership {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    Vault public immutable vault;
    ERC20 public immutable asset;

    /// @notice address which performance fees are sent to
    address public treasury;
    /// @notice performance fee sent to treasury / FEE_BASIS of 10_000
    uint16 public fee = 1_000;
    uint16 internal constant MAX_FEE = 1_000;
    uint16 internal constant FEE_BASIS = 10_000;

    /// @notice used to calculate slippage / SLIP_BASIS of 10_000
    /// @dev default to 99% (or 1%)
    uint16 public slip = 9_900;
    uint16 internal constant SLIP_BASIS = 10_000;

    /*//////////////////
    /      Events      /
    //////////////////*/

    event FeeChanged(uint16 newFee);
    event SlipChanged(uint16 newSlip);
    event TreasuryChanged(address indexed newTreasury);

    /*//////////////////
    /      Errors      /
    //////////////////*/

    error Zero();
    error NotVault();
    error InvalidValue();
    error AlreadyValue();

    constructor(Vault _vault, address _treasury, address _nominatedOwner, address _admin, address[] memory _authorized)
        Ownership(_nominatedOwner, _admin, _authorized)
    {
        vault = _vault;
        asset = vault.asset();
        treasury = _treasury;
    }

    /*//////////////////////////
    /      Public Virtual      /
    //////////////////////////*/

    /// @notice amount of 'asset' currently managed by strategy
    function totalAssets() public view virtual returns (uint256);

    /*///////////////////////////////////////////
    /      Restricted Functions: onlyVault      /
    ///////////////////////////////////////////*/

    function withdraw(uint256 _assets) external onlyVault returns (uint256 received, uint256 slippage, uint256 bonus) {
        uint256 total = totalAssets();
        if (total == 0) revert Zero();

        uint256 assets = _assets > total ? total : _assets;

        received = _withdraw(assets);

        unchecked {
            if (assets > received) {
                slippage = assets - received;
            } else if (received > assets) {
                bonus = received - assets;
                // received cannot > assets for vault calcuations
                received = assets;
            }
        }
    }

    /*//////////////////////////////////////////////////
    /      Restricted Functions: onlyAdminOrVault      /
    //////////////////////////////////////////////////*/

    function harvest() external onlyAdminOrVault returns (uint256 received) {
        _harvest();

        received = asset.balanceOf(address(this));

        if (fee > 0) {
            uint256 feeAmount = _calculateFee(received);
            received -= feeAmount;
            asset.safeTransfer(treasury, feeAmount);
        }

        asset.safeTransfer(address(vault), received);
    }

    function invest() external onlyAdminOrVault {
        _invest();
    }

    /*///////////////////////////////////////////
    /      Restricted Functions: onlyOwner      /
    ///////////////////////////////////////////*/

    function setFee(uint16 _fee) external onlyOwner {
        if (_fee > MAX_FEE) revert InvalidValue();
        if (_fee == fee) revert AlreadyValue();
        fee = _fee;
        emit FeeChanged(_fee);
    }

    function setTreasury(address _treasury) external onlyOwner {
        if (_treasury == treasury) revert AlreadyValue();
        treasury = _treasury;
        emit TreasuryChanged(_treasury);
    }

    /*////////////////////////////////////////////
    /      Restricted Functions: onlyAdmins      /
    ////////////////////////////////////////////*/

    function setSlip(uint16 _slip) external onlyAdmins {
        if (_slip > SLIP_BASIS) revert InvalidValue();
        if (_slip == slip) revert AlreadyValue();
        slip = _slip;
        emit SlipChanged(_slip);
    }

    /*////////////////////////////
    /      Internal Virtual      /
    ////////////////////////////*/

    function _withdraw(uint256 _assets) internal virtual returns (uint256 received);

    /// @dev return harvested assets
    function _harvest() internal virtual;

    function _invest() internal virtual;

    /*//////////////////////////////
    /      Internal Functions      /
    //////////////////////////////*/

    function _calculateSlippage(uint256 _amount) internal view returns (uint256) {
        return _amount.mulDivDown(slip, SLIP_BASIS);
    }

    function _calculateFee(uint256 _amount) internal view returns (uint256) {
        return _amount.mulDivDown(fee, FEE_BASIS);
    }

    modifier onlyVault() {
        if (msg.sender != address(vault)) revert NotVault();
        _;
    }

    /*//////////////////////////////
    /      Internal Functions      /
    //////////////////////////////*/

    modifier onlyAdminOrVault() {
        if (msg.sender != owner && msg.sender != admin && msg.sender != address(vault)) revert Unauthorized();
        _;
    }
}