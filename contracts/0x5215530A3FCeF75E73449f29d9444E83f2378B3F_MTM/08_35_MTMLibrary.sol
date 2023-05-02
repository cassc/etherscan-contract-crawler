// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

library MTMLibrary {

  // @dev Pool details are stored in memory for cheaper lookup
  struct Pool{
    address poolAddress;
    bool isV2;
  }

  // Stable Coins
  address internal constant USDT_ADDRESS = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
  address internal constant USDC_ADDRESS = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
  address internal constant LUSD_ADDRESS = address(0x5f98805A4E8be255a32880FDeC7F6728C6568bA0);
  address internal constant GUSD_ADDRESS = address(0x056Fd409E1d7A124BD7017459dFEa2F387b6d5Cd);
  address internal constant FRAX_ADDRESS = address(0x853d955aCEf822Db058eb8505911ED77F175b99e);
  address internal constant USDP_ADDRESS = address(0x1456688345527bE1f37E9e627DA0837D6f08C925);
  address internal constant MIM_ADDRESS = address(0x99D8a9C45b2ecA8864373A26D1459e3Dff1e17F3);
  address internal constant DAI_ADDRESS = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);
  address internal constant USDD_ADDRESS = address(0x0C10bF8FcB7Bf5412187A595ab97a3609160b5c6);
  address internal constant FEI_ADDRESS = address(0x956F47F50A910163D8BF957Cf5846D573E7f87CA);

  // WETH
  address internal constant WETH_ADDRESS = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
  address internal constant WETH_USDC_POOL = address(0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640);
  address internal constant WETH_USDT_POOL = address(0x0d4a11d5EEaaC28EC3F61d100daF4d40471f1852);

  uint8 internal constant TWAP_INTERVAL = 15;

  // @dev An array of all available pools for MTM minting
  function availablePools() internal pure returns(Pool[17] memory) {
    return [
      Pool(0xCBCdF9626bC03E24f779434178A73a0B4bad62eD, false), // WBTC
      Pool(0x3328CA5b535D537F88715b305375C591cF52d541, false), // PLSD
      Pool(0x25c0eDc51909fc20429c6EcE9B8F4FBB5af13878, false), // ASIC
      Pool(0xA5eF2a6BbE8852BD6fd2EF6AB9bB45081a6F531C, false), // PLSB
      Pool(0x2F62f2B4c5fcd7570a709DeC05D68EA19c82A9ec, false), // SHIB
      Pool(0x69D91B94f0AaF8e8A2586909fA77A5c2c89818d5, false), // HEX
      Pool(0xE859041c9C6D70177f83DE991B9d757E13CEA26E, false), // HDRN
      Pool(0x3aAf77ba7Da262e34dFfb9B10fC6777BfDA79Ab7, false), // ICSA
      Pool(0x2a9d2ba41aba912316D16742f259412B681898Db, false), // XEN
      Pool(0x30aA16699d08A6af61b7D1860845C4855b86713e, false), // DXN
      Pool(0x2CA1D6950182D28434f89A719ED9E915b8c417B5, false), // DBI
      Pool(0xA43fe16908251ee70EF74718545e4FE6C5cCEc9f, true), // PEPE
      Pool(0x0F23d49bC92Ec52FF591D091b3e16c937034496E, true), // WOJAK
      Pool(0x5281E311734869C64ca60eF047fd87759397EFe6, true), // CULT
      Pool(0xA5e9C917b4B821e4E0A5bbeFce078Ab6540d6B5E, true), // STARL
      Pool(0x2dB388d12c56fA6Bd81b101Aa6Ec8542e315eC5C, true), // CHAD
      Pool(0x6591c4BcD6D7A1eb4E537DA8B78676C1576Ba244, true) // BOND
    ];
  }

  function name(address token) internal view returns(string memory) {
    if(token == address(0)) {
      return 'Ethereum';
    } else {
      return ERC20(token).name();
    }
  }

  function decimals(address token) internal view returns(uint) {
    if(token == address(0)) {
      return 18;
    } else {
      return ERC20(token).decimals();
    }
  }

  function isStable(address token) internal pure returns(bool) {
    return
      token == USDT_ADDRESS ||
      token == USDC_ADDRESS ||
      token == LUSD_ADDRESS ||
      token == GUSD_ADDRESS ||
      token == FRAX_ADDRESS ||
      token == USDP_ADDRESS ||
      token == MIM_ADDRESS  ||
      token == DAI_ADDRESS  ||
      token == USDD_ADDRESS ||
      token == FEI_ADDRESS;
  }

  function isEther(address token) internal pure returns(bool) {
    return token == WETH_ADDRESS || token == address(0);
  }

}