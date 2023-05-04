// SPDX-License-Identifier: GPL-3.0
// presented by Wildxyz

pragma solidity ^0.8.17;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Base64 } from "@openzeppelin/contracts/utils/Base64.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { POAP } from "./POAP.sol";


contract SanctuaryAttendanceToken is POAP {

    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        uint256 _maxSupply, 
        string memory _baseURI,
        uint256 _maxPerAllowList,
        uint256 _startTime,
        uint256 _endTime
    ) POAP(tokenName,
            tokenSymbol,
            _maxSupply,
            _baseURI)
    {
        maxPerAllowList = _maxPerAllowList;
        startTime = _startTime;
        endTime = _endTime;
    }

    uint256 public maxPerAllowList; // max NFTs per allowlist address

    // minting start and end
    uint256 startTime;
    uint256 endTime;

    bool public mintingEnabled = true;

    modifier isMintingEnabled() {
        require(mintingEnabled, 'POAP: minting is not allowed.');
        _;
    }

    // allowlist stuff
    mapping(address => bool) public allowList; // address => true
    mapping(address => uint256) public allowListMinted; // address => num minted

    // public methods

    function setMintingEnabled(bool _mintingEnabled) public onlyOwner {
        mintingEnabled = _mintingEnabled;
    }

    function setMaxPerAllowlist(uint256 _maxPerAllowList) public onlyOwner {
        maxPerAllowList = _maxPerAllowList;
    }

    function setStartTime(uint256 _startTime) public onlyOwner {
        startTime = _startTime;
    }

    function setEndTime(uint256 _endTime) public onlyOwner {
        endTime = _endTime;
    }

    function addToAllowList(address[] memory _addresses) public onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            allowList[_addresses[i]] = true;
        }
    }

    // Public minting, only if on allowlist!
    function allowListMint() public isMintingEnabled returns (uint256) {
        require(block.timestamp < endTime, 'PAOP: Minting time has ended.');
        require(block.timestamp > startTime, 'POAP: Minting time has not started.');

        require(_currentTokenId < maxSupply, "POAP: Max supply reached.");

        address receiver = msg.sender;

        require(allowList[receiver], "POAP: Address not in allowlist");
        require(allowListMinted[receiver] < maxPerAllowList, "POAP: Max per allowlist reached.");

        allowListMinted[receiver]++;

        return _mintTo(receiver, _currentTokenId++);
    }

    // only owner

    function promoMint(address _to) public onlyOwner returns (uint256) {
        require(_currentTokenId < maxSupply, "POAP: Max supply reached");

        return _mintTo(_to, _currentTokenId++);
    }

    // uri getter

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
        {
            require(_exists(_tokenId), "Token does not exist.");
            return baseURI; // All tokens are the same, so lets just reuse the baseURI for all.
        }
}