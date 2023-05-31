// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {AddressUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import {AppFacet} from "../../internals/AppFacet.sol";
import {BaseStorage} from "../../diamond/BaseStorage.sol";
import {ReferralFacetStorage} from "./ReferralFacetStorage.sol";

contract ReferralFacet is AppFacet {
    using AddressUpgradeable for address;

    event ReferralSale(
        address indexed referral,
        uint256 feeRate,
        uint256 feeAmount
    );

    modifier onlyValidReferral(address referral) {
        require(referral != address(0), "Invalid referral address");
        _;
    }

    function referralSetFeeRate(
        uint256 newFeeRate
    ) external onlyRolesOrOwner(BaseStorage.MANAGER_ROLE) {
        ReferralFacetStorage.layout()._referralFeeRate = newFeeRate;
    }

    function referralFeeRate() external view returns (uint256) {
        return ReferralFacetStorage.layout()._referralFeeRate;
    }

    function referralMintTo(
        address recipient,
        uint64 quantity,
        address referral
    ) external payable onlyValidReferral(referral) {
        uint256 originalBalance = address(this).balance;
        _callAppFunction(
            keccak256("drop"),
            abi.encodeWithSelector(
                bytes4(keccak256("mintTo(address,uint64)")),
                recipient,
                quantity
            )
        );

        _referralCommision(recipient, referral, originalBalance);
    }

    function referralPresaleMintTo(
        address recipient,
        uint64 quantity,
        uint256 allowed,
        bytes32[] calldata proof,
        address referral
    ) external payable onlyValidReferral(referral) {
        uint256 originalBalance = address(this).balance;
        _callAppFunction(
            keccak256("drop"),
            abi.encodeWithSelector(
                bytes4(
                    keccak256("presaleMintTo(address,uint64,uint256,bytes32[])")
                ),
                recipient,
                quantity,
                allowed,
                proof
            )
        );

        _referralCommision(recipient, referral, originalBalance);
    }

    function referralMintEdition(
        address recipient,
        uint256 editionId,
        uint256 quantity,
        bytes calldata signature,
        bytes32[] calldata proof,
        address referral
    ) external payable onlyValidReferral(referral) {
        uint256 originalBalance = address(this).balance;
        _callAppFunction(
            keccak256("edition"),
            abi.encodeWithSelector(
                bytes4(
                    keccak256(
                        "mintEdition(address,uint256,uint256,bytes,bytes32[])"
                    )
                ),
                recipient,
                editionId,
                quantity,
                signature,
                proof
            )
        );

        _referralCommision(recipient, referral, originalBalance);
    }

    function _referralCommision(
        address recipient,
        address referral,
        uint256 originalBalance
    ) internal {
        unchecked {
            uint256 feeRate = recipient == referral
                ? 0
                : ReferralFacetStorage.layout()._referralFeeRate;

            // feeAmount = (eth sent - (fees)) * feeRate
            uint256 feeAmount = ((msg.value -
                (originalBalance - address(this).balance)) * feeRate) / 10000;

            if (feeAmount > 0) {
                AddressUpgradeable.sendValue(payable(referral), feeAmount);
                emit ReferralSale(referral, feeRate, feeAmount);
            }
        }
    }
}