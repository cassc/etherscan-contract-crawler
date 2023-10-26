// SPDX-License-Identifier: MIT
/**
 _____
/  __ \
| /  \/ ___  _ ____   _____ _ __ __ _  ___ _ __   ___ ___
| |    / _ \| '_ \ \ / / _ \ '__/ _` |/ _ \ '_ \ / __/ _ \
| \__/\ (_) | | | \ V /  __/ | | (_| |  __/ | | | (_|  __/
 \____/\___/|_| |_|\_/ \___|_|  \__, |\___|_| |_|\___\___|
                                 __/ |
                                |___/
 */
pragma solidity ^0.8.0;

import "./interfaces/IPresaleCvgSeed.sol";
import "./interfaces/IboInterface.sol";
import "./interfaces/IPresaleCvgWl.sol";

contract ProtoDao {
    /// @dev contract addresses
    IPresaleCvgSeed public immutable seedPreseed;
    IboInterface public immutable ibo;
    IPresaleCvgWl public immutable presale;
    address public immutable podTreasury;

    /// @dev corresponds to 8.5% of total CVG sold
    uint256 public constant POD_CVG_AMOUNT = 997995 ether;

    constructor(IPresaleCvgSeed _seedPreseed, IboInterface _ibo, IPresaleCvgWl _presale, address _podTreasury) {
        seedPreseed = _seedPreseed;
        ibo = _ibo;
        presale = _presale;
        podTreasury = _podTreasury;
    }

    function getCvgAmount(address _user) external view returns (uint256) {
        if (_user == podTreasury) return POD_CVG_AMOUNT;

        uint256 totalAmount;

        IPresaleCvgSeed _seedPreseed = seedPreseed;
        IboInterface _ibo = ibo;
        IPresaleCvgWl _presale = presale;

        /// @dev get CVG amount from seed and preseed
        uint256[] memory seedTokenIds = seedPreseed.getTokenIdsForWallet(_user);
        for (uint256 i; i < seedTokenIds.length;) {
            totalAmount += _seedPreseed.presaleInfoTokenId(seedTokenIds[i]).cvgAmount;
            unchecked { ++i; }
        }

        /// @dev get CVG amount from IBO
        uint256[] memory iboTokenIds = _ibo.getTokenIdsForWallet(_user);
        for (uint256 i; i < iboTokenIds.length;) {
            totalAmount += _ibo.totalCvgPerToken(iboTokenIds[i]);
            unchecked { ++i; }
        }

        /// @dev get CVG amount from presale (whitelist)
        uint256[] memory presaleTokenIds = _presale.getTokenIdsForWallet(_user);
        for (uint256 i; i < presaleTokenIds.length;) {
            totalAmount += _presale.presaleInfos(presaleTokenIds[i]).cvgAmount;
            unchecked { ++i; }
        }

        return totalAmount;
    }
}