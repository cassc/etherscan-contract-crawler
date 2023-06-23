// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Additional is Ownable {
    address private _feeWallet;
    address private _signerRole;
    address private _adminRole;
    uint16 private _commission;

    event CommissionChanged(uint16 indexed previousCommission, uint16 indexed newCommission);
    event FeeWalletChanged(address indexed previousOwner, address indexed newOwner);
    event SugnerRoleChanged(address indexed previousOwner, address indexed newOwner);
    event AdminRoleChanged(address indexed previousOwner, address indexed newOwner);

     modifier onlyAdmin() {
         require(_adminRole == _msgSender(), "KR: Caller is not the admin");
        _;
    }


    /**
    * @dev Initializes the contract setting the deployer as the initial fee wallet.
    */
    constructor() {
        _feeWallet = 0x6952143ceD1F519c6aedc9C03b10B9A1b7CdA133;
        _signerRole = 0x2085DFc2619d10b1b5c0CeFDdf9fa13DFDeEAe3E;
        _adminRole = 0x6952143ceD1F519c6aedc9C03b10B9A1b7CdA133;
        _commission = 500; //default commission 5%
    }

    /**
     * @dev Returns the commission on the contract.
     */
    function getCommission() external view returns (uint16) {
        return _commission;
    }

    /**
     * @dev Returns the address of the current fee wallet.
     */
    function getFeeWallet() external view returns (address) {
        return _feeWallet;
    }

    /**
     * @dev Returns the address of the current fee wallet.
     */
    function feeWallet() internal view returns (address payable) {
        return payable(_feeWallet);
    }

    /**
     * @dev Returns the address of the current admin wallet.
     */
    function adminRole() public view returns (address) {
        return _adminRole;
    }

    /**
     * @dev Returns the address of the current backend wallet.
     */
    function signerRole() public view returns (address) {
        return _signerRole;
    }

    /**
     * @dev Change commission of the contract to a new value.
     * Can only be called by the current admin.
     */
    function changeCommission(uint16 commission_) external onlyAdmin {
        uint16 oldComission = _commission;
        _commission = commission_;

        emit CommissionChanged(oldComission, commission_);
    }

    /**
     * @dev Change fee wallet of the contract to a new account (`newFeeWallet`).
     * Can only be called by the current owner.
     */
    function changeFeeWallet(address newFeeWallet) external onlyOwner {
        require(newFeeWallet != address(0), "KR: new fee wallet is the zero address");
        address oldFeeWallet = _feeWallet;
        _feeWallet = newFeeWallet;
        emit FeeWalletChanged(oldFeeWallet, newFeeWallet);
    }

    /**
     * @dev Change signer wallet of the contract to a new account.
     * Can only be called by the current owner.
     */
    function changeSignerRole(address newSignerRole) external onlyOwner {
        require(newSignerRole != address(0), "KR: new signer wallet is the zero address");
         address oldSignerRole = _signerRole;
        _signerRole = newSignerRole;
        emit SugnerRoleChanged(oldSignerRole, newSignerRole);
    }

    /**
     * @dev Change admin wallet of the contract to a new account.
     * Can only be called by the current owner.
     */
    function changeAdminRole(address newAdminRole) external onlyOwner {
        require(newAdminRole != address(0), "KR: new admin wallet is the zero address");
         address oldAdminRole = _adminRole;
        _adminRole = newAdminRole;
        emit AdminRoleChanged(oldAdminRole, newAdminRole);
    }

    function getFeeValue(uint price) external view returns(uint, uint) { 
        uint fee = _getFee(price);
        return (fee,  price - fee);
    }

    function _getFee(uint price) internal view returns(uint) { 
        return price * _commission / 10000;
    }
}