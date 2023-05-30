//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.18 <0.9.0;

interface iERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

interface iCCIP {
    function resolve(bytes memory name, bytes memory data) external view returns (bytes memory);
}

interface iResolver {
    function contenthash(bytes32 node) external view returns (bytes memory);
    function setContenthash(bytes32 node, bytes calldata _ch) external view returns (bytes memory);
}

interface iToken {
    function transferFrom(address from, address to, uint256 bal) external;
    function safeTransferFrom(address from, address to, uint256 bal) external;
}

interface iERC173 {
    function owner() external view returns (address);
    function transferOwnership(address _newOwner) external;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}