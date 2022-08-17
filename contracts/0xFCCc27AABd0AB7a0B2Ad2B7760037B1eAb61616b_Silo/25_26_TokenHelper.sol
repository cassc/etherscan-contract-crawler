// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";


library TokenHelper {
    uint256 private constant _BYTES32_SIZE = 32;

    error TokenIsNotAContract();

    function assertAndGetDecimals(address _token) internal view returns (uint256) {
        (bool hasMetadata, bytes memory data) = _tokenMetadataCall(_token, abi.encodeCall(IERC20Metadata.decimals,()));

        // decimals() is optional in the ERC20 standard, so if metadata is not accessible
        // we assume there are no decimals and use 0.
        if (!hasMetadata) {
            return 0;
        }

        return abi.decode(data, (uint8));
    }

    /// @dev Returns the symbol for the provided ERC20 token.
    /// An empty string is returned if the call to the token didn't succeed.
    /// @param _token address of the token to get the symbol for
    /// @return assetSymbol the token symbol
    function symbol(address _token) internal view returns (string memory assetSymbol) {
        (bool hasMetadata, bytes memory data) = _tokenMetadataCall(_token, abi.encodeCall(IERC20Metadata.symbol,()));

        if (!hasMetadata || data.length == 0) {
            return "?";
        } else if (data.length == _BYTES32_SIZE) {
            return string(removeZeros(data));
        } else {
            return abi.decode(data, (string));
        }
    }

    /// @dev Removes bytes with value equal to 0 from the provided byte array.
    /// @param _data byte array from which to remove zeroes
    /// @return result byte array with zeroes removed 
    function removeZeros(bytes memory _data) internal pure returns (bytes memory result) {
        uint256 n = _data.length;

        unchecked {
            for (uint256 i; i < n; i++) {
                if (_data[i] == 0) continue;

                result = abi.encodePacked(result, _data[i]);
            }
        }
    }

    /// @dev Performs a staticcall to the token to get its metadata (symbol, decimals, name)
    function _tokenMetadataCall(address _token, bytes memory _data) private view returns(bool, bytes memory) {
        // We need to do this before the call, otherwise the call will succeed even for EOAs
        if (!Address.isContract(_token)) revert TokenIsNotAContract();

        (bool success, bytes memory result) = _token.staticcall(_data);

        // If the call reverted we assume the token doesn't follow the metadata extension
        if (!success) {
            return (false, "");
        }

        return (true, result);
    }
}