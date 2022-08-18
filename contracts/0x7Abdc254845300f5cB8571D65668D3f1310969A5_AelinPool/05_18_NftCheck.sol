// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

library NftCheck {
    bytes4 public constant IERC165_ID = type(IERC165).interfaceId;
    bytes4 public constant IERC1155_ID = type(IERC1155).interfaceId;
    bytes4 public constant IERC721_ID = type(IERC721).interfaceId;

    function supports721(address collectionAddress) internal view returns(bool) {
        return _supportsInterface(collectionAddress, IERC721_ID);
    }

    function supports1155(address collectionAddress) internal view returns(bool) {
        return _supportsInterface(collectionAddress, IERC1155_ID);
    }

    function _supportsInterface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
}