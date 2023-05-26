// SPDX-License-Identifier: Not Licensed
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "./extensions/ERC20SupplyControlledToken.sol";
import "./extensions/ERC20BatchTransferrableToken.sol";

/**
 * ERC20 token with cap, role based access control, burning, and batch transfer functionalities.
 */
contract WFCAToken is
    Context,
    ERC20Capped,
    AccessControl,
    ERC20Burnable,
    ERC20SupplyControlledToken,
    ERC20BatchTransferrableToken
{
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    constructor(address _initialSupplyRecipient)
        ERC20SupplyControlledToken(
            "World Friendship Cash",
            "WFCA",
            18,
            1_000_000_000 * (10**18),
            1_000_000_000 * (10**18),
            _initialSupplyRecipient
        )
    {
        address _initialAdmin = _msgSender();
        _grantRole(DEFAULT_ADMIN_ROLE, _initialAdmin);
        _grantRole(BURNER_ROLE, _initialAdmin);
    }

    function decimals()
        public
        view
        virtual
        override(ERC20, ERC20SupplyControlledToken)
        returns (uint8)
    {
        return ERC20SupplyControlledToken.decimals();
    }

    /**
     * Override to restrict access.
     */
    function burn(uint256 amount) public override onlyRole(BURNER_ROLE) {
        super.burn(amount);
    }

    /**
     * Override to restrict access.
     */
    function burnFrom(address account, uint256 amount)
        public
        override
        onlyRole(BURNER_ROLE)
    {
        super.burnFrom(account, amount);
    }

    // The following functions are overrides required by Solidity.

    function _mint(address account, uint256 amount)
        internal
        virtual
        override(ERC20, ERC20Capped)
    {
        ERC20Capped._mint(account, amount);
    }
}