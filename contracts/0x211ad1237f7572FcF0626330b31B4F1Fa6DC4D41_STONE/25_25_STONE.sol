// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IVestingFactory {
    function createSchedule(
        address,
        address,
        uint64,
        uint64,
        address
    ) external returns (address);
}

contract STONE is
    Initializable,
    ERC20Upgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20 for IERC20Metadata;

    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    uint256 public maxSupply;
    uint256 private maxMintable;

    address public teamWallet;
    address public publicWallet;
    address public liquidityWallet;
    address public treasuryWallet;

    address public feeCollector;
    IERC20Metadata public vSTONE;

    uint256 public presaleMaxSupply;
    bool public taxApplied;
    uint256 public constant taxBPS = 200;

    IVestingFactory public vestingFactory;

    address public teamLockProxy;
    address public treasuryLockProxy;

    bool public isVestingStarted;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _owner,
        address _vSTONE,
        address _vestingFactory,
        address _feeCollector
    ) public initializer {
        __ERC20_init("STONE", "STONE");
        __AccessControl_init();
        __UUPSUpgradeable_init();

        presaleMaxSupply = 133333333 * 10 ** decimals();

        maxSupply = 666666666 * 10 ** decimals();
        maxMintable = maxSupply - presaleMaxSupply;

        vestingFactory = IVestingFactory(_vestingFactory);
        feeCollector = _feeCollector;

        teamWallet = address(0x9e1547BE2a32C2F1b9f1616EcbbD0c20365794fd);
        publicWallet = address(0x7794DbCcD8Ef0554c7F592e5D1081d4A20b12C6b);
        liquidityWallet = address(0x5A178681A2974C845A56d70d6582649Dc5c474af);
        treasuryWallet = address(0x7a44a8F69b844466DCC37dfE5b5c2784e16A1074);

        vSTONE = IERC20Metadata(_vSTONE);
        _mint(address(vSTONE), presaleMaxSupply);

        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
        _grantRole(UPGRADER_ROLE, _owner);
    }

    function initVestingSchedule() external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(!isVestingStarted, "VESTING_ALREADY_STARTED");
        require(
            _noZeroAddress(teamWallet) &&
                _noZeroAddress(publicWallet) &&
                _noZeroAddress(liquidityWallet) &&
                _noZeroAddress(treasuryWallet),
            "ZERO_ADDRESS"
        );
        _mint(publicWallet, _getPercentAmt(maxMintable, 3125));
        _mint(liquidityWallet, _getPercentAmt(maxMintable, 3750));

        teamLockProxy = vestingFactory.createSchedule(
            address(0xc5dA15a0Da2e0A65602D23B000eC032a525A679B),
            teamWallet,
            uint64(block.timestamp),
            uint64(47335428),
            address(0x6892eb9cd308848B9E746a637852b9180f798543)
        );
        _mint(teamLockProxy, _getPercentAmt(maxMintable, 1875));

        treasuryLockProxy = vestingFactory.createSchedule(
            address(0x950526E2834065Be732cBe1B983e4E00b27b8405),
            treasuryWallet,
            uint64(block.timestamp),
            uint64(94670856),
            address(0x6892eb9cd308848B9E746a637852b9180f798543)
        );
        _mint(treasuryLockProxy, _getPercentAmt(maxMintable, 1250));
        isVestingStarted = true;
    }

    function setvSTONE(address _vSTONE) external onlyRole(DEFAULT_ADMIN_ROLE) {
        vSTONE = IERC20Metadata(_vSTONE);
    }

    function setTaxApplied(
        bool _taxApplied
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        taxApplied = _taxApplied;
    }

    function setFeeCollector(
        address _feeCollector
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_feeCollector == address(0)) revert("ZERO_ADDRESS");
        feeCollector = _feeCollector;
    }

    function setTeamWallet(
        address _wallet
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_wallet == address(0)) revert("ZERO_ADDRESS");
        teamWallet = _wallet;
    }

    function setPublicWallet(
        address _wallet
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_wallet == address(0)) revert("ZERO_ADDRESS");
        publicWallet = _wallet;
    }

    function setLiquidityWallet(
        address _wallet
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_wallet == address(0)) revert("ZERO_ADDRESS");
        liquidityWallet = _wallet;
    }

    function setTreasuryWallet(
        address _wallet
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_wallet == address(0)) revert("ZERO_ADDRESS");
        treasuryWallet = _wallet;
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal virtual override(ERC20Upgradeable) nonReentrant {
        if (
            !taxApplied ||
            msg.sender == address(vSTONE) ||
            msg.sender == treasuryLockProxy ||
            msg.sender == teamLockProxy
        ) {
            super._transfer(from, to, value);
        } else {
            (uint256 taxPart, uint256 transferPart) = _getTaxablePart(value);
            super._transfer(from, to, transferPart);
            super._transfer(from, feeCollector, taxPart);
        }
    }

    function _getTaxablePart(
        uint256 value
    ) internal pure returns (uint256 tax, uint256 transferable) {
        tax = _getPercentAmt(value, taxBPS);
        transferable = value - tax;
    }

    function _getPercentAmt(
        uint256 _amount,
        uint256 _percBPS
    ) internal pure returns (uint256) {
        require((_amount * _percBPS) >= 10_000, "TOO_SMALL");
        return (_amount * _percBPS) / 10_000;
    }

    function _noZeroAddress(address _addr) internal pure returns (bool isAddr) {
        isAddr = _addr != address(0);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(UPGRADER_ROLE) {}
}