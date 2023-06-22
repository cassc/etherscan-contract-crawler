// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";

/**
 * @title The Husky Pack
 * @author @ScottMitchell18
 */
contract TheHuskyPack is ERC721AQueryable, ERC721ABurnable, Ownable {
    using Strings for uint256;

    // @dev Base uri for the nft
    string private baseURI;

    // @dev Hidden uri for the nft
    string private hiddenURI;

    // @dev The max amount of mints per wallet
    uint256 public maxPerWallet = 5;

    // @dev The price of a mint
    uint256 public price = 0.033 ether;

    // @dev The withdraw address
    address public treasury = 0x8e3e3e9C29EcfDCd4D3BCf115ECE46a0B783D590;

    // @dev The dev address
    address public dev = 0x593b94c059f37f1AF542c25A0F4B22Cd2695Fb68;

    // @dev The total supply of the collection
    uint256 public maxSupply;

    // @dev An address mapping to add max mints per wallet
    mapping(address => uint256) public addressToMinted;

    // @dev The merkle root proof for OG pack
    bytes32 public ogMerkleRoot;

    // @dev The merkle root proof for whitelist
    bytes32 public whitelistMerkleRoot;

    // @dev The OG pack mint state
    bool public isOGMintActive = true;

    // @dev The whitelist mint state
    bool public isWhitelistMintActive = false;

    // @dev The public mint state
    bool public isPublicMintActive = false;

    // @dev The reveal state
    bool public isRevealed = false;

    constructor() ERC721A("The Husky Pack", "HUSKY") {
        hiddenURI = "ipfs://bafybeicukx2uu5bgu2izhtj3bz2s5kjabfa27rpqm3mjraieorpx3cogmu/";
        _mintERC2309(treasury, 25);
        _mintERC2309(dev, 10);
    }

    /**
     * @notice OG pack minting function which requires a merkle proof - 2x free
     * @param _proof The bytes32 array proof to verify the merkle root
     */
    function ogMint(uint256 _amount, bytes32[] calldata _proof) public payable {
        require(_amount < 5 && isOGMintActive, "99");
        require(_amount < 3 || (msg.value >= (_amount - 2) * price), "1");
        require(addressToMinted[_msgSender()] + _amount < maxPerWallet, "3");

        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(_proof, ogMerkleRoot, leaf), "4");

        addressToMinted[_msgSender()] += _amount;
        _safeMint(_msgSender(), _amount);
    }

    /**
     * @notice Whitelisted minting function which requires a merkle proof - 1x free
     * @param _proof The bytes32 array proof to verify the merkle root
     */
    function whitelistMint(uint256 _amount, bytes32[] calldata _proof)
        public
        payable
    {
        require(_amount < 4 && isWhitelistMintActive, "99");
        require(_amount < 2 || (msg.value >= (_amount - 1) * price), "1");
        require(addressToMinted[_msgSender()] + _amount < maxPerWallet, "3");

        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(_proof, whitelistMerkleRoot, leaf), "4");

        addressToMinted[_msgSender()] += _amount;
        _safeMint(_msgSender(), _amount);
    }

    /**
     * @notice Mints a new kpmc token
     * @param _amount The number of tokens to mint
     */
    function mint(uint256 _amount) public payable {
        require(_amount < maxPerWallet && isPublicMintActive, "99");
        require(msg.value >= _amount * price, "1");
        require(totalSupply() + _amount < maxSupply, "2");
        require(addressToMinted[_msgSender()] + _amount < maxPerWallet, "3");

        addressToMinted[_msgSender()] += _amount;
        _safeMint(_msgSender(), _amount);
    }

    /**
     * @notice A toggle switch for public sale
     * @param _maxSupply The max nft collection size
     */
    function triggerPublicSale(uint256 _maxSupply) external onlyOwner {
        delete ogMerkleRoot;
        delete whitelistMerkleRoot;
        isOGMintActive = false;
        isWhitelistMintActive = false;
        isPublicMintActive = true;
        maxSupply = _maxSupply;
    }

    /**
     * @dev Returns the starting token ID.
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
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
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
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
     * @notice Sets the OG merkle root for the mint
     * @param _ogMerkleRoot The merkle root to set
     */
    function setOGMerkleRoot(bytes32 _ogMerkleRoot) external onlyOwner {
        ogMerkleRoot = _ogMerkleRoot;
    }

    /**
     * @notice Sets the Whitelist merkle root for the mint
     * @param _whitelistMerkleRoot The merkle root to set
     */
    function setWhitelistMerkleRoot(bytes32 _whitelistMerkleRoot)
        external
        onlyOwner
    {
        whitelistMerkleRoot = _whitelistMerkleRoot;
    }

    /**
     * @notice Sets the collection max supply
     * @param _maxSupply The max supply of the collection
     */
    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    /**
     * @notice Sets the max mints per wallet
     * @param _maxPerWallet The max per wallet (Keep mind its +1 n)
     */
    function setMaxPerWallet(uint256 _maxPerWallet) external onlyOwner {
        maxPerWallet = _maxPerWallet;
    }

    /**
     * @notice Sets price
     * @param _price price in wei
     */
    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    /**
     * @notice Owner Mints
     * @param _to The amount of reserves to collect
     * @param _amount The amount of reserves to collect
     */
    function ownerMint(address _to, uint256 _amount) external onlyOwner {
        _safeMint(_to, _amount);
    }

    /**
     * @notice Sets the active state for OG
     * @param _isOGMintActive The og state
     */
    function setOGActive(bool _isOGMintActive) external onlyOwner {
        isOGMintActive = _isOGMintActive;
    }

    /**
     * @notice Sets the active state for OG
     * @param _isWhitelistMintActive The og state
     */
    function setWhitelistActive(bool _isWhitelistMintActive)
        external
        onlyOwner
    {
        isWhitelistMintActive = _isWhitelistMintActive;
    }

    /**
     * @notice Sets the active state for OG
     * @param _isPublicMintActive The og state
     */
    function setPublicActive(bool _isPublicMintActive) external onlyOwner {
        isPublicMintActive = _isPublicMintActive;
    }

    /**
     * @notice Sets the reveal state
     * @param _isRevealed The reveal state
     */
    function setIsRevealed(bool _isRevealed) external onlyOwner {
        isRevealed = _isRevealed;
    }

    /**
     * @notice Sets the treasury recipient
     * @param _treasury The treasury address
     */
    function setTreasury(address _treasury) external onlyOwner {
        treasury = payable(_treasury);
    }

    /**
     * @notice Withdraws funds from contract
     */
    function withdraw() external onlyOwner {
        (bool success, ) = treasury.call{value: address(this).balance}("");
        require(success, "Failed to send to treasury.");
    }
}