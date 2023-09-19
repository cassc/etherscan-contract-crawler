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
import "contracts/usdy/allowlist/AllowlistProxy.sol";
import "contracts/usdy/allowlist/AllowlistUpgradeable.sol";
import "contracts/interfaces/IMulticall.sol";

/**
 * @title AllowlistFactory
 * @author Ondo Finance
 * @notice This contract serves as a Factory for the upgradable AllowlistUpgradeable contract.
 *         Upon calling `deployAllowlist` the `guardian` address (set in constructor) will
 *         deploy the following:
 *         1) AllowlistUpgradeable - The implementation contract.
 *         2) ProxyAdmin - OZ ProxyAdmin contract, used to upgrade the proxy instance.
 *                         @notice Owner is set to `guardian` address.
 *         3) TransparentUpgradeableProxy - OZ, proxy contract. Admin is set to `address(proxyAdmin)`.
 *                                          `_logic' is set to `address(cash)`.
 *
 * @notice `guardian` address in constructor is a msig.
 */
contract AllowlistFactory is IMulticall {
  bytes32 public constant DEFAULT_ADMIN_ROLE = bytes32(0);

  address internal immutable guardian;
  AllowlistUpgradeable public allowlistImplementation;
  ProxyAdmin public allowlistProxyAdmin;
  AllowlistProxy public allowlistProxy;

  constructor(address _guardian) {
    guardian = _guardian;
  }

  /**
   * @dev This function will deploy an upgradable instance of AllowlistUpgradeable
   *
   * @param admin  The admin account for the AllowlistUpgradeable contract.
   * @param setter The setter account for the AllowlistUpgradeable contract.
   *
   * @return address The address of the proxy contract.
   * @return address The address of the proxyAdmin contract.
   * @return address The address of the implementation contract.
   *
   */
  function deployAllowlist(
    address admin,
    address setter
  ) external onlyGuardian returns (address, address, address) {
    allowlistImplementation = new AllowlistUpgradeable();

    allowlistProxyAdmin = new ProxyAdmin();
    allowlistProxy = new AllowlistProxy(
      address(allowlistImplementation),
      address(allowlistProxyAdmin),
      ""
    );
    AllowlistUpgradeable allowlistProxied = AllowlistUpgradeable(
      address(allowlistProxy)
    );

    allowlistProxied.initialize(admin, setter);

    allowlistProxyAdmin.transferOwnership(guardian);
    assert(allowlistProxyAdmin.owner() == guardian);
    emit AllowlistDeployed(
      address(allowlistProxied),
      address(allowlistProxyAdmin),
      address(allowlistImplementation)
    );
    return (
      address(allowlistProxied),
      address(allowlistProxyAdmin),
      address(allowlistImplementation)
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
   * @dev Event emitted when upgradable AllowlistUpgradeable is deployed
   *
   * @param proxy             The address for the proxy contract
   * @param proxyAdmin        The address for the proxy admin contract
   * @param implementation    The address for the implementation contract
   */
  event AllowlistDeployed(
    address proxy,
    address proxyAdmin,
    address implementation
  );

  modifier onlyGuardian() {
    require(
      msg.sender == guardian,
      "AllowlistFactory: You are not the Guardian"
    );
    _;
  }
}