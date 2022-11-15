// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import "./libraries/LibBondDepository.sol";

import "./interfaces/IERC20.sol";
import "./interfaces/IStaking.sol";

contract BondDepositoryStorage {

    IERC20 public tos;
    IStaking public staking;
    address public treasury;
    address public calculator;
    address public uniswapV3Factory;
    address public dtos;

    bool private _entered;

    uint256[] public marketList;
    mapping(uint256 => LibBondDepository.Market) public markets;


    modifier nonZero(uint256 tokenId) {
        require(tokenId != 0, "BondDepository: zero uint");
        _;
    }

    modifier nonZeroAddress(address account) {
        require(
            account != address(0),
            "BondDepository:zero address"
        );
        _;
    }

    modifier nonReentrant() {
        require(_entered != true, "ReentrancyGuard: reentrant call");

        _entered = true;

        _;

        _entered = false;
    }

}