// SPDX-License-Identifier: Apache-2.0

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                           //
//                      _'                    AAA                                                                                            //
//                    !jz_                   A:::A                                                                                           //
//                 ;Lzzzz-                  A:::::A                                                                                          //
//              '1zzzzxzz'                 A:::::::A                                                                                         //
//            !xzzzzzzi~                  A:::::::::A             ssssssssss   ppppp   ppppppppp       eeeeeeeeeeee    nnnn  nnnnnnnn        //
//         ;izzzzzzj^`                   A:::::A:::::A          ss::::::::::s  p::::ppp:::::::::p    ee::::::::::::ee  n:::nn::::::::nn      //
//              `;^.`````               A:::::A A:::::A       ss:::::::::::::s p:::::::::::::::::p  e::::::eeeee:::::een::::::::::::::nn     //
//              -;;;;;;;-              A:::::A   A:::::A      s::::::ssss:::::spp::::::ppppp::::::pe::::::e     e:::::enn:::::::::::::::n    //
//           .;;;;;;;_                A:::::A     A:::::A      s:::::s  ssssss  p:::::p     p:::::pe:::::::eeeee::::::e  n:::::nnnn:::::n    //
//         ;;;;;;;;`                 A:::::AAAAAAAAA:::::A       s::::::s       p:::::p     p:::::pe:::::::::::::::::e   n::::n    n::::n    //
//      _;;;;;;;'                   A:::::::::::::::::::::A         s::::::s    p:::::p     p:::::pe::::::eeeeeeeeeee    n::::n    n::::n    //
//            ;{jjjjjjjjj          A:::::AAAAAAAAAAAAA:::::A  ssssss   s:::::s  p:::::p    p::::::pe:::::::e             n::::n    n::::n    //
//         `+IIIVVVVVVVVI`        A:::::A             A:::::A s:::::ssss::::::s p:::::ppppp:::::::pe::::::::e            n::::n    n::::n    //
//       ^sIVVVVVVVVVVVVI`       A:::::A               A:::::As::::::::::::::s  p::::::::::::::::p  e::::::::eeeeeeee    n::::n    n::::n    //
//    ~xIIIVVVVVVVVVVVVVI`      A:::::A                 A:::::As:::::::::::ss   p::::::::::::::pp    ee:::::::::::::e    n::::n    n::::n    //
//  -~~~;;;;;;;;;;;;;;;;;      AAAAAAA                   AAAAAAAsssssssssss     p::::::pppppppp        eeeeeeeeeeeeee    nnnnnn    nnnnnn    //
//                                                                              p:::::p                                                      //
//                                                                              p:::::p                                                      //
//                                                                             p:::::::p                                                     //
//                                                                             p:::::::p                                                     //
//                                                                             p:::::::p                                                     //
//                                                                             ppppppppp                                                     //
//                                                                                                                                           //
//  Website: https://aspenft.io/                                                                                                             //
//  Twitter: https://twitter.com/aspenft                                                                                                     //
//                                                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.8;

import "../../api/config/ITieredPricing.sol";
import "../../api/errors/ICoreErrors.sol";

