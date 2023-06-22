// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @notice This contracts handles swapping the old LOOM ERC20 token for the new LOOM ERC20 token.
 *         The old tokens will accumulate in this contract, there's no way to transfer them back out.
 */
contract TokenSwap is Ownable {
    using SafeMath for uint256;
    using Address for address;

    IERC20 public oldToken;
    IERC20 public newToken;
    bool public paused = true; // paused by default because newToken must be set first

    /**
     * @param _oldToken Address of old LOOM ERC20 contract.
     */
    constructor(address _oldToken) {
        require(
            _oldToken != address(0) && _oldToken.isContract(),
            "LoomToken: invalid old LOOM address"
        );

        oldToken = IERC20(_oldToken);
    }

    /**
     * @param _newToken Address of new LOOM ERC20 contract.
     */
    function setNewLoomToken(address _newToken) external onlyOwner {
        require(address(newToken) == address(0), "TokenSwap: new token already set");
        require(
            _newToken != address(0) && _newToken.isContract(),
            "TokenSwap: invalid contract address"
        );

        newToken = IERC20(_newToken);
        paused = false;
    }

    /**
     * @notice Pauses swapping, preventing any further calls to swap() from succeeding until
     *         unpause() is called.
     */
    function pause() external onlyOwner {
        require(!paused, "TokenSwap: already paused");
        paused = true;
    }

    /**
     * @notice Unpauses swapping if it was paused previously.
     */
    function unpause() external onlyOwner {
        require(paused, "TokenSwap: not paused");
        paused = false;
    }

    /**
     * @notice Swaps all the old LOOM held by the caller to new LOOM.
     *         Emits Swap event if the swap is successful.
     */
    function swap() external {
        _swapFor(msg.sender, oldToken.balanceOf(msg.sender));
    }

    /**
     * @notice Deducts some old LOOM from the caller and transfers the corresponding amount of new
     *         LOOM to the another account.
     * @param _recipient Account that will receive the new LOOM tokens.
     * @param _amount Amount of old LOOM tokens to swap.
     */
    function swapFor(address _recipient, uint256 _amount) external {
        _swapFor(_recipient, _amount);
    }

    /**
     * @notice Transfers some new LOOM from the contract to another account.
     * @param _recipient Account that will receive the new LOOM tokens.
     * @param _amount Amount of new LOOM tokens to transfer.
     */
    function withdrawTo(address _recipient, uint256 _amount) external onlyOwner {
        require(newToken.transfer(_recipient, _amount), "TokenSwap: failed to transfer new LOOM");
    }

    function _swapFor(address _recipient, uint256 _amount) private {
        require(!paused, "TokenSwap: paused");
        require(_amount > 0, "TokenSwap: invalid old LOOM amount");

        require(
            oldToken.transferFrom(msg.sender, address(this), _amount),
            "TokenSwap: failed to transfer old LOOM"
        );

        require(newToken.transfer(_recipient, _amount), "TokenSwap: failed to transfer new LOOM");
    }
}