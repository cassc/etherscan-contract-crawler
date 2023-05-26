// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";

/**
 * @title LionsDenPokerClub
 * @author sbmitchell.eth
 */

contract LionsDenPokerClub is ERC721AQueryable, ERC721ABurnable, Ownable {
    using Strings for uint256;

    struct MintState {
        uint256 whitelistLiveAt;
        uint256 whitelistPrice;
        uint256 publicLiveAt;
        uint256 price;
        bytes32 merkleRoot;
        uint256 maxPerWallet;
        uint256 maxSupply;
        uint256 totalSupply;
        uint256 minted;
    }

    // @dev Base uri for the nft
    string private baseURI = "ipfs://cid/";

    // @dev Hidden uri for the nft
    string private hiddenURI =
        "ipfs://bafybeighfo7xcizyvh2pxhmjuq5hup3mziiuaw3nxy4nzscknsgoq6x6u4/prereveal.json";

    /*
     * @notice Whitelist mint ~ Oct 10th, 12:00PM EST
     * @dev Whitelist mint go live date
     */
    uint256 public whitelistLiveAt = 1665417600;

    // @dev The whitelist mint price
    uint256 public whitelistPrice = 0.09 ether;

    // @dev The whitelist merkle root
    bytes32 public merkleRoot;

    /*
     * @notice Public mint ~ Oct 10th, 03:00PM EST
     * @dev Public mint go live date
     */
    uint256 public publicLiveAt = 1665428400;

    // @dev The public mint price
    uint256 public price = 0.11 ether;

    // @dev The withdraw address
    address public treasury =
        payable(0xf211ba25A6584cDE4469789bDD671f8FC57EFb6e);

    // @dev The total max per wallet (n - 1)
    uint256 public maxPerWallet = 3;

    // @dev The total supply of the collection (n-1)
    uint256 public maxSupply = 751;

    // @dev The reveal state
    bool public isRevealed = false;

    // @dev An address mapping for mints
    mapping(address => uint256) public addressToMinted;

    constructor() ERC721A("LionsDenPokerClub", "LDPC") {
        _mintERC2309(treasury, 1); // Placeholder mint
    }

    modifier whitelisted(bytes32[] calldata _proof) {
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(_proof, merkleRoot, leaf), "Invalid proof.");
        _;
    }

    modifier publicIsLive() {
        require(block.timestamp > publicLiveAt, "Public not live.");
        _;
    }

    modifier whitelistIsLive() {
        require(block.timestamp > whitelistLiveAt, "Whitelist not live.");
        _;
    }

    modifier withinMintSupply(uint256 _amount) {
        require(
            addressToMinted[_msgSender()] + _amount < maxPerWallet,
            "Max per wallet reached."
        );
        require(
            totalSupply() + _amount < maxSupply,
            "Cannot mint over max supply."
        );
        _;
    }

    /**
     * @notice Whitelist mint
     * @param _proof The bytes32 array proof to verify the merkle root
     */
    function whitelistMint(uint256 _amount, bytes32[] calldata _proof)
        external
        payable
        whitelistIsLive
        withinMintSupply(_amount)
        whitelisted(_proof)
    {
        require(msg.value >= _amount * whitelistPrice, "Not enough funds.");
        addressToMinted[_msgSender()] += _amount;
        _mint(_msgSender(), _amount);
    }

    /**
     * @notice Mints a new token
     * @param _amount The number of tokens to mint
     */
    function mint(uint256 _amount)
        external
        payable
        publicIsLive
        withinMintSupply(_amount)
    {
        require(msg.value >= _amount * price, "Not enough funds.");
        addressToMinted[_msgSender()] += _amount;
        _mint(_msgSender(), _amount);
    }

    /**
     * @notice Mints a new token for owners
     * @param _to The address
     * @param _amount The amount
     */
    function ownerMint(address _to, uint256 _amount)
        external
        withinMintSupply(_amount)
        onlyOwner
    {
        _mint(_to, _amount);
    }

    /**
     * @notice Returns current mintable state for a particular address
     * @param _address The address
     */
    function getMintableState(address _address)
        external
        view
        returns (MintState memory)
    {
        return
            MintState({
                whitelistLiveAt: whitelistLiveAt,
                whitelistPrice: whitelistPrice,
                publicLiveAt: publicLiveAt,
                price: price,
                merkleRoot: merkleRoot,
                maxPerWallet: maxPerWallet,
                maxSupply: maxSupply,
                totalSupply: totalSupply(),
                minted: addressToMinted[_address]
            });
    }

    /**
     * @notice Returns the URI for a given token id
     * @param _tokenId A tokenId
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(_tokenId)) revert OwnerQueryForNonexistentToken();
        if (!isRevealed)
            return string(abi.encodePacked(hiddenURI, "prereveal.json"));
        return
            string(
                abi.encodePacked(baseURI, Strings.toString(_tokenId), ".json")
            );
    }

    /**
     * @dev Returns the starting token ID.
     */
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

    /**
     * @notice Sets the max per wallet
     * @param _maxPerWallet The max mint count per address
     */
    function setMaxPerWallet(uint256 _maxPerWallet) external onlyOwner {
        maxPerWallet = _maxPerWallet;
    }

    /**
     * @notice Sets the collection max supply
     * @param _maxSupply The max supply of the collection
     */
    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    /**
     * @notice Sets whitelist price
     * @param _whitelistPrice price in wei
     */
    function setWhitelistPrice(uint256 _whitelistPrice) external onlyOwner {
        whitelistPrice = _whitelistPrice;
    }

    /**
     * @notice Sets public price
     * @param _price price in wei
     */
    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    /**
     * @notice Sets the treasury recipient
     * @param _treasury The treasury address
     */
    function setTreasury(address _treasury) external onlyOwner {
        treasury = payable(_treasury);
    }

    /**
     * @notice Sets the Whitelist merkle root for the mint
     * @param _merkleRoot The merkle root to set
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /**
     * @notice Sets the reveal state
     * @param _isRevealed The reveal state
     */
    function setIsRevealed(bool _isRevealed) external onlyOwner {
        isRevealed = _isRevealed;
    }

    /**
     * @notice Sets the whitelist live timestamp
     * @param _whitelistLiveAt The timestamp
     */
    function setWhitelistLiveAt(uint256 _whitelistLiveAt) external onlyOwner {
        whitelistLiveAt = _whitelistLiveAt;
    }

    /**
     * @notice Sets the public live timestamp
     * @param _publicLiveAt The timestamp
     */
    function setPublicLiveAt(uint256 _publicLiveAt) external onlyOwner {
        publicLiveAt = _publicLiveAt;
    }

    /**
     * @notice Withdraws funds from contract
     */
    function withdraw() external onlyOwner {
        (bool success, ) = treasury.call{value: address(this).balance}("");
        require(success, "Failed to send to treasury.");
    }
}