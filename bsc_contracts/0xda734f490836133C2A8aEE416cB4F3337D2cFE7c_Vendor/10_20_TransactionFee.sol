// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../security/Administered.sol";

contract TransactionFee is Context, Administered {
    // @dev fee per transaction
    uint256 public fee_fixed = 100; // 1% (Basis Points);
    address public _walletFee = address(0);

    constructor() {
        _walletFee = _msgSender();
    }

    /// @dev wallet fee
    function changeWalletFee(address newWalletFee) external onlyAdmin {
        _walletFee = newWalletFee;
    }

    /// @dev fee calculation for
    function calculateFee(uint256 amount) public view returns (uint256 fee) {
        return (amount * fee_fixed) / 10000;
    }

    /// @dev
    function changeFee(uint256 newValue) external onlyAdmin {
        fee_fixed = newValue;
    }
}