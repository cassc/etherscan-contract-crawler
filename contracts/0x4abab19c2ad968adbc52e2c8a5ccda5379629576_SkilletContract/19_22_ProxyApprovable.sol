//SPDX-License-Identifier: Skillet-Group
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract ProxyApprovable {
  uint256 private MAX_UINT256 = 2**256 - 1;

  struct ProxyApprovalParams {
    address proxyAddress;
    address[] collectionAddresses;
  }

  function checkAndSetProxyApprovalERC20(
    address proxyAddress,
    address tokenAddress
  ) internal {

    IERC20 tokenContract = IERC20(tokenAddress);
    uint256 allowance = tokenContract.allowance(address(this), proxyAddress);
    if (!(allowance == MAX_UINT256)) {
      tokenContract.approve(proxyAddress, MAX_UINT256);
    }
  }

  function checkAndSetProxyApprovalForCollection(
    address proxyAddress,
    address collectionAddress
  ) internal {

    IERC721 collectionContract = IERC721(collectionAddress);
    bool approved = collectionContract.isApprovedForAll(address(this), proxyAddress);
    if (!approved) {
      collectionContract.setApprovalForAll(proxyAddress, true);
    }
  }

  function bulkCheckAndSetAllProxyApprovals(
    ProxyApprovalParams[] memory proxyApprovals
  ) internal {

    for (uint256 i=0; i<proxyApprovals.length; i++) {
      ProxyApprovalParams memory proxyApproval = proxyApprovals[i];
      
      for (uint256 j=0; j<proxyApproval.collectionAddresses.length; j++) {
        checkAndSetProxyApprovalForCollection(
          proxyApproval.proxyAddress,
          proxyApproval.collectionAddresses[j]
        );
      }
    }
  }
}