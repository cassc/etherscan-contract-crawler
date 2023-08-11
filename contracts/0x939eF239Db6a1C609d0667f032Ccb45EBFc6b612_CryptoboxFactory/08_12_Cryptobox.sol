// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ICryptobox} from "./ICryptobox.sol";
import {Participation} from "./lib/Participation.sol";
import {Currency} from "./lib/Currency.sol";
import {EternalOwnable} from "./access/EternalOwnable.sol";

contract Cryptobox is ICryptobox, EternalOwnable {
    using Currency for address;

    uint32 private immutable _capacity;
    uint32 private _totalParticipated;
    bool private _active = true;
    address private immutable _signer;
    address private immutable _token;
    mapping(bytes32 => bool) private _participatedNames;
    mapping(address => bool) private _participatedAddresses;
    uint256 private immutable _prize;

    constructor(
        ICryptobox.Info memory blueprint,
        address signer,
        address owner
    ) EternalOwnable(owner) {
        require(signer != address(0));
        _token = blueprint.token;
        _prize = blueprint.prize;
        _capacity = blueprint.capacity;
        _signer = signer;
    }

    function info() external view override returns (ICryptobox.Info memory) {
        return ICryptobox.Info(_token, _capacity, _prize);
    }

    function isActive() external view override returns (bool) {
        return _active;
    }

    function participants() external view override returns (uint32) {
        return _totalParticipated;
    }

    function dispense(
        Participation.Participant memory candidate,
        Participation.Signature memory sig
    ) external override {
        require(_active);
        Participation.requireSigned(candidate, sig, address(this), _signer);
        _reward(candidate);
    }

    function dispenseMany(
        Participation.Participant[] memory candidates,
        Participation.Signature memory sig
    ) external override {
        require(candidates.length <= _candidatesLeft());
        require(_active);
        Participation.requireSigned(candidates, sig, address(this), _signer);
        _reward(candidates);
    }

    function stop() external onlyOwner {
        require(_active);
        _stop();
        _refund();
    }

    function participated(
        Participation.Participant memory participant
    ) external view override returns (bool) {
        return _participated(participant);
    }

    function _participated(
        Participation.Participant memory participant
    ) internal view returns (bool) {
        bool isAddressParticipated = _participatedAddresses[participant.addr];
        bool isNameParticipated = _participatedNames[participant.name];
        return isAddressParticipated || isNameParticipated;
    }

    function _reward(Participation.Participant memory candidate) private {
        _totalParticipated += 1;
        _tryToParticipate(candidate);
        if (_totalParticipated == _capacity) _finish();
        _token.transfer(candidate.addr, _prize);
    }

    function _reward(Participation.Participant[] memory candidates) private {
        _totalParticipated += uint32(candidates.length);
        if (_totalParticipated == _capacity) _finish();
        for (uint i = 0; i < candidates.length; i++)
            _tryToParticipate(candidates[i]);
        for (uint i = 0; i < candidates.length; i++)
            _token.transfer(candidates[i].addr, _prize);
    }

    function _tryToParticipate(
        Participation.Participant memory candidate
    ) private {
        require(!_participated(candidate));
        _participatedAddresses[candidate.addr] = true;
        _participatedNames[candidate.name] = true;
    }

    function _refund() private {
        _token.transfer(_owner(), _token.balanceOf(address(this)));
    }

    function _finish() private {
        _active = false;
        emit CryptoboxFinished();
    }

    function _stop() private {
        _active = false;
        emit CryptoboxStopped();
    }

    receive() external payable {
        require(_token == Currency.NATIVE);
        require(_active);
        require(address(this).balance == _tokensNeeded());
    }

    function _tokensNeeded() private view returns (uint256) {
        return _prize * _candidatesLeft();
    }

    function _candidatesLeft() private view returns (uint32) {
        return _capacity - _totalParticipated;
    }

    function version() external pure returns (uint8) {
        return 1;
    }
}