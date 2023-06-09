// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC721A, IERC721A, ERC721AQueryable} from "erc721a/contracts/extensions/ERC721AQueryable.sol";
import {ERC721ABurnable} from "erc721a/contracts/extensions/ERC721ABurnable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC2981, ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {DefaultOperatorFilterer} from "operator-filter-registry/src/DefaultOperatorFilterer.sol";

/**
 * @title Adversity + Stoics
 * @custom:website www.uvavault.comm
 * @author @uvavault
 */
contract AdversityStoics is
    DefaultOperatorFilterer,
    ERC2981,
    ERC721AQueryable,
    ERC721ABurnable,
    Ownable,
    ReentrancyGuard
{
    using Strings for uint256;

    struct MintState {
        bool isWhitelistOpen;
        bool isPublicOpen;
        bool isPaperLive;
        uint256 liveAt;
        uint256 expiresAt;
        bytes32 merkleRoot;
        uint256 maxSupply;
        uint256 totalSupply;
        uint256 price;
        uint256 priceInUsdc;
        uint256 minted;
    }

    /// @dev The whitelist merkle root
    bytes32 public merkleRoot;

    /// @dev Treasury
    address public treasury =
        payable(0x6973d7210C92f57c6a89ABeBdbaeeA0b8A0d75D3);

    // @dev Base uri for the nft
    string private baseURI = "ipfs://cid/";

    // @dev Hidden uri for the nft
    string private hiddenURI =
        "ipfs://bafybeifcrsknbivcyldnwyh4bpfejxa2q2c5glceoadbtp6eh3xmgt2o2i/";

    /// @dev The total supply of the collection (n-1)
    uint256 public maxSupply = 201;

    /// @dev The max per wallet (n-1)
    uint256 public maxPerWallet = 13;

    /// @dev The max per tx (n-1)
    uint256 public maxPerTransaction = 25;

    /// @dev USDC value
    IERC20 public usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    /// @notice ETH mint price
    uint256 public priceInUsdc = 299 * 10 ** 6;

    /// @notice ETH mint price
    uint256 public price = 0.2 ether;

    /// @notice Live timestamp
    uint256 public liveAt = 1674421200;

    /// @notice Expires timestamp
    uint256 public expiresAt = 1674684000;

    /// @notice Whitelist mint
    bool public isWhitelistOpen = false;

    /// @notice Public mint
    bool public isPublicOpen = false;

    /// @notice Is Revealed
    bool public isRevealed = false;

    /// @notice Paper mints
    bool public isPaperLive = false;

    /// @notice An address mapping mints
    mapping(address => uint256) public addressToMinted;

    /// @notice An address mapping of paired assets to a stoic token id
    mapping(uint256 => uint256) public tokenIdToStoicsPair;

    /// @notice A stoic id usage mapping
    mapping(uint256 => bool) public usedStoics;

    /// @notice The stoic contract to check ownership
    IERC721 stoicContractAddress;

    constructor(
        address _stoicContractAddress
    ) ERC721A("AdversityStoics", "ADVSTO") {
        _setDefaultRoyalty(treasury, 1000);
        stoicContractAddress = IERC721(_stoicContractAddress);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    modifier withinThreshold(address recipient, uint256 _amount) {
        require(_amount < maxPerTransaction, "Max per transaction reached.");
        require(totalSupply() + _amount < maxSupply, "Max mint reached.");
        require(
            addressToMinted[recipient] + _amount < maxPerWallet,
            "Already minted max."
        );
        _;
    }

    modifier isPaperCaller() {
        require(isPaperLive, "Paper access not live");
        address sender = _msgSenderERC721A();
        require(
            sender == 0xf3DB642663231887E2Ff3501da6E3247D8634A6D ||
                sender == 0x5e01a33C75931aD0A91A12Ee016Be8D61b24ADEB ||
                sender == 0x9E733848061e4966c4a920d5b99a123459670aEe ||
                sender == owner(),
            "Must be from Paper."
        );
        _;
    }

    modifier canMintWhitelist(
        bytes32 _merkleRoot,
        uint256 _allowance,
        bytes32[] calldata _proof
    ) {
        require(isLive() && isWhitelistOpen, "Whitelist mint is not active.");
        bytes32 leaf = keccak256(
            abi.encodePacked(_msgSenderERC721A(), Strings.toString(_allowance))
        );
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
     * @dev mint function
     * @param _amount The amount to mint
     */
    function mint(
        uint256 _amount
    ) external payable canMintPublic isCorrectPrice(_amount, price) {
        address sender = _msgSenderERC721A();
        require(_amount < maxPerTransaction, "Max per transaction reached.");
        require(totalSupply() + _amount < maxSupply, "Max mint reached.");
        require(
            addressToMinted[sender] + _amount < maxPerWallet,
            "Minted max."
        );
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
        uint256 _allowance,
        bytes32[] calldata _proof
    )
        external
        payable
        isCorrectPrice(_amount, price)
        canMintWhitelist(merkleRoot, _allowance, _proof)
    {
        address recipient = _msgSenderERC721A();
        require(_amount < maxPerTransaction, "Max per transaction reached.");
        require(totalSupply() + _amount < maxSupply, "Max mint reached.");
        require(
            addressToMinted[recipient] + _amount <= _allowance,
            "Already over allowance."
        );
        addressToMinted[recipient] += _amount;
        _mint(recipient, _amount);
    }

    /**
     * @dev Paper mint function
     * @param _recipient The recipient of the mint
     * @param _amount The amount to mint
     */
    function mintPaper(
        address _recipient,
        uint256 _amount
    )
        external
        payable
        isPaperCaller
        isCorrectPrice(_amount, price)
        withinThreshold(_recipient, _amount)
    {
        addressToMinted[_recipient] += _amount;
        _mint(_recipient, _amount);
    }

    /**
     * @dev Paper mint USDC function
     * @param _recipient The recipient of the mint
     * @param _amount The amount to mint
     */
    function mintPaperUSDC(
        address _recipient,
        uint256 _amount
    ) external payable isPaperCaller withinThreshold(_recipient, _amount) {
        address sender = _msgSenderERC721A();
        // Transfer USDC
        usdc.transferFrom(sender, address(this), _amount * priceInUsdc);
        addressToMinted[_recipient] += _amount;
        _mint(_recipient, _amount);
    }

    /// @dev Check if mint is live
    function isLive() public view returns (bool) {
        return block.timestamp > liveAt && block.timestamp < expiresAt;
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
                isWhitelistOpen: isWhitelistOpen,
                isPublicOpen: isPublicOpen,
                isPaperLive: isPaperLive,
                liveAt: liveAt,
                expiresAt: expiresAt,
                merkleRoot: merkleRoot,
                maxSupply: maxSupply,
                totalSupply: totalSupply(),
                price: price,
                priceInUsdc: priceInUsdc,
                minted: addressToMinted[_address]
            });
    }

    /**
     * @notice Pairs up the bottle
     * @param _tokenId A base uri
     * @param _stoicTokenId A base uri
     */
    function pair(uint256 _tokenId, uint256 _stoicTokenId) external {
        address owner = _msgSenderERC721A();
        require(owner == ownerOf(_tokenId), "Only asset owner can pair");
        require(
            owner == stoicContractAddress.ownerOf(_stoicTokenId),
            "Only stoic owner can pair"
        );
        require(tokenIdToStoicsPair[_tokenId] == 0, "Already paired token");
        require(!usedStoics[_stoicTokenId], "Already paired stoic");
        usedStoics[_stoicTokenId] = true;
        tokenIdToStoicsPair[_tokenId] = _stoicTokenId;
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
        uint256 pairedTokenId = tokenIdToStoicsPair[_tokenId];
        if (pairedTokenId == 0) {
            return
                string(
                    abi.encodePacked(
                        baseURI,
                        Strings.toString(_tokenId),
                        ".json"
                    )
                );
        } else {
            return
                string(
                    abi.encodePacked(
                        baseURI,
                        Strings.toString(pairedTokenId),
                        "_stoic.json"
                    )
                );
        }
    }

    /**************************************************************************
     * Admin
     *************************************************************************/

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

    /**
     * @notice Sets the reveal state
     * @param _isRevealed The reveal state
     */
    function setIsRevealed(bool _isRevealed) external onlyOwner {
        isRevealed = _isRevealed;
    }

    /**
     * @notice Sets the paper live state
     * @param _isPaperLive The reveal state
     */
    function setIsPaperLive(bool _isPaperLive) external onlyOwner {
        isPaperLive = _isPaperLive;
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
     * @notice Sets usdc price
     * @param _usdc The price in usdc
     */
    function setUSDCPrice(uint256 _usdc) external onlyOwner {
        priceInUsdc = _usdc * 10 ** 6;
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
     * @notice Sets the merkle root for the mint
     * @param _merkleRoot The merkle root to set
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /**
     * @notice Sets the mint states
     * @param _isWhitelistOpen The whitelist is open
     * @param _isPublicMintOpen The public mint is open
     * @param _isPaperLive The paper mint is open
     */
    function setMintStates(
        bool _isWhitelistOpen,
        bool _isPublicMintOpen,
        bool _isPaperLive
    ) external onlyOwner {
        isWhitelistOpen = _isWhitelistOpen;
        isPublicOpen = _isPublicMintOpen;
        isPaperLive = _isPaperLive;
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

    /*
     * @notice Withdraws a generic ERC20 token from contract
     * @param _to The address to withdraw FRG to
     */
    function withdrawERC20(
        address _tokenContract,
        address _to,
        uint256 _amount
    ) public onlyOwner {
        IERC20(_tokenContract).transfer(_to, _amount);
    }

    /// @notice Withdraws funds from contract
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = treasury.call{value: balance}("");
        require(success, "Unable to withdraw ETH");
    }

    /**
     * @dev Admin mint function
     * @param _to The address to mint to
     * @param _amount The amount to mint
     */
    function adminMint(address _to, uint256 _amount) external onlyOwner {
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