// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IAnomuraErrors {
    error InvalidRecipient();
    error InvalidTokenIds();
    error InvalidOwner();
    error InvalidItemType();
    error InvalidString();
    error InvalidLength();
    error InvalidValue();
    error InvalidEquipmentAddress();
    error InvalidCollectionType();
    error IsPaused();
}