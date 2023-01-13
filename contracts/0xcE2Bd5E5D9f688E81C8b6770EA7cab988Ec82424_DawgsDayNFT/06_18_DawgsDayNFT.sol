// SPDX-License-Identifier: MIT
// From https://www.quicknode.com/guides/smart-contract-development/how-to-mint-nfts-using-the-erc721a-implementation
pragma solidity ^0.8.13;

import "../Ownable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "../extensions/ERC721AQueryable.sol";
import "../interfaces/IERC4906.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract DawgsDayNFT is ERC721AQueryable, Ownable, DefaultOperatorFilterer, IERC4906, ERC2981 {

    uint32 public constant MAX_SUPPLY = 5555;
    uint64 public ALLOWLIST_START_TIME;
    uint64 public PUBLIC_START_TIME;

    bool public allowListActive = true;
    bool public publicMintActive = true;

    uint256 public allowListMintPrice = 0.025 ether;
    uint256 public publicMintPrice = 0.035 ether;

    address payable public teamWallet = payable(0x6Ee17b24c69dfDcad06E93E066A1911b263A5257);
    string public _baseTokenURI;
    string public _contractURI = "ipfs://QmZmWugXgQhZf9MHyHeQMzJreViPuMhwiic2m7Cpgo9dZm";

    bytes32 public merkleRoot = 0xe1b429e6dfa9e0c48d62c8affe3e5b03a2dcee0746f976669ffb15d80ed8119f;

    constructor(uint64 _startTime) ERC721A("Dawg's Day NFT", "DAWGS") {
        ALLOWLIST_START_TIME = _startTime;
        PUBLIC_START_TIME = _startTime + 7200;
        _setDefaultRoyalty(teamWallet, 1000);
    }

    // EXTERNAL

    function allowListMintEnabled(bool _paused) external onlyOwner {
        allowListActive = _paused;
    }

    function publicMintEnabled(bool _paused) external onlyOwner {
        publicMintActive = _paused;
    }

    function allowListMint(address to, uint256 quantity, bytes32[] calldata _merkleProof) external payable {
        require(allowListActive, "Allow list mint not active.");
        require(block.timestamp >= ALLOWLIST_START_TIME, "Allow list sale has not started.");
        require(block.timestamp < PUBLIC_START_TIME, "Allow list minting has concluded.");
        require(verifyAddress(_merkleProof), "Wallet not on allow list.");
        mintNFT(to, quantity);
    }

    function mint(address to, uint256 quantity) external payable {
        require(publicMintActive, "Public mint is not active.");
        require(block.timestamp >= PUBLIC_START_TIME, "Sale has not started.");
        mintNFT(to, quantity);
    }

    function gift(address receiver, uint amount) external onlyOwner {
        _safeMint(receiver, amount);
    }

    function giftBatch(address[] calldata receivers, uint[] calldata amounts) external onlyOwner {
        require(receivers.length == amounts.length, "Length mismatch.");
        for (uint256 i = 0; i < receivers.length; i++) {
            _safeMint(receivers[i], amounts[i]);
        }
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setContractURI(string calldata contractDataURI) external onlyOwner {
        _contractURI = contractDataURI;
    }

    function setMerkleRoot(bytes32 merkleRootHash) external onlyOwner {
        merkleRoot = merkleRootHash;
    }

    function setAllowListPrice(uint256 _price) external onlyOwner {
        allowListMintPrice = _price;
    }

    function setPublicPrice(uint256 _price) external onlyOwner {
        publicMintPrice = _price;
    }
    function setRoyalty(address _recipient, uint16 _royaltyFee) external onlyOwner {
        _setDefaultRoyalty(_recipient, _royaltyFee);
    }

    function setTeamWallet(address payable walletAddress) external onlyOwner {
        teamWallet = walletAddress;
    }
    function updateTokenMetadata(uint256 _tokenId) external onlyOwner {
        emit MetadataUpdate(_tokenId);
    }
    function updateBatchTokenMetadata(uint256 _fromTokenId, uint256 _toTokenId) external onlyOwner {
        emit BatchMetadataUpdate(_fromTokenId, _toTokenId);
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    // PUBLIC

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function getPrice() public view returns (uint256) {
        uint256 currentPrice = publicMintPrice;
        if (allowListActive && block.timestamp < PUBLIC_START_TIME) {
            currentPrice = allowListMintPrice;
        }
        return currentPrice;
    }

    function setApprovalForAll(address operator, bool approved) public virtual override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable virtual override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable virtual override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable virtual override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public payable virtual override(ERC721A, IERC721A) onlyAllowedOperator(from){
        super.safeTransferFrom(from, to, tokenId, _data);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721A, IERC721A, ERC2981) returns (bool) {
        return interfaceId == bytes4(0x49064906) || super.supportsInterface(interfaceId);
    }

    // INTERNAL

    function _baseURI() internal view override(ERC721A) returns (string memory) {
        return _baseTokenURI;
    }

    function mintNFT(address to, uint256 quantity) internal {
        require(_totalMinted() < MAX_SUPPLY, "Mint has completed.");
        require(_totalMinted() + quantity <= MAX_SUPPLY, "Quantity exceeds supply.");
        uint256 mintPrice = getPrice();
        require(msg.value >= quantity * mintPrice, "Insufficient funds.");
        _mint(to, quantity);
        teamWallet.transfer(msg.value);
    }

    // PRIVATE

    function verifyAddress(bytes32[] calldata _merkleProof) private view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }
}