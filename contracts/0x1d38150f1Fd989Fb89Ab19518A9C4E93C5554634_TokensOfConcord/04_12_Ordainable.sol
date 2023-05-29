// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

    error NotWorthy();
    error NotWorthyToOrdain();

contract Ordainable is Ownable {

    mapping(address => bool) private ordained;

    /**
     *  @dev 𝔒𝔫𝔩𝔶 𝔱𝔥𝔢 𝔠𝔯𝔢𝔞𝔱𝔬𝔯 𝔦𝔰 𝔴𝔬𝔯𝔱𝔥𝔶.
     */
    modifier onlyCreator {
        if ( msg.sender != owner() ) revert NotWorthy();
        _;
    }

    /**
     *  @dev 𝔒𝔫𝔩𝔶 𝔱𝔥𝔢 𝔬𝔯𝔡𝔞𝔦𝔫𝔢𝔡 𝔬𝔯 𝔠𝔯𝔢𝔞𝔱𝔬𝔯 𝔞𝔯𝔢 𝔴𝔬𝔯𝔱𝔥𝔶.
     */
    modifier onlyOrdainedOrCreator {
        if ( msg.sender != owner() && ordained[msg.sender] != true ) revert NotWorthy();
        _;
    }

    /**
     *  @dev 𝔒𝔫𝔩𝔶 𝔱𝔥𝔢 𝔬𝔯𝔡𝔞𝔦𝔫𝔢𝔡 𝔞𝔯𝔢 𝔴𝔬𝔯𝔱𝔥𝔶.
     */
    modifier onlyOrdained {
        if ( ordained[msg.sender] != true ) revert NotWorthy();
        _;
    }

    /**
     *  @dev 𝔒𝔯𝔡𝔞𝔦𝔫 𝔴𝔥𝔬𝔪 𝔦𝔰 𝔴𝔬𝔯𝔱𝔥𝔶.
     */
    function setOrdained(
        address _address,
        bool _ordained
    ) external onlyOwner {
        if ( _address.code.length == 0 ) revert NotWorthyToOrdain();
        ordained[_address] = _ordained;
    }

    /**
     *  @dev 𝔖𝔢𝔢 𝔦𝔣 𝔰𝔲𝔟𝔧𝔢𝔠𝔱 𝔦𝔰 𝔬𝔯𝔡𝔞𝔦𝔫𝔢𝔡.
     */
    function isOrdained(
        address _address
    ) external view returns (bool) {
        return ordained[_address];
    }

}