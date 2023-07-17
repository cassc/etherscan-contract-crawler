// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title IERC5827Proxy interface
/// @author Zac (zlace0x), zhongfu (zhongfu), Edison (edison0xyz)
interface IERC5827Proxy {
    /// Note: the ERC-165 identifier for this interface is 0xc55dae63.
    /// 0xc55dae63 ===
    ///   bytes4(keccak256('baseToken()')

    /// @notice Get the underlying base token being proxied.
    /// @return address address of the base token
    function baseToken() external view returns (address);
}