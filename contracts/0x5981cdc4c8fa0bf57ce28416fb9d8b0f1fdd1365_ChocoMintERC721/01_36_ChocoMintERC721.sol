// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../utils/MintERC721Lib.sol";
import "../utils/SecurityLib.sol";

import "./ChocoMintERC721Base.sol";

contract ChocoMintERC721 is IChocoMintERC721, ChocoMintERC721Base {
  constructor(
    string memory name,
    string memory version,
    string memory symbol,
    address trustedForwarder,
    address[] memory defaultApprovals
  ) {
    initialize(name, version, symbol, trustedForwarder, defaultApprovals);
  }

  function mint(MintERC721Lib.MintERC721Data memory mintERC721Data, SignatureLib.SignatureData memory signatureData)
    external
    override
  {
    bytes32 mintERC721Hash = MintERC721Lib.hashStruct(mintERC721Data);
    (bool isSignatureValid, string memory signatureErrorMessage) = _validateTx(
      mintERC721Data.minter,
      mintERC721Hash,
      signatureData
    );
    require(isSignatureValid, signatureErrorMessage);

    _mint(mintERC721Hash, mintERC721Data);
  }

  function isMinted(uint256 tokenId) external view override returns (bool) {
    return _exists(tokenId);
  }

  function _mint(bytes32 mintERC721Hash, MintERC721Lib.MintERC721Data memory mintERC721Data) internal {
    (bool isValid, string memory errorMessage) = _validate(mintERC721Data);
    require(isValid, errorMessage);
    _revokeHash(mintERC721Hash);
    super._mint(mintERC721Data.to, mintERC721Data.tokenId);
    if (mintERC721Data.data.length > 0) {
      (
        string memory tokenStaticURI,
        bool tokenStaticURIFreezing,
        RoyaltyLib.RoyaltyData memory tokenRoyaltyData,
        bool tokenRoyaltyFreezing
      ) = abi.decode(mintERC721Data.data, (string, bool, RoyaltyLib.RoyaltyData, bool));
      if (bytes(tokenStaticURI).length > 0) {
        _setTokenStaticURI(mintERC721Data.tokenId, tokenStaticURI, tokenStaticURIFreezing);
      }
      if (RoyaltyLib.isNotNull(tokenRoyaltyData)) {
        _setTokenRoyalty(mintERC721Data.tokenId, tokenRoyaltyData, tokenRoyaltyFreezing);
      }
    }
    emit Minted(mintERC721Hash);
  }

  function _validate(MintERC721Lib.MintERC721Data memory mintERC721Data) internal view returns (bool, string memory) {
    (bool isMinterValid, string memory minterErrorMessage) = _validateAdminOrOwner(mintERC721Data.minter);
    if (!isMinterValid) {
      return (false, minterErrorMessage);
    }
    (bool isSecurityDataValid, string memory securityDataErrorMessage) = SecurityLib.validate(
      mintERC721Data.securityData
    );
    if (!isSecurityDataValid) {
      return (false, securityDataErrorMessage);
    }

    return (true, "");
  }

  // solhint-disable-next-line ordering
  uint256[50] private __gap;
}