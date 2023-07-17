// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

/*****************************************************************************\
| ____        _             ____              _          _____                |
|| __ )  __ _| |__  _   _  | __ ) _   _ _ __ | |_ __ _  |  ___|_ _ _ __ ___   |
||  _ \ / _` | '_ \| | | | |  _ \| | | | '_ \| __/ _` | | |_ / _` | '_ ` _ \  |
|| |_) | (_| | |_) | |_| | | |_) | |_| | | | | || (_| | |  _| (_| | | | | | | |
||____/ \__,_|_.__/ \__, | |____/ \__,_|_| |_|\__\__,_| |_|  \__,_|_| |_| |_| |
|                    |___/                                                    |
\*****************************************************************************/
/// @notice Token URI Descriptor for BabyBuntaFam.

import "./IDescriptor.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "solady/src/utils/LibString.sol";

contract FamDescriptor is IDescriptor, Ownable {
    using LibString for uint256;

    string public baseURL =
        "";
    string public extension = "json";
    string public veilURL = "";
    mapping(address => bool) public receiver;
    bool public exclusiveProviding;
    bool public revealed;

    error InvalidReceiver();

    constructor() {
        receiver[msg.sender] = true;
        // revealed = true;
    }

    function setReceiver(address addr, bool value) external onlyOwner{
        receiver[addr] = value;
    }

    function setExclusiveProviding(bool value) external onlyOwner{
        exclusiveProviding = value;
    }

    function setBaseURL(string memory _newURL) external onlyOwner {
        baseURL = _newURL;
    }

    function setExtension(string memory _newValue) external onlyOwner {
        extension = _newValue;
    }

    function setVeilURL(string memory _newURL) external onlyOwner {
        veilURL = _newURL;
    }

    function setReveal(bool _value) external onlyOwner {
        revealed = _value;
    }

    function tokenURI(uint256 tokenId) external view override returns(string memory){
        if (exclusiveProviding){
            if (!receiver[msg.sender]) revert InvalidReceiver();
        }
        if (revealed) {
            return string.concat(
                baseURL,
                tokenId.toString(),
                ".",
                extension
            );
        } else {
            return veilURL;
        }
    }

}