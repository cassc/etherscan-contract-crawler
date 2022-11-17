// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;
interface IERC1155PresetMinterPauser {
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function balanceOf(address account, uint256 id) external view returns (uint256);
    function burn(
        address from,
        uint256 id,
        uint256 amount
    ) external;
    function totalSupply(uint256 id) external view returns (uint256);
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        external
        view
        returns (uint256[] memory);
    function burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external;
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;
    function initialize(address defaultAdmin_, address minter_, string memory uri) external;
}