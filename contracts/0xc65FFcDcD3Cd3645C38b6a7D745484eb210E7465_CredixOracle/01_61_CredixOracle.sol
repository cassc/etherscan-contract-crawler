// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "../interfaces/ICredixOracle.sol";
import "../config/AlloyxConfig.sol";
import "../config/ConfigHelper.sol";

/**
 * @title CredixOracle
 * @notice NAV or statistics related to assets managed for Credix, the managed portfolios are contracts in Credix, in here, we take portfolio with USDC as base token
 * @author AlloyX
 */
contract CredixOracle is ICredixOracle, ChainlinkClient, ConfirmedOwner {
  using Chainlink for Chainlink.Request;
  using ConfigHelper for AlloyxConfig;
  using SafeMath for uint256;

  string public url;
  bytes32 private jobId;
  uint256 private fee;
  mapping(address => uint256) public vaultToUsdcValue;
  mapping(address => string) public vaultToWalletAddress;
  mapping(bytes32 => address) public requestIdToVault;

  AlloyxConfig public config;

  event ChangeUrl(address changer, string url);
  event ChangeJobId(address changer, bytes32 jobId);
  event SetUsdcValue(address changer, address indexed vaultAddress, uint256 usdcValue);
  event ChangeWalletAddress(address changer, address indexed vaultAddress, string walletAddress);
  event DepositUsdc(address depositor, address indexed vaultAddress, uint256 usdcValue);
  event RequestUsdcValue(bytes32 indexed requestId, address indexed vaultAddress, uint256 usdcValue);

  /**
   * @notice Initialize the oracle contract with job details
   * Goerli Testnet details:
   * Link Token: 0x326C977E6efc84E512bB9C30f76E30c160eD06FB
   * Oracle: 0xCC79157eb46F5624204f47AB42b3906cAA40eaB7 (Chainlink DevRel)
   * jobId: ca98366cc7314957b8c012c72f05aeeb
   * Mainnet details:
   * Link Token: 0x514910771AF9Ca656af840dff83E8264EcF986CA
   * Oracle: 0x188b71C9d27cDeE01B9b0dfF5C1aff62E8D6F434 (Chainlink DevRel)
   * jobId: 7599d3c8f31e4ce78ad2b790cbcfc673
   */
  constructor(string memory _url, address _chainlinkToken, address _chainlinkOracle, address _configAddress, bytes32 _jobId) ConfirmedOwner(msg.sender) {
    setChainlinkToken(_chainlinkToken);
    setChainlinkOracle(_chainlinkOracle);
    url = _url;
    jobId = _jobId;
    fee = (135 * LINK_DIVISIBILITY) / 100;
    config = AlloyxConfig(_configAddress);
  }

  /**
   * @notice Initialize the oracle contract with job details
   * @param _vaultAddress  the vault address to get the wallet balance in solana
   */
  function requestUsdcValue(address _vaultAddress) public onlyOwner returns (bytes32) {
    Chainlink.Request memory req = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
    req.add("get", string(abi.encodePacked(url, vaultToWalletAddress[_vaultAddress])));
    req.add("path", "vaultValue,uiAmount");
    int256 timesAmount = 10 ** 6;
    req.addInt("multiply", timesAmount);
    bytes32 requestId = sendChainlinkRequest(req, fee);
    requestIdToVault[requestId] = _vaultAddress;
    return requestId;
  }

  /**
   * @notice Callback from oracle to set the value from solana wallet
   * @param _requestId the ID of the callback from oracle
   * @param _usdcValue the USDC value of the vault
   */
  function fulfill(bytes32 _requestId, uint256 _usdcValue) public recordChainlinkFulfillment(_requestId) {
    address vaultAddress = requestIdToVault[_requestId];
    vaultToUsdcValue[vaultAddress] = _usdcValue;
    emit RequestUsdcValue(_requestId, vaultAddress, _usdcValue);
  }

  /**
   * @notice Get the net asset value of vault
   * @param _vaultAddress the vault address to increase USDC value on
   */
  function getNetAssetValueInUsdc(address _vaultAddress) external view override returns (uint256) {
    return vaultToUsdcValue[_vaultAddress];
  }

  /**
   * @notice Set the net asset value of vault
   * @param _vaultAddress the vault address to increase USDC value on
   * @param _usdcValue the USDC value of the vault
   */
  function setNetAssetValueInUsdc(address _vaultAddress, uint256 _usdcValue) external onlyOwner {
    vaultToUsdcValue[_vaultAddress] = _usdcValue;
    emit SetUsdcValue(msg.sender, _vaultAddress, _usdcValue);
  }

  /**
   * @notice Set the wallet address
   * @param _vaultAddress the vault address to increase USDC value on
   * @param _walletAddress the wallet address bound to the vault
   */
  function setWalletAddress(address _vaultAddress, string memory _walletAddress) external onlyOwner {
    vaultToWalletAddress[_vaultAddress] = _walletAddress;
    emit ChangeWalletAddress(msg.sender, _vaultAddress, _walletAddress);
  }

  /**
   * @notice Increase the USDC value after the vault provides USDC to credix desk
   * @param _vaultAddress the vault address to increase USDC value on
   * @param _increasedValue the increased value of the vault
   */
  function increaseUsdcValue(address _vaultAddress, uint256 _increasedValue) external override {
    require(msg.sender == config.credixDeskAddress(), "the value can only be called by credix desk during deposit");
    vaultToUsdcValue[_vaultAddress] = vaultToUsdcValue[_vaultAddress].add(_increasedValue);
    emit DepositUsdc(msg.sender, _vaultAddress, _increasedValue);
  }

  /**
   * @notice Set the URL
   * @param _url the URL of the oracle
   */
  function setUrl(string memory _url) external onlyOwner {
    url = _url;
    emit ChangeUrl(msg.sender, _url);
  }

  /**
   * @notice Set the jobID
   * @param _jobId the jobID of the oracle
   */
  function setJobId(bytes32 _jobId) external onlyOwner {
    jobId = _jobId;
    emit ChangeJobId(msg.sender, _jobId);
  }

  /**
   * @notice Withdraw link token to the caller
   */
  function withdrawLink() public onlyOwner {
    LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
    require(link.transfer(msg.sender, link.balanceOf(address(this))), "Unable to transfer");
  }
}