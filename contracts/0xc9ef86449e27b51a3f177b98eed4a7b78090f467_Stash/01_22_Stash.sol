// SPDX-License-Identifier: MIT
// Toy Boogers & Pagzi Tech Inc.
pragma solidity ^0.8.16;

import "erc721psi/contracts/ERC721PsiUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./ERC721Stashable.sol";

contract Stash is
    ERC2981Upgradeable,
    OwnableUpgradeable,
    ERC721PsiUpgradeable,
    ERC721Stashable
{
    using BitMaps for BitMaps.BitMap;

    IERC721 public constant TOY =
        IERC721(0xBF662A0e4069b58dFB9bceBEBaE99A6f13e06f5a);
    IERC721 public constant KIT =
        IERC721(0x5ff1863753C1920C38c7BaE94576f2831eF99695);

    uint256 constant PRICE_PER_TOKEN = 0.025 ether;
    error Ended();
    error NotStarted();
    error NotEOA();
    error MintTooManyAtOnce();
    error InvalidSignature();
    error ZeroQuantity();
    error ExceedMaxSupply();
    error ExceedAllowedQuantity();
    error NotEnoughETH();
    error TicketUsed();

    mapping(address => bool) public operatorProxies;
    address public signer;
    struct SaleParam {
        uint64 startTime;
        uint64 endTime;
        uint64 maxSupply;
        uint64 claims;
    }
    SaleParam public saleParams;

    // Token Ids are continuous, using bitmap to save gas.
    BitMaps.BitMap toyClaimed;
    BitMaps.BitMap kitClaimed;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers(); // enhanced security
    }

    function initialize() public initializer {
        __ERC2981_init();
        __ERC721Psi_init("Toy Stash", "STASH");
        __Ownable_init();
        setPublicSale(1661014800, 1662210000, 4444, 11111);
        // Start: Saturday, August 20, 2022 5:00:00 PM GMT => 1661014800
        // Close: Saturday, September 3, 2022 1:00:00 PM GMT => 1662210000
        signer = address(0xe36f2696ddda39B31cE57B115ccCE65b21223EBa);
        _setDefaultRoyalty(0x6ed5a435495480774Dfc44cc5BC85333f1b0646A, 500);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return "https://toystash.nftapi.art/meta/";
    }

    modifier onlyEOA() {
        if (msg.sender != tx.origin) {
            revert NotEOA();
        }
        _;
    }

    modifier onlySigner() {
        require(msg.sender == signer, "must call by signer");
        _;
    }

    modifier checkSupply(uint256 quantity) {
        // quantity zero check
        if (quantity == 0) {
            revert ZeroQuantity();
        }
        // supply check
        if ((_minted + saleParams.claims + quantity) > saleParams.maxSupply) {
            revert ExceedMaxSupply();
        }
        _;
    }

    modifier checkSupplyClaim(uint256 quantity) {
        // quantity zero check
        if (quantity == 0) {
            revert ZeroQuantity();
        }
        // supply check
        if ((_minted + quantity) > saleParams.maxSupply) {
            revert ExceedMaxSupply();
        }
        _;
    }

    /**
    
        Stashing related functionality.

     */
    function setStashingEnable(bool enableStashing) external onlyOwner {
        _setStashingEnable(enableStashing);
    }

    function kickFromStash(uint256 tokenId) external onlyOwner {
        _kickStashing(tokenId);
    }

    function swapStashOperator(address operator) external onlyOwner {
        _swapOperator(operator);
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        for (
            uint256 tokenId = startTokenId;
            tokenId < startTokenId + quantity;
            tokenId++
        ) {
            _transferCheck(tokenId);
        }
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    /**
    
        Stashing-based approval control: The users cannot approve their token if it is Stashing.

     */

    function approve(address to, uint256 tokenId) public override {
        _transferCheck(tokenId);
        super.approve(to, tokenId);
    }

    /**
    
        Operator control and auto approvals.

     */
    function isApprovedForAll(address _owner, address operator)
        public
        view
        override(ERC721PsiUpgradeable)
        returns (bool)
    {
        if (operatorProxies[operator]) return true;
        return super.isApprovedForAll(_owner, operator);
    }

    function swapOperatorProxies(address _proxyAddress) public onlyOwner {
        operatorProxies[_proxyAddress] = !operatorProxies[_proxyAddress];
    }

    function devMint(address to, uint256 quantity)
        external
        checkSupplyClaim(quantity)
        onlyOwner
    {
        _mint(to, quantity);
    }

    function batchIsClaimed(
        uint256[] calldata tokenIdsTOY,
        uint256[] calldata tokenIdsKIT
    ) public view returns (bool[] memory, bool[] memory) {
        bool[] memory claimedTOY = new bool[](tokenIdsTOY.length);
        bool[] memory claimedKIT = new bool[](tokenIdsKIT.length);

        for (uint256 i = 0; i < tokenIdsTOY.length; i++) {
            uint256 tokenId = tokenIdsTOY[i];
            claimedTOY[i] = isClaimedByToy(tokenId);
        }

        for (uint256 i = 0; i < tokenIdsKIT.length; i++) {
            uint256 tokenId = tokenIdsKIT[i];
            claimedKIT[i] = isClaimedByKit(tokenId);
        }

        return (claimedTOY, claimedKIT);
    }

    function isClaimedByToy(uint256 tokenId) public view returns (bool) {
        return toyClaimed.get(tokenId);
    }

    function isClaimedByKit(uint256 tokenId) public view returns (bool) {
        return kitClaimed.get(tokenId);
    }

    // Make sure the tokenIds are all unclaimed ones. Up to 11111. 4444 max.
    function claim(
        uint256[] calldata tokenIdsTOY,
        uint256[] calldata tokenIdsKIT
    ) external checkSupplyClaim(tokenIdsTOY.length + tokenIdsKIT.length) {
        // timestamp check
        if (block.timestamp < saleParams.startTime) {
            revert NotStarted();
        }
        if (block.timestamp > saleParams.endTime) {
            revert Ended();
        }
        for (uint256 i = 0; i < tokenIdsTOY.length; i++) {
            uint256 tokenId = tokenIdsTOY[i];
            require(!isClaimedByToy(tokenId), "Claimed");
            require(TOY.ownerOf(tokenId) == msg.sender, "Not owner");
            toyClaimed.set(tokenId);
        }
        for (uint256 i = 0; i < tokenIdsKIT.length; i++) {
            uint256 tokenId = tokenIdsKIT[i];
            require(!isClaimedByKit(tokenId), "Claimed");
            require(KIT.ownerOf(tokenId) == msg.sender, "Not owner");
            kitClaimed.set(tokenId);
        }
        uint64 qty = uint64(tokenIdsTOY.length + tokenIdsKIT.length);
        _mint(msg.sender, qty);
        saleParams.claims -= qty;
    }

    /// @param quantity Amount of NFT to be minted.
    /// @param allowedQuantity Maximum allowed NFTs to be minted from a given amount.
    /// @param startTime The start time of the mint.
    /// @param endTime The end time of the mint.
    /// @param signature The NFT can only be minted with the valid signature.
    function mint(
        uint256 quantity,
        uint256 allowedQuantity,
        uint256 startTime,
        uint256 endTime,
        bytes calldata signature
    ) external payable onlyEOA checkSupply(quantity) {

        // timestamp check
        if (block.timestamp < startTime) {
            revert NotStarted();
        }

        // price check
        if (msg.value < quantity * PRICE_PER_TOKEN) {
            revert NotEnoughETH();
        }

        // signature check
        // The address of the contract is specified in the signature. This prevents the replay attact accross contracts.
        bytes32 hash = ECDSAUpgradeable.toEthSignedMessageHash(
            keccak256(
                abi.encodePacked(
                    msg.sender,
                    allowedQuantity,
                    startTime,
                    endTime,
                    address(this)
                )
            )
        );

        if (ECDSAUpgradeable.recover(hash, signature) != signer) {
            revert InvalidSignature();
        }

        // mint
        _mint(msg.sender, quantity);
    }

    function setPublicSale(
        uint64 startTime,
        uint64 endTime,
        uint64 claims,
        uint64 maxSupply
    ) public onlyOwner {
        saleParams.startTime = startTime;
        saleParams.endTime = endTime;
        saleParams.claims = claims;
        saleParams.maxSupply = maxSupply;
    }

    function setSigner(address signer_) external onlyOwner {
        signer = signer_;
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(0x6ed5a435495480774Dfc44cc5BC85333f1b0646A).transfer(
            (balance * 800) / 1000
        );
        payable(0x2d0F4bcD4D2f08FAbD5a9e6Ed7c7eE86aFC3B73f).transfer(
            (balance * 200) / 1000
        );
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721PsiUpgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}