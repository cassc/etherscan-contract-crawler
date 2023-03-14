// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract RecentHistory is ERC721A, Ownable, ERC2981, DefaultOperatorFilterer {

    // permanent royalty BPS value for collection
    uint96 constant royaltyBPS = 10_00;

    // Address for withdraw ETH from mint. By default - contract owner
    address private _withdrawAddress;

    // Limit emission amount
    uint256 private immutable _limitEmission;

    // Limit emission for private sale per one mint
    uint256 private immutable _privateSaleLimit;

    // Limit emission for private sale only. By default equals `_limitEmission`
    uint256 private _privateSaleLimitEmission;

    // Private sale current status. True if active, false if not
    bool private _isPrivateSaleActive;

    // Public sale current status. True if active false if not
    bool private _isPublicSaleActive;

    // Current status of the collection. True if freeze, false if not
    bool private _isCollectionFreeze;

    // Token price in ETH
    uint256 private _tokenPrice;

    // Token metadata
    string private _tokenUri;

    // Triggered when private sale status changed
    event PrivateSaleStatusChanged(bool active);

    // Triggered when public sate status changed
    event PublicSaleStatusChanged(bool active);

    // Triggered when collection is freeze
    event CollectionFreeze(bool freeze);

    // Triggered when new price is set
    event SetPrice(uint256 price);

    // Triggered when metadata was updated
    event MetadataUpdate(string metadata);

    constructor(string memory name_, string memory symbol_, uint256 limitEmission_, uint256 privateSaleLimit_)
    ERC721A(name_, symbol_)
    {
        _limitEmission = limitEmission_;
        _privateSaleLimit = privateSaleLimit_;
        _privateSaleLimitEmission = limitEmission_;
        _withdrawAddress = msg.sender;

        _setDefaultRoyalty(msg.sender, royaltyBPS);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC2981, ERC721A) returns (bool) {
        return
        interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
        interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
        interfaceId == 0x5b5e139f || // ERC165 interface ID for ERC721Metadata.
        interfaceId == type(IERC2981).interfaceId; // royalty

    }

    //////////////////////////////// SET AND GET CONTRACT PARAMETERS ////////////////////////////////
    /*
     * Limit emission
     * Private sale limit emission
     * Private sale limit
     * Metadata
     * Withdraw address
     * Price
     */

    // Returns current limit emission number
    function getLimitEmission() external view returns(uint256) {
        return _limitEmission;
    }

    // Returns current private sale limit number
    function getPrivateSaleLimit() external view returns(uint256) {
        return _privateSaleLimit;
    }

    /*
     * Allows to add new metadata
     *
     * Requirements:
     * - caller should be a contract owner
     * - collection should not be freeze
     *
     * @param `metadata` - new metadata
     *
     * Emits `MetadataUpdate` event
     */
    function updateMetadata(string memory metadata) external onlyOwner {
        require(!_isCollectionFreeze, "Recent History: collection is freeze");

        _tokenUri = metadata;

        emit MetadataUpdate(_tokenUri);
    }

    // Returns current metadata
    function getMetadata() external view returns(string memory) {
        return _tokenUri;
    }

    /*
     * Allows to set new withdraw address
     *
     * Requirements:
     * - caller should be a contract owner
     * - address should not be zero address
     *
     * @param `newAddress` - new withdraw address
     *
     */
    function setWithdrawAddress(address newAddress) external onlyOwner {
        require(newAddress != address(0), "Recent History: new address can not be zero address");

        _withdrawAddress = newAddress;
		_setDefaultRoyalty(newAddress, royaltyBPS);
    }

    // Allows to get withdraw address only for contract owner
    function getWithdrawAddress() external view onlyOwner returns(address) {
        return _withdrawAddress;
    }

    /*
     * Allows to set new token price in ETH
     *
     * Requirements:
     * - caller should be a contract owner
     * - public sale should be inactive
     * - private sale should be inactive
     * - collection should not be freeze
     * - new price can not be 0
     *
     * @param `price` - new price for one token in ETH
     *
     * Emits `SetPrice` event
     */
    function setPrice(uint256 price) external onlyOwner {
        require(!_isCollectionFreeze, "Recent History: collection is freeze");
        require(!_isPrivateSaleActive, "Recent History: private sale is active");
        require(!_isPublicSaleActive, "Recent History: public sale is active");
        require(price != 0, "Recent History: price can not be 0");

        _tokenPrice = price;

        emit SetPrice(_tokenPrice);
    }

    // Returns current token price in ETH
    function getPrice() external view returns(uint256) {
        return _tokenPrice;
    }

    /*
     * Allows to set private sale limit emission
     *
     * Requirements:
     * - caller should be a contract owner
     * - limit can not be 0
     * - limit should be more than total supply
     *
     * @param `limit` - new private sale limit
     *
     */
    function setPrivateSaleLimitEmission(uint256 limit) external onlyOwner {
        require(limit != 0, "Recent History: limit can not be 0");
        require(limit > totalSupply(), "Recent History: limit should be more than total supply");

        _privateSaleLimitEmission = limit;
    }

    // Returns actual private sale limit emission
    function getPrivateSaleLimitEmission() external view returns(uint256) {
        return _privateSaleLimitEmission;
    }

    // Returns token metadata
    function _baseURI() internal view override returns (string memory) {
        return _tokenUri;
    }

    /////////////////////////////////////// MINT LOGIC ///////////////////////////////////////
    /*
     * Mint payable
     * Mint presale payable, signed
     * Mint to, only contract owner
     */

    /*
     * Allows to mint `amount` of NFTs to caller during public sale
     *
     * Requirements:
     * - collection should not be freeze
     * - token price should be more than 0
     * - public sale should be active
     * - message value should be equal to token price * amount
     *
     * Emits `Transfer` event see {IERC721A}
     * Withdraws message value to owner
     */
    function mint(uint256 amount) external payable {
		require(!_isCollectionFreeze, "Recent History: collection is freeze");
        require(!_isLimitReached(amount), "Recent History: limit emission reached");
        require(_tokenPrice > 0, "Recent History: token price is not set");
        require(_isPublicSaleActive, "Recent History: public sale is not active");
        require(msg.value == _tokenPrice * amount, "Recent History: invalid funds amount");
        require(amount > 0, "Recent History: amount should be more than 0");

        _mint(msg.sender, amount);
        _withdraw(msg.value);
    }

    /*
     * Allows to mint `amount` of new NFT to caller while private sale, if caller
     * is in allow list. Can only be used with signature from contract owner. See {Recent History - _checkSignature}
     * and valid params. Params are validating by comparing message hash
     * and hash from params - caller address and amount. See {Recent History - _checkMessage}
     *
     * Requirements:
     * - should have valid signature from contract owner
     * - should have valid params and message
     * - collection should not be freeze
     * - private sale should be active
     * - amount should be more than 0
     * - message value should be equal to token price * amount
     *
     * @param `amount` - amount of tokens to mint
     * @param `hash` - message hash to prove signature
     * @param `signature` - signature hash to prove
     *
     * Emits `Transfer` event see {IERC721A}
     * Transfers message value to contract owner
     */
    function mintPresale(uint256 amount, bytes32 message, bytes calldata signature) external payable {
        require(!_isCollectionFreeze, "Recent History: collection is freeze");
		require(amount <= _privateSaleLimit, "Recent History: invalid tokens amount, set less tokens");
        require(!_isLimitReached(amount) && !_isPrivateSaleLimitReached(amount), "Recent History: limit emission reached");
        require(amount > 0, "Recent History: amount should be more than 0");
        require(_checkSignature(message, signature), "Recent History: invalid signature");
        require(_checkMessage(message, address(msg.sender), amount), "Recent History: invalid message");
        require(_isPrivateSaleActive, "Recent History: private sale is not active");
        require(msg.value == _tokenPrice * amount, "Recent History: invalid funds amount");

        _mint(msg.sender, amount);
        _withdraw(msg.value);
    }

    /*
     * Allows to mint `amount` of new NFT `_to` given address
     *
     * Requirements:
     * - caller should be a contract owner
     * - collection should not be freeze
     * - given address should not be zero address
     * - amount should be more than 0
     *
     * @param `_to` - address to whom token will be minted
     * @param `amount` - amount of tokens to mint
     *
     * Emits `Transfer` event see {IERC721A}
     */
    function mintTo(address _to, uint256 amount) external onlyOwner {
		require(!_isCollectionFreeze, "Recent History: collection is freeze");
        require(!_isLimitReached(amount), "Recent History: limit emission reached");
        require(_to != address(0), "Recent History: can not mint to zero address");
        require(amount > 0, "Recent History: amount should be more than 0");

        _mint(_to, amount);
    }

    // Transfers given `value` to `_withdrawAddress`
    function _withdraw(uint256 value) internal {
        payable(_withdrawAddress).transfer(value);
    }

    /**
     * See {ECDSA - recover}
     * @return signer address
     */
    function _recoverSigner(bytes32 message, bytes calldata signature) internal pure returns (address) {
        bytes32 messageDigest = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                message
            )
        );
        return ECDSA.recover(messageDigest, signature);
    }

    /**
     * See {RecentHistory - _recoverSigner}
     * Compares signer address and owner address. Returns true if signer is owner and false if not
     */
    function _checkSignature(bytes32 message, bytes calldata signature) internal view returns (bool) {
        return _recoverSigner(message, signature) == owner();
    }

    /**
     * Compares message hash from caller and hash from params - caller address and amount to mint.
     * If hash is not equal returns false, if it is equal (which means valid) - returns true
     */
    function _checkMessage(bytes32 message, address caller, uint256 amount) internal pure returns(bool) {
        return message == keccak256(abi.encodePacked(caller, amount));
    }

    /**
     * See {ERC721A - _startTokenId}
     */
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    // Checks if limit emission will be reached after minting given `amount`. Returns true if it is and false if not
    function _isLimitReached(uint256 amountToMint) internal view returns(bool) {
        return amountToMint + totalSupply() > _limitEmission;
    }

    // Checks if private sale limit emission will be reached after minting given `amount`. Returns true if it is and false if not
    function _isPrivateSaleLimitReached(uint256 amountToMint) internal view returns(bool) {
        return amountToMint + totalSupply() > _privateSaleLimitEmission;
    }

    //////////////////////////////////// CONTRACT STATUS MANAGEMENT ////////////////////////////////////
    /*
     * Private sale
     * Public sale
     * Freeze collection
     */

    /*
     * Allows to change status of the private sale
     *
     * Requirements:
     * - caller should be a contract owner
     * - public sale should be inactive
     *
     * Emits `PrivateSaleStatusChanged` event
     */
    function flipPrivateSaleStatus() external onlyOwner {
        require(!_isPublicSaleActive, "Recent History: public sale is active");

        _isPrivateSaleActive = !_isPrivateSaleActive;
        emit PrivateSaleStatusChanged(_isPrivateSaleActive);
    }

    // Returns true if private sale is active and false if not
    function isPrivateSaleActive() external view returns(bool) {
        return _isPrivateSaleActive;
    }

    /*
     * Allows to change status of the public sale
     *
     * Requirements:
     * - caller should be a contract owner
     * - private sale should be inactive
     *
     * Emits `PublicSaleStatusChanged` event
     */
    function flipPublicSaleStatus() external onlyOwner {
        require(!_isPrivateSaleActive, "Recent History: private sale is active");

        _isPublicSaleActive = !_isPublicSaleActive;
        emit PublicSaleStatusChanged(_isPublicSaleActive);
    }

    // Returns true if public sale is active and false if not
    function isPublicSaleActive() external view returns(bool) {
        return _isPublicSaleActive;
    }

    /*
     * Allows to freeze collection
     *
     * Requirements:
     * - caller should be a contract owner
     * - private sale should be inactive
     * - public sale should be inactive
     *
     * Emits `CollectionFreeze` event
     */
    function freezeCollection() external onlyOwner {
        require(!_isPrivateSaleActive, "Recent History: private sale is active");
        require(!_isPublicSaleActive, "Recent History: public sale is active");

        _isCollectionFreeze = true;
        emit CollectionFreeze(_isCollectionFreeze);
    }

    // Returns true if collection is freeze and false if not
    function isCollectionFreeze() external view returns(bool) {
        return _isCollectionFreeze;
    }

    //////////////////////////////////// OPEN SEA OPERATOR FILTERER ////////////////////////////////////

    // See {ERC721A - approve} and {DefaultOperatorFilterer - onlyAllowedOperatorApproval}
    function approve(address to, uint256 tokenId) public payable override onlyAllowedOperatorApproval(to) {
        ERC721A.approve(to, tokenId);
    }

    // See {ERC721A - setApprovalForAll} and {DefaultOperatorFilterer - onlyAllowedOperatorApproval}
    function setApprovalForAll(
        address operator, bool approved
    ) public virtual override onlyAllowedOperatorApproval(operator) {
        ERC721A.setApprovalForAll(operator, approved);
    }

    // See {ERC721A - transferFrom} and {DefaultOperatorFilterer - onlyAllowedOperator}
    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        ERC721A.transferFrom(from, to, tokenId);
    }

    // See {ERC721A - safeTransferFrom} and {DefaultOperatorFilterer - onlyAllowedOperator}
    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        ERC721A.safeTransferFrom(from, to, tokenId);
    }

    // See {ERC721A - safeTransferFrom} and {DefaultOperatorFilterer - onlyAllowedOperator}
    function safeTransferFrom(
        address from, address to, uint256 tokenId, bytes memory _data
    ) public payable override onlyAllowedOperator(from) {
        ERC721A.safeTransferFrom(from, to, tokenId, _data);
    }
}