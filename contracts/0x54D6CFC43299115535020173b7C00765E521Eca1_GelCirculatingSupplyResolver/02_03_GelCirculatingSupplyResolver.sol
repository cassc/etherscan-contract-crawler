// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    IERC2ILinearVestingHubHelper
} from "./interfaces/ILinearVestingHubHelper.sol";

/**
 * @title GelCirculatingSupplyResolver
 * @dev Returns the current circluating GEL token supply
 * @author hilmarx (Hilmar Orth) - Gelato Network
 */
contract GelCirculatingSupplyResolver {
    address public constant GEL_DAO =
        0x4C64ce7C270E1316692067771bbb0DCe6Ec69B7C;
    address public constant GEL_VESTING_HUB_HELPER =
        0x766F4416dc7BB3a2a38240176F1427E01291FAeE;
    address public constant GEL_VESTING_TREASURY =
        0x163407FDA1a93941358c1bfda39a868599553b6D;
    address public constant GEL = 0x15b7c0c907e4C6b9AdaAaabC300C08991D6CEA05;
    uint256 public constant VESTING_START = 1631548800; // 13 September 2021 16:00:00 GMT
    uint256 public constant VESTING_DURATION = 126230400; // 4 years

    /**
     * @notice Returns the current circulating GEL supply
     * @return circulatingSupplyWei Circulating supply of GEL in wei.
     * @return circulatingSupply Parsed circulating supply of GEL.
     */
    function returnCirculatingGelSupply()
        external
        view
        returns (uint256 circulatingSupplyWei, uint256 circulatingSupply)
    {
        circulatingSupplyWei = IERC20(GEL).totalSupply();

        uint256 gelDaoBalance = IERC20(GEL).balanceOf(GEL_DAO);
        uint256 gelVestingTreasuryBalance = IERC20(GEL).balanceOf(
            GEL_VESTING_TREASURY
        );

        // DAOs token are deducted from circulating supply
        circulatingSupplyWei -= gelDaoBalance;

        // Deduct locked tokens in GEL Vesting Hub
        uint256 lockedVestingHubTokens = IERC2ILinearVestingHubHelper(
            GEL_VESTING_HUB_HELPER
        ).calcTotalUnvestedTokens();

        circulatingSupplyWei -= lockedVestingHubTokens;

        // Deduct to be locked tokens in GEL Vesting Treasury
        uint256 lockedGelVestinTreasuryTokens = gelVestingTreasuryBalance -
            _getVestedTkns(
                gelVestingTreasuryBalance,
                VESTING_START,
                VESTING_DURATION
            );
        circulatingSupplyWei -= lockedGelVestinTreasuryTokens;
        circulatingSupply = circulatingSupplyWei / 10**18;
    }

    // solhint-disable not-rely-on-time
    function _getVestedTkns(
        uint256 tknBalance_,
        uint256 startDate_,
        uint256 duration_
    ) private view returns (uint256) {
        return ((tknBalance_) * (block.timestamp - startDate_)) / duration_;
    }
}