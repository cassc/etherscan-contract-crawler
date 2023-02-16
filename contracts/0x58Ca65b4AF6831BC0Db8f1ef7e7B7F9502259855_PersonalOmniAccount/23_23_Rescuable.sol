pragma solidity ^0.8.15;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import {SafeTransferLib} from "@solmate/utils/SafeTransferLib.sol";
import {ERC721} from "@solmate/tokens/ERC721.sol";
import {ERC20} from "@solmate/tokens/ERC20.sol";
import {ERC1155} from "@solmate/tokens/ERC1155.sol";

contract Rescuable is Ownable {
  using SafeTransferLib for ERC20;

  /**
   * @notice Rescue ETH locked up in this contract.
   * @param amount    Amount to rescue
   */
  function rescueETH(uint256 amount, address recipient) external onlyOwner {
    SafeTransferLib.safeTransferETH(recipient, amount);
  }

  /**
   * @notice Rescue ERC20 locked up in this contract
   * @param token     Token address
   * @param amount    Amount to rescue
   */
  function rescueERC20(ERC20 token, uint256 amount, address recipient) external onlyOwner {
    token.safeTransfer(recipient, amount);
  }

  /**
   * @notice Rescue ERC721 locked up in this contract
   * @param token     Token address
   * @param ids       Token ids to rescue
   */
  function rescueERC721(ERC721 token, uint256[] calldata ids, address recipient) external virtual onlyOwner {
    for (uint256 i; i < ids.length; ) {
      token.safeTransferFrom(address(this), recipient, ids[i]);
      unchecked {
        ++i;
      }
    }
  }

  /**
   * @notice Rescue ERC1155 locked up in this contract
   * @param token     Token address
   * @param ids       Token ids to rescue
   * @param ids       Amounts to rescue
   */
  function rescueERC1155(
    ERC1155 token,
    uint256[] calldata ids,
    uint256[] calldata amounts,
    address recipient
  ) external onlyOwner {
    for (uint256 i = 0; i < ids.length; ) {
      token.safeTransferFrom(address(this), recipient, ids[i], amounts[i], "");
      unchecked {
        ++i;
      }
    }
  }
}