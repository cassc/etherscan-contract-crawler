//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./BaseOpenSea.sol";
import "./SlayToEarnAccessControl.sol";
import "./ISlayToEarnItems.sol";

contract SlayToEarnItems is ISlayToEarnItems, SlayToEarnAccessControl, BaseOpenSea, ERC1155 {
    constructor(
        string memory tokenMetadataBaseUri,
        address openSeaProxyRegistry) ERC1155(tokenMetadataBaseUri) {

        if (openSeaProxyRegistry != address(0)) {
            setOpenSeaRegistry(openSeaProxyRegistry);
        }

        setTokenMetadataBaseUri(tokenMetadataBaseUri);
    }

    function ping() public override pure returns (bool) {
        return true;
    }

    function setOpenSeaRegistry(address openSeaRegistry) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(Address.isContract(openSeaRegistry), "Given OpenSeaProxy must either be zero or refer to a valid contract.");

        _setOpenSeaRegistry(openSeaRegistry);
    }

    function setTokenMetadataBaseUri(string memory newUri) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setURI(newUri);
    }

    function uri(uint256 item) public view virtual override returns (string memory) {
        return string(
            abi.encodePacked(
                super.uri(item),
                Strings.toString(item)
            )
        );
    }

    function supportsInterfaceSelfTest() public view {
        // easier to test here than getting these interface IDs in JavaScript.

        require(supportsInterface(type(IAccessControl).interfaceId), "Should support IAccessControl interface.");
        require(supportsInterface(type(IERC165).interfaceId), "Should support IERC165 interface.");
        require(supportsInterface(type(IERC1155).interfaceId), "Should support IERC1155 interface.");
        require(supportsInterface(type(IERC1155MetadataURI).interfaceId), "Should support IERC1155MetadataURI interface.");
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC1155) returns (bool) {
        return AccessControl.supportsInterface(interfaceId) || ERC1155.supportsInterface(interfaceId);
    }

    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        // allows gas less trading on OpenSea
        return super.isApprovedForAll(account, operator) || isOwnersOpenSeaProxy(account, operator);
    }

    function _getTotalAmountForId(
        uint256 id,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal pure returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < ids.length; i++) {
            if (ids[i] == id) {
                total += amounts[i];
            }
        }
        return total;
    }

    function requireBatch(
        address player,
        uint256[] memory items,
        uint256[] memory requiredAmounts
    ) public view override {

        address[] memory playerAccounts = new address[](items.length);
        for (uint i = 0; i < items.length; i++) {
            playerAccounts[i] = player;
        }

        uint256[] memory actualAmounts = super.balanceOfBatch(playerAccounts, items);

        require(items.length == requiredAmounts.length, "The length of items and amounts must match.");
        require(actualAmounts.length == requiredAmounts.length, "Internal error.");

        for (uint i = 0; i < requiredAmounts.length; i++) {
            require(
                requiredAmounts[i] <= actualAmounts[i],
                string(
                    abi.encodePacked(
                        "[",
                        Strings.toString(requiredAmounts[i]),
                        "] of item [",
                        Strings.toString(items[i]),
                        "] are required, but you do own only [",
                        Strings.toString(actualAmounts[i]),
                        "]."
                    )
                )
            );
        }
    }

    function mintBatch(
        address player,
        uint256[] memory items,
        uint256[] memory amounts,
        bytes memory data
    ) public override onlyRole(INVENTORY_ADMIN_ROLE) {

        require(items.length == amounts.length, "The length of items and amounts must match.");

        super._mintBatch(player, items, amounts, data);
    }

    function burnBatch(
        address player,
        uint256[] memory items,
        uint256[] memory amounts
    ) public override onlyRole(INVENTORY_ADMIN_ROLE) {

        require(items.length == amounts.length, "The length of items and amounts must match.");

        super._burnBatch(player, items, amounts);
    }
}