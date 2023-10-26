// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.5.0;

import { ICbETH } from "interfaces/external/coinbase/ICbETH.sol";
import { ISfrxETH } from "interfaces/external/frax/ISfrxETH.sol";
import { IStETH } from "interfaces/external/lido/IStETH.sol";
import { IRETH } from "interfaces/external/rocketPool/IRETH.sol";

/*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                 STORAGE SLOTS                                                  
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

/// @dev Storage position of `DiamondStorage` structure
/// @dev Equals `keccak256("diamond.standard.diamond.storage") - 1`
bytes32 constant DIAMOND_STORAGE_POSITION = 0xc8fcad8db84d3cc18b4c41d551ea0ee66dd599cde068d998e57d5e09332c131b;

/// @dev Storage position of `TransmuterStorage` structure
/// @dev Equals `keccak256("diamond.standard.transmuter.storage") - 1`
bytes32 constant TRANSMUTER_STORAGE_POSITION = 0xc1f2f38dde3351ac0a64934139e816326caa800303a1235dc53707d0de05d8bd;

/// @dev Storage position of `ImplementationStorage` structure
/// @dev Equals `keccak256("eip1967.proxy.implementation") - 1`
bytes32 constant IMPLEMENTATION_STORAGE_POSITION = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

/*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                     MATHS                                                      
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

uint256 constant BASE_6 = 1e6;
uint256 constant BASE_8 = 1e8;
uint256 constant BASE_9 = 1e9;
uint256 constant BASE_12 = 1e12;
uint256 constant BASE_18 = 1e18;
uint256 constant HALF_BASE_27 = 1e27 / 2;
uint256 constant BASE_27 = 1e27;
uint256 constant BASE_36 = 1e36;
uint256 constant MAX_BURN_FEE = 999_000_000;
uint256 constant MAX_MINT_FEE = BASE_12 - 1;

/*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                     REENTRANT                                                      
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

// The values being non-zero value makes deployment a bit more expensive,
// but in exchange the refund on every call to nonReentrant will be lower in
// amount. Since refunds are capped to a percentage of the total
// transaction's gas, it is best to keep them low in cases like this one, to
// increase the likelihood of the full refund coming into effect.
uint8 constant NOT_ENTERED = 1;
uint8 constant ENTERED = 2;

/*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                               COMMON ADDRESSES                                                 
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

address constant PERMIT_2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;
address constant ONE_INCH_ROUTER = 0x1111111254EEB25477B68fb85Ed929f73A960582;
address constant AGEUR = 0x1a7e4e63778B4f12a199C062f3eFdD288afCBce8;
ICbETH constant CBETH = ICbETH(0xBe9895146f7AF43049ca1c1AE358B0541Ea49704);
IRETH constant RETH = IRETH(0xae78736Cd615f374D3085123A210448E74Fc6393);
IStETH constant STETH = IStETH(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);
ISfrxETH constant SFRXETH = ISfrxETH(0xac3E018457B222d93114458476f3E3416Abbe38F);