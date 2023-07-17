// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.9;

import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721} from "@solmate/tokens/ERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SignatureChecker} from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

contract CrossPostAccount is Pausable, Ownable {
  address public OMNI_ORACLE_SIGNER;

  struct MarketplaceApprovals {
    address marketplaceOperator;
    address token;
  }

  function setApprovalForMarketplaces(MarketplaceApprovals[] calldata collectionsToApprove, bool approve) public onlyOwner {
    for (uint256 i; i < collectionsToApprove.length; ) {
      ERC721 collection = ERC721(collectionsToApprove[i].token);
      address operator = collectionsToApprove[i].marketplaceOperator;

      collection.setApprovalForAll(operator, approve);

      unchecked {
        ++i;
      }
    }
  }

  function setERC20ApprovalForMarketplaces(MarketplaceApprovals[] calldata tokensToApprove, uint256 amount) public onlyOwner {
    for (uint256 i; i < tokensToApprove.length; ) {
      IERC20 token = IERC20(tokensToApprove[i].token);
      address operator = tokensToApprove[i].marketplaceOperator;

      token.approve(operator, amount);

      unchecked {
        ++i;
      }
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