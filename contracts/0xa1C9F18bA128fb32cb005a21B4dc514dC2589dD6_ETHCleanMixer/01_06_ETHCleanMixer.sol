//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./CleanMixer.sol";

contract ETHCleanMixer is CleanMixer {
    constructor(
        IVerifier _verifier,
        IBlacklistControl _blacklistControl,
        ITwoLevelReferral _twoLevelReferral,
        uint256 _denomination,
        uint32 _merkleTreeHieght,
        Hasher _hasher
    ) CleanMixer(_verifier, _blacklistControl, _twoLevelReferral, _denomination, _merkleTreeHieght, _hasher) {}

    function _processDeposit(address _referrer) internal override {
        require(msg.value >= denomination, "Please send `mixDenomination` ETH along with transaction");
        _payReferral(msg.sender, _referrer, denomination);
    }

    function _payReferral(
        address _depositor,
        address _referrerAddress,
        uint256 _denomination
    ) internal {
        bool success = false;
        address rootOwner = owner();
        uint16 decimal = twoLevelReferral.getDecimal();
        uint8 rootOwnerPercentage0 = twoLevelReferral.getRootOwnerPercentage(0);
        uint8 rootOwnerPercentage1 = twoLevelReferral.getRootOwnerPercentage(1);
        uint8 rootOwnerPercentage2 = twoLevelReferral.getRootOwnerPercentage(2);

        if (_referrerAddress != address(0)) {
            // save depositor first
            twoLevelReferral.saveDepositor(_depositor, _referrerAddress);

            uint256 firstLevelPayAmount = twoLevelReferral.calculateFirstLevelPay(_denomination);

            // check second level
            address secondLevelRef = twoLevelReferral.getSecondLevel(_referrerAddress);

            if (secondLevelRef != address(0)) {
                // existing second level
                uint256 secLevelPayAmount = twoLevelReferral.calculateSecondLevelPay(_denomination);

                // Send 0.1% to the second level refferer if decimal is 1000
                (success, ) = secondLevelRef.call{value: secLevelPayAmount}("");
                require(success, "Transfer Failed");

                // Send 0.5% to firstLevel
                (success, ) = _referrerAddress.call{value: firstLevelPayAmount}("");
                require(success, "Transfer Failed");

                // Send 0.4% to the root owner if decimal is 1000
                (success, ) = rootOwner.call{value: (_denomination * rootOwnerPercentage0) / decimal}("");
                require(success, "Transfer Failed");
            } else {
                // no second level
                // Send 0.5% to firstLevel
                (success, ) = _referrerAddress.call{value: firstLevelPayAmount}("");
                require(success, "Transfer Failed");

                (success, ) = rootOwner.call{value: (_denomination * rootOwnerPercentage1) / decimal}("");
                require(success, "Transfer Failed");
            }
        } else {
            // send 1% direct to owner
            (success, ) = rootOwner.call{value: (_denomination * rootOwnerPercentage2) / decimal}("");
            require(success, "Transfer Failed");
        }
    }

    function _payGasToRelayer(uint256 _withdrawGasPrice) internal {
        bool success = false;
        (success, ) = msg.sender.call{value: _withdrawGasPrice}("");
        require(success, "_payGasToRelayer did not go thru");
    }

    function _processWithdraw(address payable _recipient, uint256 _relayGasFee) internal override {
        require(denomination != 0, "denomination must not be equal to zero");
        require(msg.value == 0, "msg.value is supposed to be zero for ETH instance");
        bool success = false;
        uint256 twoLvfee = (denomination * twoLevelReferral.getTotalFee()) / twoLevelReferral.getDecimal();

        (success, ) = _recipient.call{value: denomination - twoLvfee - _relayGasFee}("");
        if (_relayGasFee > 0) {
            //send gas to relayer
            _payGasToRelayer(_relayGasFee);
        }

        require(success, "_processWithdraw did not go thru");
    }
}