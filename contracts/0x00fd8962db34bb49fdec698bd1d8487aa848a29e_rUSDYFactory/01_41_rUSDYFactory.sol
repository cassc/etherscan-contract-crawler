/**SPDX-License-Identifier: BUSL-1.1

      ▄▄█████████▄
   ╓██▀└ ,╓▄▄▄, '▀██▄
  ██▀ ▄██▀▀╙╙▀▀██▄ └██µ           ,,       ,,      ,     ,,,            ,,,
 ██ ,██¬ ▄████▄  ▀█▄ ╙█▄      ▄███▀▀███▄   ███▄    ██  ███▀▀▀███▄    ▄███▀▀███,
██  ██ ╒█▀'   ╙█▌ ╙█▌ ██     ▐██      ███  █████,  ██  ██▌    └██▌  ██▌     └██▌
██ ▐█▌ ██      ╟█  █▌ ╟█     ██▌      ▐██  ██ └███ ██  ██▌     ╟██ j██       ╟██
╟█  ██ ╙██    ▄█▀ ▐█▌ ██     ╙██      ██▌  ██   ╙████  ██▌    ▄██▀  ██▌     ,██▀
 ██ "██, ╙▀▀███████████⌐      ╙████████▀   ██     ╙██  ███████▀▀     ╙███████▀`
  ██▄ ╙▀██▄▄▄▄▄,,,                ¬─                                    '─¬
   ╙▀██▄ '╙╙╙▀▀▀▀▀▀▀▀
      ╙▀▀██████R⌐

 */
pragma solidity 0.8.16;

// Proxy admin contract used in OZ upgrades plugin
import "contracts/external/openzeppelin/contracts/proxy/ProxyAdmin.sol";
import "contracts/Proxy.sol";
import "contracts/usdy/rusdy_allowlist/rUSDY.sol";
import "contracts/interfaces/IMulticall.sol";

/**
 * @title rUSDYFactory
 * @author Ondo Finance
 * @notice This contract serves as a Factory for the upgradable rUSDY token contract.
 *         Upon calling `deployrUSDY` the `guardian` address (set in constructor) will
 *         deploy the following:
 *         1) rUSDY - The implementation contract, ERC20 contract with the initializer disabled
 *         2) ProxyAdmin - OZ ProxyAdmin contract, used to upgrade the proxy instance.
 *                         @notice Owner is set to `guardian` address.
 *         3) TransparentUpgradeableProxy - OZ, proxy contract. Admin is set to `address(proxyAdmin)`.
 *                                          `_logic' is set to `address(rUSDY)`.
 * @notice `guardian` address in constructor is a msig.
 */
contract rUSDYFactory is IMulticall {
  bytes32 public constant DEFAULT_ADMIN_ROLE = bytes32(0);

  address internal immutable guardian;
  rUSDY public rUSDYImplementation;
  ProxyAdmin public rUSDYProxyAdmin;
  TokenProxy public rUSDYProxy;

  constructor(address _guardian) {
    guardian = _guardian;
  }

  /**
   * @dev This function will deploy an upgradable instance of rUSDY
   *
   * @param blocklist     The address of the blocklist
   * @param allowlist     The address of the allowlist
   * @param sanctionsList The address of the sanctions list
   * @param usdy          The address of USDY
   *
   * @return address The address of the proxy contract.
   * @return address The address of the proxyAdmin contract.
   * @return address The address of the implementation contract.
   *
   * @notice 1) Will automatically revoke all deployer roles granted to
   *            address(this).
   *         2) Will grant DEFAULT_ADMIN & PAUSER_ROLE(S) to `guardian`
   *            address specified in constructor.
   *         3) Will transfer ownership of the proxyAdmin to guardian
   *            address.
   *
   */
  function deployrUSDY(
    address blocklist,
    address allowlist,
    address sanctionsList,
    address usdy,
    address oracle
  ) external onlyGuardian returns (address, address, address) {
    rUSDYImplementation = new rUSDY();
    rUSDYProxyAdmin = new ProxyAdmin();
    rUSDYProxy = new TokenProxy(
      address(rUSDYImplementation),
      address(rUSDYProxyAdmin),
      ""
    );
    rUSDY rUSDYProxied = rUSDY(address(rUSDYProxy));
    rUSDYProxied.initialize(
      blocklist,
      allowlist,
      sanctionsList,
      usdy,
      guardian,
      oracle
    );

    rUSDYProxyAdmin.transferOwnership(guardian);
    assert(rUSDYProxyAdmin.owner() == guardian);
    emit rUSDYDeployed(
      address(rUSDYProxy),
      address(rUSDYProxyAdmin),
      address(rUSDYImplementation),
      "test Ondo Rebasing U.S. Dollar Yield",
      "test rUSDY"
    );
    return (
      address(rUSDYProxy),
      address(rUSDYProxyAdmin),
      address(rUSDYImplementation)
    );
  }

  /**
   * @notice Allows for arbitrary batched calls
   *
   * @dev All external calls made through this function will
   *      msg.sender == contract address
   *
   * @param exCallData Struct consisting of
   *       1) target - contract to call
   *       2) data - data to call target with
   *       3) value - eth value to call target with
   */
  function multiexcall(
    ExCallData[] calldata exCallData
  ) external payable override onlyGuardian returns (bytes[] memory results) {
    results = new bytes[](exCallData.length);
    for (uint256 i = 0; i < exCallData.length; ++i) {
      (bool success, bytes memory ret) = address(exCallData[i].target).call{
        value: exCallData[i].value
      }(exCallData[i].data);
      require(success, "Call Failed");
      results[i] = ret;
    }
  }

  /**
   * @dev Event emitted when upgradable rUSDY is deployed
   *
   * @param proxy             The address for the proxy contract
   * @param proxyAdmin        The address for the proxy admin contract
   * @param implementation    The address for the implementation contract
   */
  event rUSDYDeployed(
    address proxy,
    address proxyAdmin,
    address implementation,
    string name,
    string ticker
  );

  modifier onlyGuardian() {
    require(msg.sender == guardian, "rUSDYFactory: You are not the Guardian");
    _;
  }
}