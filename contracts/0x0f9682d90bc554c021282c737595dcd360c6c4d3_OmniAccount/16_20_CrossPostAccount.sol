// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.9;

import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721} from "@solmate/tokens/ERC721.sol";
import {SignatureChecker} from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

contract CrossPostAccount is Pausable, Ownable {
  address public OMNI_ORACLE_SIGNER;

  address internal constant OPENSEA_OPERATOR = 0x1E0049783F008A0085193E00003D00cd54003c71; // Mainnet, Goerli

  address internal constant BLUR_MAINNET_OPERATOR = 0x00000000000111AbE46ff893f3B2fdF1F759a8A8;

  address internal constant X2Y2_MAINNET_OPERATOR = 0xF849de01B080aDC3A814FaBE1E2087475cF2E354;
  address internal constant X2Y2_GOERLI_OPERATOR = 0x095be13D86000260852E4F92eA48dc333fa35249;

  address internal constant LOOKSRARE_MAINNET_721_OPERATOR = 0xf42aa99F011A1fA7CDA90E5E98b277E306BcA83e;
  address internal constant LOOKSRARE_MAINNET_1155_OPERATOR = 0xFED24eC7E22f573c2e08AEF55aA6797Ca2b3A051;
  address internal constant LOOKSRARE_GOERLI_721_OPERATOR = 0xF8C81f3ae82b6EFC9154c69E3db57fD4da57aB6E;
  address internal constant LOOKSRARE_GOERLI_1155_OPERATOR = 0xF2ae42e871937F4e9ffb394C5A814357C16e06d6;

  error InvalidMarketplaceOperator();
  error InvalidNetwork();

  struct MarketplaceApprovals {
    address marketplaceOperator;
    address collection;
  }

  function setApprovalForMarketplaces(MarketplaceApprovals[] calldata collectionsToApprove, bool approve) public {
    for (uint256 i; i < collectionsToApprove.length; ) {
      ERC721 collection = ERC721(collectionsToApprove[i].collection);
      address operator = collectionsToApprove[i].marketplaceOperator;

      _checkOperator(operator);

      collection.setApprovalForAll(operator, approve);

      unchecked {
        ++i;
      }
    }
  }

  function _checkOperator(address operator) internal view {
    if (block.chainid != 1 && block.chainid != 5) {
      revert InvalidNetwork();
    } 
    
    if (
      block.chainid == 1 &&
      !(operator == OPENSEA_OPERATOR ||
        operator == BLUR_MAINNET_OPERATOR ||
        operator == X2Y2_MAINNET_OPERATOR ||
        operator == LOOKSRARE_MAINNET_721_OPERATOR ||
        operator == LOOKSRARE_MAINNET_1155_OPERATOR)
    ) {
      revert InvalidMarketplaceOperator();
    } 
    
    if (
      block.chainid == 5 &&
      !(operator == OPENSEA_OPERATOR ||
        operator == X2Y2_GOERLI_OPERATOR ||
        operator == LOOKSRARE_GOERLI_721_OPERATOR ||
        operator == LOOKSRARE_GOERLI_1155_OPERATOR)
    ) {
      revert InvalidMarketplaceOperator();
    }
  }

  function setOmniOracleSigner(address newSigner) public onlyOwner {
    OMNI_ORACLE_SIGNER = newSigner;
  }

  function isValidSignature(bytes32 hash, bytes memory signature)
    public
    view
    whenNotPaused
    returns (bytes4 magicValue)
  {
    if (
      SignatureChecker.isValidSignatureNow(
        OMNI_ORACLE_SIGNER, // Omni Oracle Signer
        hash,
        signature
      ) || SignatureChecker.isValidSignatureNow(owner(), hash, signature)
    ) {
      return 0x1626ba7e;
    }

    return 0xffffffff;
  }
}