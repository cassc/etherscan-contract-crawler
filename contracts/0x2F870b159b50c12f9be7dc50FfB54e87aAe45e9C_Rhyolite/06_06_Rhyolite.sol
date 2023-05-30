// Rhyolite (RHY)
// Rhyolite is an extrusive igneous rock, formed from magma rich in silica that is extruded from a
// volcanic vent to cool quickly on the surface rather than slowly in the subsurface.
// It is generally light in color due to its low content of mafic minerals, and it is typically very fine-grained (aphanitic) or glassy.
// On a mission to dethrone Pepe!
//
//     \                              /\| | | |
//      \                            / /|_|_|_|
//       \                           \        |
//         (  ( ) ) ( )  )            \_______/
//        ( ( ( ( )  )  ) )           /______/
//       ( ( )) ) (   ) ( ( )        /       /
//       ( (__.-.___.-.__) )        /       /
//       / ---._.---._.---\        /       /
//       \||    '/  '   ||/       /       /
//         |||  (_     |||       /       /
//          || ///\\\  ||\______/       /
//     ___/ ||||\__/|||||/             /
//    /   \   ||||||||  /             /
//   /     \   ||||||  /        _____/

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Rhyolite is Context, ERC20, Ownable {
    constructor() ERC20("Rhyolite", "RHY") {
        uint256 cappedSupply = 200_000_000_000 * (10 ** decimals());
        _mint(_msgSender(), cappedSupply);
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}