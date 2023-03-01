// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

library Utils {
    // See https://chainlist.org/
    uint256 private constant Ethereum = 1;
    uint256 private constant Ropsten = 3;
    uint256 private constant Rinkeby = 4;
    uint256 private constant Goerli = 5;
    uint256 private constant Kovan = 42;
    uint256 private constant Optimism = 10;
    uint256 private constant Optimism_Kovan = 69;
    uint256 private constant Optimism_Goerli = 420;
    uint256 private constant Arbitrum = 42161;
    uint256 private constant Arbitrum_Nova = 42170;
    uint256 private constant Arbitrum_Rinkeby = 421611;
    uint256 private constant Arbitrum_Goerli = 421613;
    uint256 private constant Hardhat = 31337;
    uint256 private constant Kiln = 1337802;
    uint256 private constant Sepolia = 11155111;
    uint256 private constant BSC = 56;
    uint256 private constant BSC_Test = 97;
    uint256 private constant Polygon = 137;
    uint256 private constant Polygon_Mumbai = 80001;

    /**
     * @dev Returns the chainID of the network.
     */
    function chainID() 
        internal 
        view 
        returns (uint256) 
    {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
    * @dev Returns if the current network is known.
     */
    function isKnownNetwork() 
        internal 
        view 
        returns (bool) 
    {
        uint256 chainid = chainID();
        return chainid == Ethereum || 
               chainid == Ropsten || 
               chainid == Rinkeby || 
               chainid == Goerli || 
               chainid == Kovan || 
               chainid == Optimism || 
               chainid == Optimism_Kovan || 
               chainid == Optimism_Goerli || 
               chainid == Arbitrum || 
               chainid == Arbitrum_Nova || 
               chainid == Arbitrum_Rinkeby ||
               chainid == Arbitrum_Goerli ||
               chainid == Kiln ||
               chainid == Sepolia ||
               chainid == BSC ||
               chainid == BSC_Test ||
               chainid == Polygon ||
               chainid == Polygon_Mumbai ||
               chainid == Hardhat;
    }

    /**
     * @dev Returns if the current network is considered mainnet.
     */
    function isMainnet() 
        internal 
        view 
        returns (bool) 
    {
        uint256 chainid = chainID();
        return chainid == Ethereum || 
               chainid == Optimism || 
               chainid == Arbitrum || 
               chainid == BSC || 
               chainid == Polygon || 
               chainid == Arbitrum_Nova;
    }

    /**
     * @dev Convers the address to the hex string format.
     */
    function addressToHexString(address account) 
        internal
        pure
        returns (string memory)
    {
        return StringsUpgradeable.toHexString(uint256(uint160(account)));
    }
}