pragma solidity 0.6.12;

import 'OpenZeppelin/[email protected]/contracts/token/ERC1155/IERC1155.sol';
import 'OpenZeppelin/[email protected]/contracts/token/ERC20/IERC20.sol';

import './IERC20Wrapper.sol';
import './IMasterChef.sol';

interface IWMasterChef is IERC1155, IERC20Wrapper {
  /// @dev Mint ERC1155 token for the given ERC20 token.
  function mint(uint pid, uint amount) external returns (uint id);

  /// @dev Burn ERC1155 token to redeem ERC20 token back.
  function burn(uint id, uint amount) external returns (uint pid);

  function sushi() external returns (IERC20);

  function decodeId(uint id) external pure returns (uint, uint);

  function chef() external view returns (IMasterChef);
}