/// @title BaseTieredPricing
/// @notice Handles tha fees for the platform.
///         It allows the update and retrieval of platform feeBPS and receiver address
contract BaseTieredPricing is ITieredPricingEventsV0, ITieredPricingGettersV0, ITieredPricingEventsV1 {
    /// @dev Max basis points (bps) in Aspen platform.
    uint256 public constant MAX_BPS = 10_000;
    /// @dev Max percentage fee (bps) allowed
    uint256 public constant MAX_PERCENTAGE_FEE = 7500;
    /// @dev Receiver address for the platform fees
    address private __platformFeeReceiver;

    bytes32 private constant DEPLOYMENT_FEES_NAMESPACE = bytes32(abi.encodePacked("DEPLOYMENT_FEES"));
    bytes32 private constant CLAIM_FEES_NAMESPACE = bytes32(abi.encodePacked("CLAIM_FEES"));
    bytes32 private constant COLLECTOR_FEES_NAMESPACE = bytes32(abi.encodePacked("COLLECTOR_FEES"));

    /// @dev Namespace => Tier identifier
    mapping(bytes32 => bytes32[]) private _tierIds;
    /// @dev Namespace => Tier identifier => Tier price (BPS or Flat Amount)
    mapping(bytes32 => mapping(bytes32 => ITieredPricingDataTypesV0.Tier)) private _tiers;
    /// @dev Namespace => address => Tier identifier
    mapping(bytes32 => mapping(address => bytes32)) private _addressToTier;
    /// @dev Namespace => Tier identifier
    mapping(bytes32 => bytes32) private _defaultTier;

    /// ======================================
    /// ========== Getter functions ==========
    /// ======================================
    /// @dev Returns the platform fee receiver address
    function getPlatformFeeReceiver() public view returns (address) {
        return __platformFeeReceiver;
    }

    /// @dev Returns all the tiers for a namespace
    /// @param _namespace - namespace for which tiers are requested
    /// @return tierIds - an array with all the tierIds for a namespace
    /// @return tiers - an array with all the tier details for a namespace
    function getTiersForNamespace(bytes32 _namespace)
        public
        view
        returns (bytes32[] memory tierIds, ITieredPricingDataTypesV0.Tier[] memory tiers)
    {
        // We get the latest tier id added to the ids array
        uint256 noOfTierIds = _tierIds[_namespace].length;
        bytes32[] memory __tierIds = new bytes32[](noOfTierIds);
        ITieredPricingDataTypesV0.Tier[] memory __tiers = new ITieredPricingDataTypesV0.Tier[](noOfTierIds);
        for (uint256 i = 0; i < noOfTierIds; i++) {
            bytes32 tierId_ = _tierIds[_namespace][i];
            // empty name means that the tier does not exist, i.e. was deleted
            if (bytes(_tiers[_namespace][tierId_].name).length > 0) {
                __tiers[i] = _tiers[_namespace][tierId_];
                __tierIds[i] = tierId_;
            }
        }
        tierIds = __tierIds;
        tiers = __tiers;
    }

    /// @dev Returns the default tier for a namespace
    /// @param _namespace - namespace for which default tier is requested
    /// @return tierId - id of the default tier for a namespace
    /// @return tier - tier details of the default tier for a namespace
    function getDefaultTierForNamespace(bytes32 _namespace)
        public
        view
        returns (bytes32 tierId, ITieredPricingDataTypesV0.Tier memory tier)
    {
        tierId = _defaultTier[_namespace];
        tier = _tiers[_namespace][_defaultTier[_namespace]];
    }

    /// @dev Returns the fee for the deployment_fee namespace
    function getDeploymentFee(address _account)
        public
        view
        returns (
            address feeReceiver,
            uint256 price,
            address currency
        )
    {
        (
            address _feeReceiver,
            uint256 _price,
            ITieredPricingDataTypesV0.FeeTypes _feeType,
            address _currency
        ) = _getFee(DEPLOYMENT_FEES_NAMESPACE, _account);
        if (_feeType != ITieredPricingDataTypesV0.FeeTypes.FlatFee)
            revert ITieredPricingErrorsV0.InvalidFeeTypeForDeploymentFees();
        feeReceiver = _feeReceiver;
        price = _price;
        currency = _currency;
    }

    /// @dev Returns the fee for the claim_fee namespace
    function getClaimFee(address _account) public view returns (address feeReceiver, uint256 price) {
        (
            address _feeReceiver,
            uint256 _price,
            ITieredPricingDataTypesV0.FeeTypes _feeType,
            address _currency
        ) = _getFee(CLAIM_FEES_NAMESPACE, _account);
        if (_feeType != ITieredPricingDataTypesV0.FeeTypes.Percentage)
            revert ITieredPricingErrorsV0.InvalidFeeTypeForClaimFees();
        feeReceiver = _feeReceiver;
        price = _price;
    }

    /// @dev Returns the fee for the collector_fee namespace
    function getCollectorFee(address _account)
        public
        view
        returns (
            address feeReceiver,
            uint256 price,
            address currency
        )
    {
        (
            address _feeReceiver,
            uint256 _price,
            ITieredPricingDataTypesV0.FeeTypes _feeType,
            address _currency
        ) = _getFee(COLLECTOR_FEES_NAMESPACE, _account);
        if (_feeType != ITieredPricingDataTypesV0.FeeTypes.FlatFee)
            revert ITieredPricingErrorsV0.InvalidFeeTypeForCollectorFees();
        feeReceiver = _feeReceiver;
        price = _price;
        currency = _currency;
    }

    /// @dev Returns the fee details for a namespace and an account
    /// @param _namespace - namespace for which fee details are requested
    /// @param _account - address for which fee details are requested
    /// @return feeReceiver - The fee receiver address
    /// @return price - The price
    /// @return feeType - The type of the fee
    function getFee(bytes32 _namespace, address _account)
        public
        view
        returns (
            address feeReceiver,
            uint256 price,
            ITieredPricingDataTypesV0.FeeTypes feeType,
            address currency
        )
    {
        return _getFee(_namespace, _account);
    }

    /// @dev Returns the Tier details for a specific tier based on namespace and tier id
    /// @return tier - Tier details for the namespace and tier id
    function getTierDetails(bytes32 _namespace, bytes32 _tierId)
        public
        view
        returns (ITieredPricingDataTypesV0.Tier memory tier)
    {
        tier = _getTierById(_namespace, _tierId);
    }

    /// ======================================
    /// ========= Internal functions =========
    /// ======================================

    /// @dev Sets a new platform fee receiver. Reverts if the receiver address is the same
    function _setPlatformFeeReceiver(address _platformFeeReceiver) internal virtual {
        if (_platformFeeReceiver == __platformFeeReceiver)
            revert ITieredPricingErrorsV0.PlatformFeeReceiverAlreadySet();
        __platformFeeReceiver = _platformFeeReceiver;
        emit PlatformFeeReceiverUpdated(_platformFeeReceiver);
    }

    function _setDefaultTier(bytes32 _namespace, bytes32 _tierId) internal virtual {
        // We make sure that the tier exists
        if (bytes(_getTierById(_namespace, _tierId).name).length == 0) revert ITieredPricingErrorsV0.InvalidTierId();
        _defaultTier[_namespace] = _tierId;

        emit DefaultTierUpdated(_namespace, _tierId);
    }

    /// @dev Adds a new tier for a namespace, if the new tier price is higher than the default one
    ///     we set the new one as the default tier.
    /// @param _namespace - namespace for which tier is added
    /// @param _tierDetails - Details of the tier (name, price, fee type)
    function _addTier(bytes32 _namespace, ITieredPricingDataTypesV0.Tier calldata _tierDetails) internal virtual {
        // Collector fees and deployment fees must be of type flat fee
        if (
            (_namespace == COLLECTOR_FEES_NAMESPACE || _namespace == DEPLOYMENT_FEES_NAMESPACE) &&
            _tierDetails.feeType != ITieredPricingDataTypesV0.FeeTypes.FlatFee
        ) revert ITieredPricingErrorsV0.InvalidFeeType();
        // Claim fees must be of type percentage
        if (
            (_namespace == CLAIM_FEES_NAMESPACE) &&
            _tierDetails.feeType != ITieredPricingDataTypesV0.FeeTypes.Percentage
        ) revert ITieredPricingErrorsV0.InvalidFeeType();
        if (
            // we don't allow zero address for flat fees
            (_tierDetails.feeType == ITieredPricingDataTypesV0.FeeTypes.FlatFee &&
                _tierDetails.currency == address(0)) ||
            // and we also don't allow a namespace to have dfferent currency than the default
            (_tiers[_namespace][_defaultTier[_namespace]].currency != address(0) &&
                _tierDetails.currency != _tiers[_namespace][_defaultTier[_namespace]].currency)
        ) revert ITieredPricingErrorsV0.InvalidCurrencyAddress();
        // we don't allow empty tier name
        if (bytes(_tierDetails.name).length == 0) revert ITieredPricingErrorsV0.InvalidTierName();
        // we dont allow the same tier name for a namespace
        if (_getTierIdForName(_namespace, _tierDetails.name) != 0) revert ITieredPricingErrorsV0.TierNameAlreadyExist();
        if (
            _tierDetails.feeType == ITieredPricingDataTypesV0.FeeTypes.Percentage &&
            _tierDetails.price > MAX_PERCENTAGE_FEE
        ) revert ITieredPricingErrorsV0.InvalidPercentageFee();

        bytes32 newTierId = bytes32(abi.encodePacked(_tierDetails.name));
        _tiers[_namespace][newTierId] = _tierDetails;
        // if it's the first tier added to the namespace, also set it as the default one
        if (_tierIds[_namespace].length == 0) {
            _setDefaultTier((_namespace), newTierId);
        }
        _tierIds[_namespace].push(newTierId);

        emit TierAdded(
            _namespace,
            newTierId,
            _tierDetails.name,
            _tierDetails.price,
            _tierDetails.currency,
            _tierDetails.feeType
        );
    }

    /// @dev Updates an already existing tier. If the default is updated with lower price, then we find the one with
    ///     highest price and set that one as the default
    /// @param _namespace - namespace for which tier is added
    /// @param _tierId - the id of the tier to be updated
    /// @param _tierDetails - Details of the tier (name, price, fee type)
    function _updateTier(
        bytes32 _namespace,
        bytes32 _tierId,
        ITieredPricingDataTypesV0.Tier calldata _tierDetails
    ) internal virtual {
        // We make sure tier exists
        if (bytes(_getTierById(_namespace, _tierId).name).length == 0) revert ITieredPricingErrorsV0.InvalidTierId();
        // we don't allow empty tier name
        if (bytes(_tierDetails.name).length == 0) revert ITieredPricingErrorsV0.InvalidTierName();
        // We don't allow the fee type to change
        if (_tierDetails.feeType != _tiers[_namespace][_tierId].feeType) revert ITieredPricingErrorsV0.InvalidFeeType();
        // we don't allow the currency to change
        if (_tierDetails.currency != _tiers[_namespace][_tierId].currency)
            revert ITieredPricingErrorsV0.InvalidCurrencyAddress();
        // we dont allow the same tier name for a namespace
        if (
            _getTierIdForName(_namespace, _tierDetails.name) != 0 &&
            _getTierIdForName(_namespace, _tierDetails.name) != _tierId
        ) revert ITieredPricingErrorsV0.TierNameAlreadyExist();

        _tiers[_namespace][_tierId] = _tierDetails;

        emit TierUpdated(
            _namespace,
            _tierId,
            _tierDetails.name,
            _tierDetails.price,
            _tierDetails.currency,
            _tierDetails.feeType
        );
    }

    /// @dev Removes a tier from a namespace, if the default tier is removed, then the tier with the
    ///     highest price is set as the default one.
    /// @param _namespace - namespace from which the tier is removed
    /// @param _tierId - id of the tier to be removed
    function _removeTier(bytes32 _namespace, bytes32 _tierId) internal virtual {
        if (_tierIds[_namespace].length == 1) revert ITieredPricingErrorsV0.SingleTieredNamespace();
        if (bytes(_getTierById(_namespace, _tierId).name).length == 0) revert ITieredPricingErrorsV0.InvalidTierId();
        delete _tiers[_namespace][_tierId];

        uint256 noOfTierIds = _tierIds[_namespace].length;
        for (uint256 i = 0; i < noOfTierIds; i++) {
            if (_tierIds[_namespace][i] == _tierId) {
                _tierIds[_namespace][i] = 0;
            }
        }

        if (_defaultTier[_namespace] == _tierId) {
            // We need to find the next tier with highest price and
            // we set the new default tier
            bytes32 newTierId = _getTierIdWithHighestPrice(_namespace);
            _setDefaultTier(_namespace, newTierId);
        }
        emit TierRemoved(_namespace, _tierId);
    }

    /// @dev Adds an account to a specific tier
    /// @param _namespace - namespace for which the account's tier must be added to
    /// @param _account - address which must be added to a tier
    /// @param _tierId - tier id which the account must be added to
    function _addAddressToTier(
        bytes32 _namespace,
        address _account,
        bytes32 _tierId
    ) internal virtual {
        if (_account == address(0)) revert ITieredPricingErrorsV0.InvalidAccount();
        if (bytes(_getTierById(_namespace, _tierId).name).length == 0) revert ITieredPricingErrorsV0.InvalidTierId();
        if (_addressToTier[_namespace][_account] == _tierId) revert ITieredPricingErrorsV0.AccountAlreadyOnTier();

        _addressToTier[_namespace][_account] = _tierId;

        emit AddressAddedToTier(_namespace, _account, _tierId);
    }

    /// @dev Removes an account from a tier, i.e. it's now part of the default tier
    /// @param _namespace - namespace for which the account's tier must be removed
    /// @param _account - address which must be removed from a tier
    function _removeAddressFromTier(bytes32 _namespace, address _account) internal virtual {
        if (_account == address(0)) revert ITieredPricingErrorsV0.InvalidAccount();
        bytes32 tierId = _addressToTier[_namespace][_account];
        if (tierId == _defaultTier[_namespace]) revert ITieredPricingErrorsV0.AccountAlreadyOnDefaultTier();
        delete _addressToTier[_namespace][_account];

        emit AddressRemovedFromTier(_namespace, _account, tierId);
    }

    /// @dev Returns the fee details for a namespace and an account
    /// @return feeReceiver - the address that will receive the fees
    /// @return price - the fee price
    /// @return feeType - the fee type (percentage / flat fee)
    function _getFee(bytes32 _namespace, address _account)
        internal
        view
        returns (
            address feeReceiver,
            uint256 price,
            ITieredPricingDataTypesV0.FeeTypes feeType,
            address currency
        )
    {
        bytes32 tierIdForAddress = _addressToTier[_namespace][_account];
        // If the address does not belong to a tier OR if the tier it belongs to it was deleted
        // we return the default price
        if (tierIdForAddress == 0 || bytes(_tiers[_namespace][tierIdForAddress].name).length == 0) {
            return (
                __platformFeeReceiver,
                _tiers[_namespace][_defaultTier[_namespace]].price,
                _tiers[_namespace][_defaultTier[_namespace]].feeType,
                _tiers[_namespace][_defaultTier[_namespace]].currency
            );
        }
        return (
            __platformFeeReceiver,
            _tiers[_namespace][tierIdForAddress].price,
            _tiers[_namespace][tierIdForAddress].feeType,
            _tiers[_namespace][tierIdForAddress].currency
        );
    }

    /// @dev Returns the Tier details for a specific tier based on namespace and tier id
    function _getTierById(bytes32 _namespace, bytes32 _tierId)
        internal
        view
        returns (ITieredPricingDataTypesV0.Tier memory)
    {
        return _tiers[_namespace][_tierId];
    }

    /// @dev Returns the Tier details for a specific tier based on namespace and tier name
    function _getTierIdForName(bytes32 _namespace, string calldata _tierName) internal view returns (bytes32) {
        uint256 noOfTierIds = _tierIds[_namespace].length;
        bytes32 tierId = 0;
        if (_tierIds[_namespace].length == 0) return tierId;
        for (uint256 i = 0; i < noOfTierIds; i++) {
            bytes32 tierId_ = _tierIds[_namespace][i];
            if (
                keccak256(abi.encodePacked(_tiers[_namespace][tierId_].name)) == keccak256(abi.encodePacked(_tierName))
            ) {
                tierId = tierId_;
                break;
            }
        }
        return tierId;
    }

    /// @dev Returns the Tier Id with highest price for a specific namespace
    function _getTierIdWithHighestPrice(bytes32 _namespace) internal view returns (bytes32) {
        uint256 highestPrice = 0;
        bytes32 tierIdWithHighestPrice = 0;
        uint256 noOfTierIds = _tierIds[_namespace].length;
        for (uint256 i = 0; i < noOfTierIds; i++) {
            bytes32 tierId_ = _tierIds[_namespace][i];
            if (highestPrice < _tiers[_namespace][tierId_].price) {
                highestPrice = _tiers[_namespace][tierId_].price;
                tierIdWithHighestPrice = tierId_;
            }
        }

        return tierIdWithHighestPrice;
    }
}