pragma solidity 0.6.12;

import 'OpenZeppelin/[email protected]/contracts/token/ERC1155/IERC1155.sol';
import 'OpenZeppelin/[email protected]/contracts/token/ERC20/IERC20.sol';

import './IERC20Wrapper.sol';
import './ICurveRegistry.sol';
import './ILiquidityGauge.sol';

interface IWLiquidityGauge is IERC1155, IERC20Wrapper {
  /// @dev Mint ERC1155 token for the given ERC20 token.
  function mint(
    uint pid,
    uint gid,
    uint amount
  ) external returns (uint id);

  /// @dev Burn ERC1155 token to redeem ERC20 token back.
  function burn(uint id, uint amount) external returns (uint pid);

  function crv() external returns (IERC20);

  function registry() external returns (ICurveRegistry);

  function encodeId(
    uint,
    uint,
    uint
  ) external pure returns (uint);

  function decodeId(uint id)
    external
    pure
    returns (
      uint,
      uint,
      uint
    );
}