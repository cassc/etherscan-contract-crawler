//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./interfaces.sol";

contract Variables {
    VaultInterface public constant vault =
        VaultInterface(0xc383a3833A87009fD9597F8184979AF5eDFad019);
    IAaveAddressProvider internal constant aaveAddressProvider =
        IAaveAddressProvider(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5);
    address public constant wethAddr =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant stEthAddr =
        0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
}