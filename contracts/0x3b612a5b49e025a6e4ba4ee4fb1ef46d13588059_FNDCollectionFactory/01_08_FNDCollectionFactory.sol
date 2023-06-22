/*
  ･
   *　★
      ･ ｡
        　･　ﾟ☆ ｡
  　　　 *　★ ﾟ･｡ *  ｡
          　　* ☆ ｡･ﾟ*.｡
      　　　ﾟ *.｡☆｡★　･
​
                      `                     .-:::::-.`              `-::---...```
                     `-:`               .:+ssssoooo++//:.`       .-/+shhhhhhhhhhhhhyyyssooo:
                    .--::.            .+ossso+/////++/:://-`   .////+shhhhhhhhhhhhhhhhhhhhhy
                  `-----::.         `/+////+++///+++/:--:/+/-  -////+shhhhhhhhhhhhhhhhhhhhhy
                 `------:::-`      `//-.``.-/+ooosso+:-.-/oso- -////+shhhhhhhhhhhhhhhhhhhhhy
                .--------:::-`     :+:.`  .-/osyyyyyyso++syhyo.-////+shhhhhhhhhhhhhhhhhhhhhy
              `-----------:::-.    +o+:-.-:/oyhhhhhhdhhhhhdddy:-////+shhhhhhhhhhhhhhhhhhhhhy
             .------------::::--  `oys+/::/+shhhhhhhdddddddddy/-////+shhhhhhhhhhhhhhhhhhhhhy
            .--------------:::::-` +ys+////+yhhhhhhhddddddddhy:-////+yhhhhhhhhhhhhhhhhhhhhhy
          `----------------::::::-`.ss+/:::+oyhhhhhhhhhhhhhhho`-////+shhhhhhhhhhhhhhhhhhhhhy
         .------------------:::::::.-so//::/+osyyyhhhhhhhhhys` -////+shhhhhhhhhhhhhhhhhhhhhy
       `.-------------------::/:::::..+o+////+oosssyyyyyyys+`  .////+shhhhhhhhhhhhhhhhhhhhhy
       .--------------------::/:::.`   -+o++++++oooosssss/.     `-//+shhhhhhhhhhhhhhhhhhhhyo
     .-------   ``````.......--`        `-/+ooooosso+/-`          `./++++///:::--...``hhhhyo
                                              `````
   *　
      ･ ｡
　　　　･　　ﾟ☆ ｡
  　　　 *　★ ﾟ･｡ *  ｡
          　　* ☆ ｡･ﾟ*.｡
      　　　ﾟ *.｡☆｡★　･
    *　　ﾟ｡·*･｡ ﾟ*
  　　　☆ﾟ･｡°*. ﾟ
　 ･ ﾟ*｡･ﾟ★｡
　　･ *ﾟ｡　　 *
　･ﾟ*｡★･
 ☆∴｡　*
･ ｡
*/

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-solc-8/proxy/Clones.sol";
import "@openzeppelin/contracts-solc-8/utils/Address.sol";
import "@openzeppelin/contracts-solc-8/utils/Strings.sol";

import "./interfaces/solc8/ICollectionContractInitializer.sol";
import "./interfaces/solc8/IRoles.sol";
import "./interfaces/solc8/ICollectionFactory.sol";
import "./interfaces/solc8/IProxyCall.sol";

/**
 * @title A factory to create NFT collections.
 * @notice Call this factory to create and initialize a minimal proxy pointing to the NFT collection contract.
 */
