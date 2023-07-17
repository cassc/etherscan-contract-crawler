// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract Pills is ERC721A, Ownable, ERC2981, DefaultOperatorFilterer {
    // Address used in withdraw funds after mint. Owner address by default
    address private _withdrawAddress;

    // Address used in royalty payments. Owner address by default
    address private _royaltyWithdrawAddress;

    // Royalty value
    uint96 private _royaltyBPS;

    // Token metadata
    string private _metadata;

    // Price for 1 token in ETH
    uint256 private _tokenPrice;

    // Price for 1 set in ETH
    uint256 private _setPrice;

    // True if sale is active and false if not
    bool private _isSaleActive;

    // Triggered whenever new price for 1 token is set
    event TokenPriceChanged(uint256 newPrice, address caller);

    // Triggered whenever new price for 1 set is set
    event SetPriceChanged(uint256 newPrice, address caller);

    // Triggered whenever sale status is changed
    event SaleStatusChanged(bool status, address caller);

    // Triggered whenever new set is minted
    event SetMinted(uint256 firstTokenID, address owner);

    // Triggered whenever metadata is updated
    event MetadataUpdate(string metadata, address caller);

    constructor(string memory name, string memory symbol, uint96 royalty) ERC721A(name, symbol) {
        _setDefaultRoyalty(msg.sender, royalty);
        _royaltyBPS = royalty;
        _royaltyWithdrawAddress = msg.sender;
        _withdrawAddress = msg.sender;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC2981, ERC721A) returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f || // ERC165 interface ID for ERC721Metadata.
            interfaceId == type(IERC2981).interfaceId; // royalty
    }

    /*
     * Allows to set new token metadata
     *
     * Requirements:
     * - caller should be a contract owner
     *
     * @param metadata - new token metadata
     *
     * @emit `MetadataUpdate` event
     */
    function updateMetadata(string calldata metadata) external onlyOwner {
        _metadata = metadata;

        emit MetadataUpdate(metadata, msg.sender);
    }

    // Allows to set new royalty for contract owner
    function setRoyalty(uint96 newRoyalty) external onlyOwner {
        _royaltyBPS = newRoyalty;
        _setDefaultRoyalty(_royaltyWithdrawAddress, newRoyalty);
    }

    // Allows to set withdraw address
    function setWithdrawAddress(address to) external onlyOwner {
        _withdrawAddress = to;
    }

    // Get withdraw address
    function getWithdrawAddress() external view returns (address) {
        return _withdrawAddress;
    }

    /*
     * Allows to set new withdraw address for default royalty settings
     * Requirements:
     * - caller should be contract owner
     * - new withdraw address should not be zero address
     *
     * @param `withdrawAddress` - new withdraw address
     *
     */
    function setRoyaltyWithdrawAddress(address withdrawAddress) external onlyOwner {
        _royaltyWithdrawAddress = withdrawAddress;
        _setDefaultRoyalty(withdrawAddress, _royaltyBPS);
    }

    /*
     * Allows to mint `amount` of tokens
     *
     * Requirements:
     * - sale should be active
     * - token price should be more than 0
     * - amount should be more than 0
     * - value should be equal to token price mul amount
     *
     * @param amount - amount of tokens to mint
     *
     * @emit `Transfer` ERC721A event see {IERC721A-Transfer}
     */
    function mint(uint256 amount) external payable {
        require(_isSaleActive, "Pills: sale is not active");
        require(_tokenPrice > 0, "Pills: price is not set");
        require(amount > 0, "Pills: amount should be more than 0");
        require(amount * _tokenPrice == msg.value, "Pills: funds not equal to price");

        _mint(msg.sender, amount);

        _withdraw(msg.value);
    }

    /*
     * Allows to mint set of tokens to caller
     *
     * Requirements:
     * - sale should be active
     * - set price should be more than 0
     * - message value should be equal to set price
     *
     * @emil `SetMinted` event
     * @emit `Transfer` ERC721A event see {IERC721A-Transfer}
     */
    function mintSet() external payable {
        require(_isSaleActive, "Pills: sale is not active");
        require(_setPrice > 0, "Pills: price is not set");
        require(_setPrice == msg.value, "Pills: funds not equal to price");

        uint256 firstTokenID = _nextTokenId();

        _mint(msg.sender, 9);

        _withdraw(msg.value);

        emit SetMinted(firstTokenID, msg.sender);
    }

    /*
     * Allows to mint `amount` of tokens `to` given address
     *
     * Requirements:
     * - caller should be a contract owner
     * - amount should be more than 0
     * - to address should not be zero address
     *
     * @param amount - amount of tokens to mint
     * @param to - address where to mint
     *
     * @emit `Transfer` ERC721A event see {IERC721A-Transfer}
     */
    function mintTo(uint256 amount, address to) external onlyOwner {
        require(to != address(0), "Pills: to cannot be zero address");
        require(amount > 0, "Pills: amount should be more than 0");

        _mint(to, amount);
    }

    /*
     * Allows to mint set `to` given address
     *
     * Requirements:
     * - caller should be a contract owner
     * - to address should not be zero address
     *
     * @param to - address where to mint
     *
     * @emil `SetMinted` event
     * @emit `Transfer` ERC721A event see {IERC721A-Transfer}
     */
    function mintSetTo(address to) external onlyOwner {
        require(to != address(0), "Pills: to cannot be zero address");
        uint256 firstTokenID = _nextTokenId();

        _mint(to, 9);

        emit SetMinted(firstTokenID, to);
    }

    /*
     * Allows to change sale status to the opposite
     *
     * Requirements:
     * - caller should be a contract owner
     *
     * @emits `SaleStatusChanged` event
     */
    function flipSaleStatus() external onlyOwner {
        _isSaleActive = !_isSaleActive;

        emit SaleStatusChanged(_isSaleActive, msg.sender);
    }

    /*
     * Allows to get current sale status
     *
     * @return current sale status
     */
    function getSaleStatus() external view returns (bool) {
        return _isSaleActive;
    }

    /*
     * Allows to set new price for 1 token mint in ETH
     *
     * Requirements:
     * - caller should be a contract owner
     * - price should be more than 0
     *
     * @param `price` - new token price
     *
     * @emits `TokenPriceChanged` event
     */
    function setTokenPrice(uint256 price) external onlyOwner {
        require(price > 0, "Pills: price should be more than 0");
        _tokenPrice = price;

        emit TokenPriceChanged(price, msg.sender);
    }

    /*
     * Allows to get price for 1 token mint in ETH
     *
     * @return 1 token price in ETH as uint256
     */
    function getTokenPrice() external view returns (uint256) {
        return _tokenPrice;
    }

    /*
     * Allows to set new price for 1 set mint in ETH
     *
     * Requirements:
     * - caller should be a contract owner
     * - price should be more than 0
     *
     * @param `price` - new set price
     *
     * @emits `SetPriceChanged` event
     */
    function setSetPrice(uint256 price) external onlyOwner {
        require(price > 0, "Pills: price should be more than 0");
        _setPrice = price;

        emit SetPriceChanged(price, msg.sender);
    }

    /*
     * Allows to get price for 1 set mint in ETH
     *
     * @return 1 set price in ETH as uint256
     */
    function getSetPrice() external view returns (uint256) {
        return _setPrice;
    }

    /*
     * See {ERC721A - approve} and {DefaultOperatorFilterer - onlyAllowedOperatorApproval}
     *
     * Additional requirements:
     * - transfer should be allowed
     *
     */
    function approve(address to, uint256 tokenId) public payable override onlyAllowedOperatorApproval(to) {
        ERC721A.approve(to, tokenId);
    }

    /*
     * See {ERC721A - setApprovalForAll} and {DefaultOperatorFilterer - onlyAllowedOperatorApproval}
     *
     * Additional requirements:
     * - transfer should be allowed
     *
     */
    function setApprovalForAll(
        address operator,
        bool approved
    ) public virtual override onlyAllowedOperatorApproval(operator) {
        ERC721A.setApprovalForAll(operator, approved);
    }

    /*
     * See {ERC721A - transferFrom} and {DefaultOperatorFilterer - onlyAllowedOperator}
     *
     * Additional requirements:
     * - transfer should be allowed
     *
     */
    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        ERC721A.transferFrom(from, to, tokenId);
    }

    /*
     * See {ERC721A - safeTransferFrom} and {DefaultOperatorFilterer - onlyAllowedOperator}
     *
     * Additional requirements:
     * - transfer should be allowed
     *
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        ERC721A.safeTransferFrom(from, to, tokenId);
    }

    /*
     * See {ERC721A - safeTransferFrom} and {DefaultOperatorFilterer - onlyAllowedOperator}
     *
     * Additional requirements:
     * - transfer should be allowed
     *
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public payable override onlyAllowedOperator(from) {
        ERC721A.safeTransferFrom(from, to, tokenId, _data);
    }

    /**
     * @dev Returns the starting token ID.
     * See {ERC721A-_startTokenId}
     */
    function _startTokenId() internal view override returns (uint256) {
        return 1;
    }

    // Withdraws given value to _withdraw address
    function _withdraw(uint256 value) internal {
        payable(_withdrawAddress).transfer(value);
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`.
     * See {ERC721A-_baseURI}
     */
    function _baseURI() internal view override returns (string memory) {
        return _metadata;
    }
}