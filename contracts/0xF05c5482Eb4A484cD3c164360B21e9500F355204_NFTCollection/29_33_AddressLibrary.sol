// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/libraries/AddressLibrary.sol";

contract $AddressLibrary {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    event $callAndReturnContractAddress_address_bytes_Returned(address payable arg0);

    event $callAndReturnContractAddress_CallWithoutValue_Returned(address payable arg0);

    constructor() {}

    function $callAndReturnContractAddress(address externalContract,bytes calldata callData) external payable returns (address payable) {
        (address payable ret0) = AddressLibrary.callAndReturnContractAddress(externalContract,callData);
        emit $callAndReturnContractAddress_address_bytes_Returned(ret0);
        return (ret0);
    }

    function $callAndReturnContractAddress(CallWithoutValue calldata call) external payable returns (address payable) {
        (address payable ret0) = AddressLibrary.callAndReturnContractAddress(call);
        emit $callAndReturnContractAddress_CallWithoutValue_Returned(ret0);
        return (ret0);
    }

    receive() external payable {}
}