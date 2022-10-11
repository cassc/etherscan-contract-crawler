// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.13;

import { FixedPointMathLib } from "../utils/FixedPointMathLib.sol";
import { SafeTransferLib } from "../utils/SafeTransferLib.sol";
import { ReentrancyGuard } from "../utils/ReentrancyGuard.sol";
import { ERC2612, UpgradeableEIP712 } from "./ERC2612.sol";
import { ERC4626Storage } from "../storage/ERC4626Storage.sol";
import "../interfaces/IERC4626.sol";

/// @notice Minimal ERC4626 tokenized Vault implementation.
/// @author ZeroDAO
/// @author Modified from Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/mixins/ERC4626.sol)
/// All functions which can affect the ratio of shares to underlying assets must be nonreentrant
contract ERC4626 is ERC4626Storage, ERC2612, ReentrancyGuard, IERC4626 {
  using SafeTransferLib for address;
  using FixedPointMathLib for uint256;

  /*//////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

  address public immutable override asset;

  constructor(
    address _asset,
    string memory _name,
    string memory _symbol,
    uint8 _decimals,
    address _proxyContract,
    string memory _version
  ) ERC2612(_proxyContract, _name, _symbol, _decimals, _version) {
    asset = _asset;
  }

  modifier onlyAuthorized() {
    require(_authorized[msg.sender], "unauthorized");
    _;
  }

  function _initialize() internal virtual override(UpgradeableEIP712, ReentrancyGuard) {
    UpgradeableEIP712._initialize();
    ReentrancyGuard._initialize();
  }

  /*//////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

  function deposit(uint256 assets, address receiver)
    public
    virtual
    override
    onlyAuthorized
    nonReentrant
    returns (uint256 shares)
  {
    // Check for rounding error since we round down in previewDeposit.
    if ((shares = previewDeposit(assets)) == 0) {
      revert ZeroShares();
    }

    // Need to transfer before minting or ERC777s could reenter.
    asset.safeTransferFrom(msg.sender, address(this), assets);

    _mint(receiver, shares);

    emit Deposit(msg.sender, receiver, assets, shares);

    afterDeposit(assets, shares);
  }

  function mint(uint256 shares, address receiver) public virtual override nonReentrant returns (uint256 assets) {
    assets = previewMint(shares); // No need to check for rounding error, previewMint rounds up.

    // Need to transfer before minting or ERC777s could reenter.
    asset.safeTransferFrom(msg.sender, address(this), assets);

    _mint(receiver, shares);

    emit Deposit(msg.sender, receiver, assets, shares);

    afterDeposit(assets, shares);
  }

  function withdraw(
    uint256 assets,
    address receiver,
    address owner
  ) public virtual override nonReentrant returns (uint256 shares) {
    shares = previewWithdraw(assets); // No need to check for rounding error, previewWithdraw rounds up.

    if (msg.sender != owner) {
      uint256 allowed = _allowance[owner][msg.sender]; // Saves gas for limited approvals.

      if (allowed != type(uint256).max) _allowance[owner][msg.sender] = allowed - shares;
    }

    beforeWithdraw(assets, shares);

    _burn(owner, shares);

    emit Withdraw(msg.sender, receiver, owner, assets, shares);

    asset.safeTransfer(receiver, assets);
  }

  function redeem(
    uint256 shares,
    address receiver,
    address owner
  ) public virtual override nonReentrant returns (uint256 assets) {
    if (msg.sender != owner) {
      uint256 allowed = _allowance[owner][msg.sender]; // Saves gas for limited approvals.

      if (allowed != type(uint256).max) {
        _allowance[owner][msg.sender] = allowed - shares;
      }
    }

    // Check for rounding error since we round down in previewRedeem.
    if ((assets = previewRedeem(shares)) == 0) {
      revert ZeroShares();
    }

    beforeWithdraw(assets, shares);

    _burn(owner, shares);

    emit Withdraw(msg.sender, receiver, owner, assets, shares);

    asset.safeTransfer(receiver, assets);
  }

  /*//////////////////////////////////////////////////////////////
                            ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

  function totalAssets() public view virtual override returns (uint256) {
    return IERC20(asset).balanceOf(address(this));
  }

  function convertToShares(uint256 assets) public view virtual override returns (uint256) {
    uint256 supply = _totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

    return supply == 0 ? assets : assets.mulDivDown(supply, totalAssets());
  }

  function convertToAssets(uint256 shares) public view virtual override returns (uint256) {
    uint256 supply = _totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

    return supply == 0 ? shares : shares.mulDivDown(totalAssets(), supply);
  }

  function previewDeposit(uint256 assets) public view virtual override returns (uint256) {
    return convertToShares(assets);
  }

  function previewMint(uint256 shares) public view virtual override returns (uint256) {
    uint256 supply = _totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

    return supply == 0 ? shares : shares.mulDivUp(totalAssets(), supply);
  }

  function previewWithdraw(uint256 assets) public view virtual override returns (uint256) {
    uint256 supply = _totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

    return supply == 0 ? assets : assets.mulDivUp(supply, totalAssets());
  }

  function previewRedeem(uint256 shares) public view virtual override returns (uint256) {
    return convertToAssets(shares);
  }

  function previewWithdrawForCheckpoint(
    uint256 assets,
    uint256 checkpointSupply,
    uint256 checkpointTotalAssets
  ) internal pure virtual returns (uint256) {
    return checkpointSupply == 0 ? assets : assets.mulDivUp(checkpointSupply, checkpointTotalAssets);
  }

  function checkpointWithdrawParams() internal view returns (uint256 checkpointSupply, uint256 checkpointTotalAssets) {
    checkpointSupply = _totalSupply;
    checkpointTotalAssets = totalAssets();
  }

  /*//////////////////////////////////////////////////////////////
                     DEPOSIT/WITHDRAWAL LIMIT LOGIC
    //////////////////////////////////////////////////////////////*/

  function maxDeposit(address) public view virtual override returns (uint256) {
    return type(uint256).max;
  }

  function maxMint(address) public view virtual override returns (uint256) {
    return type(uint256).max;
  }

  function maxWithdraw(address owner) public view virtual override returns (uint256) {
    return convertToAssets(_balanceOf[owner]);
  }

  function maxRedeem(address owner) public view virtual override returns (uint256) {
    return _balanceOf[owner];
  }

  /*//////////////////////////////////////////////////////////////
                          INTERNAL HOOKS LOGIC
    //////////////////////////////////////////////////////////////*/

  function beforeWithdraw(uint256 assets, uint256 shares) internal virtual {}

  function afterDeposit(uint256 assets, uint256 shares) internal virtual {}
}