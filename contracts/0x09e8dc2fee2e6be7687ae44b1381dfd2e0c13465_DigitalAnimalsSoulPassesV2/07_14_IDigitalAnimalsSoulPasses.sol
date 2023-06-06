// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IDigitalAnimalsSoulPasses is IERC1155 {
    event NoOneCanStopDeath(
        address indexed from
    );

    enum Pass { NONE, COMMITED, SOULBOURNE, SOUL_REAPERS, LORD_OF_THE_REAPERS }

    function usersPass(address operator) external view returns (Pass pass);
    function mintedPass(Pass pass) external view returns (uint256 minted);
}