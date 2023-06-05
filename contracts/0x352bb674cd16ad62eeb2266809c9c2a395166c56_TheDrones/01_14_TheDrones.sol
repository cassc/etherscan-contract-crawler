// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract TheDrones is ERC721A, Ownable, Pausable, ReentrancyGuard {
    using Strings for uint256;

    enum MintPhase {
        CLOSED,
        OG,
        ALLOW_LIST,
        PUBLIC
    }

    // Configuration: Metadata
    string public baseURI;

    // Configuration: Opensea proxy
    address public immutable proxyRegistryAddress;
    mapping(address => bool) public projectProxy;

    // Configuration: General
    uint256 public immutable maxSupply;
    uint256 public price = 0.16 ether;
    MintPhase public phase = MintPhase.CLOSED;

    // Configuration: OG Mint
    bytes32 public ogMerkleRoot;
    uint256 public maxPerOgMinter = 4; // Actually 3, this is to avoid using <=

    // Configuration: Allowlist Mint
    bytes32 public allowlistMerkleRoot;
    uint256 public maxPerAllowlistMinter = 3; // Actually 2, this is to avoid using <=

    // Configuration: Public Mint
    uint256 public maxPerPublicTx = 6; // Actually 5, this is to avoid using <=

    // Withdraw accounts
    address private constant WALLET_D = 0x9193052B1843d7F2cAF37728756F062922eCd51d;
    address private constant WALLET_C = 0x9aBC658a4d3E82585Fb38e6D695a017e50D96564;
    address private constant WALLET_S = 0x55429B1f76bfEC0aEc3Ce0b444E208a96d916fe5;
    address private constant WALLET_K = 0x8653CB49dEB429745eD0581dA763D1014e2d0E03;

    constructor(
        string memory _initBaseUri,
        uint256 _maxSupply,
        address _proxyRegistryAddress
    ) ERC721A("DRONES", "DRONES") {
        setBaseURI(_initBaseUri);
        maxSupply = _maxSupply;
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    // ERC721A overrides ===========================================================================

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // When the contract is paused, all token transfers are prevented in case of emergency
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 tokenId,
        uint256 quantity
    ) internal override(ERC721A) whenNotPaused {
        super._beforeTokenTransfers(from, to, tokenId, quantity);
    }

    // Admin functions =============================================================================

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setOgMerkleRoot(bytes32 _ogMerkleRoot) external onlyOwner {
        ogMerkleRoot = _ogMerkleRoot;
    }

    function setAllowlistMerkleRoot(bytes32 _allowlistMerkleRoot) external onlyOwner {
        allowlistMerkleRoot = _allowlistMerkleRoot;
    }

    function setMaxPerOgMinter(uint256 _maxPerOgMinter) external onlyOwner {
        maxPerOgMinter = _maxPerOgMinter;
    }

    function setMaxPerAllowlistMinter(uint256 _maxPerAllowlistMinter) external onlyOwner {
        maxPerAllowlistMinter = _maxPerAllowlistMinter;
    }

    function setMaxPerPublicTx(uint256 _maxPerPublicTx) external onlyOwner {
        maxPerPublicTx = _maxPerPublicTx;
    }

    function setPhase(MintPhase _mintPhase) external onlyOwner {
        phase = _mintPhase;
    }

    // Update price in case of major ETH fluctuations
    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function flipProxyState(address proxyAddress) public onlyOwner {
        projectProxy[proxyAddress] = !projectProxy[proxyAddress];
    }

    /* solhint-disable avoid-low-level-calls */
    function withdraw() external nonReentrant onlyOwner {
        uint256 currentBalance = address(this).balance;

        (bool successC, ) = payable(WALLET_C).call{ value: (currentBalance * 10) / 100 }("");
        require(successC, "Failed to send to C");

        (bool successD, ) = payable(WALLET_D).call{ value: (currentBalance * 13) / 100 }("");
        require(successD, "Failed to send to D");

        (bool successS, ) = payable(WALLET_S).call{ value: (currentBalance * 25) / 100 }("");
        require(successS, "Failed to send to S");

        (bool successK, ) = payable(WALLET_K).call{ value: address(this).balance }("");
        require(successK, "Failed to send to K");
    } /* solhint-enable avoid-low-level-calls */

    // Public functions ============================================================================

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    function tokensOfOwner(address owner) public view returns (uint256[] memory) {
        uint256 holdingAmount = balanceOf(owner);
        uint256 currSupply = _currentIndex;
        uint256 tokenIdsIdx;
        address currOwnershipAddr;

        uint256[] memory list = new uint256[](holdingAmount);

        unchecked {
            for (uint256 i = _startTokenId(); i < currSupply; i++) {
                TokenOwnership memory ownership = _ownerships[i];

                if (ownership.burned) {
                    continue;
                }

                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }

                if (currOwnershipAddr == owner) {
                    list[tokenIdsIdx++] = i;
                }

                if (tokenIdsIdx == holdingAmount) {
                    break;
                }
            }
        }

        return list;
    }

    // Minting functions ===========================================================================

    function _mintPresale(
        address buyer,
        uint256 quantity,
        bytes32[] calldata proof,
        bytes32 merkleRoot,
        uint256 limit
    ) internal {
        string memory payload = string(abi.encodePacked(buyer));
        require(_verify(merkleRoot, _leaf(payload), proof), "Address is not allowed during Pre-sale");
        require(quantity < limit, "Exceeds Pre-sale per transaction limit");
        require(numberMinted(_msgSender()) + quantity < limit, "Exceeds total Pre-sale purchase limit");
        require(price * quantity == msg.value, "Incorrect amount of funds provided");

        _safeMint(buyer, quantity);
    }

    function mintOg(uint256 quantity, bytes32[] calldata proof) external payable nonReentrant {
        require(phase == MintPhase.OG || phase == MintPhase.ALLOW_LIST, "OG sale is not active");

        _mintPresale(_msgSender(), quantity, proof, ogMerkleRoot, maxPerOgMinter);
    }

    function mintAllowlist(uint256 quantity, bytes32[] calldata proof) external payable nonReentrant {
        require(phase == MintPhase.ALLOW_LIST, "Allowlist sale is not active");

        _mintPresale(_msgSender(), quantity, proof, allowlistMerkleRoot, maxPerAllowlistMinter);
    }

    function mintPublic(uint256 quantity) external payable nonReentrant {
        require(phase == MintPhase.PUBLIC, "Public sale is not active");
        require(totalMinted() + quantity <= maxSupply, "Exceeds max supply");
        require(quantity < maxPerPublicTx, "Exceeds max per transaction");
        require(price * quantity == msg.value, "Incorrect amount of funds provided");

        _safeMint(_msgSender(), quantity);
    }

    // Merkle tree functions =======================================================================

    function _leaf(string memory payload) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(payload));
    }

    function _verify(
        bytes32 merkleRoot,
        bytes32 leaf,
        bytes32[] memory proof
    ) internal pure returns (bool) {
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    // Opensea approval fee removal ================================================================

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator || projectProxy[operator]) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }
}

// solhint-disable-next-line no-empty-blocks
contract OwnableDelegateProxy {

}

contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}