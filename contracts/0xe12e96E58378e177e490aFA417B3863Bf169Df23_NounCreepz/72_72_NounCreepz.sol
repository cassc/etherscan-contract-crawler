// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@thirdweb-dev/contracts/base/ERC721LazyMint.sol";
import "@thirdweb-dev/contracts/base/ERC721Drop.sol";
import {ERC1155CreatorImplementation} from "@manifoldxyz/creator-core-solidity/contracts/ERC1155CreatorImplementation.sol";

contract NounCreepz is ERC721LazyMint {
    ERC1155CreatorImplementation public immutable eggs;

    constructor(
        string memory _name,
        string memory _symbol,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        address _eggsAddress
    ) ERC721LazyMint(_name, _symbol, _royaltyRecipient, _royaltyBps) {
        eggs = ERC1155CreatorImplementation(_eggsAddress);
    }

    function verifyClaim(address _claimer, uint256 _quantity)
        public
        view
        virtual
        override
    {
        address[] memory eggBalanceAddresses = new address[](5);
        eggBalanceAddresses[0] = _claimer;
        eggBalanceAddresses[1] = _claimer;
        eggBalanceAddresses[2] = _claimer;
        eggBalanceAddresses[3] = _claimer;
        eggBalanceAddresses[4] = _claimer;

        uint256[] memory eggBalanceIds = new uint256[](5);
        eggBalanceIds[0] = 2;
        eggBalanceIds[1] = 3;
        eggBalanceIds[2] = 4;
        eggBalanceIds[3] = 5;
        eggBalanceIds[4] = 6;

        uint256[] memory eggBalances = eggs.balanceOfBatch(
            eggBalanceAddresses,
            eggBalanceIds
        );

        uint256 eggCount = 0;

        for (uint256 i = 0; i < 5; i++) {
            eggCount = eggCount + eggBalances[i];
        }

        require(eggCount >= _quantity, "You don't own enough eggs");
    }

    function _transferTokensOnClaim(address _receiver, uint256 _quantity)
        internal
        override
        returns (uint256)
    {
        address[] memory eggBalanceAddresses = new address[](5);
        eggBalanceAddresses[0] = _receiver;
        eggBalanceAddresses[1] = _receiver;
        eggBalanceAddresses[2] = _receiver;
        eggBalanceAddresses[3] = _receiver;
        eggBalanceAddresses[4] = _receiver;

        uint256[] memory eggBalanceIds = new uint256[](5);
        // goerli
        // eggBalanceIds[0] = 2; // 5555 red
        // eggBalanceIds[1] = 3; // 4444 blue
        // eggBalanceIds[2] = 6; // 627 grey
        // eggBalanceIds[3] = 5; // 420 black
        // eggBalanceIds[4] = 4; // 65 bunny

        // main
        eggBalanceIds[0] = 3; // 5555 red
        eggBalanceIds[1] = 2; // 4444 blue
        eggBalanceIds[2] = 4; // 627 grey
        eggBalanceIds[3] = 6; // 420 black
        eggBalanceIds[4] = 5; // 65 bunny

        uint256[] memory eggBurnQuantities = new uint256[](5);

        uint256 eggSacrificesRemaining = _quantity;

        uint256[] memory eggBalances = eggs.balanceOfBatch(
            eggBalanceAddresses,
            eggBalanceIds
        );

        for (uint256 i = 0; i < 5; i++) {
            eggBurnQuantities[i] = eggBalances[i] >= eggSacrificesRemaining
                ? eggSacrificesRemaining
                : eggBalances[i];
            eggSacrificesRemaining =
                eggSacrificesRemaining -
                eggBurnQuantities[i];
        }

        eggs.burn(_receiver, eggBalanceIds, eggBurnQuantities);

        return super._transferTokensOnClaim(_receiver, _quantity);
    }
}