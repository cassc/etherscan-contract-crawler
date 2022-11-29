// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

abstract contract SignerIndexVerifiable is ContextUpgradeable {
    /// @notice Current index per signer.
    /// Updating it will invalidate all signatures created with the previous value on a signer level.
    /// @custom:schema (signer address -> index)
    mapping(address => uint256) private signerIndex;

    event SignerIndexUpdated(address indexed _signer, uint256 _newIndex, address _sender);

    function __SignerIndexVerifiable_init() internal onlyInitializing {}

    function __SignerIndexVerifiable_init_unchained() internal onlyInitializing {}

    /// @notice Get the current signer index.
    /// @param _signer The address of the signer.
    /// @return The index of the given signer.
    function getSignerIndex(address _signer) external view returns (uint256) {
        return signerIndex[_signer];
    }

    /// @notice Increase the signer index of the sender by 1.
    function bumpSignerIndex() external {
        _bumpSignerIndex(_msgSender());
    }

    /// @dev Increase the signer index by 1
    function _bumpSignerIndex(address _signer) internal {
        emit SignerIndexUpdated(_signer, ++signerIndex[_signer], _msgSender());
    }

    /// @dev Reverts if the provided index does not match the signer index.
    function _verifySignerIndex(address _signer, uint256 _index) internal view {
        require(_index == signerIndex[_signer], "SignerIndexVerifiable#_verifySignerIndex: SIGNER_INDEX_MISMATCH");
    }
}