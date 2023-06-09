pragma solidity 0.6.12;

import 'OpenZeppelin/[email protected]/contracts/token/ERC1155/IERC1155.sol';

import './IERC20Wrapper.sol';

interface IWStakingRewards is IERC1155, IERC20Wrapper {
  /// @dev Mint ERC1155 token for the given ERC20 token.
  function mint(uint amount) external returns (uint id);

  /// @dev Burn ERC1155 token to redeem ERC20 token back.
  function burn(uint id, uint amount) external returns (uint);

  function reward() external returns (address);
}