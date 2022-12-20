//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

interface IERC721 {
    function ownerOf(uint256 _tokenId) external view returns (address);

    function burn(uint256 tokenId) external;
}

interface IERC1155 {
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        bytes memory data
    ) external;
}

contract IT02RedemptionModule is AccessControl, ERC1155Holder {
    address public passport;
    address public redemption4kAddress;

    //events
    event Redeemed(uint256[] ids, address redeemer);
    event Withdraw(uint256[] ids, address recipient);

    constructor(address _passport, address _redemptionAddress) {
        passport = _passport;
        redemption4kAddress = _redemptionAddress;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @notice Redeem 4k token(s) to caller
    /// @dev this contract must be an approved operator of the respective ERC721 id's in order to burn successfully
    /// @param pomIds Proof-Of-Mint token ids to redeem. Caller must own tokens
    function redeem(uint256[] memory pomIds) external {
        uint256[] memory amounts = new uint256[](pomIds.length);

        for (uint256 i = 0; i < pomIds.length; i++) {
            require(msg.sender == IERC721(passport).ownerOf(pomIds[i]), "not token owner");
            amounts[i] = 1; // will always be 1:1 redemption
            IERC721(passport).burn(pomIds[i]);
        }

        IERC1155(redemption4kAddress).safeBatchTransferFrom(address(this), msg.sender, pomIds, amounts, "");
        emit Redeemed(pomIds, msg.sender);
    }

    /// @notice Withdraw 1155 Tokens (4kRedemptionTokens) to sender; must be contract admin
    /// @param tokenIds 1155 tokenIds to withdraw
    function withdraw1155(uint256[] memory tokenIds) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256[] memory amounts = new uint256[](tokenIds.length);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            amounts[i] = 1;
        }

        IERC1155(redemption4kAddress).safeBatchTransferFrom(address(this), msg.sender, tokenIds, amounts, "");
        emit Withdraw(tokenIds, msg.sender);
    }

    function supportsInterface(bytes4 interfaceId) public pure override(ERC1155Receiver, AccessControl) returns (bool) {
        return interfaceId == type(ERC1155Receiver).interfaceId;
    }
}