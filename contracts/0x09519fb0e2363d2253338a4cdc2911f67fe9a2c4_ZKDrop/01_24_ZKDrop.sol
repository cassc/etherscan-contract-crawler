// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "sismo-connect-solidity/SismoLib.sol";
import {ERC721} from "openzeppelin/token/ERC721/ERC721.sol";
import {Ownable} from "openzeppelin/access/Ownable.sol";

/**
 * @title ZKDrop
 * @author Sismo
 * @notice Gated ERC721 token minting contract thanks to Sismo Connect
 */
contract ZKDrop is ERC721, SismoConnect, Ownable {
  using SismoConnectHelper for SismoConnectVerifiedResult;

  struct Requests {
    AuthRequest[] auths;
    ClaimRequest[] claims;
  }

  bool public immutable IS_TRANSFERABLE;

  string private _baseTokenURI;
  Requests private _requests;

  error ERC721NonTransferable();
  event BaseTokenURISet(string baseTokenURI);

  /**
   * @dev Sets all the parameters of the ERC721 token and all requirements to mint it thanks to Sismo Connect
   * @param name_ name of the ERC721 token
   * @param symbol_ symbol of the ERC721 token
   * @param baseURI_ base URI of the ERC721 token
   * @param appId_  id of the Sismo Connect App from which the proofs are required
   * @param isImpersonationMode_ if True, the ERC721 token can be minted thanks to impersonated proofs
   * @param authRequests_ list of dataSource ownerships required to mint the ERC721 token
   * @param claimRequests_ list of group memberships required to mint the ERC721 token
   * @param owner_ owner of this ZKDrop contract
   * @param isTransferable_ if False, the ERC721 token can NOT be transferred
   */
  constructor(
    string memory name_,
    string memory symbol_,
    string memory baseURI_,
    bytes16 appId_,
    bool isImpersonationMode_,
    AuthRequest[] memory authRequests_,
    ClaimRequest[] memory claimRequests_,
    address owner_,
    bool isTransferable_
  ) ERC721(name_, symbol_) SismoConnect(buildConfig(appId_, isImpersonationMode_)) {
    _transferOwnership(owner_);
    _setBaseTokenUri(baseURI_);
    _setAuths(authRequests_);
    _setClaims(claimRequests_);
    IS_TRANSFERABLE = isTransferable_;
  }

  /**
   * @dev Mints an ERC721 token to the given address if the Sismo Connect Response contains valid proofs
   * The tokenId of the ERC721 token is the vaultId of the Sismo Connect Response
   * The vaultId is the anonymous identifier of a user's vault for a specific app
   * VaultId = hash(userVaultSecret, appId)
   * The vaultId is used to prevent double spending of an ERC721 token for a specific appId
   * @param responseBytes Response from Sismo Connect in a bytes format
   * @param to Address of the receiver of the ERC721 token
   */
  function claimWithSismoConnect(bytes memory responseBytes, address to) external {
    SismoConnectVerifiedResult memory result = verify({
      responseBytes: responseBytes,
      auths: _requests.auths,
      claims: _requests.claims,
      signature: buildSignature({message: abi.encode(to)})
    });

    uint256 tokenId = result.getUserId(AuthType.VAULT);
    _mint(to, tokenId);
  }

  /**
   * @dev Returns the list of all requests required to mint the ERC721 token
   */
  function getRequests() external view returns (Requests memory) {
    Requests memory requests = _requests;
    return requests;
  }

  /**
   * @dev Sets the base URI of the ERC721 token
   */
  function setBaseTokenUri(string memory baseUri) external onlyOwner {
    _setBaseTokenUri(baseUri);
  }

  /**
   * @dev Returns the base URI of the ERC721 token
   */
  function tokenURI(uint256) public view override returns (string memory) {
    return _baseTokenURI;
  }

  /**
   * @dev Sets the list of dataSource ownerships required to mint the ERC721 token
   */
  function _setAuths(AuthRequest[] memory auths_) private {
    for (uint256 i = 0; i < auths_.length; i++) {
      _requests.auths.push(auths_[i]);
    }
  }

  /**
   * @dev Sets the list of group memberships required to mint the ERC721 token
   */
  function _setClaims(ClaimRequest[] memory claims_) private {
    for (uint256 i = 0; i < claims_.length; i++) {
      _requests.claims.push(claims_[i]);
    }
  }

  /**
   * @dev Sets the base URI of the ERC721 token
   */
  function _setBaseTokenUri(string memory baseUri) private {
    _baseTokenURI = baseUri;
    emit BaseTokenURISet(baseUri);
  }

  /**
   * @dev Overrides the transfer function of the ERC721 token
   * If the ERC721 token is not transferable, the transfer function reverts
   * Otherwise, the transfer function is executed
   * The _transfer function is used in transferFrom, safeTransferFrom and safeTransferFrom with data parameter
   * @param from Address of the sender of the ERC721 token
   * @param to Address of the receiver of the ERC721 token
   * @param tokenId Id of the ERC721 token
   */
  function _transfer(address from, address to, uint256 tokenId) internal virtual override {
    if (!IS_TRANSFERABLE) {
      revert ERC721NonTransferable();
    }
    ERC721._transfer(from, to, tokenId);
  }
}