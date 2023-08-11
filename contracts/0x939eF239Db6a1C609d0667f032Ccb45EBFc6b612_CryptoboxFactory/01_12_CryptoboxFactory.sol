// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Currency} from "./lib/Currency.sol";
import {ICryptoboxFactory} from "./ICryptoboxFactory.sol";
import {ICryptobox} from "./ICryptobox.sol";
import {Cryptobox} from "./Cryptobox.sol";

contract CryptoboxFactory is Ownable, ICryptoboxFactory {
    using Currency for address;

    address private _feeToken;
    address private _feeDestination;
    uint256 private _participantFee;
    uint256 private _creationFee;
    uint32 private _minCapacity = 1;
    bool private _enabled = true;

    constructor() {
        _feeDestination = _msgSender();
    }

    function getFeeToken() external view override returns (address) {
        return _feeToken;
    }

    function setFeeToken(address token) external override onlyOwner {
        require(token != _feeToken);
        _feeToken = token;
        emit RulesChanged();
    }

    function getFeeDestination() external view override returns (address) {
        return _feeDestination;
    }

    function setFeeDestination(
        address destination
    ) external override onlyOwner {
        require(destination != address(0));
        require(destination != _feeDestination);
        _feeDestination = destination;
    }

    function getParticipantFee() external view override returns (uint256) {
        return _participantFee;
    }

    function setParticipantFee(uint256 fee) external override onlyOwner {
        require(fee != _participantFee);
        _participantFee = fee;
        emit RulesChanged();
    }

    function getCreationFee() external view override returns (uint256) {
        return _creationFee;
    }

    function setCreationFee(uint256 fee) external override onlyOwner {
        require(fee != _creationFee);
        _creationFee = fee;
        emit RulesChanged();
    }

    function getMinimalCapacity() external view override returns (uint32) {
        return _minCapacity;
    }

    function setMinimalCapacity(uint32 capacity) external override onlyOwner {
        require(capacity > 0);
        require(capacity != _minCapacity);
        _minCapacity = capacity;
        emit RulesChanged();
    }

    function isEnabled() external view override returns (bool) {
        return _enabled;
    }

    function enable() external override onlyOwner {
        require(!_enabled);
        _enabled = true;
        emit RulesChanged();
    }

    function disable() external override onlyOwner {
        require(_enabled);
        _enabled = false;
        emit RulesChanged();
    }

    function create(
        ICryptobox.Info memory blueprint,
        address signer
    ) external payable {
        _requireCanCreate(blueprint);
        Cryptobox cryptobox = _spawn(blueprint, signer);
        _collectFeesFor(blueprint);
        _fund(cryptobox);
    }

    function _requireCanCreate(ICryptobox.Info memory blueprint) private view {
        if (!_enabled) revert FactoryIsDisabled();
        if (blueprint.capacity < _minCapacity) revert NotEnoughParticipants();
    }

    function _collectFeesFor(ICryptobox.Info memory blueprint) private {
        uint256 fee = _creationFee + _participantFee * blueprint.capacity;
        _feeToken.take(_msgSender(), _feeDestination, fee);
    }

    function _spawn(
        ICryptobox.Info memory blueprint,
        address signer
    ) private returns (Cryptobox) {
        Cryptobox box = new Cryptobox(blueprint, signer, _msgSender());
        emit CryptoboxCreated(address(box));
        return box;
    }

    function _fund(Cryptobox box) private {
        ICryptobox.Info memory info = box.info();
        uint256 fund = info.capacity * info.prize;
        info.token.take(_msgSender(), address(box), fund);
        uint256 balance = info.token.balanceOf(address(box));
        if (balance < fund) revert CryptoboxFundingFailed();
    }

    function version() external pure returns (uint8) {
        return 1;
    }
}