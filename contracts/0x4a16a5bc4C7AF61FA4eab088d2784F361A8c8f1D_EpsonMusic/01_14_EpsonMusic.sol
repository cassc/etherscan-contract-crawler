// SPDX-License-Identifier: MIT
// Initially crafted from: https://wizard.openzeppelin.com/#erc1155
//
// Made with ❤️ in 🎵
//
pragma solidity 0.8.10;

import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol';
import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol';
import '@openzeppelin/contracts/interfaces/IERC2981.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

/**
 * @dev {ERC1155} token, including:
 *
 *  - [holder] burn (destroy) their tokens
 *  - [owner] mint token (creation)
 *  - [owner] set the metadata uri
 *  - [owner] set the royalty fee and receiver
 *
 * This contract uses {Ownable} to lock permissioned functions.
 *
 * The account that deploys the contract will be granted owner.
 *
 */
contract EpsonMusic is ERC1155, ERC1155Burnable, IERC2981, Ownable {
    string private _name;
    string private _symbol;
    uint256 private _royaltyPercentage; // percentage in BPS (basis points), 100 BPS = 1%
    address private _royaltyReceiver;

    /**
     * @dev Emitted when the new URI is set.
     *
     * This custom event does not conform with the EIP-1155 metadata as we do not separate the URI by token ID.
     */
    event SetBaseURI(string indexed baseURI);

    /**
     * @dev Emitted when the new royaltyPercentage is set.
     */
    event SetRoyalty(uint256 royaltyPercentage, address indexed royaltyReceiver);

    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        string memory uri,
        uint256 royaltyPercentageBps,
        address royaltyReceiverAddress
    ) ERC1155(uri) {
        _name = tokenName;
        _symbol = tokenSymbol;

        emit SetBaseURI(uri);

        setRoyalty(royaltyPercentageBps, royaltyReceiverAddress);
    }

    //
    // 🎵🎵🎵 Minting 🎵🎵🎵
    //

    /**
     * @dev Creates `amount` new tokens for `to`, of token type `id`.
     */
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external onlyOwner {
        _mint(to, id, amount, data);
    }

    /**
     * @dev Batched variant of {mint}.
     */
    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external onlyOwner {
        _mintBatch(to, ids, amounts, data);
    }

    //
    // 🎵🎵🎵 METADATA 🎵🎵🎵
    //

    /**
     * @dev Set the new token URI. Emit {SetBaseURI}.
     */
    function setURI(string memory newuri) external onlyOwner {
        _setURI(newuri);
        emit SetBaseURI(newuri);
    }

    /**
     * @dev Return `name` of the token.
     * The main purpose is to be compatible with the OpenSea display standard
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Return `symbol` of the token.
     * The main purpose is to be compatible with the OpenSea display standard
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    //
    // 🎵🎵🎵 ROYALTY (EIP-2981) 🎵🎵🎵
    //

    /**
     * @dev Set new royalty percentage and receiver address. Emit {SetRoyalty}.
     */
    function setRoyalty(uint256 royaltyPercentageBps, address receiver) public onlyOwner {
        _royaltyPercentage = royaltyPercentageBps;
        _royaltyReceiver = receiver;

        emit SetRoyalty(royaltyPercentageBps, receiver);
    }

    /**
     * @dev Return royalty amount and receiver. See EIP-2981.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        public
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        uint256 _royaltyAmount = (salePrice * _royaltyPercentage) / 10000;
        return (_royaltyReceiver, _royaltyAmount);
    }

    /**
     * @dev Return royalty percentage in BPS (basis point). 100 BPS = 1%
     */
    function royaltyPercentage() public view returns (uint256) {
        return _royaltyPercentage;
    }

    /**
     * @dev Return royalty receiver address.
     */
    function royaltyReceiver() public view returns (address) {
        return _royaltyReceiver;
    }

    //
    // 🎵🎵🎵 Support Interfaces (EIP-165) 🎵🎵🎵
    //

    function supportsInterface(bytes4 interfaceId) public view override(ERC1155, IERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }
}