pragma solidity 0.7.6;

import "@openzeppelin/contracts/proxy/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "./vaults/StakingData.sol";

contract ITrustVaultFactory is Initializable {
  
  address[] internal _VaultProxies;
  mapping (address => bool) internal _AdminList;
  mapping (address => bool) internal _TrustedSigners;
  mapping(address => bool) internal _VaultStatus;
  address internal _roundDataImplementationAddress;
  address internal _stakeDataImplementationAddress;
  address internal _stakingDataAddress;
  address internal _burnAddress;
  address internal _governanceDistributionAddress;
  address internal _governanceTokenAddress;
  address internal _stakingCalculationAddress;

  function initialize(
      address admin, 
      address trustedSigner, 
      address roundDataImplementationAddress, 
      address stakeDataImplementationAddress, 
      address governanceTokenAddress,
      address stakingCalculationAddress
    ) initializer external {
    require(admin != address(0));
    _AdminList[admin] = true;
    _AdminList[msg.sender] = true;
    _TrustedSigners[trustedSigner] = true;
    _roundDataImplementationAddress = roundDataImplementationAddress;
    _stakeDataImplementationAddress = stakeDataImplementationAddress;
    _governanceTokenAddress = governanceTokenAddress;
    _stakingCalculationAddress = stakingCalculationAddress;
  }

  modifier onlyAdmin() {
    require(_AdminList[msg.sender] == true, "Not Factory Admin");
    _;
  }

  function createVault(
    address contractAddress, 
    bytes memory data
  ) external onlyAdmin {
    TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(contractAddress, msg.sender, data );
    require(address(proxy) != address(0));
    _VaultProxies.push(address(proxy));
    _VaultStatus[address(proxy)] = true;
    StakingData stakingDataContract = StakingData(_stakingDataAddress);
    stakingDataContract.addVault(address(proxy));
  }

  function getVaultaddresses() external view returns (address[] memory vaults, bool[] memory status) {

    vaults = _VaultProxies;
    status = new bool[](vaults.length);

    for(uint i = 0; i < vaults.length; i++){
      status[i] = _VaultStatus[vaults[i]];
    }

    return (vaults, status);
  }

  function pauseVault(address vaultAddress) external onlyAdmin {
    _VaultStatus[vaultAddress] = false;
  }

  function unPauseVault(address vaultAddress) external onlyAdmin {
    _VaultStatus[vaultAddress] = true;
  }

  function addAdminAddress(address newAddress) external onlyAdmin {
      require(_AdminList[newAddress] == false, "Already Admin");
      _AdminList[newAddress] = true;
  }

  /**
    * @dev revoke admin
    */
  function revokeAdminAddress(address newAddress) external onlyAdmin {
      require(msg.sender != newAddress);
      _AdminList[newAddress] = false;
  }

  function addTrustedSigner(address newAddress) external onlyAdmin{
      require(_TrustedSigners[newAddress] == false);
      _TrustedSigners[newAddress] = true;
  }

  function isTrustedSignerAddress(address account) external view returns (bool) {
      return _TrustedSigners[account] == true;
  }

  function updateRoundDataImplementationAddress(address newAddress) external onlyAdmin {
      _roundDataImplementationAddress = newAddress;
  }

  function getRoundDataImplementationAddress() external view returns(address){
      return _roundDataImplementationAddress;
  }

  function updateStakeDataImplementationAddress(address newAddress) external onlyAdmin {
      _stakeDataImplementationAddress = newAddress;
  }

  function getStakeDataImplementationAddress() external view returns(address){
      return _stakeDataImplementationAddress;
  }

  function updateStakingDataAddress(address newAddress) external onlyAdmin {
      _stakingDataAddress = newAddress;
  }

  function getStakingDataAddress() external view returns(address){
      return _stakingDataAddress;
  }

  function isStakingDataAddress(address addressToCheck) external view returns (bool) {
      return _stakingDataAddress == addressToCheck;
  }

  function updateBurnAddress(address newAddress) external onlyAdmin {
      _burnAddress = newAddress;
  }

  function getBurnAddress() external view returns(address){
      return _burnAddress;
  }

  function isBurnAddress(address addressToCheck) external view returns (bool) {
      return _burnAddress == addressToCheck;
  }

  function updateGovernanceDistributionAddress(address newAddress) external onlyAdmin {
      _governanceDistributionAddress = newAddress;
  }

  function getGovernanceDistributionAddress() external view returns(address){
      return _governanceDistributionAddress;
  }

  function updateGovernanceTokenAddress(address newAddress) external onlyAdmin {
      _governanceTokenAddress = newAddress;
  }

  function getGovernanceTokenAddress() external view returns(address){
      return _governanceTokenAddress;
  }

  function updateStakingCalculationsAddress(address newAddress) external onlyAdmin {
      _stakingCalculationAddress = newAddress;
  }

  function getStakingCalculationsAddress() external view returns(address){
      return _stakingCalculationAddress;
  }

  /**
    * @dev revoke admin
    */
  function revokeTrustedSigner(address newAddress) external onlyAdmin {
      require(msg.sender != newAddress);
      _TrustedSigners[newAddress] = false;
  }

  function isAdmin() external view returns (bool) {
      return isAddressAdmin(msg.sender);
  }

  function isAddressAdmin(address account) public view returns (bool) {
      return _AdminList[account] == true;
  }

  function isActiveVault(address vaultAddress) external view returns (bool) {
    return _VaultStatus[vaultAddress] == true;
  }   
}