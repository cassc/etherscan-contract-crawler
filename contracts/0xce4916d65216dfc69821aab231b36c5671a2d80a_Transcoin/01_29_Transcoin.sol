// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

/// @custom:security-contact [email protected]
contract Transcoin is Initializable, ERC20Upgradeable, AccessControlUpgradeable, PausableUpgradeable, ERC20PermitUpgradeable, UUPSUpgradeable, ReentrancyGuardUpgradeable {
    event SetLiquidPair(address LP, bool Status);

    using SafeMath for uint256;
    uint256 public DIVI;
    uint256 public sellTax; 
    uint256 public buyTax;
    address public feeWallet;
    bool public burnAllowed;

    mapping(address => bool) public lps;
    mapping(address => bool) public blacklisted;
    mapping(address => bool) public whitelisted;

    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant TAXMAN_ROLE = keccak256("TAXMAN_ROLE");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(){
        _disableInitializers();
    }

    function initialize() initializer public {
        __ERC20_init("Transcoin", "TRNS");
        __AccessControl_init();
        __Pausable_init();
        __ERC20Permit_init("Transcoin");
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(BURNER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
        _grantRole(TAXMAN_ROLE, msg.sender);
        _mint(msg.sender, 800057907687 * 10 ** decimals());
        DIVI = 10000;
        sellTax = 5; // 5% sell tax
        buyTax = 0; // 0% buy tax
    }

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override(ERC20Upgradeable)
    {
        require(!blacklisted[from] && !blacklisted[to], "Blacklisted");
        super._beforeTokenTransfer(from, to, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused{
        uint256 sellFee = 0;
        uint256 buyFee = 0;
        if (lps[from] && !whitelisted[to] && buyTax > 0 && feeWallet != address(0)) {
                buyFee = (amount * buyTax) / 100;
            } 
            else if (lps[to] && !whitelisted[from] && sellTax > 0 && feeWallet != address(0)) {
                sellFee = (amount * sellTax) / 100;
            }

            uint256 totalFee = sellFee + buyFee;
            uint256 transferAmount = amount - totalFee;

            super._transfer(from, to, transferAmount);

            if (totalFee > 0) {
                super._transfer(from, feeWallet, totalFee);
            }
    }
    
    function _burn(
        address account,
        uint256 amount
    ) internal override {
        require(burnAllowed, "Burn not allowed.");

        super._burn(account, amount);
    }

    /**
    * @dev Set burnAllowed which is required to be true for allowing burning.
    * @notice Only address with Admin Role can call.
    */
    function setBurnStatus(bool _burnAllowed) public onlyRole(BURNER_ROLE) {
        burnAllowed = _burnAllowed;
    }

    function blacklist(address _user, bool _isBlacklisted) external onlyRole(DEFAULT_ADMIN_ROLE) {
        blacklisted[_user] = _isBlacklisted;
    }


    function whitelist(address _user, bool _enable) external onlyRole(DEFAULT_ADMIN_ROLE) {
        whitelisted[_user] = _enable;
    }

    function setLiquidPair(address _lp, bool _status) external onlyRole(TAXMAN_ROLE) {
        require(address(0) != _lp,"_lp zero address");
        lps[_lp] = _status;
        emit SetLiquidPair(_lp, _status);
    }

    function setFeeWallet(address _feeWallet) public onlyRole(TAXMAN_ROLE) {
        feeWallet = _feeWallet;
    }

    function setSellTax(uint256 _taxPercent) public onlyRole(TAXMAN_ROLE) {
        sellTax = _taxPercent;
    }

    function setBuyTax(uint256 _taxPercent) public onlyRole(TAXMAN_ROLE) {
        buyTax = _taxPercent;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(UPGRADER_ROLE)
        override
    {}
}