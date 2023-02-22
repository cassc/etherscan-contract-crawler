// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PausableUpgradeable.sol";
import "./openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract GeoToken is ERC20PausableUpgradeable, AccessControlUpgradeable {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    bytes32 public constant BUSINESS_ROLE = keccak256("BUSINESS_ROLE");    

    mapping(address => bool) public whitelist;

    function initialize(address _admin, address _minter, address _business) public initializer {
        __AccessControl_init();
        __ERC20Pausable_init();
        __ERC20_init_unchained("GEOPay UAH", "UAHg");
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _setupRole(MINTER_ROLE, _minter);
        _setupRole(BUSINESS_ROLE, _business);
    }

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "GeoToken: caller is not the Admin");
        _;
    }

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, _msgSender()), "GeoToken: caller is not a Minter");
        _;
    }

    modifier onlyBusiness() {
        require(hasRole(BUSINESS_ROLE, _msgSender()), "GeoToken: caller is not a Business");
        _;
    }

    modifier isWhitelisted(address account) {
        require(whitelist[account], "GeoToken: account is not whitelisted");
        _;
    }

    //admin functions
    function pause() onlyAdmin public {
        super._pause();
    }

    function unpause() onlyAdmin public {
        super._unpause();
    }

    function transferAdminship(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0), "GeoToken: newAdmin=0");
        _grantRole(DEFAULT_ADMIN_ROLE, newAdmin);
        _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function addToWhitelist(address[] memory accounts) public onlyAdmin {
        uint256 length = accounts.length;
        for(uint256 i = 0; i < length;){
            whitelist[accounts[i]] = true;
            unchecked { i++; }
        }
    }

    function removeFromWhitelist(address[] memory accounts) public onlyAdmin {
        uint256 length = accounts.length;
        for(uint256 i = 0; i < length;){
            whitelist[accounts[i]] = false;
            unchecked { i++; }
        }
    }

    // Minter functions

    function transferMintership(address newMinter) public onlyMinter {
        require(newMinter != address(0), "GeoToken: newMinter=0");
        _grantRole(MINTER_ROLE, newMinter);
        _revokeRole(MINTER_ROLE, msg.sender);
    }

    function mint(address to, uint256 amount) public onlyMinter isWhitelisted(to) {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public onlyMinter isWhitelisted(from) {
        _burn(from, amount);
    }

    // Business functions

    function transferBusinessship(address newBusiness) public onlyBusiness {
        require(newBusiness != address(0), "GeoToken: newBusiness=0");
        _grantRole(BUSINESS_ROLE, newBusiness);
        _revokeRole(BUSINESS_ROLE, msg.sender);
    }

    function version() public pure returns (uint32){
        //version in format aaa.bbb.ccc => aaa*1E6+bbb*1E3+ccc;
        return uint32(1000001);
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

}