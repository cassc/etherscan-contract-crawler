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
import "contracts/ommf/ommf_token/ommf.sol";
import "contracts/interfaces/IMulticall.sol";

/**
 * @title ommfFactory
 * @author Ondo Finance
 * @notice This contract serves as a Factory for the upgradable OMMF token contract.
 *         Upon calling `deployOMMF` the `guardian` address (set in constructor) will
 *         deploy the following:
 *         1) OMMF - The implementation contract, ERC20 contract with the initializer disabled
 *         2) ProxyAdmin - OZ ProxyAdmin contract, used to upgrade the proxy instance.
 *                         @notice Owner is set to `guardian` address.
 *         3) TransparentUpgradeableProxy - OZ, proxy contract. Admin is set to `address(proxyAdmin)`.
 *                                          `_logic' is set to `address(OMMF)`.
 *
 *         Following the above mentioned deployment, the address of the OMMFFactory contract will:
 *         i) Grant the `DEFAULT_ADMIN_ROLE` & PAUSER_ROLE to the `guardian` address
 *         ii) Revoke the `MINTER_ROLE`, `PAUSER_ROLE` & `DEFAULT_ADMIN_ROLE` from address(this).
 *         iii) Transfer ownership of the ProxyAdmin to that of the `guardian` address.
 *
 * @notice `guardian` address in constructor is a msig.
 */
contract OMMFFactory is IMulticall {
  address internal immutable guardian;
  OMMF public ommfImplementation;
  ProxyAdmin public ommfProxyAdmin;
  TokenProxy public ommfProxy;

  constructor(address _guardian) {
    guardian = _guardian;
  }

  /**
   * @dev This function will deploy an upgradable instance of OMMF
   *
   * @param registry         The address of the KYC Registry
   * @param requirementGroup The Requirement group of the Registry
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
  function deployOMMF(
    address registry,
    uint256 requirementGroup
  ) external onlyGuardian returns (address, address, address) {
    ommfImplementation = new OMMF();
    ommfProxyAdmin = new ProxyAdmin();
    ommfProxy = new TokenProxy(
      address(ommfImplementation),
      address(ommfProxyAdmin),
      ""
    );
    OMMF ommfProxied = OMMF(address(ommfProxy));
    ommfProxied.initialize(guardian, registry, requirementGroup);

    ommfProxyAdmin.transferOwnership(guardian);
    assert(ommfProxyAdmin.owner() == guardian);
    emit OMMFDeployed(
      address(ommfProxy),
      address(ommfProxyAdmin),
      address(ommfImplementation),
      "Test - Ondo Money Market Fund Token",
      "t-OMMF"
    );
    return (
      address(ommfProxy),
      address(ommfProxyAdmin),
      address(ommfImplementation)
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
   * @dev Event emitted when upgradable OMMF is deployed
   *
   * @param proxy             The address for the proxy contract
   * @param proxyAdmin        The address for the proxy admin contract
   * @param implementation    The address for the implementation contract
   */
  event OMMFDeployed(
    address proxy,
    address proxyAdmin,
    address implementation,
    string name,
    string ticker
  );

  modifier onlyGuardian() {
    require(msg.sender == guardian, "ommfFactory: You are not the Guardian");
    _;
  }
}