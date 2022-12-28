// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/ivault_v2.sol";
import "./interfaces/uniswapv2.sol";

import "hardhat/console.sol";

contract SupervaultV2 is ERC20, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    bool public initialized = false;

    address public capitalToken;

    uint256 public maxCap;

    uint8[] public activeVaults;

    address[] public vaults;

    string public vaultName;

    uint256 private constant MAX_APPROVAL = type(uint256).max;

    event ActiveVaultsUpdated(uint8[] activeVaults);

    constructor(string memory _name)
        ERC20(
            string(abi.encodePacked("xUBXT_", _name)),
            string(abi.encodePacked("xUBXT_", _name))
        )
    {
        vaultName = _name;
    }

    function initialize(
        address _capitalToken,
        uint256 _maxCap,
        address[] calldata _vaults,
        uint8[] calldata _activeVaults
    ) external onlyOwner {
        require(!initialized, "already initialized");

        require(_capitalToken != address(0), "invalid capitalToken");
        require(_vaults.length > 0, "invalid vaults");
        require(_activeVaults.length > 0, "invalid active vaults");
        require(_maxCap > 0, "invalid max cap");

        uint8 i;
        uint256 totalVaults = _vaults.length;
        for (i = 0; i < totalVaults; i++) {
            require(_vaults[i] != address(0), "invalid vault address");

            IERC20(_capitalToken).safeApprove(_vaults[i], MAX_APPROVAL);
        }

        for (i = 0; i < _activeVaults.length; i++) {
            require(_activeVaults[i] < totalVaults, "invalid vault index");
        }

        activeVaults = _activeVaults;
        capitalToken = _capitalToken;
        maxCap = _maxCap;
        vaults = _vaults;

        initialized = true;

        emit ActiveVaultsUpdated(activeVaults);
    }

    function estimatedPoolSize() public view returns (uint256) {
        uint256 total = 0;
        for (uint8 i = 0; i < activeVaults.length; i++) {
            total += IVaultV2(vaults[activeVaults[i]]).estimatedDeposit(
                address(this)
            );
        }
        return total;
    }

    function estimatedDeposit(address account) external view returns (uint256) {
        return
            totalSupply() == 0
                ? 0
                : (estimatedPoolSize() * balanceOf(account)) / totalSupply();
    }

    function deposit(uint256 amount) external nonReentrant {
        require(initialized, "NI");
        uint256 vaultsCount = activeVaults.length;

        // Check max cap
        uint256 _poolSize = estimatedPoolSize();
        require(_poolSize + amount < maxCap, "The vault reached the max cap");

        // receive funds

        uint256 _before = IERC20(capitalToken).balanceOf(address(this));
        IERC20(capitalToken).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
        uint256 _after = IERC20(capitalToken).balanceOf(address(this));
        amount = _after - _before;

        // divide, swap to each quote token and deposit to the vaults
        uint256 subAmount = amount / vaultsCount;
        require(subAmount > 0, "not a valid amount received");

        for (uint8 i = 0; i < vaultsCount; i++) {
            IVaultV2(vaults[activeVaults[i]]).depositQuote(subAmount);
        }

        // 4. mint tokens for shares
        uint256 shares = 0;
        if (totalSupply() == 0) {
            shares = amount;
        } else {
            shares = (amount * totalSupply()) / _poolSize;
        }
        require(shares > 0, "failure in share calculation");
        _mint(msg.sender, shares);
    }

    function withdraw(uint256 shares) external nonReentrant {
        require(initialized, "NI");
        require(shares <= balanceOf(msg.sender), "invalid share amount");
        for (uint8 i = 0; i < activeVaults.length; i++) {
            IVaultV2 vault = IVaultV2(vaults[activeVaults[i]]);
            uint256 subShare = (vault.balanceOf(address(this)) * shares) /
                totalSupply();
            vault.withdrawQuote(subShare);
        }

        if (IERC20(capitalToken).balanceOf(address(this)) > 0) {
            IERC20(capitalToken).safeTransfer(
                msg.sender,
                IERC20(capitalToken).balanceOf(address(this))
            );
        }

        _burn(msg.sender, shares);
    }

    function updateVaults(uint8[] calldata _activeVaults)
        external
        nonReentrant
        onlyOwner
    {
        require(initialized, "NI");
        require(_activeVaults.length > 0, "invalid active vaults");
        uint256 totalVaults = vaults.length;
        uint256 newActiveCount = _activeVaults.length;
        uint8 i;
        for (i = 0; i < newActiveCount; i++) {
            require(_activeVaults[i] < totalVaults, "invalid vault index");
        }

        // 3. withdraw all funds and swap back to capital token (it could be no quote token in some cases)
        for (i = 0; i < activeVaults.length; i++) {
            IVaultV2 vault = IVaultV2(vaults[activeVaults[i]]);
            vault.withdrawQuote(vault.balanceOf(address(this)));
        }

        // 4. update vaults addresses
        activeVaults = _activeVaults;

        // 5. divide, swap and deposit funds to each vault
        uint256 subAmount = IERC20(capitalToken).balanceOf(address(this)) /
            newActiveCount;
        for (i = 0; i < newActiveCount; i++) {
            IVaultV2(vaults[activeVaults[i]]).depositQuote(subAmount);
        }

        emit ActiveVaultsUpdated(activeVaults);
    }
}