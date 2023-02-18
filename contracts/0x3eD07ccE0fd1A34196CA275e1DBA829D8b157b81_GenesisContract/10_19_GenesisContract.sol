// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

/*
    ERC721A Upgradeable: https://github.com/chiru-labs/ERC721A-Upgradeable
    Documentation: https://chiru-labs.github.io/ERC721A/#/upgradeable
    Proxy Standard: https://eips.ethereum.org/EIPS/eip-2535
*/
import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";

/*
    OpenZeppelin Upgradeable: https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable
*/
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";

// Operator Filter
import "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";

contract GenesisContract is ERC721AUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable, DefaultOperatorFiltererUpgradeable {

    uint256 public constant MAX_SUPPLY = 502;
    uint256 public constant MAX_MINTS_PER_ADDRESS = 2;

    // Determines if the sale is open
    bool private saleOpen;
    
    // Whitelist enabled
    bool private whitelistEnabled;

    // Merkle proof hash
    bytes32 public merkleTreeRootHash;
    
    // The cost to mint
    uint256 private mintPrice;

    // Max Mint Mapping
    mapping (address => uint256) private mintCounts;

    // Metadata base URI
    string private metadataBaseURI;

    /*
        In upgradeable contract our constructor is this initialize method.
    */
    function initialize() initializerERC721A initializer public {
        __ERC721A_init("ETH Games Genesis Pass", "ETHGGP");

        // Ownable for onlyOwner modifier
        __Ownable_init();

        // ReentrancyGuard for nonReentrant modifier
        __ReentrancyGuard_init();

        // Operator filter
        __DefaultOperatorFilterer_init();

        // Variables from contract should be initialized here
        saleOpen = true;
        whitelistEnabled = true;
        merkleTreeRootHash = 0xaa1901035ebd1398f1553221f802a92974870d7718b16e4acb503e8ed9dc99af;
        mintPrice = 0.01 ether; // TODO: CHANGE!
        metadataBaseURI = "https://d36omlv0sk4i5.cloudfront.net/";
    }

    // === Mint ===

    function mintToken(uint256 quantity, bytes32[] calldata merkleProof) callerIsUser nonReentrant external payable {
        // Sale has to be open
        require(saleOpen, "The sale is not open");

        // Check if given quantity is valid
        require(quantity > 0, "Token quantity must be positive");

        // Check if this purchase would exceed the max supply
        uint256 supplyAfterMint = SafeMathUpgradeable.add(totalSupply(), quantity);
        require(supplyAfterMint <= MAX_SUPPLY, "Your mint would exceed the max supply");

        // If whitelist is enabled, check merkle proof
        if (whitelistEnabled) {
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(MerkleProofUpgradeable.verify(merkleProof, merkleTreeRootHash, leaf), "Your address is not whitelisted");
        }

        // Max mint check
        uint256 mintCount = mintCounts[msg.sender];
        uint256 newMintCount = SafeMathUpgradeable.add(mintCount, quantity);
        require(newMintCount <= MAX_MINTS_PER_ADDRESS, "You have exceeded the max mints per address");

        // Check enough Ether sent
        require(msg.value >= mintPrice, "Not enough ether sent");

        // Mint
        _mint(msg.sender, quantity);

        // Increment mintCount
        mintCounts[msg.sender] = newMintCount;
    }

    // === Registry Filter ===

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // === Airdrop ===

    function performAirdrop(address[] calldata addresses, uint256 amount) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            address airdropAddress = addresses[i];
            _mint(airdropAddress, amount);
        }
    }

    // === Modifiers ===

    // Makes sure the caller of the function is not another contract
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller should be an user");
        _;
    }

    // === Only owner methods ===

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{ value: address(this).balance }("");
        require(success, "Transfer failed.");
    }

    function setSaleOpen(bool _saleOpen) external onlyOwner {
        saleOpen = _saleOpen;
    }

    function setWhitelistEnabled(bool _enabled) external onlyOwner {
        whitelistEnabled = _enabled;
    }

    function setMerkleTreeRootHash(bytes32 _hash) external onlyOwner {
        merkleTreeRootHash = _hash;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setMetadataBaseURI(string calldata _metadataBaseURI) external onlyOwner {
        metadataBaseURI = _metadataBaseURI;
    }

    // === Public methods ===

    function isSaleOpen() public view returns (bool) {
        return saleOpen;
    }

    function isWhitelistEnabled() public view returns (bool) {
        return whitelistEnabled;
    }

    function getMerkleTreeRootHash() public view returns (bytes32) {
        return merkleTreeRootHash;
    }

    function getMintPrice() public view returns (uint256) {
        return mintPrice;
    }

    // === Metadata ===

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        return string(abi.encodePacked(metadataBaseURI, "token.json"));
    }

}