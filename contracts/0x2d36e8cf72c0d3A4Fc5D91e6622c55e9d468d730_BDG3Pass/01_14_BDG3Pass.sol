// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";

/*
 *             ╔═══════╗
 *            █|       |█
 *           █           █
 *          █    ╔══      █
 *          █  ╔╝         █
 *          █ ╔╝═══       █
 *           █           █
 *             @@@@@@@@@
 *
 * @title ERC721 token for the BDG3 Pass
 * @author - https://twitter.com/theincubator_
 */
contract BDG3Pass is ERC721A, ERC721ABurnable, ERC721AQueryable, Ownable, IERC2981 {
    uint256 public presaleMaxSupply = 1200;
    uint256 public maxSupply = 1200;
    uint256 public publicPrice = 0.12 ether;
    uint256 public presalePrice = publicPrice;
    uint256 public maxPresaleMintPerWallet = 1;
    uint256 public maxMintPerWallet = 2;

    bool public isPublicSaleActive = false;
    bool public isWaitlistSaleActive = false;
    bool private _isPresaleActive = false;

    bytes32 public mintlistMerkleRoot;
    bytes32 public waitlistMerkleRoot;

    string private _baseTokenURI;

    address public royaltiesAddress;
    uint256 public royaltiesBasisPoints;
    uint256 private constant ROYALTY_DENOMINATOR = 10_000;

    address payable public immutable incubator;
    address payable public bdge;

    uint256 private _amountReserved;

    string private provenanceHash;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory baseTokenURI,
        address _royaltiesAddress,
        uint256 _royaltiesBasisPoints,
        address _incubator,
        address _bdge,
        string memory _provenanceHash
    ) ERC721A(_name, _symbol) {
        _baseTokenURI = baseTokenURI;
        royaltiesAddress = _royaltiesAddress;
        royaltiesBasisPoints = _royaltiesBasisPoints;
        incubator = payable(_incubator);
        bdge = payable(_bdge);
        provenanceHash = _provenanceHash;
    }

    struct MintContext {
        bool isPresaleActive;
        bool isPresaleSoldOut;
        bool isMintListSet;
        uint256 presalePrice;
        uint256 maxPresaleMintPerWallet;
        uint256 presaleMaxSupply;
        bool isWaitlistSaleActive;
        bool isPublicSaleActive;
        uint256 publicPrice;
        uint256 maxMintPerWallet;
        uint256 maxSupply;
        uint256 currentMintCount;
        uint256 currentUserMintCount;
    }

    function getMintContext() external view returns (MintContext memory) {
        return
            MintContext({
                isPresaleSoldOut: _totalNonReservedMinted() >= presaleMaxSupply,
                isPresaleActive: isPresaleActive(),
                isMintListSet: mintlistMerkleRoot[0] != 0,
                presalePrice: presalePrice,
                maxPresaleMintPerWallet: maxPresaleMintPerWallet,
                presaleMaxSupply: presaleMaxSupply,
                isWaitlistSaleActive: isWaitlistSaleActive,
                isPublicSaleActive: isPublicSaleActive,
                publicPrice: publicPrice,
                maxMintPerWallet: maxMintPerWallet,
                maxSupply: maxSupply,
                currentMintCount: _totalMinted(),
                currentUserMintCount: _numberMinted(msg.sender)
            });
    }

    function mintPresale(bytes32[] calldata proof, uint256 quantity) public payable {
        require(quantity + _totalNonReservedMinted() <= presaleMaxSupply, "max presale supply reached");
        require(quantity + _totalMinted() <= maxSupply, "max supply reached");
        require(_isPresaleActive, "presale is not active");
        require(isOnMintlist(proof), "not on the mintlist");

        uint256 totalCost = presalePrice * quantity;
        require(msg.value >= totalCost, "not enough money");
        require(quantity + _numberMinted(msg.sender) <= maxPresaleMintPerWallet, "can't presale mint this many");
        require(tx.origin == msg.sender, "can't mint from a smart contract");

        _mint(msg.sender, quantity);

        if (msg.value > totalCost) {
            payable(msg.sender).transfer(msg.value - totalCost);
        }
    }

    function mintWaitlist(bytes32[] calldata proof, uint256 quantity) public payable {
        require(quantity + _totalNonReservedMinted() <= presaleMaxSupply, "max presale supply reached");
        require(quantity + _totalMinted() <= maxSupply, "max supply reached");
        require(isWaitlistSaleActive, "waitlist is not active");
        require(isOnWaitlist(proof), "not on the waitlist");

        uint256 totalCost = presalePrice * quantity;
        require(msg.value >= totalCost, "not enough money");
        require(quantity + _numberMinted(msg.sender) <= maxPresaleMintPerWallet, "can't presale mint this many");
        require(tx.origin == msg.sender, "can't mint from a smart contract");

        _mint(msg.sender, quantity);

        if (msg.value > totalCost) {
            payable(msg.sender).transfer(msg.value - totalCost);
        }
    }

    function mintPublic(uint256 quantity) public payable {
        require(quantity + _totalMinted() <= maxSupply, "max supply reached");
        require(isPublicSaleActive, "sale is not active");

        uint256 totalCost = publicPrice * quantity;
        require(msg.value >= totalCost, "not enough money");
        require(quantity + _numberMinted(msg.sender) <= maxMintPerWallet, "can't mint this many");
        require(tx.origin == msg.sender, "can't mint from a smart contract");

        _mint(msg.sender, quantity);

        if (msg.value > totalCost) {
            payable(msg.sender).transfer(msg.value - totalCost);
        }
    }

    function reserve(address[] calldata receivers, uint256[] calldata quantities) external onlyOwner {
        require(receivers.length == quantities.length, "need to supply an equal amount of receivers and quantities");
        for (uint256 i = 0; i < receivers.length; i++) {
            _amountReserved += quantities[i];
            _safeMint(receivers[i], quantities[i]);
        }
    }

    function isOnMintlist(bytes32[] calldata proof) public view returns (bool) {
        return MerkleProof.verify(proof, mintlistMerkleRoot, keccak256(abi.encodePacked(msg.sender)));
    }

    function isOnWaitlist(bytes32[] calldata proof) public view returns (bool) {
        return MerkleProof.verify(proof, waitlistMerkleRoot, keccak256(abi.encodePacked(msg.sender)));
    }

    function togglePresaleActive() external onlyOwner {
        _isPresaleActive = !_isPresaleActive;
    }

    function toggleWaitlistSaleActive() external onlyOwner {
        isWaitlistSaleActive = !isWaitlistSaleActive;
    }

    function togglePublicSaleActive() external onlyOwner {
        isPublicSaleActive = !isPublicSaleActive;
    }

    function isPresaleActive() public view returns (bool) {
        return _isPresaleActive && _totalNonReservedMinted() < presaleMaxSupply;
    }

    function transitionToWaitlistSale() external onlyOwner {
        _isPresaleActive = false;
        isWaitlistSaleActive = true;
        isPublicSaleActive = false;
    }

    function transitionToPublicSale() external onlyOwner {
        _isPresaleActive = false;
        isWaitlistSaleActive = false;
        isPublicSaleActive = true;
    }

    function setRoyaltiesAddress(address _royaltiesAddress) external onlyOwner {
        royaltiesAddress = _royaltiesAddress;
    }

    function setRoyaltiesBasisPoints(uint256 _royaltiesBasisPoints) external onlyOwner {
        require(_royaltiesBasisPoints < royaltiesBasisPoints, "New royalty amount must be lower");
        royaltiesBasisPoints = _royaltiesBasisPoints;
    }

    /**
     * @dev See {IERC2981-royaltyInfo}.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "Non-existent token");
        return (royaltiesAddress, (salePrice * royaltiesBasisPoints) / ROYALTY_DENOMINATOR);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721A) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    function withdraw() external onlyOwner {
        (bool incubatorSuccess, ) = incubator.call{ value: (address(this).balance * 10) / 100 }("");
        require(incubatorSuccess, "unable to send incubator value, recipient may have reverted");

        (bool success, ) = bdge.call{ value: address(this).balance }("");
        require(success, "unable to send client value, recipient may have reverted");
    }

    function setMintlistMerkleRoot(bytes32 newMintlistMerkleRoot) external onlyOwner {
        mintlistMerkleRoot = newMintlistMerkleRoot;
    }

    function setWaitlistMerkleRoot(bytes32 newWaitlistMerkleRoot) external onlyOwner {
        waitlistMerkleRoot = newWaitlistMerkleRoot;
    }

    function setPresalePrice(uint256 newPresalePrice) external onlyOwner {
        if (_totalNonReservedMinted() > 0) {
            require(newPresalePrice < presalePrice, "can't raise the price after the mint has started");
        }
        require(newPresalePrice <= publicPrice, "can't charge more for presale than the public sale");
        presalePrice = newPresalePrice;
    }

    function setMaxPresaleMintPerWallet(uint256 newMaxPresaleMintPerWallet) external onlyOwner {
        maxPresaleMintPerWallet = newMaxPresaleMintPerWallet;
    }

    function setPresaleMaxSupply(uint256 newPresaleMaxSupply) external onlyOwner {
        if (_totalNonReservedMinted() > 0) {
            require(newPresaleMaxSupply < presaleMaxSupply, "can't raise the max supply once the mint has started");
        }
        require(_totalNonReservedMinted() != presaleMaxSupply, "presale max supply already reached");
        presaleMaxSupply = newPresaleMaxSupply;
    }

    function setPublicPrice(uint256 newPublicPrice) external onlyOwner {
        if (_totalNonReservedMinted() > 0) {
            require(newPublicPrice < publicPrice, "can't raise the price after the mint has started");
        }
        publicPrice = newPublicPrice;
    }

    function setMaxMintPerWallet(uint256 newMaxMintPerWallet) public onlyOwner {
        maxMintPerWallet = newMaxMintPerWallet;
    }

    function setMaxSupply(uint256 newMaxSupply) external onlyOwner {
        if (_totalNonReservedMinted() > 0) {
            require(newMaxSupply < maxSupply, "can't raise the max supply once the mint has started");
        }
        require(_totalMinted() != maxSupply, "max supply already reached");
        maxSupply = newMaxSupply;
    }

    function setBdgeVault(address payable _bdge) external onlyOwner {
        bdge = _bdge;
    }

    function setBaseURI(string memory baseTokenURI) external onlyOwner {
        _baseTokenURI = baseTokenURI;
    }

    /**
     * @dev - See {ERC721A-_baseURI}.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev - See {ERC721A-_startTokenId}.
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _totalNonReservedMinted() internal view returns (uint256) {
        // Counter underflow is impossible as _currentIndex does not decrement,
        // and it is initialized to _startTokenId()
        unchecked {
            return _totalMinted() - _amountReserved;
        }
    }
}