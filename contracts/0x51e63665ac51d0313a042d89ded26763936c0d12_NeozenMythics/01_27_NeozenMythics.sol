// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {MerkleProofUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import {IERC2981Upgradeable, ERC2981Upgradeable} from "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import {OperatorFilterer} from "closedsea/src/OperatorFilterer.sol";
import {IERC721AUpgradeable, ERC721AUpgradeable} from "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import {ERC4907AUpgradeable} from "erc721a-upgradeable/contracts/extensions/ERC4907AUpgradeable.sol";
import {ERC721AQueryableUpgradeable} from "erc721a-upgradeable/contracts/extensions/ERC721AQueryableUpgradeable.sol";
import {ERC721ABurnableUpgradeable} from "erc721a-upgradeable/contracts/extensions/ERC721ABurnableUpgradeable.sol";
import {IERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";

/**
 * @title NeozenMythics
 */
contract NeozenMythics is
    ERC721AQueryableUpgradeable,
    ERC721ABurnableUpgradeable,
    ERC2981Upgradeable,
    ERC4907AUpgradeable,
    OperatorFilterer,
    OwnableUpgradeable
{
    using StringsUpgradeable for uint256;
    using SafeMathUpgradeable for uint256;

    struct MintState {
        bool isPublicOpen;
        uint256 liveAt;
        uint256 expiresAt;
        uint256 maxSupply;
        uint256 maxPerWallet;
        uint256 totalSupply;
        uint256 price;
        uint256 minted;
        bytes32 merkleRoot;
    }

    /// @notice Base uri
    string public baseURI;

    /// @dev Treasury
    address public treasury;

    /// @notice Public mint
    bool public isPublicOpen;

    /// @notice Maximum supply for the collection
    uint256 public maxSupply;

    /// @dev The max per wallet (n-1)
    uint256 public maxPerWallet;

    /// @notice ETH mint price
    uint256 public price;

    /// @notice Live timestamp
    uint256 public liveAt;

    /// @notice Expires timestamp
    uint256 public expiresAt;

    /// @notice Merkle root
    bytes32 merkleRoot;

    /// @notice Operator filter toggle switch
    bool private operatorFilteringEnabled;

    /// @notice An address mapping mints
    mapping(address => uint256) public addressToMinted;

    modifier withinThreshold(uint256 _amount, uint256 _allowance) {
        require(totalSupply() + _amount < maxSupply, "!supply");
        require(
            addressToMinted[_msgSenderERC721A()] + _amount < _allowance,
            "!able"
        );
        _;
    }

    modifier isWhitelisted(
        bytes32 _merkleRoot,
        uint256 _allowance,
        bytes32[] calldata _proof
    ) {
        bytes32 leaf = keccak256(
            abi.encodePacked(
                string(abi.encodePacked(_msgSenderERC721A())),
                StringsUpgradeable.toString(_allowance)
            )
        );
        require(
            MerkleProofUpgradeable.verify(_proof, _merkleRoot, leaf),
            "!valid"
        );
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory baseURI_
    ) public initializer initializerERC721A {
        __ERC721A_init("Neozen Mythics", "MYTHIC");
        __Ownable_init();
        __ERC2981_init();
        __ERC4907A_init();
        // Setup filter registry
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
        // Setup royalties to 5% (default denominator is 10000)
        _setDefaultRoyalty(_msgSender(), 750);
        // Set metadata
        baseURI = baseURI_;
        // Set treasury
        treasury = payable(_msgSender());
        // Mint setup
        maxSupply = 1001; // Max supply 1001 (n-1)
        price = 0 ether; // Just in case
        liveAt = 1689685200;
        expiresAt = 1690808400;
        maxPerWallet = 10;
        isPublicOpen = false;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @dev Whitelist mint function
     * @param _amount The amount of mints
     * @param _allowance The total allowances
     * @param _proof The merkle proof for whitelist check
     */
    function wlMint(
        uint256 _amount,
        uint256 _allowance,
        bytes32[] calldata _proof
    )
        external
        withinThreshold(_amount, _allowance)
        isWhitelisted(merkleRoot, _allowance, _proof)
    {
        require(isLive(), "!live");
        _processMint(_amount);
    }

    /**
     * @dev Public mint function
     * @param _amount The amount to mint
     */
    function mint(
        uint256 _amount
    ) external payable withinThreshold(_amount, maxPerWallet) {
        require(isLive() && isPublicOpen, "!live");
        require(msg.value >= _amount * price, "!enough");
        _processMint(_amount);
    }

    /**
     * @dev Process minting
     * @param _amount The amount to mint
     */
    function _processMint(uint256 _amount) internal {
        address sender = _msgSenderERC721A();
        addressToMinted[sender] += _amount;
        _mint(sender, _amount);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    )
        public
        override(IERC721AUpgradeable, ERC721AUpgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    )
        public
        payable
        override(IERC721AUpgradeable, ERC721AUpgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        payable
        override(IERC721AUpgradeable, ERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        payable
        override(IERC721AUpgradeable, ERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    )
        public
        payable
        override(IERC721AUpgradeable, ERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(
            IERC721AUpgradeable,
            ERC721AUpgradeable,
            ERC2981Upgradeable,
            ERC4907AUpgradeable
        )
        returns (bool)
    {
        return
            ERC721AUpgradeable.supportsInterface(interfaceId) ||
            ERC2981Upgradeable.supportsInterface(interfaceId) ||
            ERC4907AUpgradeable.supportsInterface(interfaceId);
    }

    /**
     * @notice Token uri
     * @param tokenId The token id
     */
    function tokenURI(
        uint256 tokenId
    )
        public
        view
        virtual
        override(IERC721AUpgradeable, ERC721AUpgradeable)
        returns (string memory)
    {
        require(_exists(tokenId), "!exists");
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    /// @dev Check if mint is live
    function isLive() public view returns (bool) {
        return block.timestamp >= liveAt && block.timestamp <= expiresAt;
    }

    /**
     * @notice Returns current mint state for a particular address
     * @param _address The address
     */
    function getMintState(
        address _address
    ) external view returns (MintState memory) {
        return
            MintState({
                isPublicOpen: isPublicOpen,
                liveAt: liveAt,
                expiresAt: expiresAt,
                maxSupply: maxSupply,
                maxPerWallet: maxPerWallet,
                totalSupply: totalSupply(),
                price: price,
                minted: addressToMinted[_address],
                merkleRoot: merkleRoot
            });
    }

    /**
     * @notice Sets the collection max supply
     * @param _maxSupply The max supply of the collection
     */
    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    /**
     * @notice Sets public mint is open
     * @param _isPublicOpen The public mint is open
     */
    function setIsPublicOpen(bool _isPublicOpen) external onlyOwner {
        isPublicOpen = _isPublicOpen;
    }

    /**
     * @notice Sets timestamps for live and expires timeframe
     * @param _liveAt A unix timestamp for live date
     * @param _expiresAt A unix timestamp for expiration date
     */
    function setMintWindow(
        uint256 _liveAt,
        uint256 _expiresAt
    ) external onlyOwner {
        liveAt = _liveAt;
        expiresAt = _expiresAt;
    }

    /**
     * @notice Sets the collection max per wallet
     * @param _maxPerWallet The max per wallet
     */
    function setMaxPerWallet(uint256 _maxPerWallet) external onlyOwner {
        maxPerWallet = _maxPerWallet;
    }

    /**
     * @notice Sets prices
     * @param _price The eth price in wei
     */
    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    /**
     * @notice Sets the treasury recipient
     * @param _treasury The treasury address
     */
    function setTreasury(address _treasury) public onlyOwner {
        treasury = payable(_treasury);
    }

    /**
     * @notice Sets the base uri for the token metadata
     * @param _baseURI The base uri
     */
    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    /**
     * @notice Sets the merkle root for the mint
     * @param _merkleRoot The og merkle root to set
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /**
     * @notice Set default royalty
     * @param receiver The royalty receiver address
     * @param feeNumerator A number for 10k basis
     */
    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /// @notice Withdraws ETH funds from contract
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = treasury.call{value: balance}("");
        require(success, "Unable to withdraw ETH");
    }

    /**
     * @dev Airdrop function
     * @param _to The addresses to mint to airdrop too
     */
    function airdrop(address[] calldata _to) external onlyOwner {
        require(totalSupply() + _to.length < maxSupply, "Max mint reached.");
        for (uint256 i = 0; i < _to.length; ) {
            _mint(_to[i], 1);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Sets whether the operator filter is enabled or disabled
     * @param operatorFilteringEnabled_ A boolean value for the operator filter
     */
    function setOperatorFilteringEnabled(
        bool operatorFilteringEnabled_
    ) public onlyOwner {
        operatorFilteringEnabled = operatorFilteringEnabled_;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(
        address operator
    ) internal pure override returns (bool) {
        // OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }
}