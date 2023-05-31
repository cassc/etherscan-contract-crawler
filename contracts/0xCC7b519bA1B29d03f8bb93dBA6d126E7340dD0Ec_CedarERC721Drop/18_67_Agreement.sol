// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.7;

import "./SignatureVerifier.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./api/agreement/ICedarAgreement.sol";

abstract contract Agreement is Initializable, ICedarAgreementV0 {
    string public override userAgreement;
    mapping(address => bool) termsAccepted;
    bool public override termsActivated;
    SignatureVerifier public verifier;
    string public ownerDomain;

    event TermsActive(bool status);
    event AcceptTerms(string userAgreement, address user);

    function __Agreement_init(string memory _userAgreement, address _signatureVerifier) internal onlyInitializing {
        userAgreement = _userAgreement;
        verifier = SignatureVerifier(_signatureVerifier);
    }

    /// @notice activates the terms
    /// @dev this function activates the user terms
    function _setTermsStatus(bool _status) internal virtual {
        termsActivated = _status;
        emit TermsActive(_status);
    }

    /// @notice by signing this transaction, you are confirming that you have read and agreed to the terms of use at `ownerDomain`
    /// @dev this function is called by token receivers to accept the terms before token transfer. The contract stores their acceptance
    function acceptTerms() override external {
        require(termsActivated, "ERC721Cedar: terms not activated");
        termsAccepted[msg.sender] = true;
        emit AcceptTerms(userAgreement, msg.sender);
    }

    /// @notice stores terms accepted from a signed message
    /// @dev this function is for acceptors that have signed a message offchain to accept the terms. The function calls the verifier contract to valid the signature before storing acceptance.
    function _storeTermsAccepted(address _acceptor, bytes calldata _signature) internal virtual {
        require(termsActivated, "ERC721Cedar: terms not activated");
        require(verifier.verifySignature(_acceptor, _signature), "ERC721Cedar: signature cannot be verified");
        termsAccepted[_acceptor] = true;
        emit AcceptTerms(userAgreement, _acceptor);
    }

    /// @notice checks whether an account signed the terms
    /// @dev this function calls the signature verifier to check whether the terms were accepted by an EOA.
    function checkSignature(address _account, bytes calldata _signature) external view returns (bool) {
        return verifier.verifySignature(_account, _signature);
    }

    /// @notice returns true / false for whether the account owner accepted terms
    /// @dev this function returns true / false for whether the account accepted the terms.
    function getAgreementStatus(address _address) external override view returns (bool sig) {
        return termsAccepted[_address];
    }

    function _setOwnerDomain(string calldata _ownerDomain) internal virtual {
        ownerDomain = _ownerDomain;
    }
}