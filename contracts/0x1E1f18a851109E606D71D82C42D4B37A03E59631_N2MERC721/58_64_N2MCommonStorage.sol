/** ---------------------------------------------------------------------------- //
 *                                                                               //
 *                                       .:::.                                   //
 *                                    .:::::::.                                  //
 *                                    ::::::::.                                  //
 *                                 .:::::::::.                                   //
 *                             ..:::.              ..                            //
 *                          .::::.                 ::::..                        //
 *                      ..:::..                    ::::::::.                     //
 *                   .::::.                        :::.  ..:::.                  //
 *               ..:::..                           :::.      .:::.               //
 *            .::::.                               :::.         .:::..           //
 *         .:::..               ..                 :::.            .::::.        //
 *     .::::.               ..:::=-                ::::               ..:::.     //
 *    :::.               .:::::::===:              ::::::.               .::::   //
 *   .::.            .:::::::::::=====.            ::::::::::.             .::.  //
 *   .::         .:::::::::::::::=======.          :::::::::::::..          ::.  //
 *   .::        .::::::::::::::::========-         :::::::::::::::::        ::.  //
 *   .::        .::::::::::::::::==========:       :::::::::::::::::        ::.  //
 *   .::        .::::::::::::::::============:     :::::::::::::::::        ::.  //
 *   .::        .::::::::::::::::==============.   :::::::::::::::::        ::.  //
 *   .::        .::::::::::::::::===============-. :::::::::::::::::        ::.  //
 *   .::        .::::::::::::::::=================::::::::::::::::::        ::.  //
 *   .::        .::::::::::::::::==================-::::::::::::::::        ::.  //
 *   .::        .::::::::::::::::==================-::::::::::::::::        ::.  //
 *   .::        .::::::::::::::::==================-::::::::::::::::        ::.  //
 *   .::        .:::::::::::::::::=================-::::::::::::::::        ::.  //
 *   .::        .:::::::::::::::: .-===============-::::::::::::::::        ::.  //
 *   .::        .::::::::::::::::   .==============-::::::::::::::::        ::.  //
 *   .::        .::::::::::::::::     :============-::::::::::::::::        ::.  //
 *   .::        .::::::::::::::::       :==========-::::::::::::::::        ::.  //
 *   .::        .::::::::::::::::        .-========-::::::::::::::::        ::.  //
 *   .::          .::::::::::::::          .=======-::::::::::::::.         ::.  //
 *   .::.             .::::::::::            .=====-::::::::::..            ::.  //
 *    :::..              ..::::::              :===-::::::..              .:::.  //
 *      .:::..               .:::                -=-:::.               .::::.    //
 *         .::::.            .:::                 ..                .::::.       //
 *            .::::.         .:::                               ..:::.           //
 *                .:::.      .:::                            .::::.              //
 *                   .:::..  .:::                        ..:::..                 //
 *                      .::::.:::                     .::::.                     //
 *                         ..::::                 ..:::..                        //
 *                             .:              .::::.                            //
 *                                     :::::.::::.                               //
 *                                    ::::::::.                                  //
 *                                    :::::::.                                   //
 *                                     .::::.                                    //
 *                                                                               //
 *                                                                               //
 *   Smart contract generated by https://nfts2me.com                             //
 *                                                                               //
 *   NFTs2Me. Make an NFT Collection.                                            //
 *   With ZERO Coding Skills.                                                    //
 *                                                                               //
 *   NFTs2Me is not associated or affiliated with this project.                  //
 *   NFTs2Me is not liable for any bugs or issues associated with this contract. //
 *   NFTs2Me Terms of Service: https://nfts2me.com/terms-of-service/             //
 * ----------------------------------------------------------------------------- */

/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@nfts2me/contracts/interfaces/IN2M_ERCStorage.sol";
import "@nfts2me/contracts/interfaces/IN2MCrossFactory.sol";
import "@nfts2me/contracts/ownable/NFTOwnableUpgradeable.sol";
import {IOperatorFilterRegistry} from "@nfts2me/contracts/interfaces/IOperatorFilterRegistry.sol";
import "./N2MVersion.sol";

