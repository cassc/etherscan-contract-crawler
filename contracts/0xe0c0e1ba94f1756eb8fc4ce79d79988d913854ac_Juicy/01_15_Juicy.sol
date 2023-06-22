// $Juicy
//
// Twitter: https://twitter.com/Juicy__Token
//
// Website: https://hypelaunchpad.vip
// Telegram: https://t.me/HypetokenVIP
//
// This Launch is SAFU certified by https://hypelaunchpad.vip

pragma solidity ^0.8.4;

contract Juicy is ERC20, ReentrancyGuard, AccessControl, Ownable, Taxable {
    // Used for sending the 1% buy and sell tax
    address public taxWallet = 0x304C9EB81D3fB79df81020AB56811fEB3c93597A;

    // Total max supply set at 100 Billion
    uint256 public maxSupply = 100_000_000_000 * (10 ** decimals());

    bytes32 public constant NOT_TAXED_FROM = keccak256("NOT_TAXED_FROM");
    bytes32 public constant NOT_TAXED_TO = keccak256("NOT_TAXED_TO");
    bytes32 public constant ALWAYS_TAXED_FROM = keccak256("ALWAYS_TAXED_FROM");
    bytes32 public constant ALWAYS_TAXED_TO = keccak256("ALWAYS_TAXED_TO");

    constructor() ERC20("Juicy", "JUICY") Taxable(true, 100, 1500, 25, taxWallet) {
        // Access control for tax
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(NOT_TAXED_FROM, msg.sender);
        _grantRole(NOT_TAXED_TO, msg.sender);
        _grantRole(NOT_TAXED_FROM, address(this));
        _grantRole(NOT_TAXED_TO, address(this));

        // Team wallets, 3% total
        _mint(0x8B6970Ae148E18A0Ad00ad7f769e729Cdbbf34a1, (maxSupply * 1) / 100); // 1%
        _mint(0xE5afBBD00785350280f890e08D4Caf6781E81E35, (maxSupply * 1) / 100); // 1%
        _mint(0x2aE6d471A9f4B5ce3685e0c3ab942734AE67Dd7A, (maxSupply * 1) / 100); // 1%

        // Mint the rest to deployer to be used for Uniswap
        _mint(msg.sender, (maxSupply * 97) / 100); // 97%

        // Renounce, no more minting
        renounceOwnership();
    }

    function enableTax() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _taxon();
    }

    function disableTax() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _taxoff();
    }

    function updateTax(uint newtax) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _updatetax(newtax);
    }

    function updateTaxDestination(address newdestination) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _updatetaxdestination(newdestination);
    }

    function _transfer(address from, address to, uint256 amount) internal virtual override(ERC20) nonReentrant {
        if (hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            super._transfer(from, to, amount);
        } else {
            if (
                (hasRole(NOT_TAXED_FROM, from) || hasRole(NOT_TAXED_TO, to) || !taxed()) &&
                !hasRole(ALWAYS_TAXED_FROM, from) &&
                !hasRole(ALWAYS_TAXED_TO, to)
            ) {
                super._transfer(from, to, amount);
            } else {
                require(balanceOf(from) >= amount, "Error: transfer amount exceeds balance");
                super._transfer(from, taxdestination(), (amount * thetax()) / 10000);
                super._transfer(from, to, (amount * (10000 - thetax())) / 10000);
            }
        }
    }
}

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./Taxable.sol";