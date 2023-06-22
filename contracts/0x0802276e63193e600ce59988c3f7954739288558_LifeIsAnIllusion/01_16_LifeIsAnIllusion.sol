// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./@openzeppelin/contracts/utils/ContextMixin.sol";

//    _                                    _  _
//  _//    /)                             // //
//  /   o // _    o _     __.  ____    o // // . . _   o __ ____
// /___<_//_</_  <_/_)_  (_/|_/ / <_  <_</_</_(_/_/_)_<_(_)/ / <_
//      />
//     </

/// @custom:security-contact @bgdshka
contract LifeIsAnIllusion is ERC1155, IERC2981, Ownable, ContextMixin {
    using Strings for uint256;
    string public name;
    string public symbol;
    uint256 public _totalSupply;
    address private _recipient;
    mapping(uint256 => Data) public pieces;

    struct Data {
        bool available;
        string description;
        string image;
        string base64Image;
    }

    constructor() ERC1155("") {
        name = "Life is an illusion";
        symbol = "ILLUSION";
        _totalSupply = 42;
        _recipient = owner();
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data,
        string memory image,
        string memory description,
        string memory base64Image
    ) public onlyOwner {
        require(!pieces[id].available, "ERC1155Mint: piece already minted");
        require(
            id >= 1 && id <= _totalSupply,
            "ERC1155Mint: URI query for nonexistent token"
        );
        pieces[id].image = image;
        pieces[id].description = description;
        pieces[id].base64Image = base64Image;
        _mint(account, id, amount, data);
        pieces[id].available = true;
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data,
        string[] memory image,
        string[] memory description,
        string[] memory base64Image
    ) public onlyOwner {
        require(ids.length > 0, "ERC1155BatchMint: need to provide ids");
        for (uint i = 1; i <= ids.length; i++) {
            require(
                !pieces[ids[i - 1]].available,
                "ERC1155Mint: piece already minted"
            );
            require(
                ids[i - 1] >= 1 && ids[i - 1] <= _totalSupply,
                "ERC1155Mint: URI query for nonexistent token"
            );
            pieces[ids[i - 1]].image = image[i - 1];
            pieces[ids[i - 1]].description = description[i - 1];
            pieces[ids[i - 1]].base64Image = base64Image[i - 1];
            pieces[ids[i - 1]].available = true;
        }
        _mintBatch(to, ids, amounts, data);
    }

    /** @dev URI override for OpenSea traits compatibility. */
    function uri(uint256 tokenId) public view override returns (string memory) {
        // Tokens minted above the supply cap will not have associated metadata.
        require(
            tokenId >= 1 && tokenId <= _totalSupply,
            "ERC1155Metadata: URI query for nonexistent token"
        );
        bytes memory dataURI = abi.encodePacked(
            "{",
            '"name": "illusion %',
            (abi.encodePacked(Strings.toString(tokenId))),
            '",',
            '"description": "',
            (abi.encodePacked(pieces[tokenId].description)),
            '",',
            '"image": "',
            (abi.encodePacked(pieces[tokenId].image)),
            '",',
            '"base64Image": "',
            (abi.encodePacked(pieces[tokenId].base64Image)),
            '",',
            '"license": "CC BY-NC 4.0"',
            "}"
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(dataURI)
                )
            );
    }

    /** @dev EIP2981 royalties implementation. */

    // Maintain flexibility to modify royalties recipient (could also add basis points).
    function _setRoyalties(address newRecipient) internal {
        require(
            newRecipient != address(0),
            "Royalties: new recipient is the zero address"
        );
        _recipient = newRecipient;
    }

    function setRoyalties(address newRecipient) external onlyOwner {
        _setRoyalties(newRecipient);
    }

    // EIP2981 standard royalties return.
    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view override returns (address receiver, uint256 royaltyAmount) {
        return (_recipient, (_salePrice * 500) / 10000);
    }

    // EIP2981 standard Interface return. Adds to ERC1155 and ERC165 Interface returns.
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC1155, IERC165) returns (bool) {
        return (interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId));
    }

    /** @dev Meta-transactions override for OpenSea. */

    function _msgSender() internal view override returns (address) {
        return ContextMixin.msgSender();
    }

    /** @dev Contract-level metadata for OpenSea. */

    // Update for collection-specific metadata.
    function contractURI() public pure returns (string memory) {
        bytes memory dataURI = abi.encodePacked(
            "{",
            '"name": "Life is an illusion",',
            '"symbol": "ILLUSION",',
            '"description": "Life is an illusion: this is a unique collection of 42 impressionist photos from different parts of the world dedicated to Anna`s father. Each work contains 42 copies. \nMetadata and compressed images stored on-chain, original photos stored on IPFS. \n\nLife is an illusion \nA strange game of half-slumber \nIt seems to me that \nEverything is about to collapse \nI love you \nThe sun",',
            '"image": "ipfs://bafybeih7hoid5vbphjaclajybi2czwl5xtnj7lpgwgsyaodgxkssqh3bo4/15.jpg",',
            '"artist": "Ateev Kirill, Anne Leonovich",',
            '"seller_fee_basis_points": 500,',
            '"fee_recipient": "0x2DbF1B40f0593e338E56A2C2E6bEaDE46Ac83E8B"',
            "}"
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(dataURI)
                )
            ); // Contract-level metadata
    }
}