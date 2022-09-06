// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract ETHBToken is ERC20, AccessControl, ERC20Burnable, Pausable {
    using SafeMath for uint256;

    uint256 internal _totalSupply = 0;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    constructor() ERC20("ETHB Token", "ETHB") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(BURNER_ROLE, msg.sender);
    }


    /**
    * @notice Set decimal to 18.
    */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
    * @notice used to set the newOwner of this contract.
    * @dev Public function callable by only Admin
    * @param newOwner The new admin address
    */
    function transferOwnership(address newOwner) public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Caller is not an admin"
        );
        grantRole(DEFAULT_ADMIN_ROLE, newOwner);
        revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
    * @notice used to mint new token
    * @dev Public function callable by only minter
    * @param account The account address to mint
    * @param amount The amount to mint
    */
    function mint(address account, uint256 amount)
        public
        virtual
        whenNotPaused
    {
        require(account != address(0), "ERC20: mint to the zero address");
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a Minter");
        _totalSupply = _totalSupply.add(amount * 10**18);
        emit Transfer(address(0), account, amount * 10**18);
        _mint(account, amount * 10**18);
    }

    /**
    * @notice used to transfer token
    * @dev Public function callable by anyone
    * @param from The address of the account that send token.
    * @param to The address of the account that receive token.
    * @param amount The amount to transfer
    */
    function transferFrom(address from, address to, uint256 amount )
        public
        virtual
        whenNotPaused
        override
        returns (bool)
    {
        _spendAllowance(from, _msgSender(), amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
    * @notice used to transfer token
    * @dev Public function callable by token sender
    * @param recipient The address of the account that receive token
    * @param amount The amount to transfer
    */
    function transfer(address recipient, uint256 amount)
        public
        virtual
        whenNotPaused
        override
        returns (bool)
    {
        address owner = _msgSender();
        _transfer(owner, recipient, amount);
        return true;
    }

    /**
    * @notice used to burn ETHB token
    * @dev Public Override function callable by only Burner
    * @param amount The amount to burn
    */
    function burn(uint256 amount) public virtual  whenNotPaused override{
        require(hasRole(BURNER_ROLE, msg.sender), "Caller is not a Burner");
        uint256 newBurnSupply = _totalSupply.sub(amount * 10**18);
        require(newBurnSupply >= 0, "Can't burn more!");
        _totalSupply = _totalSupply.sub(amount * 10**18);
        _burn(_msgSender(), amount * 10**18);
    }

}