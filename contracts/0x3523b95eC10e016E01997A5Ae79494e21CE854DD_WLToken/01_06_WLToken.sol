// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


/// @notice this is a specific token that is used to airdrop to a whitelist group of ppl
/// this token can be burned or minted to users, but it cannot be transferred
contract WLToken is ERC20, Ownable {
    uint256 private constant one = 1 * (10 ** 18);
    constructor(string memory tokenName, string memory tokenSymbol) ERC20(tokenName, tokenSymbol) {}

    /// @notice function to airdrop tokens to the whitelisted individuals, only sends 1 token each, as that's all they need
    /// @dev runs through the array of the whitelist and calls the internal mint function sending each one 1 token
    function list(address[] memory whiteList) external onlyOwner {
        for (uint256 i; i < whiteList.length; i++) {
            _mint(whiteList[i], one);
        }
    }

    /// @notice this function just burns the tokens of each user the owner wants to delist
    function deList(address[] memory blackList) external onlyOwner {
        for (uint256 i; i < blackList.length; i++) {
            _burn(blackList[i], one);
        }
    }

    /// @notice override the internal _transfer function so that tokens cannot be transferred
    function _transfer(address from, address to, uint256 amount) internal virtual override {
        revert('this cannot be transferred');
    }
}