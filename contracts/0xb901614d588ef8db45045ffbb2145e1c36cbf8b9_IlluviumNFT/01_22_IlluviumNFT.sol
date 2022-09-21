// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./RoyalERC1155.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

/**
 * @title Illuvium ERC1155 NFT
 *
 * @dev This is the deployed smart contract that represents Illuvium's Promotional
 *      NFTs collection using the multi-token standard (ERC1155)
 *
 * @dev UUPSUpgradeable (EIP1822) is used for upgradeability
 */

contract IlluviumNFT is Initializable, RoyalERC1155 {
    using StringsUpgradeable for uint256;

    /**
     * @dev Collection name
     */
    string public constant name = "Illuvium Promo NFTs";
    /**
     * @dev Collection token ticker (symbol)
     */
    string public constant symbol = "ILV-NFT";

    /**
     * @dev "Constructor replacement" for upgradeable, must be execute immediately after deployment
     *      see https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#initializers
     *
     * @param uri_ collection uri (ERC1155)
     * @param _owner smart contract owner having full privileges
     */
    function initialize(string memory uri_, address _owner) external initializer {
        __RoyalERC1155_init(uri_, _owner);
    }

    /**
     * @inheritdoc ERC1155Upgradeable
     */
    function uri(uint256 _id) public view virtual override returns (string memory) {
        require(exists(_id), "URI query for nonexistent token");

        string memory baseUri = super.uri(0);
        return string(abi.encodePacked(baseUri, _id.toString()));
    }

    /**
     * @dev Empty reserved space in storage. The size of the __gap array is calculated so that
     *      the amount of storage used by a contract always adds up to the 50.
     *      See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}