// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";

abstract contract RobotokenNftSale is ERC721 {
    // Airdrop
    uint256 public airdropStartTime = 1645358400; // TODO
    uint256 public constant airdropMintsTotalLimit = 100; // TODO
    uint256 public airdropMintsTotal;
    mapping(address => bool) public airdropWhitelist;
    mapping(address => uint256) public airdropMints;

    // Presale
    uint256 public presalePrice = 0.1 ether; // TODO
    uint256 public presaleStartTime = 1645444800; // TODO
    mapping(address => bool) public presaleWhitelist;

    // Sale
    uint256 public salePrice = 0.12 ether; // TODO
    uint256 public saleStartTime = 1645531200; // TODO

    // common functions
    function _greater(uint256 currentMints, uint256 totalMintsLimit)
        private
        pure
        returns (bool)
    {
        return (totalMintsLimit > 0 ? currentMints > totalMintsLimit : false);
    }

    function _low(uint256 currentMints, uint256 totalMintsLimit)
        private
        pure
        returns (bool)
    {
        return (totalMintsLimit > 0 ? currentMints < totalMintsLimit : true);
    }

    function _isActive(
        uint256 currentMints,
        uint256 totalMintsLimit,
        uint256 startTime,
        uint256 endTime
    ) private view returns (bool) {
        return
            _low(currentMints, totalMintsLimit) &&
            block.timestamp >= startTime &&
            block.timestamp < endTime;
    }

    // Airdrop
    function _makeAirdropStats(address account) internal {
        airdropMints[account]++;
        airdropMintsTotal++;
    }

    function isAirdropActive() public view returns (bool) {
        return
            _isActive(
                airdropMintsTotal,
                airdropMintsTotalLimit,
                airdropStartTime,
                presaleStartTime
            );
    }

    function isAirdropLimit(address account) public view returns (bool) {
        return
            _greater(airdropMints[account] + 1, 1) ||
            _greater(airdropMintsTotal + 1, airdropMintsTotalLimit);
    }

    function setAirdropStartTime(uint256 newTime) external onlyOwner {
        airdropStartTime = newTime;
    }

    function addToAirdropWhitelist(address[] calldata accounts)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < accounts.length; i++) {
            airdropWhitelist[accounts[i]] = true;
        }
    }

    // Presale
    function isPresaleActive() public view returns (bool) {
        return
            _isActive(
                totalSupply(),
                MAX_SUPPLY,
                presaleStartTime,
                saleStartTime
            );
    }

    function setPresalePrice(uint256 newPrice) external onlyOwner {
        presalePrice = newPrice;
    }

    function setPresaleStartTime(uint256 newTime) external onlyOwner {
        presaleStartTime = newTime;
    }

    function addToPresaleWhitelist(address[] calldata accounts)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < accounts.length; i++) {
            presaleWhitelist[accounts[i]] = true;
        }
    }

    // Sale
    function isSaleActive() public view returns (bool) {
        return _isActive(totalSupply(), MAX_SUPPLY, saleStartTime, ~uint256(0));
    }

    function isSaleLimit(uint256 count) public view returns (bool) {
        return _greater(totalSupply() + count, MAX_SUPPLY);
    }

    function setSalePrice(uint256 newPrice) external onlyOwner {
        salePrice = newPrice;
    }

    function setSaleStartTime(uint256 newTime) external onlyOwner {
        saleStartTime = newTime;
    }
}