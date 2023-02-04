// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import './IDealPointsController.sol';
import './IDealsController.sol';
import './DealPointDataInternal.sol';

abstract contract DealPointsController is IDealPointsController {
    IDealsController immutable _dealsController;
    mapping(uint256 => DealPointDataInternal) internal _data;

    /*mapping(uint256 => uint256) internal _dealId;
    mapping(uint256 => address) internal _from;
    mapping(uint256 => address) internal _to;
    mapping(uint256 => uint256) internal _value;*/
    mapping(uint256 => uint256) internal _balances;
    mapping(uint256 => uint256) internal _fee;
    mapping(uint256 => bool) internal _isExecuted;
    mapping(uint256 => address) internal _tokenAddress;

    constructor(address dealsController_) {
        _dealsController = IDealsController(dealsController_);
    }

    receive() external payable {}

    modifier onlyDealsController() {
        require(
            address(_dealsController) == msg.sender,
            'only deals controller can call this function'
        );
        _;
    }

    modifier onlyFactory() {
        require(
            _dealsController.isFactory(msg.sender),
            'only factory can call this function'
        );
        _;
    }

    function isSwapped(uint256 pointId) external view returns (bool) {
        //return _dealsController.isSwapped(_dealId[pointId]);
        return _dealsController.isSwapped(_data[pointId].dealId);
    }

    function isExecuted(uint256 pointId) external view returns (bool) {
        return _isExecuted[pointId];
        //return _data[pointId].isExecuted;
    }

    function dealId(uint256 pointId) external view returns (uint256) {
        //return _dealId[pointId];
        return _data[pointId].dealId;
    }

    function from(uint256 pointId) external view returns (address) {
        //return _from[pointId];
        return _data[pointId].from;
    }

    function to(uint256 pointId) external view returns (address) {
        //return _to[pointId];
        return _data[pointId].to;
    }

    function setTo(uint256 pointId, address account)
        external
        onlyDealsController
    {
        require(
            //_to[pointId] == address(0),
            _data[pointId].to == address(0),
            'to can be setted only once for deal point'
        );
        //_to[pointId] = account;
        _data[pointId].to = account;
    }

    function tokenAddress(uint256 pointId) external view returns (address) {
        return _tokenAddress[pointId];
    }

    function value(uint256 pointId) external view returns (uint256) {
        //return _value[pointId];
        return _data[pointId].value;
    }

    function balance(uint256 pointId) external view returns (uint256) {
        return _balances[pointId];
        //return _data[pointId].balance;
    }

    function fee(uint256 pointId) external view returns (uint256) {
        return _fee[pointId];
        //return _data[pointId].fee;
    }

    function owner(uint256 pointId) external view returns (address) {
        //return this.isSwapped(pointId) ? this.to(pointId) : this.from(pointId);
        DealPointDataInternal memory point = _data[pointId];
        return this.isSwapped(pointId) ? point.to : point.from;
    }

    function dealsController() external view returns (address) {
        return address(_dealsController);
    }

    function withdraw(uint256 pointId) external payable onlyDealsController {
        address ownerAddr = this.owner(pointId);
        DealPointDataInternal memory point = _data[pointId];
        require(
            _balances[pointId] > 0,
            //point.balance > 0,
            'has no balance to withdraw'
        );
        require(
            address(_dealsController) == msg.sender || ownerAddr == msg.sender,
            'only owner or deals controller can withdraw'
        );
        if (ownerAddr == point.from) _isExecuted[pointId] = false;
        uint256 withdrawCount = _balances[pointId];
        _balances[pointId] = 0;
        require(withdrawCount > 0, 'not enough balance');
        _withdraw(pointId, ownerAddr, withdrawCount);
    }

    function execute(uint256 pointId, address addr)
        external
        payable
        onlyDealsController
    {
        DealPointDataInternal storage point = _data[pointId];
        if (_isExecuted[pointId]) return;
        //if (_from[pointId] == address(0)) _from[pointId] = addr;
        //if (point.isExecuted) return;
        if (point.from == address(0)) point.from = addr;
        _execute(pointId, addr);
        _isExecuted[pointId] = true;
        //point.isExecuted = true;
    }

    function _execute(uint256 pointId, address from) internal virtual;

    function _withdraw(
        uint256 pointId,
        address withdrawAddr,
        uint256 withdrawCount
    ) internal virtual;
}