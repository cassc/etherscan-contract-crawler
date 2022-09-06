// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface ILooksRareTradingRewardsDistributor {
    function claim(
        uint8[] calldata treeIds,
        uint256[] calldata amounts,
        bytes32[][] calldata merkleProofs
    ) external;
}

library MELooksRareRewardProxy {
    using SafeERC20 for IERC20;

    address public constant LOOKSRAREREWARDCONTRACT =
        0x0554f068365eD43dcC98dcd7Fd7A8208a5638C72; // looksrare multi rewards distributor

    address public constant LOOKSTOKEN =
        0xf4d2888d29D722226FafA5d9B24F9164c092421E;

    address public constant MEREWARDS =
        0xE96b033FC6043c4Ec13aD1a35A36CEb5729b4972;

    function claim(
        uint8[] memory treeIds,
        uint256[] memory amounts,
        bytes32[][] memory merkleProofs
    ) external {
        bytes memory _data = abi.encodeWithSelector(
            ILooksRareTradingRewardsDistributor.claim.selector,
            treeIds,
            amounts,
            merkleProofs
        );

        (bool success, ) = LOOKSRAREREWARDCONTRACT.call{value: 0}(_data);

        SafeERC20.safeTransfer(IERC20(LOOKSTOKEN), MEREWARDS, amounts[0]);
        if (!success) {
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }
}