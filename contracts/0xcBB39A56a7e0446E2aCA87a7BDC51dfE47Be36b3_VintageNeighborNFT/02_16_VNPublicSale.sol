// SPDX-License-Identifier: Copyright

pragma solidity ^0.8.7;

import "./VNWhitelist.sol";

abstract contract VNPublicSale is VNWhitelist {
    uint256 private _startTime;
    uint256 private _publicSalePrice;

    event publicSaleInited(
        uint256 indexed startTime,
        uint256 indexed publicSalePrice
    );

    function initPublicSale(uint256 startTime, uint256 publicSalePrice)
        external
        onlyOwner
    {
        _startTime = startTime;
        _publicSalePrice = publicSalePrice;

        emit publicSaleInited(_startTime, _publicSalePrice);
    }

    function getPublicSaleStartTime() public view returns (uint256) {
        return _startTime;
    }

    function getPublicSalePrice() public view returns (uint256) {
        return _publicSalePrice;
    }

    function publicSaleStarted() public view returns (bool) {
        return _startTime != 0 && block.timestamp > _startTime;
    }
}