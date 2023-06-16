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

//  ==========  External imports    ==========
import "@openzeppelin/contracts/utils/Address.sol";

/// ========== Features ==========
import "./openzeppelin-presets/metatx/ERC2771ContextUpgradeable.sol";
import "../generated/impl/BaseAspenERC721DropV3.sol";

import "./lib/FeeType.sol";
import "./lib/MerkleProof.sol";

import "./types/DropERC721DataTypes.sol";
import "./AspenERC721DropLogic.sol";

import "../terms/types/TermsDataTypes.sol";
import "../terms/lib/TermsLogic.sol";

import "./AspenERC721DropStorage.sol";
import "../api/deploy/types/DropFactoryDataTypes.sol";
import "../api/issuance/INFTSupply.sol";
import "../api/metadata/INFTMetadata.sol";
import "../api/errors/IDropErrors.sol";

/// @title The AspenERC721Drop contract
contract AspenERC721Drop is AspenERC721DropStorage, BaseAspenERC721DropV3 {
    /// ================================
    /// =========== Libraries ==========
    /// ================================
    using StringsUpgradeable for uint256;
    using AspenERC721DropLogic for DropERC721DataTypes.ClaimData;
    using TermsLogic for TermsDataTypes.Terms;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    /// ====================================================
    /// ========== Constructor + initializer logic =========
    /// ====================================================
    constructor() {}

    /// @dev Initializes the contract, like a constructor.
    function initialize(IDropFactoryDataTypesV2.DropConfig memory _config) external initializer {
        __AspenERC721Drop_init(_config);
    }

    function __AspenERC721Drop_init(IDropFactoryDataTypesV2.DropConfig memory _config) internal {
        // Initialize inherited contracts, most base-like -> most derived.
        __ReentrancyGuard_init();
        __ERC2771Context_init(_config.tokenDetails.trustedForwarders);
        __ERC721_init(_config.tokenDetails.name, _config.tokenDetails.symbol);
        __EIP712_init(_config.tokenDetails.name, "1.0.0");
        __UpdateableDefaultOperatorFiltererUpgradeable_init(_config.operatorFilterer);

        aspenConfig = IGlobalConfigV1(_config.aspenConfig);

        // Initialize this contract's state.
        __name = _config.tokenDetails.name;
        __symbol = _config.tokenDetails.symbol;
        _contractUri = _config.tokenDetails.contractURI;
        _owner = _config.tokenDetails.defaultAdmin;

        claimData.royaltyRecipient = _config.feeDetails.royaltyRecipient;
        claimData.royaltyBps = uint16(_config.feeDetails.royaltyBps);
        claimData.primarySaleRecipient = _config.feeDetails.saleRecipient;

        claimData.nextTokenIdToClaim = TOKEN_INDEX_OFFSET;
        claimData.nextTokenIdToMint = TOKEN_INDEX_OFFSET;

        isSBT = _config.tokenDetails.isSBT;
        chargebackProtectionPeriod = _config.feeDetails.chargebackProtectionPeriod;

        // Agreement initialize
        termsData.termsURI = _config.tokenDetails.userAgreement;
        // We set the terms version to 1 if there is an actual termsURL
        if (bytes(_config.tokenDetails.userAgreement).length > 0) {
            termsData.termsVersion = 1;
        }
        delegateLogicContract = _config.dropDelegateLogic;
        restrictedLogicContract = _config.dropRestrictedLogic;

        operatorRestriction = true;

        _setupRole(DEFAULT_ADMIN_ROLE, _config.tokenDetails.defaultAdmin);
        _setupRole(MINTER_ROLE, _config.tokenDetails.defaultAdmin);
        _setupRole(ISSUER_ROLE, _config.tokenDetails.defaultAdmin);

        emit OwnershipTransferred(address(0), _config.tokenDetails.defaultAdmin);
    }

    fallback() external {
        // get facet from function selector
        address logic = restrictedLogicContract;
        require(logic != address(0));
        // Execute external function from delegate logic contract using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the facet
            let result := delegatecall(gas(), logic, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /// ============================================
    /// ========== Generic contract logic ==========
    /// ============================================
    /// @dev Returns the address of the current owner.
    function owner() public view override returns (address) {
        return _owner;
    }

    /// @dev Returns the name of the token.
    function name() public view override(ERC721Upgradeable, IERC721V3) returns (string memory) {
        return __name;
    }

    /// @dev Returns the symbol of the token.
    function symbol() public view override(ERC721Upgradeable, IERC721V3) returns (string memory) {
        return __symbol;
    }

    /// @dev See {IERC721Enumerable-totalSupply}.
    function totalSupply() public view override(IPublicNFTSupplyV0, ERC721EnumerableUpgradeable) returns (uint256) {
        return ERC721EnumerableUpgradeable.totalSupply();
    }

    /// @dev See ERC 721 - Returns the URI for a given tokenId.
    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721Upgradeable, IAspenNFTMetadataV1)
        isValidTokenId(_tokenId)
        returns (string memory)
    {
        return AspenERC721DropLogic.tokenURI(claimData, _tokenId);
    }

    /// @dev See ERC-2891 - Returns the royalty recipient and amount, given a tokenId and sale price.
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        virtual
        override
        isValidTokenId(tokenId)
        returns (address receiver, uint256 royaltyAmount)
    {
        return AspenERC721DropLogic.royaltyInfo(claimData, tokenId, salePrice);
    }

    /// @dev See ERC 165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(BaseAspenERC721DropV3, AspenERC721DropStorage)
        returns (bool)
    {
        return (AspenERC721DropStorage.supportsInterface(interfaceId) ||
            BaseAspenERC721DropV3.supportsInterface(interfaceId) ||
            // Support ERC4906
            interfaceId == bytes4(0x49064906));
    }

    /// @dev Lets a contract admin set a new owner for the contract.
    function setOwner(address _newOwner) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        // The new owner should already have the DEFAULT_ADMIN_ROLE
        if (!hasRole(DEFAULT_ADMIN_ROLE, _newOwner)) revert IDropErrorsV1.NewOwnerMustHaveAdminRole();
        address _prevOwner = _owner;
        _owner = _newOwner;
        // We are granting the necessary roles to new owner
        grantRole(MINTER_ROLE, _newOwner);
        grantRole(ISSUER_ROLE, _newOwner);
        // We are revoking all roles from previous owner
        revokeRole(MINTER_ROLE, _prevOwner);
        revokeRole(ISSUER_ROLE, _prevOwner);
        revokeRole(DEFAULT_ADMIN_ROLE, _prevOwner);

        emit OwnershipTransferred(_prevOwner, _newOwner);
    }

    /// ======================================
    /// ============= Claim logic ============
    /// ======================================
    /// @dev Lets an account claim NFTs.
    function claim(
        address _receiver,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        bytes32[] calldata _proofs,
        uint256 _proofMaxQuantityPerTransaction
    ) external payable override nonReentrant {
        address msgSender = _msgSender();
        if (!(isTrustedForwarder(msg.sender) || msgSender == tx.origin)) revert IDropErrorsV0.NotTrustedForwarder();
        if (claimIsPaused) revert IDropErrorsV0.ClaimPaused();

        (uint256[] memory tokens, AspenERC721DropLogic.InternalClaim memory internalClaim) = AspenERC721DropLogic
            .executeClaim(
                claimData,
                AspenERC721DropLogic.ClaimExecutionData(
                    _quantity,
                    _currency,
                    _pricePerToken,
                    _proofs,
                    _proofMaxQuantityPerTransaction
                ),
                AspenERC721DropLogic.ClaimFeesRequestData(aspenConfig, msgSender, _owner)
            );

        for (uint256 i = 0; i < tokens.length; i += 1) {
            _mint(_receiver, tokens[i]);
        }

        emit TokensClaimed(
            internalClaim.activeConditionId,
            msgSender,
            _receiver,
            internalClaim.tokenIdToClaim,
            _quantity,
            internalClaim.phaseId
        );

        emit ClaimFeesPaid(
            msgSender,
            internalClaim.saleRecipient,
            internalClaim.feeReceiver,
            internalClaim.phaseId,
            _currency,
            internalClaim.claimAmount,
            internalClaim.claimFee,
            internalClaim.collectorFeeCurrency,
            internalClaim.collectorFee
        );
    }

    /// ======================================
    /// ============ Agreement ===============
    /// ======================================
    /// @notice by signing this transaction, you are confirming that you have read and agreed to the terms of use at `termsUrl`
    function acceptTerms() external override {
        termsData.acceptTerms(_msgSender());
        emit TermsAccepted(termsData.termsURI, termsData.termsVersion, _msgSender());
    }

    /// ======================================
    /// ========== Getter functions ==========
    /// ======================================
    /// @dev Contract level metadata.
    function contractURI() external view override(IPublicMetadataV0) returns (string memory) {
        return _contractUri;
    }

    /// @dev Returns the sale recipient address.
    function primarySaleRecipient() external view override returns (address) {
        return claimData.primarySaleRecipient;
    }

    /// @dev Returns the default royalty recipient and bps.
    function getDefaultRoyaltyInfo() external view override returns (address, uint16) {
        return (claimData.royaltyRecipient, uint16(claimData.royaltyBps));
    }

    function balanceOf(address _account)
        public
        view
        override(ERC721Upgradeable, IERC721Upgradeable, IERC721V4)
        returns (uint256 balance)
    {
        return ERC721Upgradeable.balanceOf(_account);
    }

    function getApproved(uint256 _tokenId)
        public
        view
        override(ERC721Upgradeable, IERC721Upgradeable, IERC721V4)
        returns (address operator)
    {
        return ERC721Upgradeable.getApproved(_tokenId);
    }

    function isApprovedForAll(address _account, address _operator)
        public
        view
        override(ERC721Upgradeable, IERC721Upgradeable, IERC721V4)
        returns (bool)
    {
        return ERC721Upgradeable.isApprovedForAll(_account, _operator);
    }

    /// ======================================
    /// ==== OS Default Operator Filterer ====
    /// ======================================
    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721Upgradeable, IERC721Upgradeable, IERC721V4)
        onlyAllowedOperatorApproval(operator)
    {
        ERC721Upgradeable.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override(ERC721Upgradeable, IERC721Upgradeable, IERC721V4)
        onlyAllowedOperatorApproval(operator)
    {
        ERC721Upgradeable.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721Upgradeable, IERC721Upgradeable, IERC721V4) onlyAllowedOperator(from) {
        ERC721Upgradeable.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721Upgradeable, IERC721Upgradeable, IERC721V4) onlyAllowedOperator(from) {
        ERC721Upgradeable.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721Upgradeable, IERC721Upgradeable, IERC721V4) onlyAllowedOperator(from) {
        ERC721Upgradeable.safeTransferFrom(from, to, tokenId, data);
    }

    /// ======================================
    /// =========== Miscellaneous ============
    /// ======================================
    /// @dev Concrete implementation semantic version -
    ///         provided for completeness but not designed to be the point of dispatch
    function minorVersion() public pure override returns (uint256 minor, uint256 patch) {
        minor = 0;
        patch = 0;
    }

    /// @dev Burns `tokenId`. See {ERC721-_burn}.
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        if (!(_isApprovedOrOwner(_msgSender(), tokenId))) revert IDropErrorsV0.InvalidPermission();
        _burn(tokenId);
        // Not strictly necessary since we shouldn't issue this token again
        claimData.tokenURIs[tokenId].sequenceNumber = 0;
    }

    /// @dev Provides a function to batch together multiple calls in a single external call.
    function multicall(bytes[] calldata data) external override returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
        return results;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        return ERC2771ContextUpgradeable._msgSender();
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        return ERC2771ContextUpgradeable._msgData();
    }
}