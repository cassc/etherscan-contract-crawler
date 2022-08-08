// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

contract Platform {
    /// Hyperstructure fee recipient
    address public platformFeeRecipient;
    /// Hyperstructure fee (wei)
    uint256 public platformFee;

    /**
     * @dev Receiving native token (MATIC / ETH).
     */
    receive() external payable {}

    /**
     * @dev Receiving other ERC20 tokens.
     */
    fallback() external payable {}

    /// @notice adds platform fee to any function
    modifier hasPlatformFee() {
        require(
            msg.value >= platformFee,
            "Insufficient funds. See platformFee"
        );
        _;
    }

    /**
     * @dev Withdrawing native token balance.
     */
    function withdraw() external {
        (bool sent, bytes memory data) = payable(platformFeeRecipient).call{
            value: address(this).balance
        }("");
    }

    /**
     * @dev Withdrawing ERC20 token balance.
     * @param _tokenContract ERC20 contract address.
     */
    function withdrawToken(address _tokenContract) external {
        IERC20 tokenContract = IERC20(_tokenContract);

        tokenContract.transfer(
            platformFeeRecipient,
            tokenContract.balanceOf(address(this))
        );
    }
}