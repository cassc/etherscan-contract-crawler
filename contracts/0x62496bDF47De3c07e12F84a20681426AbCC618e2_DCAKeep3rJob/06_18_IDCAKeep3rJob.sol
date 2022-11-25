// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import 'keep3r-v2/solidity/interfaces/IKeep3r.sol';

interface IDCAKeep3rJob {
  /// @notice A struct that contains the swapper and nonce to use
  struct SwapperAndNonce {
    address swapper;
    uint96 nonce;
  }

  /// @notice Thrown when one of the parameters is a zero address
  error ZeroAddress();

  /// @notice Thrown when a user tries to execute work but the signature is invalid
  error SignerCannotSignWork();

  /// @notice Thrown when a non keep3r address tries to execute work
  error NotAKeeper();

  /**
   * @notice Emitted when a new swapper is set
   * @param newSwapper The new swapper
   */
  event NewSwapperSet(address newSwapper);

  /**
   * @notice The domain separator used for the work signature
   * @return The domain separator used for the work signature
   */
  // solhint-disable-next-line func-name-mixedcase
  function DOMAIN_SEPARATOR() external view returns (bytes32);

  /**
   * @notice Returns the swapper address
   * @return swapper The swapper's address
   * @return nonce The next nonce to use
   */
  function swapperAndNonce() external returns (address swapper, uint96 nonce);

  /**
   * @notice Returns the Keep3r address
   * @return The Keep3r address address
   */
  function keep3r() external returns (IKeep3r);

  /**
   * @notice Sets a new swapper address
   * @dev Will revert with ZeroAddress if the zero address is passed
   *      Can only be called by an admin
   * @param swapper The new swapper address
   */
  function setSwapper(address swapper) external;

  /**
   * @notice Takes an encoded call and executes it against the swapper
   * @dev Will revert with:
   *      - NotAKeeper if the caller is not a keep3r
   *      - SignerCannotSignWork if the address who signed the message cannot sign work
   * @param call The call to execut against the swapper
   * @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
   * @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
   * @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
   */
  function work(
    bytes calldata call,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;
}