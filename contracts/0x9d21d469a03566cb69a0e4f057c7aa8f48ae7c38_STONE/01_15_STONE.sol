// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IVestingFactory {
    function createLockSchedule(
        address,
        uint64,
        uint64
    ) external returns (address);
}

contract STONE is ERC20, AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20Metadata;

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

    address public teamLockSchedule;
    address public treasuryLockSchedule;

    bool public isVestingStarted;
    bool public isClaimStarted;

    constructor(address _owner) ERC20("STONE", "STONE") {
        presaleMaxSupply = 133333333 * 10 ** decimals();

        maxSupply = 666666666 * 10 ** decimals();
        maxMintable = maxSupply - presaleMaxSupply;

        teamWallet = address(0xB1ca1eD0A71fAaf41370e7A80fB33Ee277c29fA4);
        publicWallet = address(0xCfFA512F4Bf8EaA6b04541d6a39Aa9bb8Af82e64);
        liquidityWallet = address(0x79C124Fc2a5Ba568145769108e5fc5312D8cA4F8);
        treasuryWallet = address(0x3aC95a8f10E0E0ebC2DcD67570d74e7Dc7F7f851);

        feeCollector = address(0x0E826eF9119964dcb5B93720BE0Bce9BCe36112E);

        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
    }

    function initPresaleClaims() external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (address(vSTONE) == address(0)) revert("ZERO_ADDRESS");
        require(!isClaimStarted, "CLAIMS_ALREADY_STARTED");
        _mint(address(vSTONE), presaleMaxSupply);
        isClaimStarted = true;
    }

    function initVestingSchedule() external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(!isVestingStarted, "VESTING_ALREADY_STARTED");
        require(
            _noZeroAddress(teamWallet) &&
                _noZeroAddress(publicWallet) &&
                _noZeroAddress(liquidityWallet) &&
                _noZeroAddress(treasuryWallet) &&
                _noZeroAddress(address(vestingFactory)),
            "ZERO_ADDRESS"
        );
        _mint(publicWallet, _getPercentAmt(maxMintable, 3125));
        _mint(liquidityWallet, _getPercentAmt(maxMintable, 3750));

        teamLockSchedule = vestingFactory.createLockSchedule(
            teamWallet,
            uint64(block.timestamp),
            uint64(47335428)
        );
        _mint(teamLockSchedule, _getPercentAmt(maxMintable, 1875));

        treasuryLockSchedule = vestingFactory.createLockSchedule(
            treasuryWallet,
            uint64(block.timestamp),
            uint64(94670856)
        );
        _mint(treasuryLockSchedule, _getPercentAmt(maxMintable, 1250));
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

    function setVestingFactory(
        address _vestingFactory
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_vestingFactory == address(0)) revert("ZERO_ADDRESS");
        vestingFactory = IVestingFactory(_vestingFactory);
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal virtual override(ERC20) nonReentrant {
        if (
            !taxApplied ||
            msg.sender == address(vSTONE) ||
            msg.sender == treasuryLockSchedule ||
            msg.sender == teamLockSchedule
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
}