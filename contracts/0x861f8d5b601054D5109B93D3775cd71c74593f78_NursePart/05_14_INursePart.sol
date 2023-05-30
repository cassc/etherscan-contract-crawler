// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface INursePart is IERC1155 {
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external view returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) external;

    function burn(uint256 id, uint256 amount) external;

    function permit(
        address owner,
        address spender,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}