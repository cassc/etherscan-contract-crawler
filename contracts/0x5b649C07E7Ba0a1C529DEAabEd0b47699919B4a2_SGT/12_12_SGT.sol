//SPDX-License-Identifier: None
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";


contract SGT is ERC20Capped , ERC20Burnable , Ownable , AccessControl  {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(address owner , uint256 initAmount, uint256 cappedAmount) ERC20("SGT", "SGT") ERC20Capped(cappedAmount){
        require(initAmount <= cappedAmount, "ERC20Capped: init must <= cap");
        if (owner == address(0)) {
            owner = msg.sender;
        }
        ERC20._mint(owner , initAmount);
        // Grant the contract deployer the default admin role: it will be able
        // to grant and revoke any roles
        _setupRole(DEFAULT_ADMIN_ROLE, owner);
        _setupRole(MINTER_ROLE, owner);
    }

    function decimals()
        public
        view
        virtual
        override
        returns (uint8)
    {
        return 8;
    }

    /**
     * @dev See {ERC20Capped-_mint}.
     */
    function _mint(address account, uint256 amount) internal virtual override(ERC20Capped, ERC20) {
        require(ERC20.totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
        super._mint(account, amount);
    }

    /**
     * @dev mint new token to address with fix voting power and expire time
     *
     * Requirements:
     *
     * - caller must have minter role
     */
    function mint(address account, uint256 amount) public
    {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        _mint(account , amount);
    }
}