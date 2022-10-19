pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev ERC20 token to represent a single slip for a bond box
 *
 */
interface ISlip is IERC20 {

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev returns the bond box address which owns this slip contract
     *  It should have admin permissions to call mint, burn, and redeem functions
     */
    function boxOwner() external view returns (address);

    /**
     * @dev Mint `amount` tokens to `to`
     *  Only callable by the owner.
     * @param to the address to mint tokens to
     * @param amount The amount of tokens to mint
     */
    function mint(address to, uint256 amount) external;

    /**
     * @dev Burn `amount` tokens from `from`'s balance
     *  Only callable by the owner.
     * @param from The address to burn tokens from
     * @param amount The amount of tokens to burn
     */
    function burn(address from, uint256 amount) external;

    /**
     * @dev allows owner to transfer ownership to a new owner. Implemented so that factory can transfer minting/burning ability to CBB after deployment
     * @param newOwner The address of the CBB
     */
    function changeOwner(address newOwner) external;
}