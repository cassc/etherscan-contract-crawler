// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "./interfaces/IFlaixOption.sol";

contract FlaixOptionFactory {
    using Clones for address;

    address public immutable callOptionImplementation;
    address public immutable putOptionImplementation;

    constructor(address _callOptionImplementation, address _putOptionImplementation) {
        require(
            _callOptionImplementation != address(0),
            "FlaixOptionFactory: callOptionImplementation is the zero address"
        );
        require(
            _putOptionImplementation != address(0),
            "FlaixOptionFactory: putOptionImplementation is the zero address"
        );
        callOptionImplementation = _callOptionImplementation;
        putOptionImplementation = _putOptionImplementation;
    }

    function createCallOption(
        string memory name,
        string memory symbol,
        address asset,
        address minter,
        address vault,
        uint256 totalSupply,
        uint maturityTimestamp
    ) external returns (address contractAddress) {
        contractAddress = callOptionImplementation.clone();
        IFlaixOption(contractAddress).initialize(name, symbol, asset, minter, vault, totalSupply, maturityTimestamp);
    }

    function createPutOption(
        string memory name,
        string memory symbol,
        address asset,
        address minter,
        address vault,
        uint256 totalSupply,
        uint maturityTimestamp
    ) external returns (address contractAddress) {
        contractAddress = putOptionImplementation.clone();
        IFlaixOption(contractAddress).initialize(name, symbol, asset, minter, vault, totalSupply, maturityTimestamp);
    }
}