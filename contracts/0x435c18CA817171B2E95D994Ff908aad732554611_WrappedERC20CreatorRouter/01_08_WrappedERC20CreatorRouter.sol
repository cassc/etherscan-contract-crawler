// SPDX-License-Identifier: MIT
/**
 * Creator: Virtue Labs
 * Author: 0xYeety, CTO - Virtue Labs
 * Memetics: Church, CEO - Virtue Labs
**/

pragma solidity ^0.8.18;

import "./WrappedERC20Token.sol";

contract WrappedERC20CreatorRouter {
    mapping(address => address) public RAW_TO_WRAPPED;
    mapping(address => address) public WRAPPED_TO_RAW;
    mapping(uint256 => address) public RAW_CONTRACTS_ARR;
    uint256 public NUM_CONTRACTS_WRAPPED = 0;

    constructor(
        address[] memory _raw,
        address[] memory _wrapped
    ) {
        require(_raw.length == _wrapped.length, "length mismatch");
        uint256 contractsWrapped = NUM_CONTRACTS_WRAPPED;
        for (uint256 i = 0; i < _raw.length; i++) {
            require(RAW_TO_WRAPPED[_raw[i]] == address(0), "already wrapped");
            RAW_TO_WRAPPED[_raw[i]] =_wrapped[i];
            WRAPPED_TO_RAW[_wrapped[i]] =_raw[i];
            RAW_CONTRACTS_ARR[contractsWrapped] = _raw[i];
            contractsWrapped++;
        }
        NUM_CONTRACTS_WRAPPED = contractsWrapped;
    }

    function generateWrappedTokenContract(address rawTokenContract) public {
        require(RAW_TO_WRAPPED[rawTokenContract] == address(0), "already wrapped");

        WrappedERC20Token new_wERC20 = new WrappedERC20Token(
            rawTokenContract,
                string(abi.encodePacked("Wrapped ", IERC20Metadata(rawTokenContract).name())),
                string(abi.encodePacked("w", IERC20Metadata(rawTokenContract).symbol()))
        );

        RAW_TO_WRAPPED[rawTokenContract] = address(new_wERC20);
        WRAPPED_TO_RAW[address(new_wERC20)] = rawTokenContract;

        RAW_CONTRACTS_ARR[NUM_CONTRACTS_WRAPPED] = rawTokenContract;
        NUM_CONTRACTS_WRAPPED++;
    }

    function getWrappedOf(address raw) public view returns (address) {
        return RAW_TO_WRAPPED[raw];
    }

    function getRawOf(address wrapped) public view returns (address) {
        return WRAPPED_TO_RAW[wrapped];
    }

    function getRawAtPos(uint256 pos) public view returns (address) {
        return RAW_CONTRACTS_ARR[pos];
    }

    function batchGetWrappedOf(address[] calldata raw_arr) public view returns (address[] memory) {
        address[] memory toReturn = new address[](raw_arr.length);
        for (uint256 i = 0; i < raw_arr.length; i++) {
            toReturn[i] = RAW_TO_WRAPPED[raw_arr[i]];
        }
        return toReturn;
    }

    function batchGetRawOf(address[] calldata wrapped_arr) public view returns (address[] memory) {
        address[] memory toReturn = new address[](wrapped_arr.length);
        for (uint256 i = 0; i < wrapped_arr.length; i++) {
            toReturn[i] = WRAPPED_TO_RAW[wrapped_arr[i]];
        }
        return toReturn;
    }

    function batchGetRawAtPos(uint256[] calldata pos_arr) public view returns (address[] memory) {
        address[] memory toReturn = new address[](pos_arr.length);
        for (uint256 i = 0; i < pos_arr.length; i++) {
            toReturn[i] = RAW_CONTRACTS_ARR[pos_arr[i]];
        }
        return toReturn;
    }
}

/**************************************/