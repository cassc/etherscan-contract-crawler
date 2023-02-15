// contracts/venus/interfaces/IVenusUnitroller.sol
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

interface IVenusUnitroller {
    function enterMarkets(address[] memory vTokens)
        external
        returns (uint256[] memory);

    function exitMarket(address vToken) external returns (uint256);

    function markets(address vTokenAddress)
        external
        view
        returns (bool, uint256);

    function claimVenus(address holder, address[] memory vTokens) external;

    function venusAccrued(address holder) external view returns (uint256);

    function venusSupplierIndex(address contractAddress, address holder)
        external
        view
        returns (uint256 supplierIndex);

    function venusBorrowerIndex(address contractAddress, address holder)
        external
        view
        returns (uint256 borrowerIndex);

    function venusSupplyState(address holder)
        external
        view
        returns (uint224 index, uint32 block);

    function venusBorrowState(address holder)
        external
        view
        returns (uint224 index, uint32 block);

    function venusSpeeds(address token) external view returns (uint256);

    function getAccountLiquidity(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );
}