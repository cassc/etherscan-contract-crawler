// contracts/BlockalizerGenerationV2.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract BlockalizerGenerationV2 is Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    uint256 public startTime;
    uint public mintPrice;
    uint256 public maxSupply;
    uint256 public expiryTime;
    uint16 public maxMintsPerWallet;

    constructor(
        uint _mintPrice,
        uint256 _maxSupply,
        uint256 _expiryTime,
        uint256 _startTime,
        uint16 _maxMintsPerWallet
    ) {
        mintPrice = _mintPrice;
        maxSupply = _maxSupply;
        expiryTime = _expiryTime;
        startTime = _startTime;
        maxMintsPerWallet = _maxMintsPerWallet;
    }

    function getTokenCount() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function incrementTokenCount(address owner) public onlyOwner {
        _balances[owner]++;
        _tokenIdCounter.increment();
    }

    function balanceOf(address owner) public view returns (uint256) {
        require(
            owner != address(0),
            "ERC721: address zero is not a valid owner"
        );
        return _balances[owner];
    }
}