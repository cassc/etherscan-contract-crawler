//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "./interfaces/IEIP712.sol";
import "./interfaces/IManagement.sol";
import "./interfaces/IFactory.sol";
import "./interfaces/IProperty.sol";

contract EIP712 is IEIP712, EIP712Upgradeable, OwnableUpgradeable {
    using ECDSAUpgradeable for bytes32;

    // keccak256("CancellationPolicy(uint256 expireAt,uint256 refundAmount)");
    bytes32 private constant CANCELLATION_POLICY_TYPEHASH =
        0x71ed7adc2b3cc6f42e80ad08652651cbc6e0fd93b50d04298efafcfb6570f246;
    // keccak256("InsuranceInfo(uint256 damageProtectionFee,address feeReceiver,uint8 kygStatus)");
    bytes32 private constant INSURANCE_INFO_TYPEHASH =
        0x3611ae94f04e593c59ae6804f59fcfee09118c73acf88c4171954c856bb438c1;
    // keccak256("Msg(uint256 bookingId,uint256 checkIn,uint256 checkOut,uint256 expireAt,uint256 bookingAmount,address paymentToken,address referrer,address guest,address property,InsuranceInfo insuranceInfo,CancellationPolicy[] policies)CancellationPolicy(uint256 expireAt,uint256 refundAmount)InsuranceInfo(uint256 damageProtectionFee,address feeReceiver,uint8 kygStatus)");
    bytes32 private constant BOOKING_SETTING_TYPEHASH =
        0x3afc33b10506e02b8adfec843d933fc9d1536b6f83590c6e51ff6c27595733f7;

    IManagement public management;

    function init(address _management) external initializer {
        __Ownable_init();
        __EIP712_init("DtravelBooking", "1");

        management = IManagement(_management);
    }

    /**
        @notice Verify typed ethereum message for booking using EIP712
        @dev Caller must be property contract
        @param _propertyId property id
        @param _setting    booking setting
        @param _signature  signed message following EIP712
     */
    function verify(
        uint256 _propertyId,
        IProperty.BookingSetting calldata _setting,
        bytes calldata _signature
    ) external {
        address msgSender = _msgSender();
        require(
            msgSender == IFactory(management.factory()).property(_propertyId),
            "UnknownProperty"
        );

        uint256 n = _setting.policies.length;
        bytes32[] memory policiesHashes = new bytes32[](n);
        for (uint256 i; i < n; i++) {
            policiesHashes[i] = keccak256(
                abi.encode(
                    CANCELLATION_POLICY_TYPEHASH,
                    _setting.policies[i].expireAt,
                    _setting.policies[i].refundAmount
                )
            );
        }
        bytes32 insuranceInfoHash = keccak256(
            abi.encode(
                INSURANCE_INFO_TYPEHASH,
                _setting.insuranceInfo.damageProtectionFee,
                _setting.insuranceInfo.feeReceiver,
                uint8(_setting.insuranceInfo.kygStatus)
            )
        );
        {
            address signer = _hashTypedDataV4(
                keccak256(
                    bytes.concat(
                        abi.encode(
                            BOOKING_SETTING_TYPEHASH,
                            _setting.bookingId,
                            _setting.checkIn,
                            _setting.checkOut,
                            _setting.expireAt,
                            _setting.bookingAmount
                        ),
                        abi.encode(
                            _setting.paymentToken,
                            _setting.referrer,
                            _setting.guest,
                            msgSender,
                            insuranceInfoHash,
                            keccak256(abi.encodePacked(policiesHashes))
                        )
                    )
                )
            ).recover(_signature);
            require(signer == management.verifier(), "InvalidSignature");
        }
    }
}