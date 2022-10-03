// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./utils/TransferHelper.sol";
import "./utils/ERC20Recoverable.sol";
import "./utils/ERC721Recoverable.sol";
import "./utils/Recoverable.sol";

/**
 * @dev ERC721 contract features:
 * 1. Single contract ownership with renouce ownership disabled
 * 2. Auto-increment token ID
 * 3. Royalty info
 * 4. Updatable contract name, symbol, and baseURI
 * 5. Minting fee using native token or ERC20 token
 * 6. Contract owner can safeMint without fee
 * 7. Pause publicMint
 * 8. Contract can receive native tokens, ERC20 tokens, and ERC721 tokens
 * 9. Contract owner can recover native tokens, ERC20 tokens, and ERC721 tokens from this contract
 */

contract AlphaGenesisCritters is
    ERC721,
    ERC721Enumerable,
    ERC721Royalty,
    ERC721Holder,
    TransferHelper,
    Ownable,
    ReentrancyGuard,
    ERC20Recoverable,
    ERC721Recoverable,
    Recoverable
{
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    string private _name;
    string private _symbol;
    string private baseURI;

    bool public isMintingPaused;

    uint8 public constant MAX_MINT_PER_BLOCK = 150;

    MintFee public mintFee;

    struct MintFee {
        address receiver;
        address currency;
        uint256 amount;
    }

    modifier canMint(uint8 quantity) {
        require(quantity > 0, "Quantity must be greater than 0");
        require(quantity <= MAX_MINT_PER_BLOCK, "Quantity cannot exceed 150");
        _;
    }

    event Received(address, uint256);

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        address defaultRoyaltyReceiver,
        uint96 defaultRoyaltyFeeNumerator,
        MintFee memory _mintFee
    ) ERC721(name_, symbol_) {
        _name = name_;
        _symbol = symbol_;
        baseURI = baseURI_;
        _setDefaultRoyalty(defaultRoyaltyReceiver, defaultRoyaltyFeeNumerator);
        mintFee = _mintFee;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setName(string memory name_) external onlyOwner {
        _name = name_;
    }

    function setSymbol(string memory symbol_) external onlyOwner {
        _symbol = symbol_;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setRoyaltyInfo(address receiver, uint96 feeNumerator)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function deleteDefaultRoyalty() external onlyOwner {
        _deleteDefaultRoyalty();
    }

    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function resetTokenRoyalty(uint256 tokenId) external onlyOwner {
        _resetTokenRoyalty(tokenId);
    }

    function setMintFee(MintFee memory _mintFee) external onlyOwner {
        mintFee = _mintFee;
    }

    function setIsMintable(bool _isMintingPaused)
        external
        nonReentrant
        onlyOwner
    {
        isMintingPaused = _isMintingPaused;
    }

    function _mintToken(address to) internal {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function safeMint(address to, uint8 quantity)
        external
        nonReentrant
        onlyOwner
        canMint(quantity)
    {
        for (uint8 i = 0; i < quantity; i++) {
            _mintToken(to);
        }
    }

    function publicMint(uint8 quantity)
        external
        payable
        nonReentrant
        canMint(quantity)
    {
        require(isMintingPaused == false, "Minting is paused");

        uint256 fee = mintFee.amount * quantity;

        _transferIn(mintFee.currency, fee);
        _transferOut(mintFee.receiver, mintFee.currency, fee);

        for (uint8 i = 0; i < quantity; i++) {
            _mintToken(_msgSender());
        }
    }

    function recover(uint256 amount) external onlyOwner {
        _recover(amount, _msgSender());
    }

    function recoverERC20(address tokenAddress, uint256 amount)
        external
        onlyOwner
    {
        _recoverERC20(tokenAddress, amount, _msgSender());
    }

    function recoverERC721(address tokenAddress, uint256 tokenId)
        external
        onlyOwner
    {
        _recoverERC721(tokenAddress, tokenId, _msgSender());
    }

    function renounceOwnership() public pure override {
        revert("renounceOwnership disabled");
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721Royalty) {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721Royalty)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}