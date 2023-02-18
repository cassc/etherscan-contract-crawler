// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./interfaces/IPrimarySale.sol";

error PrimarySale__Unauthorized();

abstract contract PrimarySale is IPrimarySale {
    /// @dev The address that receives all primary sales value.
    address internal _recipient;

    modifier onlySale() {
        if (msg.sender != _recipient) revert PrimarySale__Unauthorized();
        _;
    }

    /// @dev Returns primary sale recipient address.
    function primarySaleRecipient() public view override returns (address) {
        return _recipient;
    }

    /// @dev Lets a contract admin set the recipient for all primary sales.
    function _setupPrimarySaleRecipient(address saleRecipient_) internal {
        _recipient = saleRecipient_;
        emit PrimarySaleRecipientUpdated(saleRecipient_);
    }

    uint256[49] private __gap;
}