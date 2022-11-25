// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/// @dev open source tokenity vendor contract
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @dev security
import "./security/ReEntrancyGuard.sol";
import "./security/Administered.sol";

/// @dev helpers
import "./Interfaces/IPropertyToken.sol";

contract Gift is Administered, ReEntrancyGuard {
    /// @dev set Address
    address tokenAddress = address(0);

    constructor(address _addr) {
        tokenAddress = _addr;
    }

    /// @dev mint gift tokens
    function mintGifts(
        uint256 _quantity
    ) external payable noReentrant returns (bool) {
        /// @dev Transfer token to the sender
        IPropertyToken(tokenAddress).mintReserved(_msgSender(), _quantity);
        return true;
    }

    /// @dev set token address
    function setTokenAddrresNft(address _tokenAddress) external onlyAdmin {
        tokenAddress = _tokenAddress;
    }

    /// @dev Allow the owner of the contract to withdraw MATIC Owner
    function withdrawOwner(
        uint256 amount,
        address to
    ) external payable onlyAdmin returns (bool) {
        require(
            payable(to).send(amount),
            "withdrawOwner: Failed to transfer token to fee contract"
        );
        return true;
    }
}