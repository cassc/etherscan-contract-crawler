// SPDX-License-Identifier: MIT

// The random generator (DoctorV2) is programmed to linearly increase the odds of a diagnosis
// since the last time it was triggered; the speed with which the odds increase is calibrated
// to accumulate to the total desired probability over the 5-year period.
//
// However, only minted pieces can be diagnosed. Because the initial mint did not sell out,
// if we stopped diagnosis 5 years after project launch, a piece minted one year after launch
// would never be exposed to the full odds we are targeting.
//
// For this reason, we are now adding a registry that keeps track of the mint date. The new
// minting contracts will write these dates, for previously minted pieces, we set the date
// manually. Now that we know the date each piece was minted, a new random generator contract
// can ensure that diagnoses for a piece stop once the five year period has passed.
//
// This process is not entirely accurate. For example, if the randomness generator is "charged"
// with, say, 1-month's odds (i.e. it was last run 1 month ago), then in theory those odds
// should not apply to a token minted today. However, we don't feel it necessary to address this.
// The final odds don't have to be exact; in fact, it feels more true to the spirit of this
// project if the actual odds are *not* mathematically precise.

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "openzeppelin-solidity/contracts/utils/structs/EnumerableSet.sol";

contract MintDateRegistry {

    using EnumerableSet for EnumerableSet.AddressSet;

    address public owner;
    EnumerableSet.AddressSet writers;

    // The initial launch date; we use this as a fallback, and thus do not need to set any values
    // for tokens minted close to launch.
    // https://etherscan.io/tx/0x7426c36fccc7562eafa5e76f0709f9d51d08296f4b76754c5f99810d42dd25c6
    uint256 defaultMintDate = 1616634003;

    mapping(uint256 => uint256) public _mintDateByToken;

    constructor(){
        owner = msg.sender;
    }

    function getMintDateForToken(uint256 tokenId) public view returns (uint256) {
        uint256 date = _mintDateByToken[tokenId];
        if (date > 0) {
            return date;
        }
        return defaultMintDate;
    }

    function setMintDateForToken(uint256 tokenId, uint256 mintDate) public onlyWriter {
        _mintDateByToken[tokenId] = mintDate;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;
    }

    function addWriter(address writer) public onlyOwner {
        writers.add(writer);
    }

    function removeWriter(address writer) public onlyOwner {
        writers.remove(writer);
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "not owner");
        _;
    }

    modifier onlyWriter() {
        require(owner == msg.sender || writers.contains(msg.sender), "not writer");
        _;
    }
}