// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./FlaixOptionFactory.sol";

import "./interfaces/IFlaixVault.sol";
import "./interfaces/IFlaixOption.sol";

/// @title FlaixVault
/// @notice This contract pertains to the FlaixVault contract, which
///         serves as a means of investing in AI tokens. The contract
///         is designed to hold tokens that are expected to increase in
///         value over time. Ownership of the vault is represented by
///         the FLAIX token, which is a proportional share of the tokens
///         held by the vault.
/// @dev This contract is based on the OpenZeppelin ERC20 contract.
contract FlaixVault is ERC20, IFlaixVault, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using Math for uint256;

    EnumerableSet.AddressSet private _allowedAssets;

    /// @notice The address of the FlaixOptionFactory contract.
    FlaixOptionFactory public immutable optionFactory;

    /// @notice The address of the admin account. The admin account should be replaced
    ///         by a multisig contract or even better a DAO in the future.
    address public admin;

    /// @notice When an option is issued, the issuer selects a maturity value, which is the
    /// point in time when the option can be exercised. The maturity period must be a
    /// minimum of three days, but the admin account has the ability to adjust the
    /// minimum maturity period.
    uint public minimalOptionsMaturity = 3 days;

    mapping(address => uint) internal minters;

    modifier onlyAdmin() {
        if (_msgSender() != admin) revert IFlaixVault.OnlyAllowedForAdmin();
        _;
    }

    /// @dev Constructor
    constructor(address optionFactory_) ERC20("Coinflakes AI Vault", "FLAIX") {
        admin = _msgSender();
        optionFactory = FlaixOptionFactory(optionFactory_);
        emit AdminChanged(admin, address(0));
    }

    /// @inheritdoc IFlaixGovernance
    function changeAdmin(address newAdmin) public onlyAdmin {
        if (newAdmin == address(0)) revert IFlaixVault.AdminCannotBeNull();
        emit AdminChanged(newAdmin, admin);
        admin = newAdmin;
    }

    /// @inheritdoc IFlaixGovernance
    function changeMinimalOptionsMaturity(uint newMaturity) public onlyAdmin {
        if (newMaturity < 3 days) revert IFlaixVault.MaturityChangeBelowLimit();
        minimalOptionsMaturity = newMaturity;
    }

    /// @inheritdoc IFlaixGovernance
    function allowAsset(address assetAddress) public onlyAdmin {
        if (assetAddress == address(0)) revert IFlaixVault.AssetCannotBeNull();
        if (!_allowedAssets.add(assetAddress)) revert AssetAlreadyOnAllowList();
        emit AssetAllowed(assetAddress);
    }

    /// @inheritdoc IFlaixGovernance
    function disallowAsset(address assetAddress) public onlyAdmin {
        if (!_allowedAssets.remove(assetAddress)) revert AssetNotOnAllowList();
        emit AssetDisallowed(assetAddress);
    }

    /// @inheritdoc IFlaixGovernance
    function isAssetAllowed(address assetAddress) public view returns (bool) {
        return _allowedAssets.contains(assetAddress);
    }

    /// @inheritdoc IFlaixGovernance
    function allowedAssets() public view returns (uint256) {
        return _allowedAssets.length();
    }

    /// @inheritdoc IFlaixGovernance
    function allowedAsset(uint256 index) public view returns (address) {
        if (index >= _allowedAssets.length()) revert IFlaixVault.AssetIndexOutOfBounds();
        return _allowedAssets.at(index);
    }

    /// @inheritdoc IFlaixVault
    function minterBudgetOf(address minter) public view returns (uint) {
        return minters[minter];
    }

    /// @inheritdoc IFlaixVault
    function redeemShares(uint256 amount, address recipient) public nonReentrant {
        if (amount == 0) return;
        if (totalSupply() == 0) return;
        if (recipient == address(0)) revert IFlaixVault.RecipientCannotBeNullAddress();
        for (uint256 i = 0; i < _allowedAssets.length(); i++) {
            address asset = _allowedAssets.at(i);
            //slither-disable-next-line calls-loop
            uint256 assetBalance = IERC20(asset).balanceOf(address(this));
            uint256 assetAmount = assetBalance.mulDiv(amount, totalSupply(), Math.Rounding.Down);
            //slither-disable-next-line calls-loop
            IERC20(asset).safeTransfer(recipient, assetAmount);
        }
        _burn(msg.sender, amount);
    }

    /// @inheritdoc IFlaixVault
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    /// @inheritdoc IFlaixVault
    function mint(uint amount, address recipient) public {
        if (minters[msg.sender] < amount) revert IFlaixVault.MinterBudgetExceeded();
        _mint(recipient, amount);
    }

    function _mint(address account, uint256 amount) internal override {
        minters[msg.sender] = minters[msg.sender].sub(amount);
        super._mint(account, amount);
    }

    /// @inheritdoc IFlaixGovernance
    function issueCallOptions(
        string memory name,
        string memory symbol,
        uint256 sharesAmount,
        address recipient,
        address asset,
        uint256 assetAmount,
        uint256 maturityTimestamp
    ) public onlyAdmin nonReentrant returns (address) {
        //slither-disable-next-line timestamp
        if (maturityTimestamp < block.timestamp + minimalOptionsMaturity) revert IFlaixVault.MaturityTooLow();
        if (!_allowedAssets.contains(asset)) revert IFlaixVault.AssetNotOnAllowList();

        address options = optionFactory.createCallOption(
            name,
            symbol,
            asset,
            recipient,
            address(this),
            sharesAmount,
            maturityTimestamp
        );
        //slither-disable-next-line reentrancy-benign
        minters[options] = sharesAmount;

        emit IssueCallOptions(options, recipient, name, symbol, sharesAmount, asset, assetAmount, maturityTimestamp);
        IERC20(asset).safeTransferFrom(msg.sender, options, assetAmount);

        return options;
    }

    /// @inheritdoc IFlaixGovernance
    function issuePutOptions(
        string memory name,
        string memory symbol,
        uint256 sharesAmount,
        address recipient,
        address asset,
        uint256 assetAmount,
        uint maturityTimestamp
    ) public onlyAdmin nonReentrant returns (address) {
        //slither-disable-next-line timestamp
        if (maturityTimestamp < block.timestamp + minimalOptionsMaturity) revert IFlaixVault.MaturityTooLow();
        if (!_allowedAssets.contains(asset)) revert IFlaixVault.AssetNotOnAllowList();

        address options = optionFactory.createPutOption(
            name,
            symbol,
            asset,
            recipient,
            address(this),
            sharesAmount,
            maturityTimestamp
        );
        emit IssuePutOptions(options, recipient, name, symbol, sharesAmount, asset, assetAmount, maturityTimestamp);
        IERC20(this).safeTransferFrom(msg.sender, options, sharesAmount);
        _burn(options, sharesAmount);
        //slither-disable-next-line reentrancy-benign
        minters[options] = sharesAmount;
        IERC20(asset).safeTransfer(options, assetAmount);
        return options;
    }
}