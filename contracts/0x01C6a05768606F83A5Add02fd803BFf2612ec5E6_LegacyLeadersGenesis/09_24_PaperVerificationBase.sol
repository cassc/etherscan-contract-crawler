// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

abstract contract PaperVerificationBase {
    address internal paperKey;
    mapping(bytes32 => bool) internal minted;

    constructor(address _paperKey) {
        paperKey = _paperKey;
    }

    function isMinted(bytes32 nonce) public view returns (bool) {
        return minted[nonce];
    }

    /// @notice Updates the paper key that is use to verify in {_checkValidity}.
    /// @dev Should only be able to be called by trusted addresses
    /// @param _paperKey The new paper key to use for verification
    function _setPaperKey(address _paperKey) internal {
        paperKey = _paperKey;
    }

    function getPaperKey() public view returns (address) {
        return paperKey;
    }
}