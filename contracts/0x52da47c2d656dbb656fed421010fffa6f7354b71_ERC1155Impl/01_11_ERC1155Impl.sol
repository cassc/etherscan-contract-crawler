// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract ERC1155Impl is ERC1155Upgradeable, OwnableUpgradeable {
    function __ERC1155Impl_init(string memory uri, address owner)
        external
        initializer
    {
        __ERC1155_init(uri);
        __Ownable_init();
        _transferOwnership(owner);

        // mint 
        for(uint256 i = 1; i <= 20; i++) {
            ERC1155Upgradeable._mint(owner, i, 10, "");
        }
    }

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external onlyOwner {
        ERC1155Upgradeable._mint(to, id, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external onlyOwner {
        ERC1155Upgradeable._mintBatch(to, ids, amounts, data);
    }
}