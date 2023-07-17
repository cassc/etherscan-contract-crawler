// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

interface IUNFTRegistry {
  event Initialized(address genericImpl, string namePrefix, string symbolPrefix);
  event GenericImplementationUpdated(address genericImpl);
  event UNFTCreated(address indexed nftAsset, address uNftImpl, address uNftProxy, uint256 totals);
  event UNFTUpgraded(address indexed nftAsset, address uNftImpl, address uNftProxy, uint256 totals);

  /**
   * @dev gets the uNFT address
   * @param nftAsset The address of the underlying NFT asset
   **/
  function getUNFTAddresses(address nftAsset) external view returns (address uNftProxy, address uNftImpl);

  /**
   * @dev gets the uNFT address by index
   * @param index the uNFT index
   **/
  function getUNFTAddressesByIndex(uint16 index) external view returns (address uNftProxy, address uNftImpl);

  /**
   * @dev gets the list of uNFTs
   **/
  function getUNFTAssetList() external view returns (address[] memory);

  /**
   * @dev gets the length of the list of uNFTs
   **/
  function allUNFTAssetLength() external view returns (uint256);

  /**
   * @dev initializes the contract
   **/
  function initialize(
    address genericImpl,
    string memory namePrefix_,
    string memory symbolPrefix_
  ) external;

  /**
   * @dev sets the uNFT generic implementation
   * @dev genericImpl the implementation contract
   **/
  function setUNFTGenericImpl(address genericImpl) external;

  /**
   * @dev Create uNFT proxy and implement, then initialize it
   * @param nftAsset The address of the underlying asset of the UNFT
   **/
  function createUNFT(address nftAsset) external returns (address uNftProxy);

  /**
   * @dev Create uNFT proxy with already deployed implement, then initialize it
   * @param nftAsset The address of the underlying asset of the UNFT
   * @param uNftImpl The address of the deployed implement of the UNFT
   **/
  function createUNFTWithImpl(address nftAsset, address uNftImpl) external returns (address uNftProxy);

  /**
   * @dev Update uNFT proxy to an new deployed implement, then initialize it
   * @param nftAsset The address of the underlying asset of the UNFT
   * @param uNftImpl The address of the deployed implement of the UNFT
   * @param encodedCallData The encoded function call.
   **/
  function upgradeUNFTWithImpl(
    address nftAsset,
    address uNftImpl,
    bytes memory encodedCallData
  ) external;

  /**
   * @dev Adding custom symbol for some special NFTs like CryptoPunks
   * @param nftAssets_ The addresses of the NFTs
   * @param symbols_ The custom symbols of the NFTs
   **/
  function addCustomeSymbols(address[] memory nftAssets_, string[] memory symbols_) external;
}