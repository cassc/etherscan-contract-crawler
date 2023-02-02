// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol";
import "../common/BaseGovernanceWithUserUpgradable.sol";
import "../features-interfaces/ITxFeeFeatureV3.sol";
import "../ERC20Base.sol";

/**
 * @dev ERC20 token with a Transaction Fee feature
 */
abstract contract TxFeeFeatureV3 is ERC20Base, ITxFeeFeatureV3 {

    /// The fee rate of the token
    bytes32 internal constant TX_FEE_SLOT = keccak256("polkalokr.features.txFeeFeature._txFee");
    /// address of the fee beneficiary
    bytes32 internal constant TX_FEE_BENEFICIARY_SLOT = keccak256("polkalokr.features.txFeeFeature._txFeeBeneficiary");
    ///@notice role for tax-exempt address
    bytes32 public constant TX_FEE_WHITELISTED_ROLE = keccak256("polkalokr.features.txFeeFeature._txFeeBeneficiaryRole");
    //@notice role to admin the TX_FEE_WHITELISTED_ROLE
    bytes32 public constant TX_FEE_WHITELISTED_MANAGER = keccak256("polkalokr.features.txFeeFeature._txFeeManagerRole");
    /// divisor for the fee calculation
    uint256 internal constant EXP = 1e18;

    function __ERC20TxFeeFeature_init_unchained(uint256 _txFee, address _txFeeBeneficiary) internal onlyInitializing {
        require(_txFee < EXP, "ERROR: TX FEE CANT BE 100%");
        require(_txFeeBeneficiary != address(0), "TX FEE BENEFICIARY CANT BE ADDRESS 0");
        StorageSlotUpgradeable.getUint256Slot(TX_FEE_SLOT).value = _txFee;
        StorageSlotUpgradeable.getAddressSlot(TX_FEE_BENEFICIARY_SLOT).value = _txFeeBeneficiary;

        _setRoleAdmin(TX_FEE_WHITELISTED_ROLE, TX_FEE_WHITELISTED_MANAGER);

        _grantRole(TX_FEE_WHITELISTED_MANAGER, _txFeeBeneficiary);

        if (tx.origin != _txFeeBeneficiary) {
            _grantRole(TX_FEE_WHITELISTED_MANAGER, tx.origin);
        }
    }

    /// @dev Set the tx fee and the tx fee beneficiary
    /// @param _txFee The tx fee in wei
    /// @param _txFeeBeneficiary The address of the beneficiary of the tx fee
    /// @notice The tx fee beneficiary must be a valid address
    function changeTxFeeProperties(uint256 _txFee, address _txFeeBeneficiary) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_txFee < EXP, "ERROR: TX FEE CANT BE 100%");
        require(_txFeeBeneficiary != address(0), "TX FEE BENEFICIARY CANT BE ADDRESS 0");
        /// factories or deployers will be excluded from the tx fee
        grantRole(TX_FEE_WHITELISTED_ROLE, _msgSender());
        StorageSlotUpgradeable.getUint256Slot(TX_FEE_SLOT).value = _txFee;
        StorageSlotUpgradeable.getAddressSlot(TX_FEE_BENEFICIARY_SLOT).value = _txFeeBeneficiary;
    }

    function _beforeTokenTransfer_hook(address from, address to, uint256 amount)  internal virtual {
    }

    /// @dev called before a token transfer is made and modificated to charge the tx fee
    function transfer(address recipient, uint256 amount) public virtual override(ERC20Upgradeable, ITxFeeFeatureV3) returns (bool) {
        uint256 txFee = StorageSlotUpgradeable.getUint256Slot(TX_FEE_SLOT).value;
        address txFeeBeneficiary = StorageSlotUpgradeable.getAddressSlot(TX_FEE_BENEFICIARY_SLOT).value;
        uint256 txFeeAmount = 0;
        /// fee is paid to the beneficiary as an additional transaction
        /// charge the tx fee beneficiary while sender or recipient has not been whitelisted
        if( 
            (txFee != 0 ||                   // No txFee
            txFeeBeneficiary != recipient || // Send txFee itself
            address(0) != recipient) &&      // Burn
            !_checkTXRoles(_msgSender(), recipient)
        ){
            txFeeAmount = amount * txFee / EXP;
            _transfer(_msgSender(), txFeeBeneficiary, txFeeAmount);
        }
        
        
        _transfer(_msgSender(), recipient, amount - txFeeAmount);
        return true;
    }

    /// @dev called before a token transfer is made and modificated to charge the tx fee
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override(ERC20Upgradeable, ITxFeeFeatureV3) returns (bool) {
        uint256 txFee = StorageSlotUpgradeable.getUint256Slot(TX_FEE_SLOT).value;
        address txFeeBeneficiary = StorageSlotUpgradeable.getAddressSlot(TX_FEE_BENEFICIARY_SLOT).value;
        uint256 txFeeAmount = 0;
        /// fee is paid to the beneficiary as an additional transaction
        /// charge the tx fee beneficiary while sender or recipient has not been whitelisted
        if( 
            (txFee != 0 || // No txFee
            txFeeBeneficiary != recipient || // Send txFee itself
            address(0) != recipient) &&      // Burn
            !_checkTXRoles(sender, recipient)
        ){
            txFeeAmount = amount * txFee / EXP;
            _transfer(sender, txFeeBeneficiary, txFeeAmount);
        }

        
        _transfer(sender, recipient, amount - txFeeAmount);

        /// handle the allowance of the sender
        uint256 currentAllowance = allowance(sender, _msgSender());
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function _checkTXRoles(address sender, address recipient) internal view returns(bool) {
        return(
            hasRole(TX_FEE_WHITELISTED_ROLE, sender) ||
            hasRole(TX_FEE_WHITELISTED_ROLE, recipient) ||
            hasRole(TX_FEE_WHITELISTED_MANAGER, _msgSender()) ||
            hasRole(TX_FEE_WHITELISTED_MANAGER, recipient)
        );
    }
}