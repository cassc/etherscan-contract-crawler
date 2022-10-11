// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "./ERC20Preset.sol";

/**
 * @title The NORI token on Ethereum.
 * @author Nori Inc.
 * @notice The NORI token is an unwrapped version of the BridgedPolygonNORI (bpNORI) token for use on Ethereum.
 * @dev This token is a layer-1 (L1) equivalent of the respective layer-1 (L2) bpNORI token.
 *
 * ##### Behaviors and features:
 *
 * - Check the [bpNORI docs](../docs/BridgedPolygonNORI.md) for more.
 *
 * ##### Inherits:
 *
 * - [ERC20Preset](../docs/ERC20Preset.md)
 */
contract NORI is ERC20Preset {
  /**
   * @notice Locks the contract, preventing any future re-initialization.
   * @dev See more [here](https://docs.openzeppelin.com/contracts/4.x/api/proxy#Initializable-_disableInitializers--).
   * @custom:oz-upgrades-unsafe-allow constructor
   */
  constructor() {
    _disableInitializers();
  }

  /**
   * @notice Initialize the NORI contract
   */
  function initialize() external virtual initializer {
    __Context_init_unchained();
    __ERC165_init_unchained();
    __AccessControl_init_unchained();
    __AccessControlEnumerable_init_unchained();
    __Pausable_init_unchained();
    __EIP712_init_unchained({name: "NORI", version: "1"});
    __ERC20_init_unchained({name_: "NORI", symbol_: "NORI"});
    __ERC20Permit_init_unchained("NORI");
    __ERC20Burnable_init_unchained();
    __ERC20Preset_init_unchained();
    __Multicall_init_unchained();
    _mint({account: _msgSender(), amount: 500_000_000 ether});
  }
}