/// @title NFTs2Me.com Smart Contracts
/// @author The NFTs2Me Team
/// @notice Read our terms of service
/// @custom:security-contact [email protected]
/// @custom:terms-of-service https://nfts2me.com/terms-of-service/
/// @custom:website https://nfts2me.com/
abstract contract N2MCommonStorage is
    NFTOwnableUpgradeable,
    IN2M_ERCStorage,
    N2MVersion
{
    /// CONSTANTS
    address internal constant DEFAULT_SUBSCRIPTION = address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);
    address internal constant OPENSEA_CONDUIT = address(0x1E0049783F008A0085193E00003D00cd54003c71);
    address internal constant N2M_CONDUIT = address(0x88899DC0B84C6E726840e00DFb94ABc6248825eC);
    IOperatorFilterRegistry internal constant operatorFilterRegistry = IOperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);
    address internal constant N2M_PRESALE_SIGNER = address(0xC0ffee06CE3D6689305035601a055A96acd619c6);
    address internal constant N2M_TREASURY = address(0x955aF4de9Ca03f84c9462457D075aCABf1A8AfC8);
    uint256 internal constant N2M_FEE = 5_00;
    uint256 internal constant MAX_AFFILIATE_DISCOUNT = 100_00;
    uint256 internal constant MAX_AFFILIATE_PERCENTAGE = 100_00;
    uint256 internal constant NOT_ENTERED = 0;

    /// IMMUTABLE    
    address payable internal immutable _factory;

    bytes32 internal _baseURICIDHash;
    bytes32 internal _placeholderImageCIDHash;
    bytes32 internal _contractURIMetadataCIDHash;

    mapping(address => uint256) internal _pendingAffiliateBalance;
    uint256 internal _pendingTotalAffiliatesBalance;

    RevenueAddress[] internal _revenueInfo;
    mapping(address => AffiliateInformation) internal _affiliatesInfo;

    uint256 internal _mintPrice;
    uint256 internal _withdrawnAmount;
    uint256 internal _reentrancyEntered;
    uint256 internal _dropDateTimestamp;
    uint256 internal _endDateTimestamp; 

    mapping(address => uint256) internal _withdrawnERC20Amount;
    address internal _erc20PaymentAddress;

    mapping(address => RandomTicket) internal _randomTickets;
    mapping(bytes => uint256) internal _usedAmountSignature;
    mapping(uint256 => bool) internal _soulbound;
    mapping(uint256 => bytes32) internal _customURICIDHashes;

    uint32 internal _soldTokens;
    SalePhase internal _currentPhase;
    OperatorFilterStatus internal _operatorFilterStatus;
    MintingType internal _mintingType;                                                              
    uint16 internal _royaltyFee;
    uint16 internal _maxPerAddress;                                                                 
    uint32 internal _collectionSize;
    bool internal _isERC20Payment;
    bool internal _soulboundCollection;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address payable factoryAddress) {
        _factory = factoryAddress;
        _disableInitializers();
    }

    /// @notice Returns the address of the current collection owner.
    function owner() public view override(NFTOwnableUpgradeable) returns (address collectionOwner) {
        try IN2MCrossFactory(_factory).ownerOf(uint256(uint160(address(this)))) returns (address ownerOf) {
            return ownerOf;
        } catch {}
    }

    function _strictOwner() internal view override(NFTOwnableUpgradeable) returns (address ownerStrictAddress) {
        try IN2MCrossFactory(_factory).strictOwnerOf(uint256(uint160(address(this)))) returns (address strictOwnerOf) {
            return strictOwnerOf;
        } catch {}
    }

    function _getN2MFeeAddress() internal view override(NFTOwnableUpgradeable) returns (address) {

        try IN2MCrossFactory(_factory).getN2MTreasuryAddress() returns (address n2mTreasuryAddress) {
            return n2mTreasuryAddress;
        } catch {
            return N2M_TREASURY;
        }
    }    

    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        if (_reentrancyEntered != 0) revert ReentrancyGuard();
        _reentrancyEntered = 1;
    }

    function _nonReentrantAfter() private {
        delete(_reentrancyEntered);
    }    

    /// @notice Returns true if the metadata is fixed and immutable. If the metadata hasn't been fixed yet it will return false. Once fixed, it can't be changed by anyone.
    function isMetadataFixed() public view override returns (bool) {
        return (_baseURICIDHash != 0 || (_mintingType == MintingType.CUSTOM_URI));
    }

}