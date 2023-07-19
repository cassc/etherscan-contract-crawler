// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {RequestBuilder, SismoConnectRequest, SismoConnectResponse, SismoConnectConfig} from "../utils/RequestBuilder.sol";
import {AuthRequestBuilder, AuthRequest, Auth, VerifiedAuth, AuthType} from "../utils/AuthRequestBuilder.sol";
import {ClaimRequestBuilder, ClaimRequest, Claim, VerifiedClaim, ClaimType} from "../utils/ClaimRequestBuilder.sol";
import {SignatureBuilder, SignatureRequest, Signature} from "../utils/SignatureBuilder.sol";
import {VaultConfig} from "../utils/Structs.sol";
import {ISismoConnectVerifier, SismoConnectVerifiedResult} from "../../interfaces/ISismoConnectVerifier.sol";
import {IAddressesProvider} from "../../periphery/interfaces/IAddressesProvider.sol";
import {SismoConnectHelper} from "../utils/SismoConnectHelper.sol";
import {IHydraS3Verifier} from "../../verifiers/IHydraS3Verifier.sol";

contract SismoConnect {
  uint256 public constant SISMO_CONNECT_LIB_VERSION = 2;

  IAddressesProvider public constant ADDRESSES_PROVIDER_V2 =
    IAddressesProvider(0x3Cd5334eB64ebBd4003b72022CC25465f1BFcEe6);

  ISismoConnectVerifier immutable _sismoConnectVerifier;

  // external libraries
  AuthRequestBuilder immutable _authRequestBuilder;
  ClaimRequestBuilder immutable _claimRequestBuilder;
  SignatureBuilder immutable _signatureBuilder;
  RequestBuilder immutable _requestBuilder;

  // config
  bytes16 public immutable APP_ID;
  bool public immutable IS_IMPERSONATION_MODE;

  constructor(SismoConnectConfig memory _config) {
    APP_ID = _config.appId;
    IS_IMPERSONATION_MODE = _config.vault.isImpersonationMode;

    _sismoConnectVerifier = ISismoConnectVerifier(
      ADDRESSES_PROVIDER_V2.get(string("sismoConnectVerifier-v1.1"))
    );
    // external libraries
    _authRequestBuilder = AuthRequestBuilder(
      ADDRESSES_PROVIDER_V2.get(string("authRequestBuilder-v1.1"))
    );
    _claimRequestBuilder = ClaimRequestBuilder(
      ADDRESSES_PROVIDER_V2.get(string("claimRequestBuilder-v1.1"))
    );
    _signatureBuilder = SignatureBuilder(
      ADDRESSES_PROVIDER_V2.get(string("signatureBuilder-v1.1"))
    );
    _requestBuilder = RequestBuilder(ADDRESSES_PROVIDER_V2.get(string("requestBuilder-v1.1")));
  }

  // public function because it needs to be used by this contract and can be used by other contracts
  function config() public view returns (SismoConnectConfig memory) {
    return buildConfig(APP_ID, IS_IMPERSONATION_MODE);
  }

  function buildConfig(bytes16 appId) internal pure returns (SismoConnectConfig memory) {
    return SismoConnectConfig({appId: appId, vault: buildVaultConfig()});
  }

  function buildConfig(
    bytes16 appId,
    bool isImpersonationMode
  ) internal pure returns (SismoConnectConfig memory) {
    return SismoConnectConfig({appId: appId, vault: buildVaultConfig(isImpersonationMode)});
  }

  function buildVaultConfig() internal pure returns (VaultConfig memory) {
    return VaultConfig({isImpersonationMode: false});
  }

  function buildVaultConfig(bool isImpersonationMode) internal pure returns (VaultConfig memory) {
    return VaultConfig({isImpersonationMode: isImpersonationMode});
  }

  function verify(
    bytes memory responseBytes,
    AuthRequest memory auth,
    ClaimRequest memory claim,
    SignatureRequest memory signature,
    bytes16 namespace
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(auth, claim, signature, namespace);
    return _sismoConnectVerifier.verify(response, request, config());
  }

  function verify(
    bytes memory responseBytes,
    AuthRequest memory auth,
    ClaimRequest memory claim,
    bytes16 namespace
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(auth, claim, namespace);
    return _sismoConnectVerifier.verify(response, request, config());
  }

  function verify(
    bytes memory responseBytes,
    AuthRequest memory auth,
    SignatureRequest memory signature,
    bytes16 namespace
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(auth, signature, namespace);
    return _sismoConnectVerifier.verify(response, request, config());
  }

  function verify(
    bytes memory responseBytes,
    ClaimRequest memory claim,
    SignatureRequest memory signature,
    bytes16 namespace
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(claim, signature, namespace);
    return _sismoConnectVerifier.verify(response, request, config());
  }

  function verify(
    bytes memory responseBytes,
    AuthRequest memory auth,
    bytes16 namespace
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(auth, namespace);
    return _sismoConnectVerifier.verify(response, request, config());
  }

  function verify(
    bytes memory responseBytes,
    ClaimRequest memory claim,
    bytes16 namespace
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(claim, namespace);
    return _sismoConnectVerifier.verify(response, request, config());
  }

  function verify(
    bytes memory responseBytes,
    AuthRequest memory auth,
    ClaimRequest memory claim,
    SignatureRequest memory signature
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(auth, claim, signature);
    return _sismoConnectVerifier.verify(response, request, config());
  }

  function verify(
    bytes memory responseBytes,
    AuthRequest memory auth,
    ClaimRequest memory claim
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(auth, claim);
    return _sismoConnectVerifier.verify(response, request, config());
  }

  function verify(
    bytes memory responseBytes,
    AuthRequest memory auth,
    SignatureRequest memory signature
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(auth, signature);
    return _sismoConnectVerifier.verify(response, request, config());
  }

  function verify(
    bytes memory responseBytes,
    ClaimRequest memory claim,
    SignatureRequest memory signature
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(claim, signature);
    return _sismoConnectVerifier.verify(response, request, config());
  }

  function verify(
    bytes memory responseBytes,
    AuthRequest memory auth
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(auth);
    return _sismoConnectVerifier.verify(response, request, config());
  }

  function verify(
    bytes memory responseBytes,
    ClaimRequest memory claim
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(claim);
    return _sismoConnectVerifier.verify(response, request, config());
  }

  function verify(
    bytes memory responseBytes,
    SismoConnectRequest memory request
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    return _sismoConnectVerifier.verify(response, request, config());
  }

  function verify(
    bytes memory responseBytes,
    AuthRequest[] memory auths,
    ClaimRequest[] memory claims,
    SignatureRequest memory signature,
    bytes16 namespace
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(auths, claims, signature, namespace);
    return _sismoConnectVerifier.verify(response, request, config());
  }

  function verify(
    bytes memory responseBytes,
    AuthRequest[] memory auths,
    ClaimRequest[] memory claims,
    bytes16 namespace
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(auths, claims, namespace);
    return _sismoConnectVerifier.verify(response, request, config());
  }

  function verify(
    bytes memory responseBytes,
    AuthRequest[] memory auths,
    SignatureRequest memory signature,
    bytes16 namespace
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(auths, signature, namespace);
    return _sismoConnectVerifier.verify(response, request, config());
  }

  function verify(
    bytes memory responseBytes,
    ClaimRequest[] memory claims,
    SignatureRequest memory signature,
    bytes16 namespace
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(claims, signature, namespace);
    return _sismoConnectVerifier.verify(response, request, config());
  }

  function verify(
    bytes memory responseBytes,
    AuthRequest[] memory auths,
    bytes16 namespace
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(auths, namespace);
    return _sismoConnectVerifier.verify(response, request, config());
  }

  function verify(
    bytes memory responseBytes,
    ClaimRequest[] memory claims,
    bytes16 namespace
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(claims, namespace);
    return _sismoConnectVerifier.verify(response, request, config());
  }

  function verify(
    bytes memory responseBytes,
    AuthRequest[] memory auths,
    ClaimRequest[] memory claims,
    SignatureRequest memory signature
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(auths, claims, signature);
    return _sismoConnectVerifier.verify(response, request, config());
  }

  function verify(
    bytes memory responseBytes,
    AuthRequest[] memory auths,
    ClaimRequest[] memory claims
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(auths, claims);
    return _sismoConnectVerifier.verify(response, request, config());
  }

  function verify(
    bytes memory responseBytes,
    AuthRequest[] memory auths,
    SignatureRequest memory signature
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(auths, signature);
    return _sismoConnectVerifier.verify(response, request, config());
  }

  function verify(
    bytes memory responseBytes,
    ClaimRequest[] memory claims,
    SignatureRequest memory signature
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(claims, signature);
    return _sismoConnectVerifier.verify(response, request, config());
  }

  function verify(
    bytes memory responseBytes,
    AuthRequest[] memory auths
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(auths);
    return _sismoConnectVerifier.verify(response, request, config());
  }

  function verify(
    bytes memory responseBytes,
    ClaimRequest[] memory claims
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(claims);
    return _sismoConnectVerifier.verify(response, request, config());
  }

  function buildClaim(
    bytes16 groupId,
    bytes16 groupTimestamp,
    uint256 value,
    ClaimType claimType,
    bytes memory extraData
  ) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId, groupTimestamp, value, claimType, extraData);
  }

  function buildClaim(bytes16 groupId) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId);
  }

  function buildClaim(
    bytes16 groupId,
    bytes16 groupTimestamp
  ) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId, groupTimestamp);
  }

  function buildClaim(bytes16 groupId, uint256 value) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId, value);
  }

  function buildClaim(
    bytes16 groupId,
    ClaimType claimType
  ) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId, claimType);
  }

  function buildClaim(
    bytes16 groupId,
    bytes memory extraData
  ) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId, extraData);
  }

  function buildClaim(
    bytes16 groupId,
    bytes16 groupTimestamp,
    uint256 value
  ) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId, groupTimestamp, value);
  }

  function buildClaim(
    bytes16 groupId,
    bytes16 groupTimestamp,
    ClaimType claimType
  ) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId, groupTimestamp, claimType);
  }

  function buildClaim(
    bytes16 groupId,
    bytes16 groupTimestamp,
    bytes memory extraData
  ) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId, groupTimestamp, extraData);
  }

  function buildClaim(
    bytes16 groupId,
    uint256 value,
    ClaimType claimType
  ) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId, value, claimType);
  }

  function buildClaim(
    bytes16 groupId,
    uint256 value,
    bytes memory extraData
  ) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId, value, extraData);
  }

  function buildClaim(
    bytes16 groupId,
    ClaimType claimType,
    bytes memory extraData
  ) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId, claimType, extraData);
  }

  function buildClaim(
    bytes16 groupId,
    bytes16 groupTimestamp,
    uint256 value,
    ClaimType claimType
  ) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId, groupTimestamp, value, claimType);
  }

  function buildClaim(
    bytes16 groupId,
    bytes16 groupTimestamp,
    uint256 value,
    bytes memory extraData
  ) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId, groupTimestamp, value, extraData);
  }

  function buildClaim(
    bytes16 groupId,
    bytes16 groupTimestamp,
    ClaimType claimType,
    bytes memory extraData
  ) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId, groupTimestamp, claimType, extraData);
  }

  function buildClaim(
    bytes16 groupId,
    uint256 value,
    ClaimType claimType,
    bytes memory extraData
  ) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId, value, claimType, extraData);
  }

  function buildClaim(
    bytes16 groupId,
    bool isOptional,
    bool isSelectableByUser
  ) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId, isOptional, isSelectableByUser);
  }

  function buildClaim(
    bytes16 groupId,
    bytes16 groupTimestamp,
    bool isOptional,
    bool isSelectableByUser
  ) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId, groupTimestamp, isOptional, isSelectableByUser);
  }

  function buildClaim(
    bytes16 groupId,
    uint256 value,
    bool isOptional,
    bool isSelectableByUser
  ) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId, value, isOptional, isSelectableByUser);
  }

  function buildClaim(
    bytes16 groupId,
    ClaimType claimType,
    bool isOptional,
    bool isSelectableByUser
  ) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId, claimType, isOptional, isSelectableByUser);
  }

  function buildClaim(
    bytes16 groupId,
    bytes16 groupTimestamp,
    uint256 value,
    bool isOptional,
    bool isSelectableByUser
  ) internal view returns (ClaimRequest memory) {
    return
      _claimRequestBuilder.build(groupId, groupTimestamp, value, isOptional, isSelectableByUser);
  }

  function buildClaim(
    bytes16 groupId,
    bytes16 groupTimestamp,
    ClaimType claimType,
    bool isOptional,
    bool isSelectableByUser
  ) internal view returns (ClaimRequest memory) {
    return
      _claimRequestBuilder.build(
        groupId,
        groupTimestamp,
        claimType,
        isOptional,
        isSelectableByUser
      );
  }

  function buildClaim(
    bytes16 groupId,
    uint256 value,
    ClaimType claimType,
    bool isOptional,
    bool isSelectableByUser
  ) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId, value, claimType, isOptional, isSelectableByUser);
  }

  function buildClaim(
    bytes16 groupId,
    bytes16 groupTimestamp,
    uint256 value,
    ClaimType claimType,
    bool isOptional,
    bool isSelectableByUser
  ) internal view returns (ClaimRequest memory) {
    return
      _claimRequestBuilder.build(
        groupId,
        groupTimestamp,
        value,
        claimType,
        isOptional,
        isSelectableByUser
      );
  }

  function buildAuth(
    AuthType authType,
    bool isAnon,
    uint256 userId,
    bytes memory extraData
  ) internal view returns (AuthRequest memory) {
    return _authRequestBuilder.build(authType, isAnon, userId, extraData);
  }

  function buildAuth(AuthType authType) internal view returns (AuthRequest memory) {
    return _authRequestBuilder.build(authType);
  }

  function buildAuth(AuthType authType, bool isAnon) internal view returns (AuthRequest memory) {
    return _authRequestBuilder.build(authType, isAnon);
  }

  function buildAuth(AuthType authType, uint256 userId) internal view returns (AuthRequest memory) {
    return _authRequestBuilder.build(authType, userId);
  }

  function buildAuth(
    AuthType authType,
    bytes memory extraData
  ) internal view returns (AuthRequest memory) {
    return _authRequestBuilder.build(authType, extraData);
  }

  function buildAuth(
    AuthType authType,
    bool isAnon,
    uint256 userId
  ) internal view returns (AuthRequest memory) {
    return _authRequestBuilder.build(authType, isAnon, userId);
  }

  function buildAuth(
    AuthType authType,
    bool isAnon,
    bytes memory extraData
  ) internal view returns (AuthRequest memory) {
    return _authRequestBuilder.build(authType, isAnon, extraData);
  }

  function buildAuth(
    AuthType authType,
    uint256 userId,
    bytes memory extraData
  ) internal view returns (AuthRequest memory) {
    return _authRequestBuilder.build(authType, userId, extraData);
  }

  function buildAuth(
    AuthType authType,
    bool isOptional,
    bool isSelectableByUser
  ) internal view returns (AuthRequest memory) {
    return _authRequestBuilder.build(authType, isOptional, isSelectableByUser);
  }

  function buildAuth(
    AuthType authType,
    bool isOptional,
    bool isSelectableByUser,
    uint256 userId
  ) internal view returns (AuthRequest memory) {
    return _authRequestBuilder.build(authType, isOptional, isSelectableByUser, userId);
  }

  function buildAuth(
    AuthType authType,
    bool isAnon,
    bool isOptional,
    bool isSelectableByUser
  ) internal view returns (AuthRequest memory) {
    return _authRequestBuilder.build(authType, isAnon, isOptional, isSelectableByUser);
  }

  function buildAuth(
    AuthType authType,
    uint256 userId,
    bool isOptional
  ) internal view returns (AuthRequest memory) {
    return _authRequestBuilder.build(authType, userId, isOptional);
  }

  function buildAuth(
    AuthType authType,
    bool isAnon,
    uint256 userId,
    bool isOptional
  ) internal view returns (AuthRequest memory) {
    return _authRequestBuilder.build(authType, isAnon, userId, isOptional);
  }

  function buildSignature(bytes memory message) internal view returns (SignatureRequest memory) {
    return _signatureBuilder.build(message);
  }

  function buildSignature(
    bytes memory message,
    bool isSelectableByUser
  ) internal view returns (SignatureRequest memory) {
    return _signatureBuilder.build(message, isSelectableByUser);
  }

  function buildSignature(
    bytes memory message,
    bytes memory extraData
  ) external view returns (SignatureRequest memory) {
    return _signatureBuilder.build(message, extraData);
  }

  function buildSignature(
    bytes memory message,
    bool isSelectableByUser,
    bytes memory extraData
  ) external view returns (SignatureRequest memory) {
    return _signatureBuilder.build(message, isSelectableByUser, extraData);
  }

  function buildSignature(bool isSelectableByUser) external view returns (SignatureRequest memory) {
    return _signatureBuilder.build(isSelectableByUser);
  }

  function buildSignature(
    bool isSelectableByUser,
    bytes memory extraData
  ) external view returns (SignatureRequest memory) {
    return _signatureBuilder.build(isSelectableByUser, extraData);
  }

  function buildRequest(
    AuthRequest memory auth,
    ClaimRequest memory claim,
    SignatureRequest memory signature
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(auth, claim, signature);
  }

  function buildRequest(
    AuthRequest memory auth,
    ClaimRequest memory claim
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(auth, claim, _GET_EMPTY_SIGNATURE_REQUEST());
  }

  function buildRequest(
    ClaimRequest memory claim,
    SignatureRequest memory signature
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(claim, signature);
  }

  function buildRequest(
    AuthRequest memory auth,
    SignatureRequest memory signature
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(auth, signature);
  }

  function buildRequest(
    ClaimRequest memory claim
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(claim, _GET_EMPTY_SIGNATURE_REQUEST());
  }

  function buildRequest(
    AuthRequest memory auth
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(auth, _GET_EMPTY_SIGNATURE_REQUEST());
  }

  function buildRequest(
    AuthRequest memory auth,
    ClaimRequest memory claim,
    SignatureRequest memory signature,
    bytes16 namespace
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(auth, claim, signature, namespace);
  }

  function buildRequest(
    AuthRequest memory auth,
    ClaimRequest memory claim,
    bytes16 namespace
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(auth, claim, _GET_EMPTY_SIGNATURE_REQUEST(), namespace);
  }

  function buildRequest(
    ClaimRequest memory claim,
    SignatureRequest memory signature,
    bytes16 namespace
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(claim, signature, namespace);
  }

  function buildRequest(
    AuthRequest memory auth,
    SignatureRequest memory signature,
    bytes16 namespace
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(auth, signature, namespace);
  }

  function buildRequest(
    ClaimRequest memory claim,
    bytes16 namespace
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(claim, _GET_EMPTY_SIGNATURE_REQUEST(), namespace);
  }

  function buildRequest(
    AuthRequest memory auth,
    bytes16 namespace
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(auth, _GET_EMPTY_SIGNATURE_REQUEST(), namespace);
  }

  function buildRequest(
    AuthRequest[] memory auths,
    ClaimRequest[] memory claims,
    SignatureRequest memory signature
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(auths, claims, signature);
  }

  function buildRequest(
    AuthRequest[] memory auths,
    ClaimRequest[] memory claims
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(auths, claims, _GET_EMPTY_SIGNATURE_REQUEST());
  }

  function buildRequest(
    ClaimRequest[] memory claims,
    SignatureRequest memory signature
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(claims, signature);
  }

  function buildRequest(
    AuthRequest[] memory auths,
    SignatureRequest memory signature
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(auths, signature);
  }

  function buildRequest(
    ClaimRequest[] memory claims
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(claims, _GET_EMPTY_SIGNATURE_REQUEST());
  }

  function buildRequest(
    AuthRequest[] memory auths
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(auths, _GET_EMPTY_SIGNATURE_REQUEST());
  }

  function buildRequest(
    AuthRequest[] memory auths,
    ClaimRequest[] memory claims,
    SignatureRequest memory signature,
    bytes16 namespace
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(auths, claims, signature, namespace);
  }

  function buildRequest(
    AuthRequest[] memory auths,
    ClaimRequest[] memory claims,
    bytes16 namespace
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(auths, claims, _GET_EMPTY_SIGNATURE_REQUEST(), namespace);
  }

  function buildRequest(
    ClaimRequest[] memory claims,
    SignatureRequest memory signature,
    bytes16 namespace
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(claims, signature, namespace);
  }

  function buildRequest(
    AuthRequest[] memory auths,
    SignatureRequest memory signature,
    bytes16 namespace
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(auths, signature, namespace);
  }

  function buildRequest(
    ClaimRequest[] memory claims,
    bytes16 namespace
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(claims, _GET_EMPTY_SIGNATURE_REQUEST(), namespace);
  }

  function buildRequest(
    AuthRequest[] memory auths,
    bytes16 namespace
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(auths, _GET_EMPTY_SIGNATURE_REQUEST(), namespace);
  }

  function _GET_EMPTY_SIGNATURE_REQUEST() internal view returns (SignatureRequest memory) {
    return _signatureBuilder.buildEmpty();
  }
}