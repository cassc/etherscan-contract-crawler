// @author: @gizmolab_
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IDoriStaking {
    function getStakedTokens(address _owner, address _contract)
        external
        view
        returns (uint256[] memory);
}

contract DoriVerification is Ownable {
    address public doriGenesis;
    address public dori1776;
    address public doriSweeperClub;
    address public doriStaking;

    constructor(
        address _doriGenesis,
        address _dori1776,
        address _doriSweeperClub,
        address _doriStaking
    ) {
        doriGenesis = _doriGenesis;
        dori1776 = _dori1776;
        doriSweeperClub = _doriSweeperClub;
        doriStaking = _doriStaking;
    }

    /*==============================================================
    ==                    User Verification Functions             ==
    ==============================================================*/

    function balanceOf(address _owner) external view returns (uint256) {
        require(doriStaking != address(0), "Dori Staking not set");
        require(doriGenesis != address(0), "Dori Genesis not set");
        require(dori1776 != address(0), "Dori 1776 not set");
        require(doriSweeperClub != address(0), "Dori Sweeper Club not set");
        return
            IDoriStaking(doriStaking)
                .getStakedTokens(_owner, doriGenesis)
                .length +
            IDoriStaking(doriStaking).getStakedTokens(_owner, dori1776).length +
            IDoriStaking(doriStaking)
                .getStakedTokens(_owner, doriSweeperClub)
                .length;
    }

    function balanceOfGen1(address _owner) external view returns (uint256) {
        require(doriStaking != address(0), "Dori Staking not set");
        require(doriGenesis != address(0), "Dori Genesis not set");
        return
            IDoriStaking(doriStaking)
                .getStakedTokens(_owner, doriGenesis)
                .length;
    }

    function balanceOfGen2(address _owner) external view returns (uint256) {
        require(doriStaking != address(0), "Dori Staking not set");
        require(dori1776 != address(0), "Dori 1776 not set");
        return
            IDoriStaking(doriStaking).getStakedTokens(_owner, dori1776).length;
    }

    function balanceOfSweeper(address _owner) external view returns (uint256) {
        require(doriStaking != address(0), "Dori Staking not set");
        require(doriSweeperClub != address(0), "Dori Sweeper Club not set");
        return
            IDoriStaking(doriStaking)
                .getStakedTokens(_owner, doriSweeperClub)
                .length;
    }

    /*==============================================================
    ==                    Owner Functions                         ==
    ==============================================================*/

    function setDoriGenesis(address _doriGenesis) external onlyOwner {
        doriGenesis = _doriGenesis;
    }

    function setDori1776(address _dori1776) external onlyOwner {
        dori1776 = _dori1776;
    }

    function setDoriSweeperClub(address _doriSweeperClub) external onlyOwner {
        doriSweeperClub = _doriSweeperClub;
    }

    function setDoriStaking(address _doriStaking) external onlyOwner {
        doriStaking = _doriStaking;
    }
}