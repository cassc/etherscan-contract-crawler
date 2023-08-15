// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @notice This contract handles the 1:1 swap of the ABIv1 ERC20 token for the ABIv2 ERC20 token.
 *         The ABIv1 tokens transfered in this contract cannot be transfered out.
 */
contract AbachiRedemption is Ownable {
    using Address for address;
    IERC20 public ABIv1;
    IERC20 public ABIv2;
    bool public paused = false;
    uint256 public constant DECIMALS_DIFF_FACTOR = 10**9;

    event Swap(address _sender, address _recipient, uint256 _amount);

    /**
     * @param _ABIv1 Address of ABIv1 ERC20 contract.
     * @param _ABIv2 Address of ABIv2 ERC20 contract.
     */
    constructor(address _ABIv1, address _ABIv2) {
        require(_ABIv1 != address(0) && _ABIv1.isContract(), "Invalid ABIv1 address");
        require(_ABIv2 != address(0) && _ABIv2.isContract(), "Invalid ABIv2 address");
        ABIv1 = IERC20(_ABIv1);
        ABIv2 = IERC20(_ABIv2);
    }

    /**
     * @notice Pauses swapping, preventing any further calls to swap() from succeeding until
     *         unpause() is called.
     */
    function pause() external onlyOwner {
        require(!paused, "Bridge already already paused");
        paused = true;
    }

    /**
     * @notice Unpauses swapping if it was paused previously.
     */
    function unpause() external onlyOwner {
        require(paused, "Bridge is not paused");
        paused = false;
    }

    /**
     * @notice Swaps all the ABIv1 held by the caller to ABIv2.
     *         Emits Swap event if the swap is successful.
     */
    function swap() external {
        _swapFor(msg.sender, ABIv1.balanceOf(msg.sender));
    }

    /**
     * @notice Deducts some ABIv1 from the caller and transfers the corresponding amount of ABIv2 to the another account.
     * @param _recipient Account that will receive the ABIv2 tokens.
     * @param _amount Amount of ABIv1 tokens to swap.
     */
    function swapFor(address _recipient, uint256 _amount) external {
        _swapFor(_recipient, _amount);
    }

    /**
     * @notice Transfers some ABIv2 from the contract to another account.
     * @param _recipient Account that will receive the ABIv2 tokens.
     * @param _amount Amount of ABIv2 tokens to transfer.
     */
    function withdrawTo(address _recipient, uint256 _amount) external onlyOwner {
        require(ABIv2.transfer(_recipient, _amount), "Failed to transfer ABIv2");
    }

    function _swapFor(address _recipient, uint256 _amount) private {
        require(!paused, "Bridge is paused");
        require(_amount > 0, "Invalid ABIv1 amount");

        require(
            ABIv1.transferFrom(msg.sender, address(this), _amount),
            "Failed to transfer ABIv1"
        );

        uint256 ABIv2Amount = _amount * DECIMALS_DIFF_FACTOR;

        require(ABIv2.transfer(_recipient, ABIv2Amount), "Failed to transfer ABIv2");
        emit Swap(msg.sender, _recipient, ABIv2Amount);
    }
}