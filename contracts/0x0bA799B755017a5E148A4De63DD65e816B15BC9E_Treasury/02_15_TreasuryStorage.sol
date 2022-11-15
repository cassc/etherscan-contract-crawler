// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import "./libraries/LibTreasury.sol";
import "./interfaces/IERC20.sol";

contract TreasuryStorage {

    string internal notAccepted = "Treasury: not accepted";
    string internal notApproved = "Treasury: not approved";
    string internal invalidToken = "Treasury: invalid token";
    string internal insufficientReserves = "Treasury: insufficient reserves";

    IERC20 public tos;
    address public calculator;
    address public wethAddress;
    address public uniswapV3Factory;
    address public stakingV2;
    address public poolAddressTOSETH;

    uint256 public mintRate;
    uint256 public mintRateDenominator;
    uint256 public foundationAmount;
    uint256 public foundationTotalPercentage;

    mapping(LibTreasury.STATUS => address[]) public registry;
    mapping(LibTreasury.STATUS => mapping(address => bool)) public permissions;
    mapping(address => uint256) public backingIndexPlusOne;

    address[] public backings;
    LibTreasury.Minting[] public mintings;
    uint256[] public lpTokens;


    modifier nonZero(uint256 tokenId) {
        require(tokenId != 0, "Treasury: zero uint");
        _;
    }

    modifier nonZeroAddress(address account) {
        require(
            account != address(0),
            "Treasury:zero address"
        );
        _;
    }

}