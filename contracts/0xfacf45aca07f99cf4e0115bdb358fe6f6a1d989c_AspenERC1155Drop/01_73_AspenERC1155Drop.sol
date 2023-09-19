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
import "../generated/impl/BaseAspenERC1155DropV4.sol";

import "./lib/FeeType.sol";
import "./lib/MerkleProof.sol";

import "./types/DropERC1155DataTypes.sol";
import "./AspenERC1155DropLogic.sol";

import "../terms/types/TermsDataTypes.sol";
import "../terms/lib/TermsLogic.sol";

import "./AspenERC1155DropStorage.sol";
import "../api/deploy/types/DropFactoryDataTypes.sol";
import "../api/issuance/IDropClaimCondition.sol";
import "../api/errors/IDropErrors.sol";

/// @title The AspenERC1155Drop contract
contract AspenERC1155Drop is AspenERC1155DropStorage, BaseAspenERC1155DropV4 {
    /// ================================
    /// =========== Libraries ==========
    /// ================================
    using StringsUpgradeable for uint256;
    using TermsLogic for TermsDataTypes.Terms;
    using AspenERC1155DropLogic for DropERC1155DataTypes.ClaimData;

    /// ====================================================
    /// ========== Constructor + initializer logic =========
    /// ====================================================
    constructor() {}

    /// @dev Initializes the contract, like a constructor.
    function initialize(IDropFactoryDataTypesV2.DropConfig memory _config) external initializer {
        // Initialize inherited contracts, most base-like -> most derived.
        __ReentrancyGuard_init();
        __ERC2771Context_init_unchained(_config.tokenDetails.trustedForwarders);
        __ERC1155_init_unchained("");
        __EIP712_init(_config.tokenDetails.name, "1.0.0");

        __UpdateableDefaultOperatorFiltererUpgradeable_init(_config.operatorFilterer);

        aspenConfig = IGlobalConfigV1(_config.aspenConfig);

        // Initialize this contract's state.
        __name = _config.tokenDetails.name;
        __symbol = _config.tokenDetails.symbol;
        _owner = _config.tokenDetails.defaultAdmin;
        _contractUri = _config.tokenDetails.contractURI;

        claimData.royaltyRecipient = _config.feeDetails.royaltyRecipient;
        claimData.royaltyBps = uint16(_config.feeDetails.royaltyBps);
        claimData.primarySaleRecipient = _config.feeDetails.saleRecipient;

        claimData.nextTokenIdToMint = TOKEN_INDEX_OFFSET;

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

    /// @dev See ERC 165
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(BaseAspenERC1155DropV4, AspenERC1155DropStorage) returns (bool) {
        return (AspenERC1155DropStorage.supportsInterface(interfaceId) ||
            BaseAspenERC1155DropV4.supportsInterface(interfaceId) ||
            // Support ERC4906
            interfaceId == bytes4(0x49064906));
    }

    /// ============================================
    /// ========== Generic contract logic ==========
    /// ============================================

    /// @dev Returns the address of the current owner.
    function owner() public view override returns (address) {
        return _owner;
    }

    /// @dev Returns the name of the token.
    function name() public view override returns (string memory) {
        return __name;
    }

    /// @dev Returns the symbol of the token.
    function symbol() public view override returns (string memory) {
        return __symbol;
    }

    /// @dev See ERC 1155 - Returns the URI for a given tokenId.
    function uri(
        uint256 _tokenId
    )
        public
        view
        virtual
        override(ERC1155Upgradeable, IERC1155MetadataURIV0)
        isValidTokenId(_tokenId)
        returns (string memory _tokenURI)
    {
        return AspenERC1155DropLogic.tokenURI(claimData, _tokenId);
    }

    /// @dev See ERC-2891 - Returns the royalty recipient and amount, given a tokenId and sale price.
    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external view virtual override isValidTokenId(tokenId) returns (address receiver, uint256 royaltyAmount) {
        return AspenERC1155DropLogic.royaltyInfo(claimData, tokenId, salePrice);
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

    /// @dev Lets an account claim a given quantity of NFTs, of a single tokenId.
    function claim(
        address _receiver,
        uint256 _tokenId,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        bytes32[] calldata _proofs,
        uint256 _proofMaxQuantityPerTransaction
    ) external payable override nonReentrant isValidTokenId(_tokenId) {
        address msgSender = _msgSender();
        if (!(isTrustedForwarder(msg.sender) || msgSender == tx.origin)) revert IDropErrorsV3.NotTrustedForwarder();
        if (claimIsPaused) revert IDropErrorsV3.ClaimPaused();

        AspenERC1155DropLogic.InternalClaim memory internalClaim = AspenERC1155DropLogic.executeClaim(
            claimData,
            AspenERC1155DropLogic.ClaimExecutionData(
                _tokenId,
                _quantity,
                _currency,
                _pricePerToken,
                _proofs,
                _proofMaxQuantityPerTransaction
            ),
            AspenERC1155DropLogic.ClaimFeesRequestData(aspenConfig, msgSender, _owner)
        );
        _mint(_receiver, _tokenId, _quantity, "");
        emit TokensClaimed(
            internalClaim.activeConditionId,
            msgSender,
            _receiver,
            _tokenId,
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

    function balanceOf(
        address _account,
        uint256 _id
    ) public view override(ERC1155Upgradeable, IERC1155V5) returns (uint256) {
        return ERC1155Upgradeable.balanceOf(_account, _id);
    }

    function balanceOfBatch(
        address[] memory _accounts,
        uint256[] memory _ids
    ) public view override(ERC1155Upgradeable, IERC1155V5) returns (uint256[] memory) {
        return ERC1155Upgradeable.balanceOfBatch(_accounts, _ids);
    }

    function isApprovedForAll(
        address _account,
        address _operator
    ) public view override(ERC1155Upgradeable, IERC1155V5) returns (bool) {
        return ERC1155Upgradeable.isApprovedForAll(_account, _operator);
    }

    /// ======================================
    /// ==== OS Default Operator Filterer ====
    /// ======================================
    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(ERC1155Upgradeable, IERC1155V5) onlyAllowedOperatorApproval(operator) {
        ERC1155Upgradeable.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public override(ERC1155Upgradeable, IERC1155V5) onlyAllowedOperator(from) {
        ERC1155Upgradeable.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override(ERC1155Upgradeable, IERC1155V5) onlyAllowedOperator(from) {
        ERC1155Upgradeable.safeBatchTransferFrom(from, to, ids, amounts, data);
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

    /// @dev Lets a token owner burn the tokens they own (i.e. destroy for good)
    function burn(address account, uint256 id, uint256 value) public virtual {
        if (!(account == _msgSender() || isApprovedForAll(account, _msgSender())))
            revert IDropErrorsV3.InvalidPermission();
        _burn(account, id, value);
    }

    /// @dev Lets a token owner burn multiple tokens they own at once (i.e. destroy for good)
    function burnBatch(address account, uint256[] memory ids, uint256[] memory values) public virtual {
        if (!(account == _msgSender() || isApprovedForAll(account, _msgSender())))
            revert IDropErrorsV3.InvalidPermission();
        _burnBatch(account, ids, values);
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

    // FIXME: well, fix solc, this is a horrible hack to make these library-emitted events appear in the ABI for this
    //   contract
    function __termsNotAccepted() external pure {
        revert IDropErrorsV3.TermsNotAccepted(address(0), "", uint8(0));
    }
}