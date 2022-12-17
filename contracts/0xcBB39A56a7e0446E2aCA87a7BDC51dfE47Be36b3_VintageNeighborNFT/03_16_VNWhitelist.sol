// SPDX-License-Identifier: Copyright

pragma solidity ^0.8.7;

import "./VNAdmin.sol";

abstract contract VNWhitelist is VNAdmin {
    enum WhiteListState {
        NOT_IN_LIST, // 0
        WHITELISTED, // 1
        PURCHASED // 2
    }

    mapping(address => WhiteListState) private _whitelist;
    uint256 private _whiteListPrice;
    uint256 private _whiteListStartTime;
    uint256 private _whiteListEndTime;

    event whiteListPriceSet(
        uint256 indexed price,
        uint256 indexed startTime,
        uint256 indexed endTime
    );

    function addToWhiteList(address[] calldata addresses) external onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            _whitelist[addresses[i]] = WhiteListState.WHITELISTED;
        }
    }

    function removeFromWhiteList(address[] calldata addresses)
        external
        onlyOwner
    {
        for (uint i = 0; i < addresses.length; i++) {
            _whitelist[addresses[i]] = WhiteListState.NOT_IN_LIST;
        }
    }

    function initWhiteList(
        uint256 whiteListPrice,
        uint256 startTime,
        uint256 endTime
    ) external onlyOwner {
        _whiteListPrice = whiteListPrice;
        _whiteListStartTime = startTime;
        _whiteListEndTime = endTime;

        emit whiteListPriceSet(
            _whiteListPrice,
            _whiteListStartTime,
            _whiteListEndTime
        );
    }

    function setWhiteListPurchased(address addr) internal {
        require(_whitelist[addr] == WhiteListState.WHITELISTED, "wrong state");
        _whitelist[addr] = WhiteListState.PURCHASED;
    }

    function isWhiteListActive() public view returns (bool) {
        if (_whiteListPrice == 0) {
            return false;
        } else {
            return
                block.timestamp >= _whiteListStartTime &&
                block.timestamp <= _whiteListEndTime;
        }
    }

    function getWhiteListState(address addr)
        public
        view
        returns (WhiteListState)
    {
        return _whitelist[addr];
    }

    function getWhiteListPrice() public view returns (uint256) {
        return _whiteListPrice;
    }

    function getWhiteListStartTime() public view returns (uint256) {
        return _whiteListStartTime;
    }

    function getWhiteListEndTime() public view returns (uint256) {
        return _whiteListEndTime;
    }
}