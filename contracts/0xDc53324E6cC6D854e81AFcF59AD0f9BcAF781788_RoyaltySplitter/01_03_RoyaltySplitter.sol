// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract RoyaltySplitter is Initializable {
    address payable public artist;
    address payable public twoFiveSix;
    uint256 public artistShare;

    function initRoyaltySplitter(
        address payable _artist,
        address payable _twoFiveSix,
        uint256 _artistShare
    ) public initializer {
        artist = _artist;
        twoFiveSix = _twoFiveSix;
        artistShare = _artistShare;
    }

    function withdraw() public {
        require(
            (msg.sender == twoFiveSix || msg.sender == artist),
            "Not allowed"
        );
        uint256 balance = address(this).balance;

        twoFiveSix.transfer((balance / 10000) * (10000 - artistShare));
        artist.transfer((balance / 10000) * artistShare);
    }

    receive() external payable {}
}