// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract Generations is ERC721A, Ownable, ERC2981, DefaultOperatorFilterer {
    // permanent royalty BPS value for collection
    uint96 constant royaltyBPS = 10_00;

    // Price in ETH for 1 token
    uint256 private _price;

    // Limit emission for all types of mint
    uint256 private _limitEmission;

    // Limit for ont time private sale
    uint256 private _presaleLimit;

    // Public sale status, true if active false if not
    bool private _isPublicSaleActive;

    // Private sale status, true if active false if not
    bool private _isPrivateSaleActive;

    // Address where all ETH value will withdraw on mints
    address private _withdrawAddress;

    // Token metadata
    string private _metadata;

    // If true change metadata is unavailable
    bool private _isMetadataFreeze;

    // Mapping user address to nonce for signed mint
    mapping(address => uint256) private _signedMintNonce;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory metadata,
        uint256 limitEmission,
        uint256 presaleLimit
    ) ERC721A(name_, symbol_) {
        _withdrawAddress = msg.sender;
        _setDefaultRoyalty(msg.sender, royaltyBPS);
        _metadata = metadata;
        _limitEmission = limitEmission;
        _presaleLimit = presaleLimit;
    }

    // Emits whenever new price is set with new price and caller address as arguments
    event NewPrice(uint256 price, address caller);

    // Emits whenever public sale status is changed with current sale status and caller address as arguments
    event PublicSaleStatusChanged(bool status, address caller);

    // Emits whenever private sale status is changed with current sale status and caller address as arguments
    event PrivateSaleStatusChanged(bool status, address caller);

    // Emits whenever public sale mint is made with amount of minted tokens, total ETH value and address as arguments
    event PublicSaleMint(uint256 amount, uint256 value, address to);

    // Emits whenever private sale mint is made with amount of minted tokens, total ETH value and address as arguments
    event PrivateSaleMint(uint256 amount, uint256 value, address to);

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC2981, ERC721A) returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f || // ERC165 interface ID for ERC721Metadata.
            interfaceId == type(IERC2981).interfaceId; // royalty
    }

    // Returns current limit emission number
    function getLimitEmission() external view returns (uint256) {
        return _limitEmission;
    }

    // Returns current presale limit number
    function getPresaleLimit() external view returns (uint256) {
        return _presaleLimit;
    }

    // Allows to set new metadata
    function setMetadata(string memory newMetadata) external onlyOwner {
        require(!_isMetadataFreeze, "Generations: metadata is freeze");
        _metadata = newMetadata;
    }

    // Allows to freeze metadata. After function call changing metadata is unavailable
    function freezeMetadata() external onlyOwner {
        _isMetadataFreeze = true;
    }

    /*
     * Allows to set new withdraw address
     * Requirements:
     * - caller should be contract owner
     * - new withdraw address should not be zero address
     *
     * @param `withdrawAddress` - new withdraw address
     *
     */
    function setWithdrawAddress(address withdrawAddress) external onlyOwner {
        require(withdrawAddress != address(0), "Generations: withdraw address cant not be zero address");
        _withdrawAddress = withdrawAddress;
    }

    // Returns current `_withdrawAddress`
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
        require(withdrawAddress != address(0), "Generations: withdraw address cant not be zero address");
        _setDefaultRoyalty(withdrawAddress, royaltyBPS);
    }

    /*
     * Allows to set new token price in ETH
     * Requirements:
     * - caller should be token owner
     * - price should be more than 0
     * - public sale should be not active
     * - private sale should be nor active
     *
     * @param `price` - new price for one token
     *
     * @emit `NewPrice` event with new price and caller as arguments
     *
     */
    function setPrice(uint256 price) external onlyOwner {
        require(price > 0, "Generations: price should be more than 0");
        require(!_isPublicSaleActive, "Generations: public sale is active");
        require(!_isPrivateSaleActive, "Generations: private sale is active");

        _price = price;

        emit NewPrice(price, msg.sender);
    }

    // Allows to return current token price in ETH
    function getPrice() external view returns (uint256) {
        return _price;
    }

    /*
     * Allows to change public sale status
     * Requirements:
     * - caller should be contract owner
     * - private sale should be not active
     *
     * @emit `PublicSaleStatusChanged` event with current status and caller as arguments
     *
     */
    function flipPublicSaleStatus() external onlyOwner {
        require(!_isPrivateSaleActive, "Generations: private sale is active");
        _isPublicSaleActive = !_isPublicSaleActive;

        emit PublicSaleStatusChanged(_isPublicSaleActive, msg.sender);
    }

    // Returns current public sale status
    function getPublicSaleStatus() external view returns (bool) {
        return _isPublicSaleActive;
    }

    /*
     * Allows to change private sale status
     * Requirements:
     * - caller should be contract owner
     * - public sale should be not active
     *
     * @emit `PrivateSaleStatusChanged` event with current status and caller as arguments
     *
     */
    function flipPrivateSaleStatus() external onlyOwner {
        require(!_isPublicSaleActive, "Generations: public sale is active");
        _isPrivateSaleActive = !_isPrivateSaleActive;

        emit PrivateSaleStatusChanged(_isPrivateSaleActive, msg.sender);
    }

    // Returns current private sale status
    function getPrivateSaleStatus() external view returns (bool) {
        return _isPrivateSaleActive;
    }

    /*
     * Allows to mint given amount of tokens to caller during public sale. Transfers ETH value to `_withdrawAddress`
     * Requirements:
     * - limit emission should not be reached
     * - public sale should be active
     * - amount should be more than 0
     * - ETH value should equal amount mul price
     *
     * @param `amount` - amount of tokens to mint
     *
     * @emit `PublicSaleMint` event with amount, ETH value and caller address as arguments
     * @emit `ERC721A-Transfer` event
     *
     */
    function mint(uint256 amount) external payable {
        require(_limitEmission >= totalSupply() + amount, "Generations: limit emission reached");
        require(_isPublicSaleActive, "Generations: public sale should be active");
        require(amount > 0, "Generations: amount should be more than 0");
        require(msg.value == amount * _price, "Generations: invalid funds");

        _mint(msg.sender, amount);
        _withdraw(msg.value);

        emit PublicSaleMint(amount, msg.value, msg.sender);
    }

    /*
     * Allows to mint given amount of tokens to given address for contract owner
     * Requirements:
     * - limit emission should not be reached
     * - caller should be a contract owner
     * - amount should be more than 0
     * - to address should not be zero address
     *
     * @param `amount` - amount of tokens to mint
     * @param `to` - address to mint
     *
     * @emit `ERC721A-Transfer` event
     *
     */
    function mintTo(uint256 amount, address to) external onlyOwner {
        require(_limitEmission >= totalSupply() + amount, "Generations: limit emission reached");
        require(amount > 0, "Generations: amount should be more than 0");
        require(to != address(0), "Generations: to address can not be zero address");

        _mint(to, amount);
    }

    /*
     * Allows to mint `amount` of new NFT to caller while private sale, if caller
     * is in allow list. Can only be used with signature from contract owner. See {Recent History - _checkSignature}
     * and valid params. Params are validating by comparing message hash
     * and hash from params - caller address, amount and nonce. See {Recent History - _checkMessage}
     *
     * Requirements:
     * - limit emission should not be reached
     * - amount should be less or equal to
     * - should have valid signature from contract owner
     * - should have valid params and message
     * - private sale should be active
     * - amount should be more than 0
     * - message value should be equal to token price mul amount
     *
     * @param `amount` - amount of tokens to mint
     * @param `hash` - message hash to prove signature
     * @param `signature` - signature hash to prove
     *
     * Emits `ERC721A-Transfer` event
     * Emits `PrivateSaleMint` event with amount, ETH value and caller address as arguments
     * Transfers message value to contract owner
     */
    function mintPresale(uint256 amount, bytes32 message, bytes calldata signature) external payable {
        require(_limitEmission >= totalSupply() + amount, "Generations: limit emission reached");
        require(amount > 0, "Generations: amount should be more than 0");
        require(amount <= _presaleLimit, "Generations: amount for one mint is to big");
        require(_checkSignature(message, signature), "Generations: invalid signature");
        require(_checkMessage(message, address(msg.sender), amount), "Generations: invalid message");
        require(_isPrivateSaleActive, "Generations: private sale is not active");
        require(msg.value == _price * amount, "Generations: invalid funds");
        _signedMintNonce[msg.sender]++;

        _mint(msg.sender, amount);
        _withdraw(msg.value);

        emit PrivateSaleMint(amount, msg.value, msg.sender);
    }

    // Returns current nonce for given address for signed mint
    function getNonce(address to) public view returns (uint256) {
        return _signedMintNonce[to];
    }

    // See {ERC721A - approve} and {DefaultOperatorFilterer - onlyAllowedOperatorApproval}
    function approve(address to, uint256 tokenId) public payable override onlyAllowedOperatorApproval(to) {
        ERC721A.approve(to, tokenId);
    }

    // See {ERC721A - setApprovalForAll} and {DefaultOperatorFilterer - onlyAllowedOperatorApproval}
    function setApprovalForAll(
        address operator,
        bool approved
    ) public virtual override onlyAllowedOperatorApproval(operator) {
        ERC721A.setApprovalForAll(operator, approved);
    }

    // See {ERC721A - transferFrom} and {DefaultOperatorFilterer - onlyAllowedOperator}
    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        ERC721A.transferFrom(from, to, tokenId);
    }

    // See {ERC721A - safeTransferFrom} and {DefaultOperatorFilterer - onlyAllowedOperator}
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        ERC721A.safeTransferFrom(from, to, tokenId);
    }

    // See {ERC721A - safeTransferFrom} and {DefaultOperatorFilterer - onlyAllowedOperator}
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public payable override onlyAllowedOperator(from) {
        ERC721A.safeTransferFrom(from, to, tokenId, _data);
    }

    // Transfers given `value` to owner
    function _withdraw(uint256 value) internal {
        payable(_withdrawAddress).transfer(value);
    }

    /**
     * See {ECDSA - recover}
     * @return signer address
     */
    function _recoverSigner(bytes32 message, bytes calldata signature) internal pure returns (address) {
        bytes32 messageDigest = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", message));
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
     * Compares message hash from caller and hash from params - caller address, amount to mint and nonce.
     * If hash is not equal returns false, if it is equal (which means valid) - returns true
     */
    function _checkMessage(bytes32 message, address caller, uint256 amount) internal view returns (bool) {
        return message == keccak256(abi.encodePacked(caller, amount, getNonce(caller)));
    }

    // See {ERC721A - _baseURI}
    function _baseURI() internal view override returns (string memory) {
        return _metadata;
    }

    // Returns the starting token ID.
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
}