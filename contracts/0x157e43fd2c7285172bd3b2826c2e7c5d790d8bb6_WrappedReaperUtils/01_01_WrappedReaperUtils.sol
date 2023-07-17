/// SPDX-License-Identifier CC0-1.0
pragma solidity 0.8.17;

library WrappedReaperUtils {

  /// @notice An uppercase version of: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/5420879d9b834a0579423d668fb60c5fc13b60cc/contracts/utils/Strings.sol#L13
  /// @dev We use this for evaluation of OpenSea style short addresses.
  bytes16 private constant __SYMBOLS = "0123456789ABCDEF";

  /// @notice Decimal precision of ReapersGambit.
  uint256 public constant DECIMALS = 18;

  /// @notice Computes the short address string for an address.
  /// @param a Address to create a short address for.
  /// @return A shorthand of a string address of length 6 (without 0x prefix).
  function short(address a) public pure returns (string memory) {
    bytes memory buffer = new bytes(6);

    uint256 value = uint160(a) >> 34 * 4;

    for (uint256 i = 0; i < 6; i += 1) {
      buffer[5 - i] = __SYMBOLS[value & 0xf];
      value >>= 4;
    }

    return string(buffer);
  }

  // @notice Converts the provided color into an SVG hexadecimal color string.
  // @dev Logic ported across from OpenZeppelin for runtime gas efficiency:
  //      https://github.com/OpenZeppelin/openzeppelin-contracts/blob/dfef6a68ee18dbd2e1f5a099061a3b8a0e404485/contracts/utils/Strings.sol#L13
  // @param color The color to stringify.
  // @return An SVG-compliant color.
  function color(uint24 color_) public pure returns (string memory) {
    bytes memory buffer = new bytes(7);
    buffer[0] = "#";

    for (uint256 i = 6; i >= 1; i -= 1) {
      buffer[i] = __SYMBOLS[color_ & 0xf];
      color_ >>= 4;
    }

    return string(buffer);
  }

}