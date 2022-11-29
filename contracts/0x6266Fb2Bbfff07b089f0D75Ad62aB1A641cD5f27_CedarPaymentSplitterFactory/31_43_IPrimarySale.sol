// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IPrimarySaleV0 {
    /// @dev The address that receives all primary sales value.
    function primarySaleRecipient() external view returns (address);

    /// @dev Lets a module admin set the default recipient of all primary sales.
    function setPrimarySaleRecipient(address _saleRecipient) external;

    /// @dev Emitted when a new sale recipient is set.
    event PrimarySaleRecipientUpdated(address indexed recipient);
}

interface IPrimarySaleV1 {
    /// @dev The address that receives all primary sales value.
    function primarySaleRecipient() external view returns (address);

    /// @dev Lets a module admin set the default recipient of all primary sales.
    function setPrimarySaleRecipient(address _saleRecipient) external;

    /// @dev Emitted when a new sale recipient is set.
    event PrimarySaleRecipientUpdated(address indexed recipient, bool frogs);
}

interface IPublicPrimarySaleV1 {
    /// @dev The address that receives all primary sales value.
    function primarySaleRecipient() external view returns (address);
}

interface IRestrictedPrimarySaleV1 {
    /// @dev Lets a module admin set the default recipient of all primary sales.
    function setPrimarySaleRecipient(address _saleRecipient) external;
}