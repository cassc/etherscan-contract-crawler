pragma solidity 0.5.4;

import "../../openzeppelin-solidity-2.2.0/contracts/token/ERC20/ERC20.sol";
import "../../openzeppelin-solidity-2.2.0/contracts/math/SafeMath.sol";


contract ERC20Redeemable is ERC20 {
    using SafeMath for uint256;

    uint256 public totalRedeemed;

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account. Overriden to track totalRedeemed.
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burn(address account, uint256 value) internal {
        totalRedeemed = totalRedeemed.add(value); // Keep track of total for Rewards calculation
        super._burn(account, value);
    }
}