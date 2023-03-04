// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

/// @title BearCave: Only one true honey can make a bear wake up
interface IBearCave {
    struct HibernatingBear {
        uint256 id;
        uint256 specialHoneycombId; // defaults to 0
        uint256 publicMintTime; // block.timstamp that general public can start making honeycombs
        bool specialHoneycombFound; // So tokenID=0 can't wake bear before special honey is found
        bool isAwake; // don't try to wake if its already awake
    }

    struct MintConfig {
        uint32 maxHoneycomb; // Max # of generated honeys (Max of 4.2m -- we'll have 10420)
        uint32 maxClaimableHoneycomb; // # of honeycombs that can be claimed (total)
        uint256 honeycombPrice_ERC20;
        uint256 honeycombPrice_ETH;
    }

    /// @notice Puts the bear into the cave to mek it sleep
    /// @dev Should be permissioned to be onlyOwner
    /// @param _bearId ID of the bear to mek sleep
    function hibernateBear(uint256 _bearId) external;

    /// @notice Meks honey for `_bearID` that could wake it up. Will revert if user does not have the funds.
    /// @param _bearId ID of the bear the honey will wake up
    function mekHoneyCombWithERC20(uint256 _bearId, uint256 amount) external returns (uint256); // Makes honey for the bear

    /// @notice Same as `mekHoneyCombWithERC20` however this function accepts ETH payments
    function mekHoneyCombWithEth(uint256 _bearId, uint256 amount) external payable returns (uint256);

    /// @notice Takes special honey to wake up the bear
    /// @param _bearId ID of the bear to wake up
    function wakeBear(uint256 _bearId) external;
}