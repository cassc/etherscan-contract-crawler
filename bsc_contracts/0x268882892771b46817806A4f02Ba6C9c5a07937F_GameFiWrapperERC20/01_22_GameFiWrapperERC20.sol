// SPDX-License-Identifier: BUSL-1.1
// GameFi Core™ by CDEVS

pragma solidity 0.8.10;
// solhint-disable not-rely-on-time

// inheritance
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20WrapperUpgradeable.sol";
import "../basic/GameFiTokenERC20.sol";
import "../../../interface/core/token/custom/IGameFiWrapperERC20.sol";

// libs
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

/**
 * @author Alex Kaufmann
 * @dev ERC20-based token contract for wrapping other erc20 tokens.
 *
 * Works in two modes:
 * 
 * 1) Original token holder wraps the token;
 * 2) An administrator sends original tokens to the contract, and then wrapped tokens are minted.
 * 
 */
contract GameFiWrapperERC20 is GameFiTokenERC20, ERC20WrapperUpgradeable, IGameFiWrapperERC20 {
    using SafeMathUpgradeable for uint256;

    address private _hookContract;

    //
    // General
    //

    function _afterInitialize(
        string memory name_,
        string memory symbol_,
        string memory contractURI_,
        bytes memory data_
    ) internal override(GameFiTokenERC20) {
        name_;
        symbol_;
        contractURI_;

        // decode args
        address underlyingToken = abi.decode(data_, (address));

        __ERC20Wrapper_init(IERC20Upgradeable(underlyingToken));
    }

    /**
     * @dev Withdraw a set amount of source tokens if the wrapper is overcollateralized.
     * function that can be exposed with access control if desired.
     *
     * @param account Where to send withdrawable tokens.
     * @param amount Target withdrawal amount.
     *
     * Requirements:
     *
     * - `from` cannot be the zero account.
     * - `amount` must be more than 0.
     * - `amount` must be more than overcollateralized amount (see leftToMint()).
     */
    function recoverTo(address account, uint256 amount) external onlyOwner {
        require(account != address(0), "GameFiWrapperERC20: zero account address");
        require(amount > 0, "GameFiWrapperERC20: zero amount");
        require(amount <= _leftToMint(), "GameFiWrapperERC20: cap exceeded");

        SafeERC20Upgradeable.safeTransfer(underlying, account, amount);

        emit RecoverTo({
            sender: _msgSender(),
            amount: amount,
            timestamp: block.timestamp
        });
    }

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() external view returns (uint256) {
        return _cap();
    }

    /**
     * @dev Returns amount of overcollateralized tokens.
     */
    function leftToMint() external view returns (uint256) {
        return _leftToMint();
    }

    //
    // Overrides
    //

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - caller must be owner (for GameFiCore only).
     * - consider token collatterazation.
     */
    function mint(
        address to,
        uint256 amount,
        bytes memory data
    ) external override(GameFiTokenERC20, IGameFiTokenERC20) onlyOwner {
        require(amount > 0, "GameFiWrapperERC20: zero amount");
        require(amount <= _leftToMint(), "GameFiWrapperERC20: cap exceeded");
        _mint(to, amount);

        data;
    }

    function decimals()
        public
        view
        virtual
        override(ERC20WrapperUpgradeable, ERC20Upgradeable, IERC20MetadataUpgradeable)
        returns (uint8)
    {
        return super.decimals();
    }

    //
    // Other
    //

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(GameFiTokenERC20) returns (bool) {
        return (interfaceId == type(IGameFiWrapperERC20).interfaceId ||
            interfaceId == type(ERC20WrapperUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId));
    }

    //
    // Internal methods
    //

    function _cap() internal view returns (uint256) {
        return underlying.balanceOf(address(this));
    }

    function _leftToMint() internal view returns (uint256) {
        if (_cap() > totalSupply()) {
            return _cap().sub(totalSupply());
        } else {
            return 0;
        }
    }
}