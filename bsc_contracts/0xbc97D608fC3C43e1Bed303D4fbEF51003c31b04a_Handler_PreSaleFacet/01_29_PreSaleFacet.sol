// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;

import "./OwnersFacet.sol";
import "./AppStorage.sol";
import "../PreSale.sol";

struct PreSaleFacetStorage {
    mapping(string => string) preSaleItemToLuckyBoxName;
    IPreSaleBurnable preSaleContract;
}

library LibPreSale {
    bytes32 constant STORAGE_POSITION =
        keccak256("diamond.handler.presale.storage");

    function facetStorage()
        internal
        pure
        returns (PreSaleFacetStorage storage s)
    {
        bytes32 position = STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }

    function updateMap(string memory preSaleName, string memory luckyBoxName)
        internal
    {
        PreSaleFacetStorage storage s = facetStorage();
        s.preSaleItemToLuckyBoxName[preSaleName] = luckyBoxName;
    }

    function getLuckyBoxNameFromPreSaleItem(string memory _preSaleItem)
        internal
        view
        returns (string memory)
    {
        PreSaleFacetStorage storage s = facetStorage();
        return s.preSaleItemToLuckyBoxName[_preSaleItem];
    }
}

contract Handler_PreSaleFacet is OwnersAware {
    function preSale() public view returns (IPreSaleBurnable) {
        return LibPreSale.facetStorage().preSaleContract;
    }

    function setPreSale(IPreSaleBurnable _preSale) external onlyOwners {
        PreSaleFacetStorage storage s = LibPreSale.facetStorage();
        s.preSaleContract = _preSale;
    }

    function preSaleMapping(string calldata preSaleName)
        public
        view
        returns (string memory)
    {
        return LibPreSale.getLuckyBoxNameFromPreSaleItem(preSaleName);
    }

    function setPreSaleMapping(
        string[] memory preSaleNames,
        string[] memory luckyBoxesNames
    ) external onlyOwners {
        require(
            preSaleNames.length == luckyBoxesNames.length,
            "Handler: Length mismatch"
        );

        for (uint256 i = 0; i < preSaleNames.length; i++) {
            LibPreSale.updateMap({
                preSaleName: preSaleNames[i],
                luckyBoxName: luckyBoxesNames[i]
            });
        }
    }

    function createLuckyBoxFromPreSale(address user, uint256 preSaleItemIdx)
        external
    {
        require(
            msg.sender == user || LibOwners.isOwner(msg.sender),
            "Handler: Don't mess with others claims"
        );

        PreSaleFacetStorage storage s = LibPreSale.facetStorage();
        IPreSaleBurnable _preSale = s.preSaleContract;

        (, uint256 amount, string memory itemName) = _preSale.burnItemTypeFrom(
            user,
            preSaleItemIdx
        );

        require(amount >= 0, "Handler: No items bought of this type");

        LibAppStorage.appStorage().lucky.createLuckyBoxesAirDrop(
            LibPreSale.getLuckyBoxNameFromPreSaleItem(itemName),
            amount,
            user
        );
    }
}