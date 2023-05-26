// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "../../dependencies/governance/Multisig.sol";
import "../../interfaces/IPhiatMultisigTreasury.sol";
import "./PhiatFeeDistribution.sol";
import "./PhiatToken.sol";

contract PhiatMultisigTreasury is Multisig, IPhiatMultisigTreasury {
    address public phiatFeeDistribution;

    constructor(
        address[] memory _owners,
        uint256 _required,
        address _phiatFeeDistribution
    ) Multisig(_owners, _required) {
        require(
            _phiatFeeDistribution != address(0),
            "Phiat fee distribution can not be zero address"
        );
        phiatFeeDistribution = _phiatFeeDistribution;
    }

    function mintPhiat() external override ownerExists(msg.sender) {
        PhiatToken phiat = PhiatToken(
            address(PhiatFeeDistribution(phiatFeeDistribution).stakingToken())
        );
        phiat.mint();
    }

    function mintPhiatByTreasury(address account)
        external
        override
        ownerExists(msg.sender)
    {
        PhiatToken phiat = PhiatToken(
            address(PhiatFeeDistribution(phiatFeeDistribution).stakingToken())
        );
        phiat.mintByTreasury(account);
    }

    function getReward() external override ownerExists(msg.sender) {
        PhiatFeeDistribution(phiatFeeDistribution).getReward();
    }

    function setPhiatFeeDistribution(address _phiatFeeDistribution)
        external
        onlyWallet
    {
        require(
            _phiatFeeDistribution != address(0),
            "Phiat fee distribution can not be zero address"
        );
        phiatFeeDistribution = _phiatFeeDistribution;
    }
}