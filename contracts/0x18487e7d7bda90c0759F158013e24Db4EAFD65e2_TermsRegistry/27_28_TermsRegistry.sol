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

/// ========== External imports ==========
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "../api/agreement/IAgreementsRegistry.sol";
import "../api/ownable/IOwnable.sol";
import "../api/IAspenVersioned.sol";
import "../terms/types/TermsDataTypes.sol";
import "../api/errors/ITermsErrors.sol";
import "../api/errors/IUUPSUpgradeableErrors.sol";
import "../terms/lib/TermsLogic.sol";
import "../generated/impl/BaseTermsRegistryV1.sol";

/// @title TermsRegistry
/// @notice This contract is responsible for managing the terms of use for 3rd party ERC721 and ERC1155 contracts.
contract TermsRegistry is
    ContextUpgradeable,
    UUPSUpgradeable,
    AccessControlUpgradeable,
    BaseTermsRegistryV1,
    EIP712Upgradeable
{
    /// ================================
    /// =========== Libraries ==========
    /// ================================
    using TermsLogic for TermsDataTypes.Terms;
    using ERC165CheckerUpgradeable for address;

    bytes32 public constant MESSAGE_HASH =
        keccak256("AcceptTerms(address acceptor,string termsURI,uint8 termsVersion)");

    struct AcceptTerms {
        address acceptor;
        string termsURI;
        uint8 termsVersion;
    }

    /// ===============================
    /// =========== Mappings ==========
    /// ===============================
    /// @notice Mapping with the address of the contract and the terms of use.
    mapping(address => TermsDataTypes.Terms) public terms;

    function initialize() public initializer {
        __UUPSUpgradeable_init();
        __EIP712_init("TermsRegistry", "1.0.0");
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @dev See ERC 165
    /// NOTE: Due to this function being overridden by 2 different contracts, we need to explicitly specify the interface here
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(BaseTermsRegistryV1, AccessControlUpgradeable)
        returns (bool)
    {
        return
            BaseTermsRegistryV1.supportsInterface(interfaceId) ||
            AccessControlUpgradeable.supportsInterface(interfaceId);
    }

    function _authorizeUpgrade(address newImplementation) internal view override onlyRole(DEFAULT_ADMIN_ROLE) {
        (uint256 major, uint256 minor, uint256 patch) = this.implementationVersion();
        if (!newImplementation.supportsInterface(type(ICedarVersionedV1).interfaceId)) {
            revert IUUPSUpgradeableErrorsV0.ImplementationNotVersioned(newImplementation);
        }
        (uint256 newMajor, uint256 newMinor, uint256 newPatch) = ICedarVersionedV1(newImplementation)
            .implementationVersion();
        // Do not permit a breaking change via an UUPS proxy upgrade - this requires a new proxy. Otherwise, only allow
        // minor/patch versions to increase
        if (major != newMajor || minor > newMinor || (minor == newMinor && patch > newPatch)) {
            revert IUUPSUpgradeableErrorsV0.IllegalVersionUpgrade(major, minor, patch, newMajor, newMinor, newPatch);
        }
    }

    /// @notice by signing this transaction, you are confirming that you have read and agreed to the terms of use at `termsUrl`
    function acceptTerms(address _token) external {
        TermsDataTypes.Terms storage termsData = terms[_token];
        _canAcceptTerms(termsData, _token, _msgSender());
        _acceptTerms(termsData, _msgSender());
        emit TermsAccepted(_token, termsData.termsURI, termsData.termsVersion, _msgSender());
    }

    /// @notice allows an admin to accept terms on behalf of a user
    function acceptTerms(address _token, address _acceptor) external onlyRole(DEFAULT_ADMIN_ROLE) {
        TermsDataTypes.Terms storage termsData = terms[_token];
        _canAcceptTerms(termsData, _token, _acceptor);
        _acceptTerms(termsData, _acceptor);
        emit TermsAccepted(_token, termsData.termsURI, termsData.termsVersion, _acceptor);
    }

    /// @notice allows anyone to accept terms on behalf of a user, as long as they provide a valid signature
    function acceptTerms(
        address _token,
        address _acceptor,
        bytes calldata _signature
    ) external {
        TermsDataTypes.Terms storage termsData = terms[_token];
        _canAcceptTerms(termsData, _token, _acceptor);
        if (!_verifySignature(termsData, _acceptor, _signature)) revert ITermsErrorsV0.SignatureVerificationFailed();
        _acceptTerms(termsData, _acceptor);
        emit TermsWithSignatureAccepted(_token, termsData.termsURI, termsData.termsVersion, _acceptor, _signature);
    }

    /// @notice allows an admin to batch accept terms on behalf of multiple users
    function batchAcceptTerms(address _token, address[] calldata _acceptors) external onlyRole(DEFAULT_ADMIN_ROLE) {
        TermsDataTypes.Terms storage termsData = terms[_token];
        for (uint256 i = 0; i < _acceptors.length; i++) {
            _canAcceptTerms(termsData, _token, _acceptors[i]);
            _acceptTerms(termsData, _acceptors[i]);
            emit TermsAccepted(_token, termsData.termsURI, termsData.termsVersion, _acceptors[i]);
        }
    }

    /// @notice activates / deactivates the terms of use.
    function setTermsActivation(address _token, bool _active) external {
        if (IOwnableV0(_token).owner() != _msgSender()) revert ITermsErrorsV0.TermsCanOnlyBeSetByOwner(_token);
        TermsDataTypes.Terms storage termsData = terms[_token];
        if (_active) {
            _activateTerms(termsData, _token);
        } else {
            _deactivateTerms(termsData, _token);
        }
        emit TermsActivationStatusUpdated(_token, _active);
    }

    /// @notice updates the term URI and pumps the terms version
    function setTermsURI(address _token, string calldata _termsURI) external {
        if (IOwnableV0(_token).owner() != _msgSender()) revert ITermsErrorsV0.TermsCanOnlyBeSetByOwner(_token);
        TermsDataTypes.Terms storage termsData = terms[_token];
        if (keccak256(abi.encodePacked(termsData.termsURI)) == keccak256(abi.encodePacked(_termsURI)))
            revert ITermsErrorsV0.TermsUriAlreadySetForToken(_token);
        if (bytes(_termsURI).length > 0) {
            termsData.termsVersion = termsData.termsVersion + 1;
            termsData.termsActivated = true;
        } else {
            termsData.termsActivated = false;
        }
        termsData.termsURI = _termsURI;
        emit TermsUpdated(_token, termsData.termsURI, termsData.termsVersion);
    }

    /// @notice returns the details of the terms for a specific token
    /// @return termsURI - the URI of the terms
    /// @return termsVersion - the version of the terms
    /// @return termsActivated - the status of the terms
    function getTermsDetails(address _token)
        external
        view
        returns (
            string memory termsURI,
            uint8 termsVersion,
            bool termsActivated
        )
    {
        TermsDataTypes.Terms storage termsData = terms[_token];
        (termsURI, termsVersion, termsActivated) = (
            termsData.termsURI,
            termsData.termsVersion,
            termsData.termsActivated
        );
    }

    /// @notice returns true if an address has accepted the terms
    /// @return hasAccepted - weather the address has accepted the terms or not
    function hasAcceptedTerms(address _token, address _address) external view returns (bool hasAccepted) {
        TermsDataTypes.Terms storage termsData = terms[_token];
        hasAccepted =
            termsData.termsAccepted[_address] &&
            termsData.acceptedVersion[_address] == termsData.termsVersion;
    }

    /// @notice returns true if an address has accepted the terms
    /// @return hasAccepted - weather the address has accepted the specific version of the terms or not
    function hasAcceptedTerms(
        address _token,
        address _address,
        uint8 _termsVersion
    ) external view returns (bool hasAccepted) {
        TermsDataTypes.Terms storage termsData = terms[_token];
        hasAccepted = termsData.termsAccepted[_address] && termsData.acceptedVersion[_address] == _termsVersion;
    }

    /// @notice activates the terms
    function _activateTerms(TermsDataTypes.Terms storage termsData, address _token) internal {
        if (bytes(termsData.termsURI).length == 0) revert ITermsErrorsV0.TermsURINotSetForToken(_token);
        if (termsData.termsActivated) revert ITermsErrorsV0.TermsStatusAlreadySetForToken(_token);
        termsData.termsActivated = true;
    }

    /// @notice deactivates the terms
    function _deactivateTerms(TermsDataTypes.Terms storage termsData, address _token) internal {
        if (!termsData.termsActivated) revert ITermsErrorsV0.TermsStatusAlreadySetForToken(_token);
        termsData.termsActivated = false;
    }

    /// @notice accepts the terms.
    function _acceptTerms(TermsDataTypes.Terms storage termsData, address _acceptor) internal {
        termsData.termsAccepted[_acceptor] = true;
        termsData.acceptedVersion[_acceptor] = termsData.termsVersion;
    }

    /// @notice checks if the terms can be accepted
    function _canAcceptTerms(
        TermsDataTypes.Terms storage termsData,
        address _token,
        address _acceptor
    ) internal view {
        if (!termsData.termsActivated) revert ITermsErrorsV0.TermsNotActivatedForToken(_token);
        if (termsData.termsAccepted[_acceptor] && termsData.acceptedVersion[_acceptor] == termsData.termsVersion)
            revert ITermsErrorsV0.TermsAlreadyAcceptedForToken(_token, termsData.termsVersion);
    }

    /// @notice verifies a signature
    /// @dev this function takes the signers address and the signature signed with their private key.
    ///     ECDSA checks whether a hash of the message was signed by the user's private key.
    ////    If yes, the _to address == ECDSA's returned address
    function _verifySignature(
        TermsDataTypes.Terms storage termsData,
        address _acceptor,
        bytes memory _signature
    ) internal view returns (bool) {
        if (_signature.length == 0) return false;
        bytes32 hash = _hashMessage(termsData, _acceptor);
        address signer = ECDSAUpgradeable.recover(hash, _signature);
        return signer == _acceptor;
    }

    /// @dev this function hashes the terms url and message
    function _hashMessage(TermsDataTypes.Terms storage termsData, address _acceptor) private view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(MESSAGE_HASH, _acceptor, keccak256(bytes(termsData.termsURI)), termsData.termsVersion)
                )
            );
    }

    /// ================================
    /// ======== Miscellaneous =========
    /// ================================
    /// @dev Provides a function to batch together multiple calls in a single external call.
    function multicall(bytes[] calldata data) external override(IMulticallableV0) returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = _functionDelegateCallForMulticall(address(this), data[i]);
        }
        return results;
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCallForMulticall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    // Concrete implementation semantic version - provided for completeness but not designed to be the point of dispatch
    function minorVersion() public pure virtual override returns (uint256 minor, uint256 patch) {
        minor = 0;
        patch = 0;
    }
}