// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IERC721SalesItem {
    function sellerMint(address to, uint256 quantity) external;
    function supportsInterface(bytes4) external view returns (bool);
}

contract SalesIntermediary is IERC721SalesItem, Ownable {
    ///////////////////////////////////////////////////////////////////////////
    // Constant Variables
    ///////////////////////////////////////////////////////////////////////////
    /// @dev NFT Holder's address.
    address public immutable ADDRESS_HOLDER;
    /// @dev Target NFT
    IERC721 public immutable SALES_TARGET;
    /// @dev Start token Id
    uint256 public immutable START_ID;
    /// @dev End token Id
    uint256 public immutable END_ID;

    ///////////////////////////////////////////////////////////////////////////
    // Variables
    ///////////////////////////////////////////////////////////////////////////
    /// @dev Sales status.
    bool public onSale;
    /// @dev Index at sale.
    uint64 public nextTokenId;
    /// @dev Sales contract.
    address public seller;

    ///////////////////////////////////////////////////////////////////////////
    // Custom Errors
    ///////////////////////////////////////////////////////////////////////////

    /// @dev A specified parmeter is Zero Address.
    error ZeroAddress();
    /// @dev Invalid parameters.
    error InvalidParameters();
    /// @dev Not allowed seller.
    error NotAllowedSeller();
    /// @dev Not allowed seller.
    error MintExceedingSupply();
    /// @dev The sale is not open.
    error NotOnSale();

    constructor(address target, uint256 startId, uint256 endId, address holder) {
        if (target == address(0)) revert ZeroAddress();
        if (startId > endId) revert InvalidParameters();
        if (holder == address(0)) revert ZeroAddress();
        if (!IERC721(target).supportsInterface(0x80ac58cd)) revert InvalidParameters();
        ADDRESS_HOLDER = holder;
        SALES_TARGET = IERC721(target);
        START_ID = startId;
        END_ID = endId;
        nextTokenId = uint64(startId);
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        // Response true for interface of ERC721
        if (interfaceId == 0x80ac58cd) return true;
        return false;
    }

    function sellerMint(address to, uint256 quantity) external {
        // Check sale is open.
        if (!onSale) revert NotOnSale();
        // Check caller is valid seller.
        if (msg.sender != seller) revert NotAllowedSeller();

        // Grab on stack.
        uint256 currentTokenId = uint256(nextTokenId);

        // Check max id.
        if (currentTokenId + quantity > END_ID + 1) revert MintExceedingSupply();

        // Transfer from holder to destination address.
        uint256 boundary = currentTokenId + quantity;
        while (currentTokenId < boundary) {
            SALES_TARGET.safeTransferFrom(ADDRESS_HOLDER, to, currentTokenId);
            unchecked {
                ++currentTokenId;
            }
        }

        // Update next Id on storage.
        nextTokenId = uint64(currentTokenId);
    }

    function setOnSale(bool value) external onlyOwner {
        onSale = value;
    }

    function setSeller(address newSeller) external onlyOwner {
        seller = newSeller;
    }

}