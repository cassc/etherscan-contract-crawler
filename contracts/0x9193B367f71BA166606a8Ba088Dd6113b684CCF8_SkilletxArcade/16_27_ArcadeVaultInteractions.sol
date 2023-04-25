//SPDX-License-Identifier: Skillet-Group
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./ArcadeAddressProvider.sol";
import "../SkilletProtocolBase.sol";

import "./interfaces/IVaultFactory.sol";
import "./interfaces/IVaultRouter.sol";
import "./interfaces/IAssetVault.sol";

contract ArcadeVaultInteractions is
  ArcadeAddressProvider,
  SkilletProtocolBase
{ 

  constructor(address _skilletRegistryAddress) SkilletProtocolBase(_skilletRegistryAddress) {}

  /**
   * Create new Arcade Vault
   * https://etherscan.io/address/0x6e9B4c2f6Bd57b7b924d29b5dcfCa1273Ecc94A2#writeProxyContract#F4
   * @return vaultId unique identifier for the new vault
   */
  function createVault() 
    internal 
    returns (uint256 vaultId) 
  {
    IVaultFactory vaultFactory = IVaultFactory(vaultFactoryAddress);
    vaultId = vaultFactory.initializeBundle(address(this));
  }

  /**
   * Get the vault address for the provided vault id
   * https://etherscan.io/address/0x6e9B4c2f6Bd57b7b924d29b5dcfCa1273Ecc94A2#readProxyContract#F10
   * @param vaultId unique identifier returned by initializeBundle
   * @return vaultAddress address of the given vault implementation
   */
  function getVaultAddress(uint256 vaultId) 
    internal 
    view
    returns (address vaultAddress) 
  {
    IVaultFactory vaultFactory = IVaultFactory(vaultFactoryAddress);
    vaultAddress = vaultFactory.instanceAt(vaultId);
  }

  /**
   * Approve the origination controller to transfer the vault
   * https://etherscan.io/address/0x6e9B4c2f6Bd57b7b924d29b5dcfCa1273Ecc94A2#writeProxyContract#F1
   * @param vaultAddress the address of the unique vault implementation
   */
  function approveVaultTransfer(address vaultAddress) 
    internal 
  {
    IVaultFactory vaultFactory = IVaultFactory(vaultFactoryAddress);
    vaultFactory.approve(
      originationControllerAddress,
      uint256(uint160(vaultAddress))
    );
  }

  /**
   * Deposit a single ERC721 asset into the vault implementation
   * https://etherscan.io/address/0x4B95640d56f81Fc851F952793f4e5485E352bED2#writeContract#F5
   * @param vaultAddress address of the given vault implementation
   * @param collectionAddress address of the ERC721
   * @param tokenId identifier of the ERC721
   */
  function depositAsset(
    address vaultAddress, 
    address collectionAddress,
    uint256 tokenId
  ) internal 
  {
    // check and set approval for vaultRouterAddress
    checkAndSetOperatorApprovalForERC721(
      vaultRouterAddress, 
      collectionAddress
    );

    // deposit nft into vault
    IVaultRouter vaultRouter = IVaultRouter(vaultRouterAddress);
    vaultRouter.depositERC721(
      vaultAddress,
      collectionAddress,
      tokenId
    );
  }

  /**
   * Withdraw an asset from the vault identified by vaultId
   * https://etherscan.io/address/0xd898456e39a461b102ce4626aac191582c38acb6#writeContract#F9
   * @param vaultId unique identifier returned by initializeBundle
   * @param borrowerAddress address to send the ERC721
   * @param collectionAddress address of the ERC721
   * @param tokenId identifier of the ERC721
   */
  function withdrawAsset(
    uint256 vaultId,
    address borrowerAddress,
    address collectionAddress,
    uint256 tokenId
  ) internal 
  {
    address vaultAddress = getVaultAddress(vaultId);
    IAssetVault assetVault = IAssetVault(vaultAddress);

    assetVault.enableWithdraw();
    assetVault.withdrawERC721(collectionAddress, tokenId, borrowerAddress);
  }
}