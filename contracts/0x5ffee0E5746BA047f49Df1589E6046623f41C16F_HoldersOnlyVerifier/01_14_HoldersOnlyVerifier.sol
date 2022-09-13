// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

interface IIdentityVerifier is IERC165 {
    function verify(uint40 listingId, address identity, address tokenAddress, uint256 tokenId, uint24 requestCount, uint256 requestAmount, address requestERC20, bytes calldata data) external returns (bool);
}

// Verifies ownership of a 721 token address
contract HoldersOnlyVerifier is AdminControl, IIdentityVerifier {

    struct Token {
      address contractAddress;
    }

    struct HolderRule {
      Token[] tokens;
      bool and; // true if they must hold all ("and"), false if they must hold one ("or")
    }

    // Mapping of listing ID to holder rule
    mapping(uint => HolderRule) _holderRules;

    function configure(uint listingId, HolderRule calldata holderRules) public adminRequired {
      _holderRules[listingId] = holderRules;
    }

    function passesHolderRule(uint listingId, address holder) public view returns (bool) {
      HolderRule storage rule = _holderRules[listingId];

      bool passesRule = false;

      if (rule.and) {
        uint rulePassing = 0;
        for (uint i; i < rule.tokens.length; i++) {
          if (IERC721(rule.tokens[i].contractAddress).balanceOf(holder) > 0) {
            rulePassing++;
          }
        }
        passesRule = rulePassing == rule.tokens.length;
      } else {
        for (uint i; i < rule.tokens.length; i++) {
          if (IERC721(rule.tokens[i].contractAddress).balanceOf(holder) > 0) {
            passesRule = true;
          }
        }
      }


      return passesRule;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, IERC165) returns (bool) {
        return interfaceId == type(IIdentityVerifier).interfaceId || super.supportsInterface(interfaceId);
    }

    function verify(uint40 listingId, address identity, address, uint256, uint24, uint256, address, bytes calldata) external view override returns (bool) {
        return passesHolderRule(listingId, identity);
    }

    function verifyView(uint40 listingId, address identity, address, uint256, uint24, uint256, address, bytes calldata) external view returns (bool) {
        return passesHolderRule(listingId, identity);
    }
}