// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
 ______   _______  _______  _______  _       _________
(  __  \ (  ____ \(  ____ \(  ____ \( (    /|\__   __/
| (  \  )| (    \/| (    \/| (    \/|  \  ( |   ) (
| |   ) || (__    | |      | (__    |   \ | |   | |
| |   | ||  __)   | |      |  __)   | (\ \) |   | |
| |   ) || (      | |      | (      | | \   |   | |
| (__/  )| (____/\| (____/\| (____/\| )  \  |   | |
(______/ (_______/(_______/(_______/|/    )_)   )_(

*/

/// ============ Imports ============

import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IDCNTSDK.sol";
import "./storage/EditionConfig.sol";
import "./storage/MetadataConfig.sol";
import "./storage/TokenGateConfig.sol";

contract DCNTVaultNFT is Ownable {
  /// ============ Immutable storage ============

  /// @notice implementation addresses for base contracts
  address public DCNT721AImplementation;
  address public DCNT4907AImplementation;
  address public DCNTSeriesImplementation;
  address public DCNTCrescendoImplementation;
  address public DCNTVaultImplementation;
  address public DCNTStakingImplementation;
  address public ZKEditionImplementation;

  /// @notice address of the metadata renderer
  address public metadataRenderer;

  /// @notice address of the associated registry
  address public contractRegistry;

  /// ============ Events ============

  /// @notice Emitted after successfully deploying a contract
  event Create(address nft, address vault);

  /// ============ Constructor ============

  /// @notice Creates a new DecentVaultWrapped instance
  constructor(address _DCNTSDK) {
    IDCNTSDK sdk = IDCNTSDK(_DCNTSDK);
    DCNT721AImplementation = sdk.DCNT721AImplementation();
    DCNT4907AImplementation = sdk.DCNT4907AImplementation();
    DCNTVaultImplementation = sdk.DCNTVaultImplementation();
    metadataRenderer = sdk.metadataRenderer();
    contractRegistry = sdk.contractRegistry();
  }

  /// ============ Functions ============

  function create(
    address _DCNTSDK,
    EditionConfig memory _editionConfig,
    MetadataConfig memory _metadataConfig,
    TokenGateConfig memory _tokenGateConfig,
    address _vaultDistributionTokenAddress,
    uint256 _unlockDate,
    bool _supports4907
  ) external returns (address nft, address vault) {
    address deployedNFT;
    if (_supports4907) {
      (bool success1, bytes memory data1) = _DCNTSDK.delegatecall(
        abi.encodeWithSignature(
          "deployDCNT4907A("
            "(string,string,bool,bool,uint32,uint32,uint32,uint32,uint32,uint32,uint16,uint96,address,address,bytes32),"
            "(string,string,bytes,address),"
            "(address,uint88,uint8)"
          ")",
          _editionConfig,
          _metadataConfig,
          _tokenGateConfig
        )
      );

      require(success1);
      deployedNFT = abi.decode(data1, (address));
    } else {
      (bool success2, bytes memory data2) = _DCNTSDK.delegatecall(
        abi.encodeWithSignature(
          "deployDCNT721A("
            "(string,string,bool,bool,uint32,uint32,uint32,uint32,uint32,uint32,uint16,uint96,address,address,bytes32),"
            "(string,string,bytes,address),"
            "(address,uint88,uint8)"
          ")",
          _editionConfig,
          _metadataConfig,
          _tokenGateConfig
        )
      );

      require(success2);
      deployedNFT = abi.decode(data2, (address));
    }

    (bool success, bytes memory data) = _DCNTSDK.delegatecall(
      abi.encodeWithSignature(
        "deployDCNTVault(address,address,uint256,uint256)",
        _vaultDistributionTokenAddress,
        deployedNFT,
        _editionConfig.maxTokens,
        _unlockDate
      )
    );

    require(success);
    address deployedVault = abi.decode(data, (address));

    emit Create(deployedNFT, deployedVault);
    return (deployedNFT, deployedVault);
  }

  function bytesToAddress(bytes memory _bytes)
    private
    pure
    returns (address addr)
  {
    assembly {
      addr := mload(add(_bytes, 32))
    }
  }
}