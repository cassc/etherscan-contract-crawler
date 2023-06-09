// SPDX-License-Identifier: CLOSED - Pending Licensing Audit
pragma solidity ^0.8.4;

contract ERC165 {

    mapping(bytes4 => bool) private supportedInterfaces;

    function initializeERC165() internal {
        require(supportedInterfaces[0x01ffc9a7] == false, "Already Registered");
        _registerInterface(0x01ffc9a7);
    }
    
    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return supportedInterfaces[interfaceId];
    }
    
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        supportedInterfaces[interfaceId] = true;
    }
}

// interface IERC1155Receiver {
//     function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data) external returns(bytes4);
//     function onERC1155BatchReceived(address operator, address from, uint256[] calldata ids, uint256[] calldata values, bytes calldata data) external returns(bytes4);
// }

// interface IERC1155MetadataURI  {
//     function uri(uint256 id) external view returns (string memory);
// }