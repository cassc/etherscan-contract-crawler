// SPDX-License-Identifier: MIT

/// @title County Fair FLea Market
/// @notice burn and redeem contract for Negotiations With The Abyss
/// @author transientlabs.xyz

pragma solidity 0.8.17;

import {Ownable} from "Ownable.sol";

interface BurnContract {
    function burn(address from, uint256[] calldata tokenIds, uint256[] calldata amounts) external;
}

interface RedeemContract {
    function externalMint(address recipient, uint256 tokenId) external;
}

contract CountyFairFleaMarket is Ownable {

    // State Variables
    bool public redeemOpen;
    BurnContract public burnContract;
    RedeemContract public redeemContract;
    mapping(uint256 => uint256) private _pointsForPrize;

    // constructor
    constructor(address burnContractAddress, address redeemContractAddress) Ownable() {
        burnContract = BurnContract(burnContractAddress);
        redeemContract = RedeemContract(redeemContractAddress);
    }

    /// @notice function to set points for a prize
    /// @dev requires owner
    function setPointsPerPrize(uint256[] calldata prizeTokenIds, uint256[] calldata prizePoints) external onlyOwner {
        require(prizeTokenIds.length == prizePoints.length, "array length mismatch");

        for (uint256 i = 0; i < prizePoints.length; i++) {
            _pointsForPrize[prizeTokenIds[i]] = prizePoints[i];
        }
    }

    /// @notice function to open/close the redeem
    /// @dev requires owner
    function setRedeemStatus(bool status) external onlyOwner {
        redeemOpen = status;
    }

    /// @notice redeem function
    function redeem(uint256 prizeTokenId) external {
        require(redeemOpen, "redeem not open");
        uint256 numToBurn = _pointsForPrize[prizeTokenId];
        require(numToBurn > 0, "invalid prize token id");
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = numToBurn;
        burnContract.burn(msg.sender, tokenIds, amounts);
        redeemContract.externalMint(msg.sender, prizeTokenId);
    }
}