contract FNDCollectionFactory is ICollectionFactory {
  using Address for address;
  using Address for address payable;
  using Clones for address;
  using Strings for uint256;

  /**
   * @notice The contract address which manages common roles.
   * @dev Used by the collections for a shared operator definition.
   */
  IRoles public rolesContract;

  /**
   * @notice The address of the template all new collections will leverage.
   */
  address public implementation;

  /**
   * @notice The address of the proxy call contract implementation.
   * @dev Used by the collections to safely call another contract with arbitrary call data.
   */
  IProxyCall public proxyCallContract;

  /**
   * @notice The implementation version new collections will use.
   * @dev This is auto-incremented each time the implementation is changed.
   */
  uint256 public version;

  event RolesContractUpdated(address indexed rolesContract);
  event CollectionCreated(
    address indexed collectionContract,
    address indexed creator,
    uint256 indexed version,
    string name,
    string symbol,
    uint256 nonce
  );
  event ImplementationUpdated(address indexed implementation, uint256 indexed version);
  event ProxyCallContractUpdated(address indexed proxyCallContract);

  modifier onlyAdmin() {
    require(rolesContract.isAdmin(msg.sender), "FNDCollectionFactory: Caller does not have the Admin role");
    _;
  }

  constructor(address _proxyCallContract, address _rolesContract) {
    _updateRolesContract(_rolesContract);
    _updateProxyCallContract(_proxyCallContract);
  }

  /**
   * @notice Create a new collection contract.
   * @param nonce An arbitrary value used to allow a creator to mint multiple collections.
   * @dev The nonce is required and must be unique for the msg.sender + implementation version,
   * otherwise this call will revert.
   */
  function createCollection(
    string calldata name,
    string calldata symbol,
    uint256 nonce
  ) external returns (address) {
    require(bytes(symbol).length > 0, "FNDCollectionFactory: Symbol is required");

    // This reverts if the NFT was previously created using this implementation version + msg.sender + nonce
    address proxy = implementation.cloneDeterministic(_getSalt(msg.sender, nonce));

    ICollectionContractInitializer(proxy).initialize(payable(msg.sender), name, symbol);

    emit CollectionCreated(proxy, msg.sender, version, name, symbol, nonce);

    // Returning the address created allows other contracts to integrate with this call
    return address(proxy);
  }

  /**
   * @notice Allows Foundation to change the admin role contract address.
   */
  function adminUpdateRolesContract(address _rolesContract) external onlyAdmin {
    _updateRolesContract(_rolesContract);
  }

  /**
   * @notice Allows Foundation to change the collection implementation used for future collections.
   * This call will auto-increment the version.
   * Existing collections are not impacted.
   */
  function adminUpdateImplementation(address _implementation) external onlyAdmin {
    _updateImplementation(_implementation);
  }

  /**
   * @notice Allows Foundation to change the proxy call contract address.
   */
  function adminUpdateProxyCallContract(address _proxyCallContract) external onlyAdmin {
    _updateProxyCallContract(_proxyCallContract);
  }

  /**
   * @notice Returns the address of a collection given the current implementation version, creator, and nonce.
   * This will return the same address whether the collection has already been created or not.
   * @param nonce An arbitrary value used to allow a creator to mint multiple collections.
   */
  function predictCollectionAddress(address creator, uint256 nonce) external view returns (address) {
    return implementation.predictDeterministicAddress(_getSalt(creator, nonce));
  }

  function _updateRolesContract(address _rolesContract) private {
    require(_rolesContract.isContract(), "FNDCollectionFactory: RolesContract is not a contract");
    rolesContract = IRoles(_rolesContract);

    emit RolesContractUpdated(_rolesContract);
  }

  /**
   * @dev Updates the implementation address, increments the version, and initializes the template.
   * Since the template is initialized when set, implementations cannot be re-used.
   * To downgrade the implementation, deploy the same bytecode again and then update to that.
   */
  function _updateImplementation(address _implementation) private {
    require(_implementation.isContract(), "FNDCollectionFactory: Implementation is not a contract");
    implementation = _implementation;
    version++;

    // The implementation is initialized when assigned so that others may not claim it as their own.
    ICollectionContractInitializer(_implementation).initialize(
      payable(address(rolesContract)),
      string(abi.encodePacked("Foundation Collection Template v", version.toString())),
      string(abi.encodePacked("FCTv", version.toString()))
    );

    emit ImplementationUpdated(_implementation, version);
  }

  function _updateProxyCallContract(address _proxyCallContract) private {
    require(_proxyCallContract.isContract(), "FNDCollectionFactory: Proxy call address is not a contract");
    proxyCallContract = IProxyCall(_proxyCallContract);

    emit ProxyCallContractUpdated(_proxyCallContract);
  }

  function _getSalt(address creator, uint256 nonce) private pure returns (bytes32) {
    return keccak256(abi.encodePacked(creator, nonce));
  }
}