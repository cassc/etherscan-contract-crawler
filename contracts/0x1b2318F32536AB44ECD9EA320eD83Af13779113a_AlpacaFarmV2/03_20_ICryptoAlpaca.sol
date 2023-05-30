// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface ICryptoAlpaca is IERC1155 {
    function getAlpaca(uint256 _id)
        external
        view
        returns (
            uint256 id,
            bool isReady,
            uint256 cooldownEndBlock,
            uint256 birthTime,
            uint256 matronId,
            uint256 sireId,
            uint256 hatchingCost,
            uint256 hatchingCostMultiplier,
            uint256 hatchCostMultiplierEndBlock,
            uint256 generation,
            uint256 gene,
            uint256 energy,
            uint256 state
        );

    function hasPermissionToBreedAsSire(address _addr, uint256 _id)
        external
        view
        returns (bool);

    function grandPermissionToBreed(address _addr, uint256 _sireId) external;

    function clearPermissionToBreed(uint256 _alpacaId) external;

    function hatch(uint256 _matronId, uint256 _sireId)
        external
        payable
        returns (uint256);

    function crack(uint256 _id) external;
}