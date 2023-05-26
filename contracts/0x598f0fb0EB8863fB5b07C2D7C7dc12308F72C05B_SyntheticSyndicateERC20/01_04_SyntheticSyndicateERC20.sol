// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "../utils/ERC20.sol";
import "../utils/AccessControl.sol";

contract SyntheticSyndicateERC20 is ERC20("Synthetic Syndicate Token", "sSYNR"), AccessControl {
  /**
   * @dev Smart contract unique identifier, a random number
   * @dev Should be regenerated each time smart contact source code is changed
   *      and changes smart contract itself is to be redeployed
   * @dev Generated using https://www.random.org/bytes/
   */
  uint256 public constant TOKEN_UID = 0xac3051b8d4f50966afb632468a4f61483ae6a953b74e387a01ef94316d6b7d62;

  uint32 public constant ROLE_TOKEN_DESTROYER = 0x0002_0000;

  uint32 public constant ROLE_WHITE_LISTED_RECEIVER = 0x0004_0000;

  constructor(address _superAdmin) AccessControl(_superAdmin) {}

  /**
   * @notice Must be called by ROLE_TOKEN_CREATOR addresses.
   *
   * @param recipient address to receive the tokens.
   * @param amount number of tokens to be minted.
   */
  function mint(address recipient, uint256 amount) external {
    require(isSenderInRole(ROLE_TOKEN_CREATOR), "sSYNR: insufficient privileges (ROLE_TOKEN_CREATOR required)");
    _mint(recipient, amount);
  }

  /**
   * @param amount number of tokens to be burned.
   */
  function burn(uint256 amount) external {
    _burn(msg.sender, amount);
  }

  /**
   * @notice Must be called by ROLE_TOKEN_DESTROYER addresses (SynrSwapper)
   *         Can burn only tokens owned by ROLE_WHITE_LISTED_RECEIVER address
   * @param recipient address to burn the tokens.
   * @param amount number of tokens to be burned
   */
  function burn(address recipient, uint256 amount) external {
    require(isSenderInRole(ROLE_TOKEN_DESTROYER), "sSYNR: insufficient privileges (ROLE_TOKEN_DESTROYER required)");
    require(isOperatorInRole(recipient, ROLE_WHITE_LISTED_RECEIVER), "sSYNR: Non Allowed Receiver");
    _burn(recipient, amount);
  }

  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual override {
    require(isOperatorInRole(recipient, ROLE_WHITE_LISTED_RECEIVER), "sSYNR: Non Allowed Receiver");
    super._transfer(sender, recipient, amount);
  }
}