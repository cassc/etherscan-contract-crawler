// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Vault is Ownable {
  using SafeERC20 for IERC20;
  // Mapping from {token} to {amount}
  mapping(address => uint256) public totalAffiliateBalance;
  // Mapping from {affiliate} to {token} to {amount}
  mapping(address => mapping(address => uint256)) public affiliateBalance;
  // Mapping from {integationProtocol} to {status}
  mapping(address => bool) public isIntegrationProtocol;

  address internal constant ETH_ADDRESS =
    0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  modifier onlyIntegrationProtocols() {
    require(isIntegrationProtocol[msg.sender], "Is not integration protocol");
    _;
  }

  /// @notice Set IntegrationProtocol status
  function setIntegrationProtocol(
    address[] calldata protocolAddresses,
    bool[] calldata statuses
  ) external onlyOwner {
    require(
      protocolAddresses.length == statuses.length,
      "IntegrationProtocol: Invalid input length"
    );

    for (uint256 i = 0; i < protocolAddresses.length; i++) {
      isIntegrationProtocol[protocolAddresses[i]] = statuses[i];
    }
  }

  /// @notice Add affiliate balances
  function addAffiliateBalance(
    address affiliate,
    address token,
    uint256 affiliatePortion
  ) external onlyIntegrationProtocols {
    affiliateBalance[affiliate][token] += affiliatePortion;
    totalAffiliateBalance[token] += affiliatePortion;
  }

  ///@notice Withdraw affilliate share, retaining goodwill share
  function affiliateWithdraw(address[] calldata tokens) external {
    uint256 tokenBalance;
    for (uint256 i = 0; i < tokens.length; i++) {
      tokenBalance = affiliateBalance[msg.sender][tokens[i]];
      affiliateBalance[msg.sender][tokens[i]] = 0;
      totalAffiliateBalance[tokens[i]] =
        totalAffiliateBalance[tokens[i]] -
        tokenBalance;

      if (tokens[i] == ETH_ADDRESS) {
        Address.sendValue(payable(msg.sender), tokenBalance);
      } else {
        IERC20(tokens[i]).safeTransfer(msg.sender, tokenBalance);
      }
    }
  }

  ///@notice Withdraw goodwill share, retaining affilliate share
  function withdrawTokens(address[] calldata tokens) external onlyOwner {
    for (uint256 i = 0; i < tokens.length; i++) {
      uint256 amount;

      if (tokens[i] == ETH_ADDRESS) {
        amount = address(this).balance - totalAffiliateBalance[tokens[i]];
        Address.sendValue(payable(owner()), amount);
      } else {
        amount =
          IERC20(tokens[i]).balanceOf(address(this)) -
          totalAffiliateBalance[tokens[i]];
        IERC20(tokens[i]).safeTransfer(owner(), amount);
      }
    }
  }

  receive() external payable {
    // solhint-disable-next-line
    require(msg.sender != tx.origin, "Do not send ETH directly");
  }
}