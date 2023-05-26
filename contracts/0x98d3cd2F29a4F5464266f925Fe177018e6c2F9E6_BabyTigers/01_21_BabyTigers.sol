// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/ERC721A.sol";



contract BabyTigers is ERC721A, ReentrancyGuard, Ownable {

    // Minting Variables
    uint256 public mintPrice = 0.04 ether;
    uint256 public whitelistMintPrice = 0.03 ether;
    uint256 public maxPurchase = 20;
    uint256 public maxSupply = 7800;
    address public typicalTigersAddress;

    // Sale Status
    bool public saleIsActive = false;
    bool public holderSaleIsActive = false;
    bool public whitelistSaleIsActive = false;
    mapping(uint256 => bool) public claimedTypicalTigers;

    // Merkle Roots
    bytes32 private merkleRoot;

    // Metadata
    string _baseTokenURI = "ipfs://Qmc2Ub7TG1xRpESxVcYUBiEYZqefURErUf1XqYonPWQNuS/";
    bool public locked;

    // Events
    event SaleActivation(bool isActive);
    event HolderSaleActivation(bool isActive);
    event WhitelistSaleActivation(bool isActive);


    constructor(address _typicalTigersAddress) ERC721A("Baby Cub Tigers", "BCT") {
    typicalTigersAddress = _typicalTigersAddress;
    }

    // Merkle Proofs
    function setMerkleRoot(bytes32 _root) external onlyOwner {
        merkleRoot = _root;
    }
    function _leaf(address _account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account));
    }

    function isWhitelisted(
        address _account,
        bytes32[] calldata _proof
    ) public view returns (bool) {
        return MerkleProof.verify(_proof, merkleRoot, _leaf(_account));
    }

    //Holder status validation

    function isTypicalTigerAvailable(uint256 _tokenId) public view returns(bool) {
        return claimedTypicalTigers[_tokenId] != true;
    }

    function isOwnerOfValidTigers(uint256[] calldata _typicalTigerIds, address _account) internal view {
        ERC721Enumerable typicalTigers = ERC721Enumerable(typicalTigersAddress);
        require(typicalTigers.balanceOf(_account) > 0, "NO_TT_TOKENS");
        for (uint256 i = 0; i < _typicalTigerIds.length; i++) {
            require(isTypicalTigerAvailable(_typicalTigerIds[i]), "TT_ALREADY_CLAIMED");
            require(typicalTigers.ownerOf(_typicalTigerIds[i]) == _account, "NOT_TT_OWNER");
        }
    }

    // Minting
    function ownerMint(address _to, uint256 _count) external onlyOwner {
        require(
            totalSupply() + _count <= maxSupply,
            "SOLD_OUT"
        );
        _safeMint(_to, _count);
    }

    function holderMint(uint256[] calldata _typicalTigerIds, uint256 _count) external nonReentrant {
        require(holderSaleIsActive, "HOLDER_SALE_INACTIVE");
        require(
            _count == _typicalTigerIds.length,
            "INSUFFICIENT_TT_TOKENS"
        );
        require(
            totalSupply() + _count <= maxSupply,
            "SOLD_OUT"
        );
        isOwnerOfValidTigers(_typicalTigerIds, msg.sender);
        for (uint256 i = 0; i < _typicalTigerIds.length; i++) {
            claimedTypicalTigers[_typicalTigerIds[i]] = true;
        }
        _safeMint(msg.sender, _count);
    }

    function whitelistMint(
        uint256 _count,
        bytes32[] calldata _proof
    ) external payable {
        require(whitelistSaleIsActive, "WHITELIST_SALE_INACTIVE");
        require(
            isWhitelisted(msg.sender, _proof),
            "NOT_WHITELISTED"
        );
        require(
            totalSupply() + _count <= maxSupply,
            "SOLD_OUT"
        );
        require(
            whitelistMintPrice * _count <= msg.value,
            "INCORRECT_ETHER_VALUE"
        );

            _safeMint(msg.sender, _count);

    }

    function mint(uint256 _count) external payable nonReentrant {
        require(saleIsActive, "SALE_INACTIVE");

        require(_count <= maxPurchase, "MAX_PURCHASE_LIMIT");

        require(
            totalSupply() + _count <= maxSupply,
            "SOLD_OUT"
        );
        require(
            mintPrice * _count <= msg.value,
            "INCORRECT_ETHER_VALUE"
        );

                _safeMint(msg.sender, _count);
        }


    function toggleHolderSaleStatus() external onlyOwner {
        holderSaleIsActive = !holderSaleIsActive;
        emit HolderSaleActivation(holderSaleIsActive);
    }

    function toggleWhitelistSaleStatus() external onlyOwner {
        whitelistSaleIsActive = !whitelistSaleIsActive;
        emit WhitelistSaleActivation(whitelistSaleIsActive);
    }

    function toggleSaleStatus() external onlyOwner {
        saleIsActive = !saleIsActive;
        emit SaleActivation(saleIsActive);
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setWhitelistMintPrice(uint256 _mintPrice) external onlyOwner {
        whitelistMintPrice = _mintPrice;
    }

    function setMaxPurchase(uint256 _maxPurchase) external onlyOwner {
        maxPurchase = _maxPurchase;
    }

    function lockMetadata() external onlyOwner {
        locked = true;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function getWalletOfOwner(address owner) external view returns (uint256[] memory) {
    unchecked {
        uint256[] memory a = new uint256[](balanceOf(owner));
        uint256 end = _currentIndex;
        uint256 tokenIdsIdx;
        address currOwnershipAddr;
        for (uint256 i; i < end; i++) {
            TokenOwnership memory ownership = _ownerships[i];
            if (ownership.burned) {
                continue;
            }
            if (ownership.addr != address(0)) {
                currOwnershipAddr = ownership.addr;
            }
            if (currOwnershipAddr == owner) {
                a[tokenIdsIdx++] = i;
            }
        }
        return a;
    }
    }

    function getTotalSupply() external view returns (uint256) {
        return totalSupply();
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        require(!locked, "METADATA_LOCKED");
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory){
        return string(abi.encodePacked(super.tokenURI(tokenId), ".json"));
    }

    function _startTokenId() internal view virtual override returns (uint256){
        return 1;
    }


}