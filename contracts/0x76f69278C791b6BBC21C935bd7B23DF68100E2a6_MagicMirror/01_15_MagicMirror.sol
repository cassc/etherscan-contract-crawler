// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract MagicMirror is IERC1155Receiver, ERC721, ERC2981, Ownable {
    using Address for address;
    using Strings for uint256;

    IERC721 public token;

    uint256 public price;
    string public baseURI;
    address public keyTokenAddress;
    uint256 public keyTokenId;

    address private _relay;

    constructor(
        string memory _name,
        string memory _symbol,
        IERC721 _token
    ) ERC721(_name, _symbol) {
        token = _token;
    }

    /**
     * *** EXTERNAL ***
     *
     * @notice Mint `tokenIds`
     *
     * @param tokenIds | the token ids to mint
     *
     * Requirements:
     *
     * - must own EightBit token with `tokenId`
     */
    function mint(uint256[] memory tokenIds) external payable {
        require(msg.value == price * tokenIds.length, "MagicMirror#mint: INCORRECT_ETH_VALUE");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (!_exists(tokenIds[i])) {
                _mint(tokenIds[i], msg.sender);
            } else {
                require(ownerOf(tokenIds[i]) == msg.sender, "MagicMirror#mint: MUST_BE_OWNER");
                emit PaymentReceived(msg.sender, tokenIds[i]);
            }
        }
    }

    /**
     * *** PUBLIC ***
     *
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "MagicMirror#tokenURI: TOKEN_DOES_NOT_EXIST");
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    /**
     * *** ONLY OWNER ***
     *
     * @notice set the base token uri
     *
     * @param _baseURI | the new base URI
     */
    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;

        emit SetBaseURI({ baseURI: baseURI });
    }

    /**
     * *** ONLY OWNER ***
     *
     * @notice set/update the token price
     *
     * @param _price | the new price
     */
    function setPrice(uint256 _price) external onlyOwner {
        price = _price;

        emit SetPrice({ price: price });
    }

    /**
     * *** ONLY OWNER ***
     *
     * @notice set/update the key token address
     *
     * @param _keyTokenAddress | the new loot address
     */
    function setLootAddress(address _keyTokenAddress) external onlyOwner {
        keyTokenAddress = _keyTokenAddress;

        emit SetKeyTokenAddress({ keyTokenAddress: keyTokenAddress });
    }

    /**
     * *** ONLY OWNER ***
     *
     * @notice set/update the key token id
     *
     * @param _keyTokenId | the new loot token id
     */
    function setKeyTokenId(uint256 _keyTokenId) external onlyOwner {
        keyTokenId = _keyTokenId;

        emit SetKeyTokenId({ keyTokenId: keyTokenId });
    }

    /**
     * *** ONLY OWNER ***
     *
     * @notice withdraw ether
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(msg.sender), balance);

        emit WithdrawBalance({ balance: balance });
    }

    /**
     * *** ONLY OWNER ***
     *
     * @notice set / update balance
     */
    function transfer(
        address from,
        address to,
        uint256 tokenId
    ) external {
        require(msg.sender == _relay, "MagicMirror#transfer: ONLY_RELAY");
        _transfer(from, to, tokenId);
    }

    /**
     * *** ONLY OWNER ***
     *
     * @notice set / update balance
     */
    function setRelay(address relay) external onlyOwner {
        _relay = relay;

        emit SetRelay(_relay);
    }

    /**
     * *** INTERNAL ***
     *
     * @notice Mint relection `tokenId`
     *
     * @param tokenId | the token id to mint
     *
     * Requirements:
     *
     * - must own EightBit token with `tokenId`
     */
    function _mint(uint256 tokenId, address operator) internal {
        require(token.ownerOf(tokenId) == operator, "MagicMirror#mint: MUST_OWN_BOUND_TOKEN");
        _mint(operator, tokenId);

        emit PaymentReceived(operator, tokenId);
    }

    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override returns (bytes4) {
        require(msg.sender == keyTokenAddress, "MagicMirror#onERC1155Received: ONLY_LOOT");
        require(id == keyTokenId, "MagicMirror#onERC1155Received: INVALID_TOKEN_ID");
        require(value == 1, "MagicMirror#onERC1155Received: BATCH_NOT_SUPPORTED");

        uint256 tokenId = uint256(bytes32(data));

        if (!_exists(tokenId)) {
            _mint(tokenId, operator);
        } else {
            emit PaymentReceived(operator, tokenId);
        }

        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) public virtual override returns (bytes4) {
        revert("MagicMirror#onERC1155BatchReceived: BATCH_NOT_SUPPORTED");
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address,
        address,
        uint256
    ) public virtual override {
        revert("MagicMirror#transferFrom: NON_TRANSFERABLE");
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address, uint256) public virtual override {
        revert("MagicMirror#approve: NON_TRANSFERABLE");
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address, bool) public virtual override {
        revert("MagicMirror#setApprovalForAll: NON_TRANSFERABLE");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address,
        address,
        uint256
    ) public virtual override {
        revert("MagicMirror#safeTransferFrom: NON_TRANSFERABLE");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override {
        revert("MagicMirror#safeTransferFrom: NON_TRANSFERABLE");
    }

    /**
     * @dev See {IERC165-supportsInterface}
     * @param interfaceId | the interface id to query support for
     */
    function supportsInterface(bytes4 interfaceId) public view override(IERC165, ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    event PaymentReceived(address operator, uint256 tokenId);
    event SetBaseURI(string baseURI);
    event SetKeyTokenAddress(address keyTokenAddress);
    event SetKeyTokenId(uint256 keyTokenId);
    event SetPrice(uint256 price);
    event SetRelay(address relay);
    event WithdrawBalance(uint256 balance);
}