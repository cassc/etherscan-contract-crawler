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

import "contracts/external/openzeppelin/contracts-upgradeable/token/ERC20/ERC20PresetMinterPauserUpgradeable.sol";
import "contracts/external/openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "contracts/kyc/KYCRegistryClientUpgradeable.sol";
import "contracts/interfaces/IOmmf.sol";

contract WOMMF is
  ERC20PresetMinterPauserUpgradeable,
  KYCRegistryClientUpgradeable
{
  IOMMF public ommf;
  bytes32 public constant BURNER_ROLE = keccak256("BURN_ROLE");
  bytes32 public constant WOMMF_MANAGER_ROLE = keccak256("WOMMF_MANAGER_ROLE");
  bytes32 public constant KYC_CONFIGURER_ROLE =
    keccak256("KYC_CONFIGURER_ROLE");

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  /**
   * @notice Function to initialize the proxy wOMMF contract
   *
   * @param name        The name of this token
   * @param symbol      The symbol for this token
   * @param ommfAddress The address of the underlying token to wrap
   */
  function initialize(
    address admin,
    string memory name,
    string memory symbol,
    address ommfAddress,
    address kycRegistry,
    uint256 requirementGroup
  ) public initializer {
    __ERC20PresetMinterPauser_init(name, symbol);
    __KYCRegistryClientInitializable_init(kycRegistry, requirementGroup);
    ommf = IOMMF(ommfAddress);
    _grantRole(DEFAULT_ADMIN_ROLE, admin);
    _grantRole(PAUSER_ROLE, admin);
    _grantRole(BURNER_ROLE, admin);
    _grantRole(KYC_CONFIGURER_ROLE, admin);
    _grantRole(WOMMF_MANAGER_ROLE, admin);
  }

  /**
   * @notice Event emitted when a user wraps their OMMF tokens
   *
   * @param from The address that initiated the wrap
   * @param ommfAmountIn The amount of OMMF tokens sent to the `from` address
   * @param wommfAmountOut The amount of wOMMF tokens minted
   */
  event Wrap(
    address indexed from,
    uint256 ommfAmountIn,
    uint256 wommfAmountOut
  );

  /**
   * @notice Event emitted when a user unwraps their OMMF tokens
   *
   * @param from The address that initiated the unwrap
   * @param ommfAmountOut The amount of OMMF tokens sent to the `from` address
   * @param wommfAmountIn The amount of wOMMF tokens burned
   */
  event Unwrap(
    address indexed from,
    uint256 ommfAmountOut,
    uint256 wommfAmountIn
  );

  /**
   * @notice Function called by users to wrap their wOMMF tokens
   *
   * @param _OMMFAmount The amount of OMMF Tokens to wrap
   *
   * @dev KYC checks implicit in OMMF Transfer
   */
  function wrap(uint256 _OMMFAmount) external {
    require(_OMMFAmount > 0, "wOMMF: can't wrap zero OMMF tokens");
    uint256 shares = ommf.getSharesByPooledCash(_OMMFAmount);
    _mint(msg.sender, shares);
    ommf.transferFrom(msg.sender, address(this), _OMMFAmount);
    emit Wrap(msg.sender, _OMMFAmount, shares);
  }

  /**
   * @notice Function called by users to unwrap their wOMMF tokens
   *
   * @param _wOMMFAmount The amount of wOMMF to unwrap
   *
   * @dev KYC checks implicit in OMMF Transfer
   */
  function unwrap(uint256 _wOMMFAmount) external {
    require(_wOMMFAmount > 0, "wOMMF: can't unwrap zero wOMMF tokens");
    uint256 ommfAmount = ommf.getBalanceOfByShares(_wOMMFAmount);
    _burn(msg.sender, _wOMMFAmount);
    ommf.transfer(msg.sender, ommfAmount);
    emit Unwrap(msg.sender, ommfAmount, _wOMMFAmount);
  }

  /**
   * @notice Function to get the amount of wOMMF tokens given an
   *         amount of OMMF tokens
   *
   * @param _OMMFAmount The amount of OMMF tokens to convert to
   *                    wOMMF
   */
  function getwOMMFByOMMF(uint256 _OMMFAmount) external view returns (uint256) {
    return ommf.getSharesByPooledCash(_OMMFAmount);
  }

  /**
   * @notice Functions to get the amount of OMMF tokens given an
   *         amount of wOMMF tokens
   *
   * @param _wOMMFAmount The amount of wOMMF tokens to convert to
   *                     OMMF
   */
  function getOMMFbywOMMF(
    uint256 _wOMMFAmount
  ) external view returns (uint256) {
    return ommf.getBalanceOfByShares(_wOMMFAmount);
  }

  /**
   * @notice Returns the amount of OMMF tokens redeemable for a
   *         single token on wOMMF
   */
  function OMMFPerToken() external view returns (uint256) {
    return ommf.getBalanceOfByShares(1e18);
  }

  /**
   * @notice Returns the amount of wOMMF tokens redeemable for a
   *         single token of OMMF
   */
  function tokensPerOMMF() external view returns (uint256) {
    return ommf.getSharesByPooledCash(1e18);
  }

  /**
   * @notice Admin function to burn wOMMF tokens from a given address
   *
   * @param account The account to burn the tokens from
   * @param amount  The amount of tokens to burn
   *
   * @dev Function will withdraw the OMMF tokens corresponding to the
   *      wOMMF tokens burned to the `account`
   * @dev Function will send underlying OMMF to the `BURNER_ROLE` account
   *      that initiated the admin burn
   */
  function adminBurn(
    address account,
    uint256 amount
  ) public onlyRole(BURNER_ROLE) {
    _burn(account, amount);
    uint256 ommfAmount = ommf.getBalanceOfByShares(amount);
    ommf.transfer(msg.sender, ommfAmount);
  }

  /**
   * @dev Hook that is called before any transfer of tokens. This includes
   *      minting and burning.
   *
   * @param from   The source of tokens being transferred
   * @param to     The destination for tokens being transferred
   * @param amount The amount of tokens being transferred
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override {
    super._beforeTokenTransfer(from, to, amount);
    if (from != _msgSender() && to != _msgSender()) {
      require(
        _getKYCStatus(_msgSender()),
        "wOMMF: must be KYC'd to initiate transfer"
      );
    }
    if (from != address(0)) {
      require(
        _getKYCStatus(from),
        "wOMMF: `from` address must be KYC'd to send tokens"
      );
    }
    if (to != address(0)) {
      require(_getKYCStatus(to), "wOMMF: `to` address must be KYC'd");
    }
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

  function pause() public override onlyRole(PAUSER_ROLE) {
    _pause();
  }

  function unpause() public override onlyRole(WOMMF_MANAGER_ROLE) {
    _unpause();
  }
}