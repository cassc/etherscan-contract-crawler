// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0;

interface IERC721Describable {

    event DescriptorUpdate(address prevValue, address newValue, address indexed sender);

    function descriptor() external view returns (address);

}