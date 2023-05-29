// SPDX-License-Identifier: MIT
// https://github.com/Brickken/license/blob/main/README.md
pragma solidity ^0.8.0;

import "@openzeppelin/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/openzeppelin-contracts/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @dev Extension of the underlying contract to support wrapping.
 *
 * Anyone can deposit underlying and receive a matching number of "wrapped" tokens.
 * At construction time, underlying tokens are transferred in and wrapped tokens are minted to the contract (so that advisor wallet can exchange them)
 * It has a `releaseTime` set in the constructor which is used to let the advisor wallet to burn their wrapped tokens in exchange
 * for underlying tokens only if `block.timestamp` is greater or equal than the `releaseTime`.
 *
*/
contract WBrickken is ERC20, AccessControlEnumerable {
    IERC20 public immutable underlying;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 private releaseTime_;

    constructor(
        IERC20 _underlyingToken, 
        uint256 _releaseTime, 
        uint256 _advisorsQuantity, 
        address _advisorAddress
    ) ERC20("Wrapped Brickken", "WBKN") {
        require(address(_underlyingToken) != address(0x0), "Underlying token address is zero address");
        require(_releaseTime >= block.timestamp, "Can't set a date in the past");

        underlying = _underlyingToken;
        releaseTime_ = _releaseTime;

        // Assign mintable roles to the msg.sender
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());

        // Mint the same quantity of underlying that will be sent manually to this contract after construction
        _mint(_advisorAddress, _advisorsQuantity);
    }

    /**
     * @dev Allow a user to deposit underlying tokens and mint the corresponding number of wrapped tokens.
     * This function will be called to allocate the wrapped tokens to the parties involved.
     * After `releaseTime`, wrapped token holders can exchange them for underlying tokens deposited in this contract by using `release()`.
    */
    function depositFor(address account, uint256 amount) public virtual onlyRole(MINTER_ROLE) returns (bool) {
        SafeERC20.safeTransferFrom(underlying, _msgSender(), address(this), amount);
        _mint(account, amount);
        return true;
    }

    /**
     * @dev Batch `depositFor` function
    */
    function depositForBatched(address[] calldata accounts, uint256[] calldata amounts) public virtual onlyRole(MINTER_ROLE) returns (bool succeeded) {
        require(accounts.length == amounts.length, "Mismatch between accounts and amounts lenghts");
        require(accounts.length > 0, "Invalid input lenghts");
        for(uint256 i = 0; i<accounts.length; i++) {
            bool result = depositFor(accounts[i], amounts[i]);
            require(result, "Deposit failed for one of the provided accounts");
        }
        succeeded = true;
    }

    /**
     * @return the time when the tokens can be released.
    */
    function releaseTime() public view virtual returns (uint256) {
        return releaseTime_;
    }

    /**
     * @notice Transfers tokens held by the contract to beneficiary after `releaseTime` has passed.
     * It also burns wrapped tokens before sending the BKNs.
     * This function will be called by any wrapped token holder.
    */
    function release(address account, uint256 amount) public virtual returns (bool) {
        require(block.timestamp >= releaseTime(), "Current time is before release time");
        require(amount > 0, "No tokens to release");
        _burn(_msgSender(), amount);
        SafeERC20.safeTransfer(underlying, account, amount);
        return true;
    }

    /**
     * @dev Mint wrapped token to cover any BKN that would have been transfered by mistake.
     * @notice Only the minter can call this function
    */
    function recover(address to) public virtual onlyRole(MINTER_ROLE) {
        _recover(to);
    }

    /**
     * @dev Calculate the difference between the contract's balance in underlying
     * and the total supply of wrapped tokens. If there's any difference which is greater than zero
     * then mint that as wrapped tokens and send it to `account`
    */
    function _recover(address account) internal virtual returns (uint256) {
        uint256 value = underlying.balanceOf(address(this)) - totalSupply();
        _mint(account, value);
        return value;
    }
}