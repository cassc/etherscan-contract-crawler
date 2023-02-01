// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import "./libraries/Ownable.sol";

contract HedgepieAdapterInfoEth is Ownable {
    struct AdapterInfo {
        uint256 tvl;
        uint256 participant;
        uint256 traded;
        uint256 profit;
    }

    // nftId => AdapterInfo
    mapping(uint256 => AdapterInfo) public adapterInfo;

    // nftId => participant's address existing
    mapping(uint256 => mapping(address => bool)) public participants;

    // AdapterInfoEth managers mapping
    mapping(address => bool) public managers;

    /////////////////
    /// Modifiers ///
    /////////////////

    modifier isManager() {
        require(managers[msg.sender], "Invalid manager address");
        _;
    }

    ////////////////
    //// Events ////
    ////////////////

    event AdapterInfoUpdated(
        uint256 indexed tokenId,
        uint256 participant,
        uint256 traded,
        uint256 profit
    );
    event ManagerAdded(address manager);
    event ManagerRemoved(address manager);

    /////////////////////////
    /// Manager Functions ///
    /////////////////////////

    function updateTVLInfo(
        uint256 _tokenId,
        uint256 _value,
        bool _adding
    ) external isManager {
        adapterInfo[_tokenId].tvl = _adding
            ? adapterInfo[_tokenId].tvl + _value
            : adapterInfo[_tokenId].tvl - _value;
        _emitEvent(_tokenId);
    }

    function updateTradedInfo(
        uint256 _tokenId,
        uint256 _value,
        bool _adding
    ) external isManager {
        adapterInfo[_tokenId].traded = _adding
            ? adapterInfo[_tokenId].traded + _value
            : adapterInfo[_tokenId].traded - _value;
        _emitEvent(_tokenId);
    }

    function updateProfitInfo(
        uint256 _tokenId,
        uint256 _value,
        bool _adding
    ) external isManager {
        adapterInfo[_tokenId].profit = _adding
            ? adapterInfo[_tokenId].profit + _value
            : adapterInfo[_tokenId].profit - _value;
        _emitEvent(_tokenId);
    }

    function updateParticipantInfo(
        uint256 _tokenId,
        address _account,
        bool _adding
    ) external isManager {
        bool isExisted = participants[_tokenId][_account];

        if (_adding) {
            adapterInfo[_tokenId].participant = isExisted
                ? adapterInfo[_tokenId].participant
                : adapterInfo[_tokenId].participant + 1;

            if (!isExisted) participants[_tokenId][_account] = true;
        } else {
            adapterInfo[_tokenId].participant = isExisted
                ? adapterInfo[_tokenId].participant - 1
                : adapterInfo[_tokenId].participant;
            delete participants[_tokenId][_account];
            if (isExisted) participants[_tokenId][_account] = false;
        }

        if ((_adding && !isExisted) || (!_adding && isExisted))
            _emitEvent(_tokenId);
    }

    /////////////////////////
    //// Owner Functions ////
    /////////////////////////

    function setManager(address _adapter, bool _value) external onlyOwner {
        if (_value) emit ManagerAdded(_adapter);
        else emit ManagerRemoved(_adapter);

        managers[_adapter] = _value;
    }

    /////////////////////////
    /// Internal Functions //
    /////////////////////////

    function _emitEvent(uint256 _tokenId) internal {
        emit AdapterInfoUpdated(
            _tokenId,
            adapterInfo[_tokenId].participant,
            adapterInfo[_tokenId].traded,
            adapterInfo[_tokenId].profit
        );
    }
}