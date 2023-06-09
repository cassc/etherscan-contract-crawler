// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0;

interface IERC721Details {

    event SellerFeeUpdate(uint256 prevValue, uint256 newValue, address indexed sender);
    event FeeReceiverUpdate(address prevValue, address newValue, address indexed sender);
    event ContractDetailsUpdate(
        ContractDetails prevValue,
        ContractDetails newValue,
        address indexed sender
    );

    struct ContractDetails {
        string name;
        string description;
        string image;
        string link;
    }

    function contractURI() external view returns (string memory);
    function details() external view returns (ContractDetails memory);
    function sellerFee() external view returns (uint256);
    function feeReceiver() external view returns (address);
}