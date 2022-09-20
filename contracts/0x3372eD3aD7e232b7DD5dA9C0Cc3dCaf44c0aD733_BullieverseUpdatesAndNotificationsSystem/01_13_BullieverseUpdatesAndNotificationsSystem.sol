// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BullieverseUpdatesAndNotificationsSystem is ERC1155Supply, Ownable {
    using Strings for uint256;

    string public name;
    string public symbol;

    event BurnedAsset(address burner, uint256 tokenId, uint256 amount);
    event MintAsset(address owner, uint256 tokenId, uint256 amount);

    /**
     * @dev Initializes the contract by setting the name and the token symbol
     */
    constructor(string memory baseURI) ERC1155(baseURI) {
        name = "BullieverseUpdatesAndNotificationsSystem";
        symbol = "BUNS";
    }

    /**
     * @dev Contracts the metadata URI for the Asset of the given collectionId.
     *
     * Requirements:
     *
     * - The Asset exists for the given collectionId
     */
    function uri(uint256 collectionId)
        public
        view
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    super.uri(collectionId),
                    collectionId.toString(),
                    ".json"
                )
            );
    }

    function mintAsset(
        address[] memory addresses,
        uint256 collectionId,
        uint256 amount
    ) external onlyOwner {
        for (uint256 index = 0; index < addresses.length; index++) {
            _mint(addresses[index], collectionId, amount, "");
            emit MintAsset(addresses[index], collectionId, amount);
        }
    }

    /**
     * @dev Sets the base URI for the Collection metadata.
     */
    function setBaseURI(string memory baseURI) external onlyOwner {
        require(bytes(baseURI).length != 0, "baseURI cannot be empty");
        _setURI(baseURI);
    }

    function burn(
        uint256 collectionId,
        uint256 amount,
        address[] memory addresses
    ) external payable onlyOwner {
        for (uint256 index = 0; index < addresses.length; index++) {
            _burn(addresses[index], collectionId, amount);
            emit BurnedAsset(addresses[index], collectionId, amount);
        }
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override onlyOwner {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}