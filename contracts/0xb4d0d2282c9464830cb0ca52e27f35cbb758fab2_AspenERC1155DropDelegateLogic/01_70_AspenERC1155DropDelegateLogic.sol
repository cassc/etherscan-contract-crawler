// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

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

import "./AspenERC1155DropStorage.sol";
import "./../api/issuance/IDropClaimCondition.sol";
import "../generated/impl/BaseAspenERC1155DropV4.sol";

contract AspenERC1155DropDelegateLogic is
    IDropClaimConditionV1,
    AspenERC1155DropStorage,
    IDelegateBaseAspenERC1155DropV4
{
    /// ================================
    /// =========== Libraries ==========
    /// ================================
    using StringsUpgradeable for uint256;
    using TermsLogic for TermsDataTypes.Terms;
    using AspenERC1155DropLogic for DropERC1155DataTypes.ClaimData;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    constructor() {}

    function initialize() external initializer {}

    /// @dev See ERC 165
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return AspenERC1155DropStorage.supportsInterface(interfaceId);
    }

    /// ======================================
    /// ========= Delegated Logic ============
    /// ======================================

    /// @dev Returns the default royalty recipient and bps.
    function getDefaultRoyaltyInfo() external view override returns (address, uint16) {
        return (claimData.royaltyRecipient, uint16(claimData.royaltyBps));
    }

    /// @dev Returns the royalty recipient and bps for a particular token Id.
    function getRoyaltyInfoForToken(
        uint256 _tokenId
    ) public view override isValidTokenId(_tokenId) returns (address, uint16) {
        return AspenERC1155DropLogic.getRoyaltyInfoForToken(claimData, _tokenId);
    }

    /// @dev Returns the platform fee recipient and bps.
    function getPlatformFeeInfo() external view override returns (address platformFeeRecipient, uint16 platformFeeBps) {
        (address _platformFeeReceiver, uint256 _claimFeeBPS) = aspenConfig.getClaimFee(_owner);
        platformFeeRecipient = _platformFeeReceiver;
        platformFeeBps = uint16(_claimFeeBPS);
    }

    /// @dev Returns the claim condition at the given uid.
    function getClaimConditionById(
        uint256 _tokenId,
        uint256 _conditionId
    ) external view isValidTokenId(_tokenId) returns (ClaimCondition memory condition) {
        condition = AspenERC1155DropLogic.getClaimConditionById(claimData, _tokenId, _conditionId);
    }

    /// @dev Returns an array with all the claim conditions.
    function getClaimConditions(
        uint256 _tokenId
    ) external view isValidTokenId(_tokenId) returns (ClaimCondition[] memory conditions) {
        conditions = AspenERC1155DropLogic.getClaimConditions(claimData, _tokenId);
    }

    /// @dev Returns basic info for claim data
    function getClaimData(
        uint256 _tokenId
    ) external view returns (uint256 nextTokenIdToMint, uint256 maxTotalSupply, uint256 maxWalletClaimCount) {
        (nextTokenIdToMint, maxTotalSupply, maxWalletClaimCount) = AspenERC1155DropLogic.getClaimData(
            claimData,
            _tokenId
        );
    }

    /// @dev Returns the total payment amount the collector has to pay taking into consideration all the fees
    function getClaimPaymentDetails(
        uint256 _quantity,
        uint256 _pricePerToken,
        address _claimCurrency
    )
        external
        view
        returns (
            address claimCurrency,
            uint256 claimPrice,
            uint256 claimFee,
            address collectorFeeCurrency,
            uint256 collectorFee
        )
    {
        AspenERC1155DropLogic.ClaimFeeDetails memory claimFees = AspenERC1155DropLogic.getAllClaimFees(
            aspenConfig,
            _owner,
            _claimCurrency,
            _quantity,
            _pricePerToken
        );

        return (
            claimFees.claimCurrency,
            claimFees.claimPrice,
            claimFees.claimFee,
            claimFees.collectorFeeCurrency,
            claimFees.collectorFee
        );
    }

    /// @dev Returns the amount of stored baseURIs
    function getBaseURICount() external view override returns (uint256) {
        return claimData.baseURIIndices.length;
    }

    /// @dev Returns the transfer times for a token and a token owner. - see _getTransferTimesForToken()
    /// @return quantityOfTokens - array with quantity of tokens
    /// @return transferableAt - array with timestamps at which the respective quantity from first array can be transferred
    function getTransferTimesForToken(
        address _tokenOwner,
        uint256 _tokenId
    ) external view override returns (uint256[] memory quantityOfTokens, uint256[] memory transferableAt) {
        (
            uint256[] memory _quantityOfTokens,
            uint256[] memory _transferableAt,
            uint256 largestActiveSlotId
        ) = _getTransferTimesForToken(_tokenId, _tokenOwner);
        quantityOfTokens = _quantityOfTokens;
        transferableAt = _transferableAt;
    }

    /// @dev Returns the issue buffer size for a token and a token owner
    function getIssueBufferSizeForAddressAndToken(address _tokenOwner, uint256 _tokenId) public view returns (uint256) {
        return issueBufferSize[_tokenOwner][_tokenId];
    }

    /// @dev Returns the chargeback protection period
    function getChargebackProtectionPeriod() external view override returns (uint256) {
        return chargebackProtectionPeriod;
    }

    /// @dev Expose the user specific limits related to the current active claim condition
    function getUserClaimConditions(
        uint256 _tokenId,
        address _claimer
    )
        external
        view
        override
        isValidTokenId(_tokenId)
        returns (
            ClaimCondition memory condition,
            uint256 conditionId,
            uint256 walletMaxClaimCount,
            uint256 tokenSupply,
            uint256 maxTotalSupply,
            uint256 walletClaimedCount,
            uint256 walletClaimedCountInPhase,
            uint256 lastClaimTimestamp,
            uint256 nextValidClaimTimestamp,
            bool isClaimPaused
        )
    {
        (condition, conditionId, walletMaxClaimCount, maxTotalSupply) = AspenERC1155DropLogic.getActiveClaimConditions(
            claimData,
            _tokenId
        );
        (
            conditionId,
            walletClaimedCount,
            walletClaimedCountInPhase,
            lastClaimTimestamp,
            nextValidClaimTimestamp
        ) = AspenERC1155DropLogic.getUserClaimConditions(claimData, _tokenId, _claimer);
        isClaimPaused = claimIsPaused;
        tokenSupply = claimData.totalSupply[_tokenId];
    }

    /// @dev Checks a request to claim NFTs against the active claim condition's criteria
    ///     including verification proofs.
    function verifyClaim(
        address _receiver,
        uint256 _tokenId,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        bytes32[] calldata _proofs,
        uint256 _proofMaxQuantityPerTransaction
    ) public view override isValidTokenId(_tokenId) {
        AspenERC1155DropLogic.fullyVerifyClaim(
            claimData,
            _receiver,
            _tokenId,
            _quantity,
            _currency,
            _pricePerToken,
            _proofs,
            _proofMaxQuantityPerTransaction
        );
    }

    /// @dev Returns the offset for token IDs.
    function getSmallestTokenId() external pure override returns (uint8) {
        return TOKEN_INDEX_OFFSET;
    }

    /// @dev returns the total number of unique tokens in existence.
    function getLargestTokenId() public view override returns (uint256) {
        return claimData.nextTokenIdToMint - TOKEN_INDEX_OFFSET;
    }

    function exists(uint256 _tokenId) public view override isValidTokenId(_tokenId) returns (bool) {
        return claimData.totalSupply[_tokenId] > 0;
    }

    function totalSupply(uint256 _tokenId) public view override isValidTokenId(_tokenId) returns (uint256) {
        return claimData.totalSupply[_tokenId];
    }

    /// @dev returns the pause status of the drop contract.
    function getClaimPauseStatus() external view override returns (bool pauseStatus) {
        pauseStatus = claimIsPaused;
    }

    /// @dev Gets the base URI indices
    function getBaseURIIndices() external view override returns (uint256[] memory) {
        return claimData.baseURIIndices;
    }

    /// @dev Contract level metadata.
    function contractURI() external view override(IDelegatedMetadataV0) returns (string memory) {
        return _contractUri;
    }

    /// @dev Returns the sale recipient address.
    function primarySaleRecipient() external view override returns (address) {
        return claimData.primarySaleRecipient;
    }

    /// ======================================
    /// ============ Agreement ===============
    /// ======================================
    /// @notice returns the details of the terms
    /// @return termsURI - the URI of the terms
    /// @return termsVersion - the version of the terms
    /// @return termsActivated - the status of the terms
    function getTermsDetails()
        external
        view
        override
        returns (string memory termsURI, uint8 termsVersion, bool termsActivated)
    {
        return termsData.getTermsDetails();
    }

    /// @notice returns true if an address has accepted the terms
    function hasAcceptedTerms(address _address) external view override returns (bool hasAccepted) {
        hasAccepted = termsData.hasAcceptedTerms(_address);
    }

    /// @notice returns true if an address has accepted the terms
    function hasAcceptedTerms(address _address, uint8 _termsVersion) external view override returns (bool hasAccepted) {
        hasAccepted = termsData.hasAcceptedTerms(_address, _termsVersion);
    }
}