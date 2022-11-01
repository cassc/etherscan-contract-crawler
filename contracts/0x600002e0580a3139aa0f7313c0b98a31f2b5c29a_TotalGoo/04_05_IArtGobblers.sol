// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.15;

import {IERC721} from "@openzeppelin/token/ERC721/IERC721.sol";

/// @author Philogy <https://github.com/Philogy>
/// @notice Not full interface, certain methods missing
interface IArtGobblers is IERC721 {
    function goo() external view returns (address);

    function tokenURI(uint256 gobblerId) external view returns (string memory);

    function gooBalance(address user) external view returns (uint256);

    function removeGoo(uint256 gooAmount) external;

    function addGoo(uint256 gooAmount) external;

    function getUserEmissionMultiple(address user)
        external
        view
        returns (uint256);

    function getGobblerEmissionMultiple(uint256 gobblerId)
        external
        view
        returns (uint256);

    function mintLegendaryGobbler(uint256[] calldata gobblerIds)
        external
        returns (uint256 gobblerId);

    function mintFromGoo(uint256 maxPrice, bool useVirtualBalance)
        external
        returns (uint256 gobblerId);

    function legendaryGobblerPrice() external view returns (uint256);
}