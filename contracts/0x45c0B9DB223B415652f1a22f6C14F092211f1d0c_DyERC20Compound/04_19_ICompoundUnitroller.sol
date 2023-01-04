// contracts/compound/interfaces/ICompoundUnitroller.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 ________      ___    ___ ________   ________  _____ ______   ___  ________     
|\   ___ \    |\  \  /  /|\   ___  \|\   __  \|\   _ \  _   \|\  \|\   ____\    
\ \  \_|\ \   \ \  \/  / | \  \\ \  \ \  \|\  \ \  \\\__\ \  \ \  \ \  \___|    
 \ \  \ \\ \   \ \    / / \ \  \\ \  \ \   __  \ \  \\|__| \  \ \  \ \  \       
  \ \  \_\\ \   \/  /  /   \ \  \\ \  \ \  \ \  \ \  \    \ \  \ \  \ \  \____  
   \ \_______\__/  / /      \ \__\\ \__\ \__\ \__\ \__\    \ \__\ \__\ \_______\
    \|_______|\___/ /        \|__| \|__|\|__|\|__|\|__|     \|__|\|__|\|_______|
             \|___|/                                                            

 */

interface ICompoundUnitroller {
    function enterMarkets(address[] memory vTokens)
        external
        returns (uint256[] memory);

    function markets(address vTokenAddress)
        external
        view
        returns (bool, uint256);

    function claimComp(address holder, address[] memory vTokens) external;

    function compAccrued(address holder) external view returns (uint256);

    function compSupplierIndex(address contractAddress, address holder)
        external
        view
        returns (uint256 supplierIndex);

    function compBorrowerIndex(address contractAddress, address holder)
        external
        view
        returns (uint256 borrowerIndex);

    function compSupplyState(address holder)
        external
        view
        returns (uint224 index, uint32 block);

    function compBorrowState(address holder)
        external
        view
        returns (uint224 index, uint32 block);

    function compSupplySpeeds(address token) external view returns (uint256);

    function compBorrowSpeeds(address token) external view returns (uint256);
}