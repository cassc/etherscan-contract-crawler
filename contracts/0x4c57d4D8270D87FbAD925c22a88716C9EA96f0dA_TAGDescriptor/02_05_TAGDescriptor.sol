// SPDX-License-Identifier: UNLICENSED
/*
  _____     _                     _    _ _                        _   _              ____ _      _     
 |_   _|__ | | ___   _  ___      / \  | | |_ ___ _ __ _ __   __ _| |_(_)_   _____   / ___(_)_ __| |___ 
   | |/ _ \| |/ / | | |/ _ \    / _ \ | | __/ _ \ '__| '_ \ / _` | __| \ \ / / _ \ | |  _| | '__| / __|
   | | (_) |   <| |_| | (_) |  / ___ \| | ||  __/ |  | | | | (_| | |_| |\ V /  __/ | |_| | | |  | \__ \
   |_|\___/|_|\_\\__, |\___/  /_/   \_\_|\__\___|_|  |_| |_|\__,_|\__|_| \_/ \___|  \____|_|_|  |_|___/
                 |___/                                                                                 

*/
pragma solidity ^0.8.17;

/// @notice Token URI Descriptor for TAG.

import "./IDescriptor.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "solady/src/utils/LibString.sol";

contract TAGDescriptor is IDescriptor, Ownable {
    using LibString for uint256;

    string public baseURL =
        "https://nanataku.net/json/";
    string public extension = "json";
    string public veilURL = "https://arweave.net/eEJIrRN8Ob5YLPzkX6i0nQ1zvOKu8JFdySckKIaLQk8";
    mapping(address => bool) public receiver;
    bool public exclusiveProviding;
    bool public revealed;

    error InvalidReceiver();

    constructor() {
        //revealed = true;
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