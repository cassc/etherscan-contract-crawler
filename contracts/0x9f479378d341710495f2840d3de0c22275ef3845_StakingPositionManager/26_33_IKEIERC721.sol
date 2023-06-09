// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0;

import "./IERC721Details.sol";

interface IKEIERC721 {

    function totalSupply() external view returns (uint256);

    function updateSellerFee(uint256 newSellerFee) external;
    function updateDetails(IERC721Details.ContractDetails calldata newContractDetails) external;
    function updateDescriptor(address newDescriptor) external;
    function updateFeeReceiver(address newAssetReceiver) external;
}