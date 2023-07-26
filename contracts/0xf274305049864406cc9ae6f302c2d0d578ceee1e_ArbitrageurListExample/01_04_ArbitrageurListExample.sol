// (c) Copyright 2022, Bad Pumpkin Inc. All Rights Reserved
//
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.7.6;

import { IArbitrageurList } from "../interfaces/IArbitrageurList.sol";
import { ReentrancyGuard } from "../balancer-core-v2/lib/openzeppelin/ReentrancyGuard.sol";

address constant NULL_ADDR = address(0);

/// @notice Abstract contract for managing list of addresses permitted to perform preferred rate
///         arbitrage swaps on Cron-Fi TWAMM V1.0.
///
/// @dev    In Cron-Fi TWAMM V1.0 pools, the partner swap (preferred rate arbitrage swap) may only
///         be successfully called by an address that returns true when isArbitrageur in a contract
///         derived from this one (the caller must also specify the address of the arbitrage partner
///         to facilitate a call to isArbitrageur in the correct contract).
///
/// @dev    Two mechanisms are provided for updating the arbitrageur list, they are:
///             - The setArbitrageurs method, which allows a list of addresses to
///               be given or removed arbitrage permission.
///             - The nextList mechanism. In order to use this mechanism, a new contract deriving
///               from this contract with new arbitrage addresses specified must be deployed.
///               A listOwner then sets the nextList address to the newly deployed contract
///               address with the setNextList method.
///               Finally, the arbPartner address in the corresponding Cron-Fi TWAMM contract will
///               then call updateArbitrageList to retrieve the new arbitrageur list contract address
///               from this contract instance. Note that all previous arbitraguer contracts in the TWAMM
///               contract using the updated list are ignored.
///
/// @dev    Note that this is a bare-bones implementation without conveniences like a list to
///         inspect all current arbitraguer addresses at once (emitted events can be consulted and
///         aggregated off-chain for this purpose), however users are encouraged to modify the contract
///         as they wish as long as the following methods continue to function as specified:
///             - isArbitrageur
contract ArbitrageurListExample is IArbitrageurList, ReentrancyGuard {
  mapping(address => bool) private listOwners;
  mapping(address => bool) private permittedAddressMap;
  address public override(IArbitrageurList) nextList;

  modifier senderIsListOwner() {
    require(listOwners[msg.sender], "Sender must be listOwner");
    _;
  }

  /// @notice Constructs this contract with next contract and the specified list of addresses permitted
  ///         to arbitrage.
  /// @param _arbitrageurs is a list of addresses to give arbitrage permission to on contract instantiation.
  ///
  constructor(address[] memory _arbitrageurs) {
    bool permitted = true;

    listOwners[msg.sender] = permitted;
    emit ListOwnerPermissions(msg.sender, msg.sender, permitted);

    setArbitrageurs(_arbitrageurs, permitted);
    emit ArbitrageurPermissions(msg.sender, _arbitrageurs, permitted);

    nextList = NULL_ADDR;
  }

  /// @notice Sets whether or not a specified address is a list owner.
  /// @param _address is the address to give or remove list owner priviliges from.
  /// @param _permitted if true, gives the specified address list owner priviliges. If false
  ///        removes list owner priviliges.
  function setListOwner(address _address, bool _permitted) public nonReentrant senderIsListOwner {
    listOwners[_address] = _permitted;

    emit ListOwnerPermissions(msg.sender, _address, _permitted);
  }

  /// @notice Sets whether the specified list of addresses is permitted to arbitrage Cron-Fi TWAMM
  ///         pools at a preffered rate or not.
  /// @param _arbitrageurs is a list of addresses to add or remove arbitrage permission from.
  /// @param _permitted specifies if the list of addresses contained in _arbitrageurs will be given
  ///        arbitrage permission when set to true. When false, arbitrage permission is removed from
  ///        the specified addresses.
  function setArbitrageurs(address[] memory _arbitrageurs, bool _permitted) public override nonReentrant senderIsListOwner {
    uint256 length = _arbitrageurs.length;
    for (uint256 index = 0; index < length; index++) {
      permittedAddressMap[_arbitrageurs[index]] = _permitted;
    }

    emit ArbitrageurPermissions(msg.sender, _arbitrageurs, _permitted);
  }

  /// @notice Sets the next contract address to use for arbitraguer permissions. Requires that the
  ///         contract be instantiated and that a call to updateArbitrageList is made by the
  ///         arbitrage partner list on the corresponding TWAMM pool.
  /// @param _address is the address of the instantiated contract deriving from this contract to
  ///        use for address arbitrage permissions.
  function setNextList(address _address) public nonReentrant senderIsListOwner {
    nextList = _address;

    emit NextList(msg.sender, _address);
  }

  /// @notice Returns true if specified address has list owner permissions.
  /// @param _address is the address to check for list owner permissions.
  function isListOwner(address _address) public view returns (bool) {
    return listOwners[_address];
  }

  /// @notice Returns true if the provide address is permitted the preferred
  ///         arbitrage rate in the partner swap method of a Cron-Fi TWAMM pool.
  ///         Returns false otherwise.
  /// @param _address the address to check for arbitrage rate permissions.
  ///
  function isArbitrageur(address _address) public view override(IArbitrageurList) returns (bool) {
    return permittedAddressMap[_address];
  }
}