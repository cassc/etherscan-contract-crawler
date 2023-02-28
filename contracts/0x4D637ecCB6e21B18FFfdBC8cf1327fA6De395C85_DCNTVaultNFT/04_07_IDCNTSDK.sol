// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDCNTSDK {
  /// @notice implementation addresses for base contracts
  function DCNT721AImplementation() external returns (address);

  function DCNT4907AImplementation() external returns (address);

  function DCNTCrescendoImplementation() external returns (address);

  function DCNTVaultImplementation() external returns (address);

  function DCNTStakingImplementation() external returns (address);

  function metadataRenderer() external returns (address);

  function contractRegistry() external returns (address);

  function SplitMain() external returns (address);

  /// ============ Functions ============

  // deploy and initialize an erc721a clone
  function deployDCNT721A(
    string memory _name,
    string memory _symbol,
    uint256 _maxTokens,
    uint256 _tokenPrice,
    uint256 _maxTokenPurchase
  ) external returns (address clone);

  // deploy and initialize an erc4907a clone
  function deployDCNT4907A(
    string memory _name,
    string memory _symbol,
    uint256 _maxTokens,
    uint256 _tokenPrice,
    uint256 _maxTokenPurchase
  ) external returns (address clone);

  // deploy and initialize a Crescendo clone
  function deployDCNTCrescendo(
    string memory _name,
    string memory _symbol,
    string memory _uri,
    uint256 _initialPrice,
    uint256 _step1,
    uint256 _step2,
    uint256 _hitch,
    uint256 _trNum,
    uint256 _trDenom,
    address payable _payouts
  ) external returns (address clone);

  // deploy and initialize a vault wrapper clone
  function deployDCNTVault(
    address _vaultDistributionTokenAddress,
    address _nftVaultKeyAddress,
    uint256 _nftTotalSupply,
    uint256 _unlockDate
  ) external returns (address clone);

  // deploy and initialize a vault wrapper clone
  function deployDCNTStaking(
    address _nft,
    address _token,
    uint256 _vaultDuration,
    uint256 _totalSupply
  ) external returns (address clone);
}