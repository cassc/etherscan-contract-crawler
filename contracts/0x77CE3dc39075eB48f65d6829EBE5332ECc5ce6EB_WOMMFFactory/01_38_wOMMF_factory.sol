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
import "contracts/ommf/wrappedOMMF/wOMMF.sol";
import "contracts/interfaces/IMulticall.sol";

/**
 * @title wommfFactory
 * @author Ondo Finance
 * @notice This contract serves as a Factory for the upgradable wOMMF token contract.
 *         Upon calling `deployWOMMF` the `guardian` address (set in constructor) will
 *         deploy the following:
 *         1) wOMMF - The implementation contract, ERC20 contract with the initializer disabled
 *         2) ProxyAdmin - OZ ProxyAdmin contract, used to upgrade the proxy instance.
 *                         @notice Owner is set to `guardian` address.
 *         3) TransparentUpgradeableProxy - OZ, proxy contract. Admin is set to `address(proxyAdmin)`.
 *                                          `_logic' is set to `address(rwa)`.
 *
 *         Following the above mentioned deployment, the address of the RWAFactory contract will:
 *         i) Transfer ownership of the ProxyAdmin to that of the `guardian` address.
 *         ii) Emit an event detailing the addresses on the upgradable contract array.
 *
 * @notice `guardian` address in constructor is a msig.
 */
contract WOMMFFactory is IMulticall {
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
  bytes32 public constant DEFAULT_ADMIN_ROLE = bytes32(0);

  address internal immutable guardian;
  WOMMF public wommfImplementation;
  ProxyAdmin public wommfProxyAdmin;
  TokenProxy public wommfProxy;

  constructor(address _guardian) {
    guardian = _guardian;
  }

  /**
   * @dev This function will deploy an upgradable instance of RWA
   *
   * @param name             The name of the token we want to deploy.
   * @param ticker           The ticker for the token we want to deploy.
   * @param ommfAddress      The address of the OMMF token to wrap
   * @param registry         The address of the KYC Registry
   * @param requirementGroup The KYC requirement group for this token
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
  function deployWOMMF(
    string calldata name,
    string calldata ticker,
    address ommfAddress,
    address registry,
    uint256 requirementGroup
  ) external onlyGuardian returns (address, address, address) {
    wommfImplementation = new WOMMF();
    wommfProxyAdmin = new ProxyAdmin();
    wommfProxy = new TokenProxy(
      address(wommfImplementation),
      address(wommfProxyAdmin),
      ""
    );
    WOMMF wOMMFProxied = WOMMF(address(wommfProxy));
    wOMMFProxied.initialize(
      guardian,
      name,
      ticker,
      ommfAddress,
      registry,
      requirementGroup
    );
    wOMMFProxied.revokeRole(MINTER_ROLE, address(this));
    wOMMFProxied.revokeRole(PAUSER_ROLE, address(this));
    wOMMFProxied.revokeRole(DEFAULT_ADMIN_ROLE, address(this));

    wommfProxyAdmin.transferOwnership(guardian);
    assert(wommfProxyAdmin.owner() == guardian);
    emit WOMMFDeployed(
      address(wOMMFProxied),
      address(wommfProxyAdmin),
      address(wommfImplementation),
      name,
      ticker
    );
    return (
      address(wOMMFProxied),
      address(wommfProxyAdmin),
      address(wommfImplementation)
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
   * @dev Event emitted when upgradable RWA token is deployed
   *
   * @param proxy             The address for the proxy contract
   * @param proxyAdmin        The address for the proxy admin contract
   * @param implementation    The address for the implementation contract
   */
  event WOMMFDeployed(
    address proxy,
    address proxyAdmin,
    address implementation,
    string name,
    string ticker
  );

  modifier onlyGuardian() {
    require(msg.sender == guardian, "WOMMFFactory: You are not the Guardian");
    _;
  }
}