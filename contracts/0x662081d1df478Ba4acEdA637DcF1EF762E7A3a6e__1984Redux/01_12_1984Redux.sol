// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "erc721a/contracts/ERC721A.sol";

import "./OperatorFilterer.sol";

error AlreadyReservedTokens();
error CallerNotOffsetter();
error FunctionLocked();
error InsufficientValue();
error InsufficientMints();
error InsufficientSupply();
error InvalidSignature();
error NoContractMinting();
error ProvenanceHashAlreadySet();
error ProvenanceHashNotSet();
error TokenOffsetAlreadySet();
error TokenOffsetNotSet();
error WithdrawFailed();

interface Offsetable { function setOffset(uint256 randomness) external; }

contract _1984Redux is ERC721A, ERC2981, OperatorFilterer, Ownable {
    using ECDSA for bytes32;

    string private _baseTokenURI;
    uint256 private _tokenOffset;

    address public immutable OFFSETTER;
    uint256 public constant RESERVED = 198;
    uint256 public constant MAX_SUPPLY = 1984;
    uint256 public constant MINT_PRICE = .05 ether;
    string public provenanceHash;
    address public signer;
    bool public operatorFilteringEnabled;
    mapping(bytes4 => bool) public functionLocked;

    constructor(
        address _signer,
        address _offsetter,
        address _royaltyReceiver,
        uint96 _royaltyFraction
    )
        ERC721A("1984Redux", "1984")
    {
        signer = _signer;
        OFFSETTER = _offsetter;

        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;

        _setDefaultRoyalty(_royaltyReceiver, _royaltyFraction);
    }

    /**
     * @notice Modifier applied to functions that will be disabled when they're no longer needed
     */
    modifier lockable() {
        if (functionLocked[msg.sig]) revert FunctionLocked();
        _;
    }

    /**
     * @inheritdoc ERC721A
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return
            ERC721A.supportsInterface(interfaceId)
            || ERC2981.supportsInterface(interfaceId);
    }

    /**
     * @notice Override ERC721A _baseURI function to use base URI pattern
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /*
     * @notice Token offset is not applied to the first `RESERVED` amount of tokens
     */
    function tokenOffset() public view returns (uint256) {
        if (_tokenOffset == 0) revert TokenOffsetNotSet();

        return _tokenOffset;
    }

    /**
     * @notice Return the number of tokens an address has minted
     * @param account Address to return the number of tokens minted for
     */
    function numberMinted(address account) external view returns (uint256) {
        return _numberMinted(account);
    }

    /**
     * @notice Lock a function so that it can no longer be called
     * @dev WARNING: THIS CANNOT BE UNDONE
     * @param id Function signature
     */
    function lockFunction(bytes4 id) external onlyOwner {
        functionLocked[id] = true;
    }

    /**
     * @notice Set the state of the OpenSea operator filter
     * @param value Flag indicating if the operator filter should be applied to transfers and approvals
     */
    function setOperatorFilteringEnabled(bool value) external lockable onlyOwner {
        operatorFilteringEnabled = value;
    }

    /**
     * @notice Set new royalties settings for the collection
     * @param receiver Address to receive royalties
     * @param royaltyFraction Royalty fee respective to fee denominator (10_000)
     */
    function setRoyalties(address receiver, uint96 royaltyFraction) external onlyOwner {
        _setDefaultRoyalty(receiver, royaltyFraction);
    }

    /**
     * @notice Set signer for creating mint signatures
     * @param _signer New signer address
     */
    function setSigner(address _signer) external lockable onlyOwner {
        signer = _signer;
    }

    /**
     * @notice Set token metadata base URI
     * @param _newBaseURI New base URI
     */
    function setBaseURI(string calldata _newBaseURI) external lockable onlyOwner {
        _baseTokenURI = _newBaseURI;
    }

    /**
     * @notice Set provenance hash for the collection
     * @param _provenanceHash New hash of the metadata
     */
    function setProvenanceHash(string calldata _provenanceHash) external lockable onlyOwner {
        if (bytes(provenanceHash).length != 0) revert ProvenanceHashAlreadySet();

        provenanceHash = _provenanceHash;
    }

    /**
     * @notice Set the offset for the token metadata
     * @param randomness Random value used to seed offset
     */
    function setOffset(uint256 randomness) external lockable {
        if (msg.sender != OFFSETTER) revert CallerNotOffsetter();
        if (bytes(provenanceHash).length == 0) revert ProvenanceHashNotSet();
        if (_tokenOffset != 0) revert TokenOffsetAlreadySet();

        _tokenOffset = randomness % MAX_SUPPLY;
    }

    /**
     * @notice Mint `RESERVED` amount of tokens to an address
     * @param to Address to send the reserved tokens
     */
    function reserve(address to) external lockable onlyOwner {
        if (_totalMinted() >= RESERVED) revert AlreadyReservedTokens();

        _mint(to, RESERVED);
    }

    /**
     * @notice Mint a specified amount of tokens using a signature
     * @param amount Amount of tokens to mint
     * @param max Max amount of tokens mintable with the provided signature
     * @param signature Ethereum signed message, created by `signer`
     */
    function mint(
        uint256 amount,
        uint256 max,
        bytes calldata signature
    ) external payable lockable {
        if (msg.sender != tx.origin) revert NoContractMinting();
        if (msg.value != MINT_PRICE * amount) revert InsufficientValue();
        if (amount + _totalMinted() > MAX_SUPPLY) revert InsufficientSupply();
        if (_numberMinted(msg.sender) + amount > max) revert InsufficientMints();

        if (signer != ECDSA.recover(
            ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(msg.sender, max))),
            signature
        )) revert InvalidSignature();

        _mint(msg.sender, amount);
    }

    /**
     * @notice Withdraw all ETH sent to the contract
     */
    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        if (!success) revert WithdrawFailed();
    }

    /**
     * @notice Override to enforce OpenSea's operator filter requirement to receive collection royalties
     * @inheritdoc ERC721A
     */
    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator, operatorFilteringEnabled)
    {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @notice Override to enforce OpenSea's operator filter requirement to receive collection royalties
     * @inheritdoc ERC721A
     */
    function approve(address operator, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperatorApproval(operator, operatorFilteringEnabled)
    {
        super.approve(operator, tokenId);
    }

    /**
     * @notice Override to enforce OpenSea's operator filter requirement to receive collection royalties
     * @inheritdoc ERC721A
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from, operatorFilteringEnabled) {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @notice Override to enforce OpenSea's operator filter requirement to receive collection royalties
     * @inheritdoc ERC721A
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from, operatorFilteringEnabled) {
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @notice Override to enforce OpenSea's operator filter requirement to receive collection royalties
     * @inheritdoc ERC721A
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from, operatorFilteringEnabled) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}