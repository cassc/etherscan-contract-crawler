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

import "contracts/cash/external/openzeppelin/contracts-upgradeable/token/ERC20/ERC20PresetMinterPauserUpgradeable.sol";
import "contracts/cash/kyc/KYCRegistryClientInitializable.sol";

/// @notice This token enables transfers to and from addresses that have been KYC'd
contract CashKYCSenderReceiver is
  ERC20PresetMinterPauserUpgradeable,
  KYCRegistryClientInitializable
{
  bytes32 public constant KYC_CONFIGURER_ROLE =
    keccak256("KYC_CONFIGURER_ROLE");

  bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function setKYCRequirementGroup(
    uint256 group
  ) external override onlyRole(KYC_CONFIGURER_ROLE) {
    _setKYCRequirementGroup(group);
  }

  function setKYCRegistry(
    address registry
  ) external override onlyRole(KYC_CONFIGURER_ROLE) {
    _setKYCRegistry(registry);
  }

  function initialize(
    string memory name,
    string memory symbol,
    address kycRegistry,
    uint256 kycRequirementGroup
  ) public initializer {
    __ERC20PresetMinterPauser_init(name, symbol);
    __KYCRegistryClientInitializable_init(kycRegistry, kycRequirementGroup);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override {
    super._beforeTokenTransfer(from, to, amount);

    require(
      _getKYCStatus(_msgSender()),
      "CashKYCSenderReceiver: must be KYC'd to initiate transfer"
    );

    if (from != address(0)) {
      // Only check KYC if not minting
      require(
        _getKYCStatus(from),
        "CashKYCSenderReceiver: `from` address must be KYC'd to send tokens"
      );
    }

    if (to != address(0)) {
      // Only check KYC if not burning
      require(
        _getKYCStatus(to),
        "CashKYCSenderReceiver: `to` address must be KYC'd to receive tokens"
      );
    }
  }

  function burn(address from, uint256 amount) external onlyRole(BURNER_ROLE) {
    _burn(from, amount);
  }
}