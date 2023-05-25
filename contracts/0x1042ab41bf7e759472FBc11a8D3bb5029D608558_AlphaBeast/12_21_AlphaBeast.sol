// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC721A, IERC721A, ERC721AQueryable} from "erc721a/contracts/extensions/ERC721AQueryable.sol";
import {ERC721ABurnable} from "erc721a/contracts/extensions/ERC721ABurnable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC2981, ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {DefaultOperatorFilterer} from "operator-filter-registry/src/DefaultOperatorFilterer.sol";

/**
 * @title ALPHABEAST 🐂 REAL ALPHA! NOT BULLSH*T!
 * @custom:website https://twitter.com/RealAlphaBeast
 * @author @RealAlphaBeast
 * @notice NFT Alpha Group. Real Alpha & Real Automation Means Real Trade Wins.
 */
contract AlphaBeast is
    DefaultOperatorFilterer,
    ERC2981,
    ERC721AQueryable,
    ERC721ABurnable,
    Ownable,
    ReentrancyGuard
{
    using Strings for uint256;

    struct MintState {
        bool isMintPassOpen;
        bool isWhitelistOpen;
        bool isPublicOpen;
        uint256 liveAt;
        uint256 expiresAt;
        bytes32 merkleRoot;
        uint256 maxSupply;
        uint256 totalSupply;
        uint256 price;
        uint256 minted;
    }

    address public constant DEAD_ADDRESS =
        0x000000000000000000000000000000000000dEaD;

    /// @dev The whitelist merkle root
    bytes32 public merkleRoot;

    /// @dev Treasury
    address public treasury =
        payable(0x15E39a1C0F5f85B519CFe08eFa58D155E231D4BB);

    // @dev Base uri for the nft
    string private baseURI =
        "ipfs://bafybeiezcy4tbz273xcwt4uozuvlu6o64yo6qyc5bvnpue3cjx3nqil2ku/";

    // @dev Hidden uri for the nft
    string private hiddenURI =
        "ipfs://bafybeicmao57ukowuazilgwnri6tpom5ai3jzxic6fpvcpboilmk65z66y/";

    /// @dev The total supply of the collection (n-1)
    uint256 public maxSupply = 10001;

    /// @dev The max per wallet (n-1)
    uint256 public maxPerWallet = 10001;

    /// @dev The max per tx (n-1)
    uint256 public maxPerTransaction = 6;

    /// @notice ETH mint price
    uint256 public price = 0.1 ether;

    /// @notice Live timestamp
    uint256 public liveAt = 1676048400;

    /// @notice Expires timestamp
    uint256 public expiresAt = 1707584400;

    /// @notice Mint Pass contract
    IERC721 public mintPassContract;

    /// @notice Mint pass open
    bool public isMintPassOpen = true;

    /// @notice Whitelist mint
    bool public isWhitelistOpen = false;

    /// @notice Public mint
    bool public isPublicOpen = true;

    /// @notice Is Revealed
    bool public isRevealed = true;

    /// @notice An address mapping mints
    mapping(address => uint256) public addressToMinted;

    constructor(address _mintPassContract) ERC721A("AlphaBeast", "BEAST") {
        _setDefaultRoyalty(treasury, 690);
        mintPassContract = IERC721(_mintPassContract);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @notice Sets the hidden URI of the NFT
     * @param _hiddenURI A base uri
     */
    function setHiddenURI(string calldata _hiddenURI) external onlyOwner {
        hiddenURI = _hiddenURI;
    }

    /**
     * @notice Sets the base URI of the NFT
     * @param _baseURI A base uri
     */
    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    modifier withinThreshold(uint256 _amount) {
        require(_amount < maxPerTransaction, "Max per transaction reached.");
        require(totalSupply() + _amount < maxSupply, "Max mint reached.");
        require(
            addressToMinted[_msgSenderERC721A()] + _amount < maxPerWallet,
            "Already minted max."
        );
        _;
    }

    modifier canMintWhitelist(bytes32 _merkleRoot, bytes32[] calldata _proof) {
        require(isLive() && isWhitelistOpen, "Whitelist mint is not active.");
        bytes32 leaf = keccak256(abi.encodePacked(_msgSenderERC721A()));
        require(
            MerkleProof.verify(_proof, _merkleRoot, leaf),
            "Invalid proof."
        );
        _;
    }

    modifier canMintPublic() {
        require(isLive() && isPublicOpen, "Public mint is not active.");
        _;
    }

    modifier isCorrectPrice(uint256 _amount, uint256 _price) {
        require(msg.value >= _amount * _price, "Not enough funds.");
        _;
    }

    /**************************************************************************
     * Minting
     *************************************************************************/

    /**
     * @dev Public mint function
     * @param _amount The amount to mint
     */
    function mint(
        uint256 _amount
    )
        external
        payable
        canMintPublic
        isCorrectPrice(_amount, price)
        withinThreshold(_amount)
    {
        address sender = _msgSenderERC721A();
        addressToMinted[sender] += _amount;
        _mint(sender, _amount);
    }

    /**
     * @dev Whitelist mint function
     * @param _amount The amount to mint
     * @param _proof The generated merkel proof
     */
    function whitelistMint(
        uint256 _amount,
        bytes32[] calldata _proof
    )
        external
        payable
        isCorrectPrice(_amount, price)
        withinThreshold(_amount)
        canMintWhitelist(merkleRoot, _proof)
    {
        address sender = _msgSenderERC721A();
        addressToMinted[sender] += _amount;
        _mint(sender, _amount);
    }

    /**
     * @dev Mint pass exchange
     * @param _tokenIds The token ids of owned passes
     */
    function claim(uint256[] calldata _tokenIds) external {
        require(isLive() && isMintPassOpen, "Core pass mint not live.");
        address sender = _msgSenderERC721A();
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            mintPassContract.transferFrom(sender, DEAD_ADDRESS, _tokenIds[i]);
        }
        // Mint with the core pass
        _mint(sender, _tokenIds.length);
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
                isMintPassOpen: isMintPassOpen,
                isWhitelistOpen: isWhitelistOpen,
                isPublicOpen: isPublicOpen,
                liveAt: liveAt,
                expiresAt: expiresAt,
                merkleRoot: merkleRoot,
                maxSupply: maxSupply,
                totalSupply: totalSupply(),
                price: price,
                minted: addressToMinted[_address]
            });
    }

    /**
     * @notice Returns the URI for a given token id
     * @param _tokenId A tokenId
     */
    function tokenURI(
        uint256 _tokenId
    ) public view override(IERC721A, ERC721A) returns (string memory) {
        if (!_exists(_tokenId)) revert OwnerQueryForNonexistentToken();
        if (!isRevealed)
            return string(abi.encodePacked(hiddenURI, "prereveal.json"));
        return
            string(
                abi.encodePacked(baseURI, Strings.toString(_tokenId), ".json")
            );
    }

    /**************************************************************************
     * Admin
     *************************************************************************/

    /**
     * @notice Sets the reveal state
     * @param _isRevealed The reveal state
     */
    function setIsRevealed(bool _isRevealed) external onlyOwner {
        isRevealed = _isRevealed;
    }

    /**
     * @notice Sets the collection max supply
     * @param _maxSupply The max supply of the collection
     */
    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    /**
     * @notice Sets the collection max per transaction
     * @param _maxPerTransaction The max per transaction
     */
    function setMaxPerTransaction(
        uint256 _maxPerTransaction
    ) external onlyOwner {
        maxPerTransaction = _maxPerTransaction;
    }

    /**
     * @notice Sets the collection max per wallet
     * @param _maxPerWallet The max per wallet
     */
    function setMaxPerWallet(uint256 _maxPerWallet) external onlyOwner {
        maxPerWallet = _maxPerWallet;
    }

    /**
     * @notice Sets eth price
     * @param _price The price in wei
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
     * @notice Sets the mint pass contracts
     * @param _mintPassContract The core pass contract address
     */
    function setPassesContracts(address _mintPassContract) public onlyOwner {
        mintPassContract = IERC721(_mintPassContract);
    }

    /**
     * @notice Sets the merkle root for the mint
     * @param _merkleRoot The merkle root to set
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /**
     * @notice Sets the mint states
     * @param _isMintPassOpen Alpha core mint is open
     * @param _isWhitelistOpen The whitelist is open
     * @param _isPublicMintOpen The public mint is open
     */
    function setMintStates(
        bool _isMintPassOpen,
        bool _isWhitelistOpen,
        bool _isPublicMintOpen
    ) external onlyOwner {
        isMintPassOpen = _isMintPassOpen;
        isWhitelistOpen = _isWhitelistOpen;
        isPublicOpen = _isPublicMintOpen;
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
     * @notice Changes the contract defined royalty
     * @param _receiver - The receiver of royalties
     * @param _feeNumerator - The numerator that represents a percent out of 10,000
     */
    function setDefaultRoyalty(
        address _receiver,
        uint96 _feeNumerator
    ) public onlyOwner {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    /// @notice Withdraws funds from contract
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = treasury.call{value: balance}("");
        require(success, "Unable to withdraw ETH");
    }

    /**
     * @dev Airdrop function
     * @param _to The address to mint to
     * @param _amount The amount to mint
     */
    function airdrop(address _to, uint256 _amount) external onlyOwner {
        require(totalSupply() + _amount < maxSupply, "Max mint reached.");
        _mint(_to, _amount);
    }

    /**************************************************************************
     * Royalties
     *************************************************************************/

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC721A, ERC721A, ERC2981) returns (bool) {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(IERC721A, ERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    )
        public
        payable
        override(IERC721A, ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}