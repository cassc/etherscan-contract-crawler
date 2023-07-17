// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8;

import {ERC20} from "solmate/src/tokens/ERC20.sol";
import "../splits/interfaces/ISplitMain.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Splits is Ownable {

  address public splitMain;
  address public splitWallet;

  function createSplit(
    address _splitMain,
    address[] calldata accounts,
    uint32[] calldata percentAllocations,
    uint32 distributorFee
  ) public virtual onlyOwner {
    require(splitWallet == address(0), "Split already created");
    splitMain = _splitMain;
    splitWallet = ISplitMain(splitMain).createSplit(
      accounts,
      percentAllocations,
      distributorFee,
      msg.sender
    );
  }

  function distributeETH(
    address[] calldata accounts,
    uint32[] calldata percentAllocations,
    uint32 distributorFee,
    address distributorAddress
  ) public virtual requireSplit {
    _transferETHToSplit();
    ISplitMain(splitMain).distributeETH(
      splitWallet,
      accounts,
      percentAllocations,
      distributorFee,
      distributorAddress
    );
  }

  function distributeERC20(
    ERC20 token,
    address[] calldata accounts,
    uint32[] calldata percentAllocations,
    uint32 distributorFee,
    address distributorAddress
  ) public virtual requireSplit {
    _transferERC20ToSplit(token);
    ISplitMain(splitMain).distributeERC20(
      splitWallet,
      token,
      accounts,
      percentAllocations,
      distributorFee,
      distributorAddress
    );
  }

  function distributeAndWithdraw(
    address account,
    uint256 withdrawETH,
    ERC20[] memory tokens,
    address[] calldata accounts,
    uint32[] calldata percentAllocations,
    uint32 distributorFee,
    address distributorAddress
  ) public virtual requireSplit {
    if (withdrawETH != 0) {
      distributeETH(
        accounts,
        percentAllocations,
        distributorFee,
        distributorAddress
      );
    }

    for (uint256 i = 0; i < tokens.length; ++i) {
      distributeERC20(
        tokens[i],
        accounts,
        percentAllocations,
        distributorFee,
        distributorAddress
      );
    }

    _withdraw(account, withdrawETH, tokens);
  }

  function transferToSplit(uint256 transferETH, ERC20[] memory tokens)
    public
    virtual
    requireSplit
  {
    if (transferETH != 0) {
      _transferETHToSplit();
    }

    for (uint256 i = 0; i < tokens.length; ++i) {
      _transferERC20ToSplit(tokens[i]);
    }
  }

  function _transferETHToSplit() internal virtual {
    (bool success, ) = splitWallet.call{value: address(this).balance}("");
    require(success, "Could not transfer ETH to split");
  }

  function _transferERC20ToSplit(ERC20 token) internal virtual {
    uint256 balance = token.balanceOf(address(this));
    token.transfer(splitWallet, balance);
  }

  function _withdraw(
    address account,
    uint256 withdrawETH,
    ERC20[] memory tokens
  ) internal virtual {
    ISplitMain(splitMain).withdraw(
      account,
      withdrawETH,
      tokens
    );
  }

  modifier requireSplit() {
    require(splitWallet != address(0), "Split not created yet");
    _;
  }
}