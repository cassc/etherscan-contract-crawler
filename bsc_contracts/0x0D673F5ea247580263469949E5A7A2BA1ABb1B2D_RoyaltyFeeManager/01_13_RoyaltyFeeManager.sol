// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IERC165, IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";

import "./Errors.sol";
import {IRoyaltyFeeManager} from "./interfaces/IRoyaltyFeeManager.sol";
import {IRoyaltyFeeRegistry} from "./interfaces/IRoyaltyFeeRegistry.sol";
import {IRoyaltyFeeRegistryV2} from "./interfaces/IRoyaltyFeeRegistryV2.sol";
import {RoyaltyFeeTypes} from "./libraries/RoyaltyFeeTypes.sol";

/**
 * @title RoyaltyFeeManager
 * @notice Handles the logic to check and transfer royalty fees (if any).
 */
contract RoyaltyFeeManager is
    IRoyaltyFeeManager,
    Initializable,
    OwnableUpgradeable
{
    using RoyaltyFeeTypes for RoyaltyFeeTypes.FeeInfoPart;

    // https://eips.ethereum.org/EIPS/eip-2981
    bytes4 public constant INTERFACE_ID_ERC2981 = 0x2a55205a;

    IRoyaltyFeeRegistry public royaltyFeeRegistry;
    IRoyaltyFeeRegistryV2 public royaltyFeeRegistryV2;

    event RoyaltyFeeRegistryV2Initialized(
        address indexed newRoyaltyFeeRegistryV2
    );

    /**
     * @notice Initializer
     * @param _royaltyFeeRegistry address of the RoyaltyFeeRegistry
     * @param _royaltyFeeRegistryV2 address of the RoyaltyFeeRegistryV2
     */
    function initialize(
        address _royaltyFeeRegistry,
        address _royaltyFeeRegistryV2
    ) public initializer {
        __Ownable_init();

        royaltyFeeRegistry = IRoyaltyFeeRegistry(_royaltyFeeRegistry);
        _initializeRoyaltyFeeRegistryV2(_royaltyFeeRegistryV2);
    }

    /**
     * @notice Initialize `royaltyFeeRegistryV2` if not already set.
     * @dev We have this method because `royaltyFeeRegistryV2` was added
     * after the initial deploy of this contract.
     * @param _royaltyFeeRegistryV2 address of royalty fee registry V2
     */
    function initializeRoyaltyFeeRegistryV2(address _royaltyFeeRegistryV2)
        external
        onlyOwner
    {
        _initializeRoyaltyFeeRegistryV2(_royaltyFeeRegistryV2);
    }

    /**
     * @notice Initialize `royaltyFeeRegistryV2` if not already set.
     * @param _royaltyFeeRegistryV2 address of royalty fee registry V2
     */
    function _initializeRoyaltyFeeRegistryV2(address _royaltyFeeRegistryV2)
        internal
    {
        if (address(royaltyFeeRegistryV2) != address(0)) {
            revert RoyaltyFeeManager__RoyaltyFeeRegistryV2AlreadyInitialized();
        }
        if (_royaltyFeeRegistryV2 == address(0)) {
            revert RoyaltyFeeManager__InvalidRoyaltyFeeRegistryV2();
        }

        royaltyFeeRegistryV2 = IRoyaltyFeeRegistryV2(_royaltyFeeRegistryV2);

        emit RoyaltyFeeRegistryV2Initialized(_royaltyFeeRegistryV2);
    }

    /**
     * @notice Calculate royalty fee and get recipient
     * @param collection address of the NFT contract
     * @param tokenId tokenId
     * @param amount amount to transfer
     */
    function calculateRoyaltyFeeAndGetRecipient(
        address collection,
        uint256 tokenId,
        uint256 amount
    ) external view override returns (address, uint256) {
        return _calculateRoyaltyFeeAndGetRecipient(collection, tokenId, amount);
    }

    /**
     * @notice Calculate royalty fee amount parts
     * @param _collection address of the NFT contract
     * @param _tokenId tokenId
     * @param _amount amount to transfer
     */
    function calculateRoyaltyFeeAmountParts(
        address _collection,
        uint256 _tokenId,
        uint256 _amount
    ) external view override returns (RoyaltyFeeTypes.FeeAmountPart[] memory) {
        // If royaltyFeeRegistryV2 has been initialized, check to see if there is
        // royalty info set
        if (address(royaltyFeeRegistryV2) != address(0)) {
            RoyaltyFeeTypes.FeeAmountPart[]
                memory registryFeeAmountParts = royaltyFeeRegistryV2
                    .royaltyAmountParts(_collection, _amount);

            if (registryFeeAmountParts.length > 0) {
                return registryFeeAmountParts;
            }
        }

        // Otherwise, fallback to v1 royalty fee calculation
        (
            address receiver,
            uint256 royaltyAmount
        ) = _calculateRoyaltyFeeAndGetRecipient(_collection, _tokenId, _amount);

        if (receiver == address(0) || royaltyAmount == 0) {
            return new RoyaltyFeeTypes.FeeAmountPart[](0);
        }

        RoyaltyFeeTypes.FeeAmountPart[]
            memory feeAmountParts = new RoyaltyFeeTypes.FeeAmountPart[](1);
        feeAmountParts[0] = RoyaltyFeeTypes.FeeAmountPart({
            receiver: receiver,
            amount: royaltyAmount
        });
        return feeAmountParts;
    }

    /**
     * @notice Calculate royalty fee and get recipient
     * @param _collection address of the NFT contract
     * @param _tokenId tokenId
     * @param _amount amount to transfer
     */
    function _calculateRoyaltyFeeAndGetRecipient(
        address _collection,
        uint256 _tokenId,
        uint256 _amount
    ) internal view returns (address, uint256) {
        // 1. Check if there is a royalty info in the system
        (address receiver, uint256 royaltyAmount) = royaltyFeeRegistry
            .royaltyInfo(_collection, _amount);

        // 2. If the receiver is address(0), fee is null, check if it supports the ERC2981 interface
        if ((receiver == address(0)) || (royaltyAmount == 0)) {
            if (IERC165(_collection).supportsInterface(INTERFACE_ID_ERC2981)) {
                (receiver, royaltyAmount) = IERC2981(_collection).royaltyInfo(
                    _tokenId,
                    _amount
                );
            }
        }
        return (receiver, royaltyAmount);
    }
}