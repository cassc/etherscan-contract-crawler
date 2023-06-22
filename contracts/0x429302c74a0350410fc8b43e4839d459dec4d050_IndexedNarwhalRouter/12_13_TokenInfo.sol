pragma solidity >=0.5.0;


library TokenInfo {
  function unpack(bytes32 tokenInfo) internal pure returns (address token, bool useSushiNext) {
    assembly {
      token := shr(8, tokenInfo)
      useSushiNext := byte(31, tokenInfo)
    }
  }

  function pack(address token, bool sushi) internal pure returns (bytes32 tokenInfo) {
    assembly {
      tokenInfo := or(
        shl(8, token),
        sushi
      )
    }
  }

  function readToken(bytes32 tokenInfo) internal pure returns (address token) {
    assembly {
      token := shr(8, tokenInfo)
    }
  }

  function readSushi(bytes32 tokenInfo) internal pure returns (bool useSushiNext) {
    assembly {
      useSushiNext := byte(31, tokenInfo)
    }
  }
}