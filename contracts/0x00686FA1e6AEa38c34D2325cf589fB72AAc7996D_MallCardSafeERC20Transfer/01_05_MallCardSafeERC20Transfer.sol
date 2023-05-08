// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Contract to use as transfer helper for ERC20 tokens which doesn't return
/// bool value at the end of transfer and tranferFrom function.
/// @notice Adds "return true" statement at the end of tranferFrom function to help
/// mint function of NFT contract to meet requirements
contract MallCardSafeERC20Transfer {
    using SafeERC20 for IERC20;

    address public usdtAddress = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public mallCardNFTContract = 0xc32c6c6761935f22374295e520beea6e0BEac75a;

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(msg.sender == mallCardNFTContract, 'MallCard: Caller is not MallCard NFT contract');
        IERC20 token = IERC20(usdtAddress);
        token.safeTransferFrom(from, to, amount);
        return true;
    }
}