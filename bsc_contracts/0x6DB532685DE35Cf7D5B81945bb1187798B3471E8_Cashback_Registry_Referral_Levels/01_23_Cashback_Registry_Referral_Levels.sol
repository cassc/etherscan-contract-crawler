// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.4;

import "./Cashback_Registry.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Cashback_Registry_Referral_Levels is Ownable {
    Cashback_Registry CBR =
        Cashback_Registry(0xe32a6BF04d6Aaf34F3c29af991a6584C5D8faB5C);

    constructor() Ownable() {}

    function getSignerReferredAccountLevels(
        address _signer,
        uint256 _start,
        uint256 _count
    )
        external
        view
        returns (
            uint64[] memory accountIds_,
            Cashback_Registry.LEVEL[] memory levels_,
            bool[] memory canRecaptures_
        )
    {
        levels_ = new Cashback_Registry.LEVEL[](_count);
        canRecaptures_ = new bool[](_count);
        uint64 signerAccountId = CBR.signerToAccountId(_signer);
        (
            Cashback_Registry.LEVEL signerLevel,
            ,
            uint64[6] memory signerLevelNodeIds,
            ,
            ,
            ,
            ,

        ) = CBR.getAccountInfo(signerAccountId);
        accountIds_ = CBR.getAccountReferrals(signerAccountId, _start, _count);
        for (uint256 i = 0; i < _count; i++) {
            (
                Cashback_Registry.LEVEL level,
                ,
                uint64[6] memory accountLevelNodeIds,
                ,
                ,
                ,
                ,

            ) = CBR.getAccountInfo(accountIds_[i]);
            levels_[i] = level;
            if (level >= signerLevel || uint8(level) == 5) {
                canRecaptures_[i] = false;
            } else {
                (, , uint64 accountParentId) = CBR.getNodeInfo(
                    accountLevelNodeIds[uint256(level)]
                );
                canRecaptures_[i] =
                    signerLevelNodeIds[uint256(level) - 1] != accountParentId;
            }
        }
    }

    function setCbr(Cashback_Registry _to) external onlyOwner {
        CBR = _to;
    }
}