// SPDX-License-Identifier: MIT
//.___________. __  .__   __. ____    ____      ___           _______..___________..______        ______
//|           ||  | |  \ |  | \   \  /   /     /   \         /       ||           ||   _  \      /  __  \
//`---|  |----`|  | |   \|  |  \   \/   /     /  ^  \       |   (----``---|  |----`|  |_)  |    |  |  |  |
//    |  |     |  | |  . `  |   \_    _/     /  /_\  \       \   \        |  |     |      /     |  |  |  |
//    |  |     |  | |  |\   |     |  |      /  _____  \  .----)   |       |  |     |  |\  \----.|  `--'  |
//    |__|     |__| |__| \__|     |__|     /__/     \__\ |_______/        |__|     | _| `._____| \______/

pragma solidity ^0.8.14;

import {SafeTransferLib} from "@rari-capital/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "@rari-capital/solmate/src/tokens/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC721} from "@openzeppelin/contracts/interfaces/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/interfaces/IERC1155.sol";
import {IWETH} from "./interfaces/IWETH.sol";

contract AstroSwap is Ownable, Pausable, ReentrancyGuard {
  struct ProxyInput {
    address proxy;
    bytes data;
  }

  struct ERC20Token {
    ERC20 asset;
    uint256 amount;
  }

  event ProxyUpdated(address proxy, bool isRemoval);

  IWETH public immutable weth;

  mapping(address => bool) public proxies;

  constructor(address _weth) {
    weth = IWETH(_weth);
  }

  function setPaused(bool paused) external onlyOwner {
    paused ? _pause() : _unpause();
  }

  function updateProxies(address[] calldata toAdd, address[] calldata toRemove) external onlyOwner {
    for (uint256 i = 0; i < toAdd.length; ) {
      proxies[toAdd[i]] = true;
      emit ProxyUpdated(toAdd[i], false);
      unchecked {
        ++i;
      }
    }

    for (uint256 i = 0; i < toRemove.length; ) {
      delete proxies[toRemove[i]];
      emit ProxyUpdated(toRemove[i], true);
      unchecked {
        ++i;
      }
    }
  }

  function batchSwapWithETH(ProxyInput[] memory proxyInputs) external payable whenNotPaused nonReentrant {
    _executeProxyInput(proxyInputs);

    // Refund remaining ETH
    _refundETH();
  }

  function batchSwapWithERC20(
    ERC20Token[] calldata erc20Tokens,
    ProxyInput[] memory proxyInputs,
    uint256 amountToEth,
    uint256 amountToWeth
  ) external payable whenNotPaused nonReentrant {
    // Collect ERC20 tokens before trading
    _collectERC20Tokens(erc20Tokens);

    // Convert ETH <=> WETH
    _convertWrappedNative(amountToEth, amountToWeth);

    _executeProxyInput(proxyInputs);

    // Refund remaining ERC20 tokens
    _refundERC20Tokens(erc20Tokens);

    // Refund remaining ETH
    _refundETH();
  }

  function _executeProxyInput(ProxyInput[] memory inputs) internal {
    for (uint256 i = 0; i < inputs.length; ) {
      address proxy = inputs[i].proxy;
      require(proxies[proxy], "Invalid proxy");

      _performDelegatecall(proxy, inputs[i].data);

      unchecked {
        ++i;
      }
    }
  }

  function _performDelegatecall(address to, bytes memory data) internal {
    (bool success, ) = to.delegatecall(data);
    if (!success) {
      assembly {
        returndatacopy(0, 0, returndatasize())
        revert(0, returndatasize())
      }
    }
  }

  function _convertWrappedNative(uint256 amountToEth, uint256 amountToWeth) internal {
    if (amountToEth > 0) {
      weth.withdraw(amountToEth);
    }
    if (amountToWeth > 0) {
      weth.deposit{value: amountToWeth}();
    }
  }

  /*//////////////////////////////////////////////////////////////
                          RECEIVERS
  //////////////////////////////////////////////////////////////*/

  receive() external payable {}

  function onERC1155Received(
    address,
    address,
    uint256,
    uint256,
    bytes calldata
  ) external pure returns (bytes4) {
    return this.onERC1155Received.selector;
  }

  function onERC1155BatchReceived(
    address,
    address,
    uint256[] calldata,
    uint256[] calldata,
    bytes calldata
  ) external pure returns (bytes4) {
    return this.onERC1155BatchReceived.selector;
  }

  function onERC721Received(
    address,
    address,
    uint256,
    bytes calldata
  ) external pure returns (bytes4) {
    return this.onERC721Received.selector;
  }

  /*//////////////////////////////////////////////////////////////
                          TOKEN TRANSFERS
  //////////////////////////////////////////////////////////////*/

  function _transferETH(address to, uint256 amount) internal {
    (bool success, ) = to.call{value: amount}("");
    require(success, "Unable to transfer eth");
  }

  // Refund remaining ETH to the caller
  function _refundETH() internal {
    uint256 amount = address(this).balance;
    if (amount > 0) {
      _transferETH(msg.sender, amount);
    }
  }

  // Transfer and approval ERC20 tokens to the contract before swapping
  function _collectERC20Tokens(ERC20Token[] calldata erc20Tokens) internal {
    for (uint256 i = 0; i < erc20Tokens.length; ) {
      // Collect ERC20 tokens from provided by the caller, need approval first.
      if (erc20Tokens[i].amount > 0) {
        SafeTransferLib.safeTransferFrom(erc20Tokens[i].asset, msg.sender, address(this), erc20Tokens[i].amount);
      }

      unchecked {
        ++i;
      }
    }
  }

  // Refund remaining ERC20 back to the caller
  function _refundERC20Tokens(ERC20Token[] calldata erc20Tokens) internal {
    for (uint256 i = 0; i < erc20Tokens.length; ) {
      // Refund remaining ERC20 tokens back the the caller.
      uint256 amount = erc20Tokens[i].asset.balanceOf(address(this));
      if (amount > 0) {
        SafeTransferLib.safeTransfer(erc20Tokens[i].asset, msg.sender, amount);
      }

      unchecked {
        ++i;
      }
    }
  }

  function transferETH(address to, uint256 amount) external onlyOwner {
    _transferETH(to, amount);
  }

  function transferERC20(
    address asset,
    address to,
    uint256 amount
  ) external onlyOwner {
    SafeTransferLib.safeTransfer(ERC20(asset), to, amount);
  }

  function transferERC721(
    address asset,
    address to,
    uint256[] calldata tokenIds
  ) external onlyOwner {
    for (uint256 i = 0; i < tokenIds.length; ) {
      IERC721(asset).transferFrom(address(this), to, tokenIds[i]);
      unchecked {
        ++i;
      }
    }
  }

  function transferERC1155(
    address asset,
    address to,
    uint256[] calldata tokenIds,
    uint256[] calldata amounts
  ) external onlyOwner {
    for (uint256 i = 0; i < tokenIds.length; ) {
      IERC1155(asset).safeTransferFrom(address(this), to, tokenIds[i], amounts[i], "");
      unchecked {
        ++i;
      }
    }
  }

  function approveERC20(
    address asset,
    address spender,
    uint256 amount
  ) external onlyOwner {
    SafeTransferLib.safeApprove(ERC20(asset), spender, amount);
  }
}