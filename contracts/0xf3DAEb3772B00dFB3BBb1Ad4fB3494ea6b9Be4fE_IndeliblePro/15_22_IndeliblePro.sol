// SPDX-License-Identifier: MIT
// Indelible Labs LLC

pragma solidity ^0.8.17;

import "./ERC721X.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "solady/src/utils/Base64.sol";
import "./interfaces/IIndelibleProRenderer.sol";
import "./interfaces/IBurnedKevins.sol";

contract IndeliblePro is ERC721X, DefaultOperatorFilterer, ReentrancyGuard, Ownable {
    IERC721 public OnChainKevin;
    address internal burnAddress = 0x000000000000000000000000000000000000dEaD;

    struct ContractData {
        string name;
        string description;
        string image;
        string banner;
        string website;
        uint royalties;
        string royaltiesRecipient;
    }

    mapping(uint => address[]) private _chunks;
    mapping(address => uint) private _tier1TokensMinted;

    uint private constant MAX_SUPPLY_TIER_1 = 2000;
    uint private constant MAX_SUPPLY_TIER_2 = 2000;
    
    bytes32 private merkleRoot;
    uint public maxSupplyTier1Limit = 2000;
    uint public maxPerWallet = 1;
    uint public totalTier1Minted;
    uint public totalTier2Minted;
    uint public mintPrice = 0.35 ether;
    string public baseURI = "";
    bool public isAllowListMintActive;
    bool public isPublicMintActive;
    bool public isTier2MintActive;
    address public renderContractAddress;
    address public burnedKevinsContractAddress;

    ContractData public contractData = ContractData(
        "Indelible Pro",
        "Indelible Pro grants holders special access to products and services by Indelible Labs.",
        "https://app.indelible.xyz/assets/images/indelible-pro.gif",
        "https://app.indelible.xyz/assets/images/indelible-pro-banner.png",
        "https://indelible.xyz",
        1000,
        "0x29FbB84b835F892EBa2D331Af9278b74C595EDf1"
    );

    constructor() ERC721("IndeliblePro", "INDELIBLEPRO") {}

    modifier whenMintActive() {
        require(isMintActive(), "Mint is not active");
        _;
    }

    modifier whenPaidMintActive() {
        require(isPublicMintActive || isAllowListMintActive, "Paid mint is not active");
        _;
    }

    modifier whenTier2MintActive() {
        require(isTier2MintActive, "Free mint is not active");
        _;
    }

    receive() external payable {
        require(isPublicMintActive, "Public minting is not active");
        tier1Mint(msg.value / mintPrice, msg.sender);
    }

    function maxSupply() public pure returns (uint) {
        return MAX_SUPPLY_TIER_1 + MAX_SUPPLY_TIER_2;
    }

    function totalSupply() public view returns (uint) {
        return totalTier1Minted + totalTier2Minted;
    }

    function burnToMint(uint[] calldata tokenIds, address recipient)
        external
        nonReentrant
        whenTier2MintActive
    {
        require(totalTier2Minted + tokenIds.length <= MAX_SUPPLY_TIER_2, "All tokens are gone");

        for (uint i; i < tokenIds.length; i += 1) {
            require(!_exists(tokenIds[i]), "Token has already been claimed");

            if (msg.sender != owner()) {
                OnChainKevin.safeTransferFrom(msg.sender, burnAddress, tokenIds[i]);
            }

            _mint(recipient, tokenIds[i]);
        }
        totalTier2Minted = totalTier2Minted + tokenIds.length;

        IBurnedKevins burnedKevins = IBurnedKevins(burnedKevinsContractAddress);
        burnedKevins.mint(tokenIds, recipient);
    }

    function tier1Mint(uint count, address recipient)
        internal
        whenPaidMintActive
    {
        require(count > 0, "Invalid token count");
        require(totalTier1Minted + count <= maxSupplyTier1Limit, "All tokens are gone");

        if (isPublicMintActive) {
            require(msg.sender == tx.origin, "EOAs only");
        }
        if (msg.sender != owner()) {
            require(_tier1TokensMinted[msg.sender] + count <= maxPerWallet, "Exceeded max mints allowed");
            require(count * mintPrice == msg.value, "Incorrect amount of ether sent");
        }

        for (uint i; i < count; i += 1) {
            _mint(recipient, totalTier1Minted + 2000 + i + 1);
        }
        
        _tier1TokensMinted[msg.sender] = _tier1TokensMinted[msg.sender] + count;
        totalTier1Minted = totalTier1Minted + count;
    }

    function mint(uint count, bytes32[] calldata merkleProof)
        external
        payable
        nonReentrant
        whenMintActive
    {
        if (!isPublicMintActive && msg.sender != owner()) {
            require(onAllowList(msg.sender, merkleProof), "Not on allow list");
            require(count * mintPrice == msg.value, "Incorrect amount of ether sent");
        }
        tier1Mint(count, msg.sender);
    }

    function airdrop(uint count, address recipient)
        external
        payable
        nonReentrant
        whenMintActive
    {
        require(isPublicMintActive || msg.sender == owner(), "Public minting is not active");
        tier1Mint(count, recipient);
    }

    function onAllowList(address addr, bytes32[] calldata merkleProof) public view returns (bool) {
        return MerkleProof.verify(merkleProof, merkleRoot, keccak256(abi.encodePacked(addr)));
    }

    function isMintActive() public view returns (bool) {
        return totalTier2Minted + totalTier1Minted < maxSupply() && (isPublicMintActive || isAllowListMintActive || isTier2MintActive || msg.sender == owner());
    }

    function contractURI()
        public
        view
        returns (string memory)
    {
        return string.concat(
            "data:application/json;base64,",
            Base64.encode(
                abi.encodePacked(
                    '{"name":"',
                    contractData.name,
                    '","description":"',
                    contractData.description,
                    '","image":"',
                    contractData.image,
                    '","banner":"',
                    contractData.banner,
                    '","external_link":"',
                    contractData.website,
                    '","seller_fee_basis_points":',
                    Strings.toString(contractData.royalties),
                    ',"fee_recipient":"',
                    contractData.royaltiesRecipient,
                    '"}'
                )
            )
        );
    }

    function tokenURI(uint tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Invalid token");

        if (renderContractAddress == address(0)) {
            return "";
        }

        IIndelibleProRenderer renderer = IIndelibleProRenderer(renderContractAddress);
        return renderer.tokenURI(tokenId);
    }

    function setContractData(ContractData memory data)
        external
        onlyOwner
    {
        contractData = data;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function setMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        merkleRoot = newMerkleRoot;
    }

    function setMintPrice(uint price) external onlyOwner {
        mintPrice = price;
    }

    function setMaxPerWallet(uint max) external onlyOwner {
        maxPerWallet = max;
    }

    function setMaxSupplyTier1Limit(uint limit) external onlyOwner {
        require(limit <= MAX_SUPPLY_TIER_1, "Limit is too large");
        require(limit >= totalTier1Minted, "Limit is too small");
        maxSupplyTier1Limit = limit;
    }

    function setOnChainKevinContract(address contractAddress) external onlyOwner {
        OnChainKevin = IERC721(contractAddress);
    }

    function setBurnedKevinsContract(address contractAddress) external onlyOwner {
        burnedKevinsContractAddress = contractAddress;
    }

    function setRenderContract(address contractAddress) external onlyOwner {
        renderContractAddress = contractAddress;
    }

    function toggleTier2Mint() external onlyOwner {
        isTier2MintActive = !isTier2MintActive;
    }

    function toggleAllowListMint() external onlyOwner {
        isAllowListMintActive = !isAllowListMintActive;
    }

    function togglePublicMint() external onlyOwner {
        isPublicMintActive = !isPublicMintActive;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        if (!success) revert("Failed");
    }

    function transferFrom(address from, address to, uint tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint tokenId, bytes memory data) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}