// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {ISynthereumRegistry} from './interfaces/IRegistry.sol';
import {ISynthereumFinder} from '../interfaces/IFinder.sol';
import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SynthereumInterfaces} from '../Constants.sol';
import {
  EnumerableSet
} from '../../../@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import {StringUtils} from '../../base/utils/StringUtils.sol';
import {
  ReentrancyGuard
} from '../../../@openzeppelin/contracts/security/ReentrancyGuard.sol';

/**
 * @title Register and track all the pools deployed
 */
contract SynthereumRegistry is ISynthereumRegistry, ReentrancyGuard {
  using EnumerableSet for EnumerableSet.AddressSet;
  using EnumerableSet for EnumerableSet.UintSet;
  using EnumerableSet for EnumerableSet.Bytes32Set;
  using StringUtils for string;
  using StringUtils for bytes32;

  //----------------------------------------
  // Storage
  //----------------------------------------

  ISynthereumFinder public immutable synthereumFinder;

  string public registryType;

  mapping(string => mapping(IERC20 => mapping(uint8 => EnumerableSet.AddressSet)))
    private symbolToElements;

  EnumerableSet.Bytes32Set private syntheticTokens;

  EnumerableSet.AddressSet private collaterals;

  EnumerableSet.UintSet private versions;

  //----------------------------------------
  // Modifiers
  //----------------------------------------

  /**
   * @notice Check if the sender is the deployer
   */
  modifier onlyDeployer() {
    address deployer =
      synthereumFinder.getImplementationAddress(SynthereumInterfaces.Deployer);
    require(msg.sender == deployer, 'Sender must be Synthereum deployer');
    _;
  }

  //----------------------------------------
  // Constructor
  //----------------------------------------

  /**
   * @notice Constructs the SynthereumRegistry contract
   * @param _registryType Type of registry
   * @param _synthereumFinder Synthereum finder contract
   * @param _registryInterface Interface identifier forthe finder associated to the registry
   */
  constructor(
    string memory _registryType,
    ISynthereumFinder _synthereumFinder,
    bytes32 _registryInterface
  ) {
    synthereumFinder = _synthereumFinder;
    registryType = _registryType;

    try _synthereumFinder.getImplementationAddress(_registryInterface) returns (
      address oldRegistryAddr
    ) {
      ISynthereumRegistry oldRegistry = ISynthereumRegistry(oldRegistryAddr);
      string[] memory oldSyntheticTokens = oldRegistry.getSyntheticTokens();
      address[] memory oldCollaterals = oldRegistry.getCollaterals();
      uint8[] memory oldVersions = oldRegistry.getVersions();

      for (uint256 j = 0; j < oldSyntheticTokens.length; j++) {
        for (uint256 i = 0; i < oldCollaterals.length; i++) {
          for (uint256 k = 0; k < oldVersions.length; k++) {
            address[] memory oldElements =
              oldRegistry.getElements(
                oldSyntheticTokens[j],
                IERC20(oldCollaterals[i]),
                oldVersions[k]
              );
            for (uint256 w = 0; w < oldElements.length; w++) {
              symbolToElements[oldSyntheticTokens[j]][
                IERC20(oldCollaterals[i])
              ][oldVersions[k]]
                .add(oldElements[w]);
            }
          }
        }
      }

      for (uint256 j = 0; j < oldSyntheticTokens.length; j++) {
        syntheticTokens.add(oldSyntheticTokens[j].stringToBytes32());
      }

      for (uint256 j = 0; j < oldCollaterals.length; j++) {
        collaterals.add(oldCollaterals[j]);
      }

      for (uint256 j = 0; j < oldVersions.length; j++) {
        versions.add(oldVersions[j]);
      }
    } catch {}
  }

  /**
   * @notice Allow the deployer to register an element
   * @param syntheticTokenSymbol Symbol of the syntheticToken of the element to register
   * @param collateralToken Collateral ERC20 token of the element to register
   * @param version Version of the element to register
   * @param element Address of the element to register
   */
  function register(
    string calldata syntheticTokenSymbol,
    IERC20 collateralToken,
    uint8 version,
    address element
  ) external override onlyDeployer nonReentrant {
    require(
      symbolToElements[syntheticTokenSymbol][collateralToken][version].add(
        element
      ),
      'Element already supported'
    );
    syntheticTokens.add(syntheticTokenSymbol.stringToBytes32());
    collaterals.add(address(collateralToken));
    versions.add(version);
  }

  /**
   * @notice Allow the deployer to unregister an element
   * @param syntheticTokenSymbol Symbol of the syntheticToken of the element to unregister
   * @param collateralToken Collateral ERC20 token of the element to unregister
   * @param version Version of the element  to unregister
   * @param element Address of the element  to unregister
   */
  function unregister(
    string calldata syntheticTokenSymbol,
    IERC20 collateralToken,
    uint8 version,
    address element
  ) external override onlyDeployer nonReentrant {
    require(
      symbolToElements[syntheticTokenSymbol][collateralToken][version].remove(
        element
      ),
      'Element not supported'
    );
  }

  /**
   * @notice Returns if a particular element exists or not
   * @param syntheticTokenSymbol Synthetic token symbol of the element
   * @param collateralToken ERC20 contract of collateral currency
   * @param version Version of the element
   * @param element Contract of the element to check
   * @return isElementDeployed Returns true if a particular element exists, otherwise false
   */
  function isDeployed(
    string calldata syntheticTokenSymbol,
    IERC20 collateralToken,
    uint8 version,
    address element
  ) external view override returns (bool isElementDeployed) {
    isElementDeployed = symbolToElements[syntheticTokenSymbol][collateralToken][
      version
    ]
      .contains(element);
  }

  /**
   * @notice Returns all the elements with partcular symbol, collateral and version
   * @param syntheticTokenSymbol Synthetic token symbol of the element
   * @param collateralToken ERC20 contract of collateral currency
   * @param version Version of the element
   * @return List of all elements
   */
  function getElements(
    string calldata syntheticTokenSymbol,
    IERC20 collateralToken,
    uint8 version
  ) external view override returns (address[] memory) {
    EnumerableSet.AddressSet storage elementSet =
      symbolToElements[syntheticTokenSymbol][collateralToken][version];
    uint256 numberOfElements = elementSet.length();
    address[] memory elements = new address[](numberOfElements);
    for (uint256 j = 0; j < numberOfElements; j++) {
      elements[j] = elementSet.at(j);
    }
    return elements;
  }

  /**
   * @notice Returns all the synthetic token symbol used
   * @return List of all synthetic token symbol
   */
  function getSyntheticTokens()
    external
    view
    override
    returns (string[] memory)
  {
    uint256 numberOfSynthTokens = syntheticTokens.length();
    string[] memory synthTokens = new string[](numberOfSynthTokens);
    for (uint256 j = 0; j < numberOfSynthTokens; j++) {
      synthTokens[j] = syntheticTokens.at(j).bytes32ToString();
    }
    return synthTokens;
  }

  /**
   * @notice Returns all the versions used
   * @return List of all versions
   */
  function getVersions() external view override returns (uint8[] memory) {
    uint256 numberOfVersions = versions.length();
    uint8[] memory actualVersions = new uint8[](numberOfVersions);
    for (uint256 j = 0; j < numberOfVersions; j++) {
      actualVersions[j] = uint8(versions.at(j));
    }
    return actualVersions;
  }

  /**
   * @notice Returns all the collaterals used
   * @return List of all collaterals
   */
  function getCollaterals() external view override returns (address[] memory) {
    uint256 numberOfCollaterals = collaterals.length();
    address[] memory collateralAddresses = new address[](numberOfCollaterals);
    for (uint256 j = 0; j < numberOfCollaterals; j++) {
      collateralAddresses[j] = collaterals.at(j);
    }
    return collateralAddresses;
  }
}