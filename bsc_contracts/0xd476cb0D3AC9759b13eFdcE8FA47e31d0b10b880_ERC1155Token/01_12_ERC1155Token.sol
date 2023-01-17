// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {IERC165, IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";

/// @title Mock ERC1155 Token
/// @author Trader Joe
contract ERC1155Token is
    ERC1155(
        "https://ikzttp.mypinata.cloud/ipfs/QmQFkLSQysj94s5GvTHPyzTxrawwtjgiiYS2TBLgrvw8CW/2174"
    ),
    Ownable,
    IERC2981
{
    // https://eips.ethereum.org/EIPS/eip-2981
    bytes4 public constant INTERFACE_ID_ERC2981 = 0x2a55205a;

    /// @dev Mint `_amount` NFT with `_tokenId` to `_to`
    /// @param _to The address that will receive the mint
    /// @param _tokenId The tokenId to mint
    /// @param _amount The number of tokens to mint
    /// @return the `tokenId` of the minted NFT
    function mint(
        address _to,
        uint256 _tokenId,
        uint256 _amount
    ) external returns (uint256) {
        _mint(_to, _tokenId, _amount, "");

        return _tokenId;
    }

    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be payed in that same unit of exchange.
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = owner();
        royaltyAmount = _salePrice / 100;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(IERC165, ERC1155)
        returns (bool)
    {
        return
            interfaceId == INTERFACE_ID_ERC2981 ||
            super.supportsInterface(interfaceId);
    }
}