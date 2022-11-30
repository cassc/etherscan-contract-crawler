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
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./interfaces/IDCNTRegistry.sol";
import "./storage/EditionConfig.sol";
import "./storage/MetadataConfig.sol";
import "./storage/TokenGateConfig.sol";
import "./storage/CrescendoConfig.sol";

contract DCNTSDK is Ownable {
  /// ============ Storage ===========
  /// @notice implementation addresses for base contracts
  address public DCNT721AImplementation;
  address public DCNT4907AImplementation;
  address public DCNTCrescendoImplementation;
  address public DCNTVaultImplementation;
  address public DCNTStakingImplementation;
  address public ZKEditionImplementation;

  /// @notice address of the metadata renderer
  address public metadataRenderer;

  /// @notice address of the associated registry
  address public contractRegistry;

  /// @notice addresses for splits contract
  address public SplitMain;

  /// ============ Events ============

  /// @notice Emitted after successfully deploying a contract
  event DeployDCNT721A(address DCNT721A);
  event DeployDCNT4907A(address DCNT4907A);
  event DeployDCNTCrescendo(address DCNTCrescendo);
  event DeployDCNTVault(address DCNTVault);
  event DeployDCNTStaking(address DCNTStaking);
  event DeployZKEdition(address ZKEdition);

  /// ============ Constructor ============

  /// @notice Creates a new DecentSDK instance
  constructor(
    address _DCNT721AImplementation,
    address _DCNT4907AImplementation,
    address _DCNTCrescendoImplementation,
    address _DCNTVaultImplementation,
    address _DCNTStakingImplementation,
    address _metadataRenderer,
    address _contractRegistry,
    address _SplitMain,
    address _ZKEditionImplementation
  ) {
    DCNT721AImplementation = _DCNT721AImplementation;
    DCNT4907AImplementation = _DCNT4907AImplementation;
    DCNTCrescendoImplementation = _DCNTCrescendoImplementation;
    DCNTVaultImplementation = _DCNTVaultImplementation;
    DCNTStakingImplementation = _DCNTStakingImplementation;
    metadataRenderer = _metadataRenderer;
    contractRegistry = _contractRegistry;
    SplitMain = _SplitMain;
    ZKEditionImplementation = _ZKEditionImplementation;
  }

  /// ============ Functions ============

  /// @notice deploy and initialize an erc721a clone
  function deployDCNT721A(
    EditionConfig memory _editionConfig,
    MetadataConfig memory _metadataConfig,
    TokenGateConfig memory _tokenGateConfig
  ) external returns (address clone) {
    clone = Clones.clone(DCNT721AImplementation);
    (bool success, ) = clone.call(
      abi.encodeWithSignature(
        "initialize("
          "address,"
          "(string,string,bool,uint256,uint256,uint256,bytes32,uint256,uint256,uint256,uint256,uint256),"
          "(string,string,bytes,address),"
          "(address,uint88,uint8),"
          "address,"
          "address"
        ")",
        msg.sender,
        _editionConfig,
        _metadataConfig,
        _tokenGateConfig,
        metadataRenderer,
        SplitMain
      )
    );
    require(success);
    IDCNTRegistry(contractRegistry).register(msg.sender, clone, "DCNT721A");
    emit DeployDCNT721A(clone);
  }

  /// @notice deploy and initialize a ZKEdition clone
  function deployZKEdition(
    EditionConfig memory _editionConfig,
    MetadataConfig memory _metadataConfig,
    TokenGateConfig memory _tokenGateConfig,
    address zkVerifier
  ) external returns (address clone) {
    clone = Clones.clone(ZKEditionImplementation); //zkedition implementation
    (bool success, ) = clone.call(
      abi.encodeWithSignature(
        "initialize("
          "address,"
          "(string,string,bool,uint256,uint256,uint256,bytes32,uint256,uint256,uint256,uint256,uint256),"
          "(string,string,bytes,address),"
          "(address,uint88,uint8),"
          "address,"
          "address,"
          "address"
        ")",
        msg.sender,
        _editionConfig,
        _metadataConfig,
        _tokenGateConfig,
        metadataRenderer,
        SplitMain,
        zkVerifier
      )
    );
    require(success);
    IDCNTRegistry(contractRegistry).register(msg.sender, clone, "ZKEdition");
    emit DeployZKEdition(clone);
  }

  /// @notice deploy and initialize an erc4907a clone
  function deployDCNT4907A(
    EditionConfig memory _editionConfig,
    MetadataConfig memory _metadataConfig,
    TokenGateConfig memory _tokenGateConfig
  ) external returns (address clone) {
    clone = Clones.clone(DCNT4907AImplementation);
    (bool success, ) = clone.call(
      abi.encodeWithSignature(
        "initialize("
          "address,"
          "(string,string,bool,uint256,uint256,uint256,bytes32,uint256,uint256,uint256,uint256,uint256),"
          "(string,string,bytes,address),"
          "(address,uint88,uint8),"
          "address,"
          "address"
        ")",
        msg.sender,
        _editionConfig,
        _metadataConfig,
        _tokenGateConfig,
        metadataRenderer,
        SplitMain
      )
    );
    require(success);
    IDCNTRegistry(contractRegistry).register(msg.sender, clone, "DCNT4907A");
    emit DeployDCNT4907A(clone);
  }

  // deploy and initialize a Crescendo clone
  function deployDCNTCrescendo(
    CrescendoConfig memory _config,
    MetadataConfig memory _metadataConfig
  ) external returns (address clone) {
    clone = Clones.clone(DCNTCrescendoImplementation);
    (bool success, ) = clone.call(
      abi.encodeWithSignature(
        "initialize("
          "address,"
          "(string,string,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256),"
          "(string,string,bytes,address),"
          "address,"
          "address"
        ")",
        msg.sender,
        _config,
        _metadataConfig,
        metadataRenderer,
        SplitMain
      )
    );
    require(success);
    IDCNTRegistry(contractRegistry).register(
      msg.sender,
      clone,
      "DCNTCrescendo"
    );
    emit DeployDCNTCrescendo(clone);
  }

  // deploy and initialize a vault wrapper clone
  function deployDCNTVault(
    address _vaultDistributionTokenAddress,
    address _nftVaultKeyAddress,
    uint256 _nftTotalSupply,
    uint256 _unlockDate
  ) external returns (address clone) {
    clone = Clones.clone(DCNTVaultImplementation);
    (bool success, ) = clone.call(
      abi.encodeWithSignature(
        "initialize(address,address,address,uint256,uint256)",
        msg.sender,
        _vaultDistributionTokenAddress,
        _nftVaultKeyAddress,
        _nftTotalSupply,
        _unlockDate
      )
    );
    require(success);
    IDCNTRegistry(contractRegistry).register(msg.sender, clone, "DCNTVault");
    emit DeployDCNTVault(clone);
  }

  // deploy and initialize a vault wrapper clone
  function deployDCNTStaking(
    address _nft,
    address _token,
    uint256 _vaultDuration,
    uint256 _totalSupply
  ) external returns (address clone) {
    clone = Clones.clone(DCNTStakingImplementation);
    (bool success, ) = clone.call(
      abi.encodeWithSignature(
        "initialize(address,address,address,uint256,uint256)",
        msg.sender,
        _nft,
        _token,
        _vaultDuration,
        _totalSupply
      )
    );
    require(success);
    IDCNTRegistry(contractRegistry).register(msg.sender, clone, "DCNTStaking");
    emit DeployDCNTStaking(clone);
  }
}