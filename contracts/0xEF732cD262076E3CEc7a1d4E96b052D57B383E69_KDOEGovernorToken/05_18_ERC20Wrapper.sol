// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/ERC20Wrapper.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @dev Extension of the ERC20 token contract to support token wrapping.
 *
 * Users can deposit and withdraw "underlying tokens" and receive a matching number of "wrapped tokens". This is useful
 * in conjunction with other modules. For example, combining this wrapping mechanism with {ERC20Votes} will allow the
 * wrapping of an existing "basic" ERC20 into a governance token.
 *
 * _Available since v4.2._
 */
abstract contract ERC20Wrapper is ERC20 {
    IERC20 public immutable underlying;

    address public immutable KDOEStakingAddress;

    constructor(IERC20 underlyingToken, address _KDOEStakingAddress) {
        underlying = underlyingToken;
        KDOEStakingAddress = _KDOEStakingAddress;
    }

    /**
     * @dev Allow a user to deposit underlying tokens and mint the corresponding number of wrapped tokens.
     */
    function depositFor(address account, uint256 amount)
        public
        virtual
        returns (bool)
    {
        SafeERC20.safeTransferFrom(
            underlying,
            _msgSender(),
            address(this),
            amount
        );
        _mint(account, amount);
        return true;
    }

    function depositForStaking(address account, uint256 amount)
        public
        virtual
        returns (bool)
    {
	    require(_msgSender() == KDOEStakingAddress, "Sender is not staking address");
		
        // send kdoe from account to staking contract
        SafeERC20.safeTransferFrom(
            underlying,
            account,
            KDOEStakingAddress,
            amount
        );

        // mint gkdoe to account
        _mint(account, amount);

        return true;
    }

    function withdrawFromStaking(address account, uint256 amount)
        public
        virtual
        returns (bool)
    {
	    require(_msgSender() == KDOEStakingAddress, "Sender is not staking address");
		
        // burn gkDOE from staker
        _burn(account, amount);

        return true;
    }

    /**
     * @dev Allow a user to burn a number of wrapped tokens and withdraw the corresponding number of underlying tokens.
     */
    function withdrawTo(address account, uint256 amount)
        public
        virtual
        returns (bool)
    {
        _burn(_msgSender(), amount);
        SafeERC20.safeTransfer(underlying, account, amount);
        return true;
    }

    /**
     * @dev Mint wrapped token to cover any underlyingTokens that would have been transfered by mistake. Internal
     * function that can be exposed with access control if desired.
     */
    function _recover(address account) internal virtual returns (uint256) {
        uint256 value = underlying.balanceOf(address(this)) - totalSupply();
        _mint(account, value);
        return value;
    }
}