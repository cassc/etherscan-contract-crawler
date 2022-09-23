// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Noji is ERC721A, IERC2981, Ownable {
    using Strings for uint256;

    uint256 public MAX_SUPPLY = 3000;
    uint256 public MAX_SALE_SUPPLY = 1500;
    uint256 public MAX_NOJI_PER_WALLET = 2;
    uint256 public OGLIST_SALE_PRICE = 0.059 ether;
    uint256 public WHITELIST_SALE_PRICE = 0.059 ether;
    uint256 public PUBLIC_SALE_PRICE = 0.059 ether;
    uint96 public royaltyFeesInBips = 700;

    address public royaltyAddress;

    string baseURI;
    string public placeholderTokenUri;

    bool public isRevealed = false;
    bool public isPaused = true;
    bool public isOGListMintActive = false;
    bool public isWhiteListMintActive = false;
    bool public isPublicMintActive = false;
    bool public isTeamMintActive = false;
    bool public isAirdropClaimActive = false;

    bytes32 public ogListMerkleRoot;
    bytes32 public whiteListMerkleRoot;
    bytes32 public teamListMerkleRoot;

    struct airdropData {
        uint256 qty;
        bool hasClaimed;
    }

    mapping(address => bool) public teamListClaimed;
    mapping(address => uint256) nojiPerAddress;
    mapping(address => airdropData) airdropList;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Caller is another contract");
        _;
    }

    modifier mintIsActive(bool category) {
        require(!isPaused, "Minting paused");
        require(category, "List minting not active");
        _;
    }

    modifier canAfford(uint256 categoryPrice, uint256 qty) {
        require(msg.value >= categoryPrice * qty, "Insufficient Funds");
        _;
    }

    modifier canMint(uint256 qty) {
        require(qty > 0, "Mint at least 1 Noji");
        require(
            totalSupply() + qty <= MAX_SALE_SUPPLY,
            "Cannot mint beyound Max Supply"
        );
        require(
            nojiPerAddress[msg.sender] + qty <= MAX_NOJI_PER_WALLET,
            "Max Noji per Wallet exceded"
        );
        _;
    }

    modifier isValidMerkleProof(
        bytes32[] calldata merkleProof,
        bytes32 merkleRoot
    ) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(merkleProof, merkleRoot, leaf),
            "Address not listed"
        );
        _;
    }

    constructor() ERC721A("Noji", "NOJI") {
        royaltyAddress = owner();
        _safeMint(0x79FC0EF9190F444a230A41d44234C454aB10a35f, 15);
    }

    function publicMint(uint256 qty)
        public
        payable
        callerIsUser
        mintIsActive(isPublicMintActive)
        canAfford(PUBLIC_SALE_PRICE, qty)
        canMint(qty)
    {
        _safeMint(msg.sender, qty);
    }

    function oglistMint(uint256 qty, bytes32[] calldata merkleProof)
        public
        payable
        callerIsUser
        mintIsActive(isOGListMintActive)
        canAfford(OGLIST_SALE_PRICE, qty)
        canMint(qty)
        isValidMerkleProof(merkleProof, ogListMerkleRoot)
    {
        _safeMint(msg.sender, qty);
    }

    function whitelistMint(uint256 qty, bytes32[] calldata merkleProof)
        public
        payable
        callerIsUser
        mintIsActive(isWhiteListMintActive)
        canAfford(WHITELIST_SALE_PRICE, qty)
        canMint(qty)
        isValidMerkleProof(merkleProof, whiteListMerkleRoot)
    {
        _safeMint(msg.sender, qty);
    }

    function teamMint(bytes32[] calldata merkleProof)
        public
        callerIsUser
        mintIsActive(isTeamMintActive)
        canMint(1)
        isValidMerkleProof(merkleProof, teamListMerkleRoot)
    {
        require(!teamListClaimed[msg.sender], "Noji already claimed");
        teamListClaimed[msg.sender] = true;
        _safeMint(msg.sender, 1);
    }

    function claimAirdrop()
        public
        callerIsUser
        mintIsActive(isAirdropClaimActive)
    {
        require(airdropList[msg.sender].qty > 0, "No airdrop to claim");
        require(!airdropList[msg.sender].hasClaimed, "Airdrop already claimed");
        _safeMint(msg.sender, airdropList[msg.sender].qty);
    }

    function togglePause() external onlyOwner {
        isPaused = !isPaused;
    }

    function toggleOGListMint() external onlyOwner {
        isOGListMintActive = !isOGListMintActive;
    }

    function toggleWhiteListMint() external onlyOwner {
        isWhiteListMintActive = !isWhiteListMintActive;
    }

    function togglePublicMint() external onlyOwner {
        isPublicMintActive = !isPublicMintActive;
    }

    function toggleTeamMint() external onlyOwner {
        isTeamMintActive = !isTeamMintActive;
    }

    function toggleAirdopClaim() external onlyOwner {
        isAirdropClaimActive = !isAirdropClaimActive;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "nonexistent token");

        if (!isRevealed) {
            return placeholderTokenUri;
        }

        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    function setPlaceHolderTokenUri(string memory uri) external onlyOwner {
        placeholderTokenUri = uri;
    }

    function toggleReveal() public onlyOwner {
        isRevealed = !isRevealed;
    }

    function setMaxSupply(uint256 supply) external onlyOwner {
        MAX_SUPPLY = supply;
    }

    function setMaxSaleSupply(uint256 supply) external onlyOwner {
        MAX_SALE_SUPPLY = supply;
    }

    function setOGListMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        ogListMerkleRoot = merkleRoot;
    }

    function setWhiteListMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        whiteListMerkleRoot = merkleRoot;
    }

    function setTeamListMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        teamListMerkleRoot = merkleRoot;
    }

    function setMaxNojiPerWallet(uint256 num) public onlyOwner {
        MAX_NOJI_PER_WALLET = num;
    }

    function setAirdropList(address[] memory addresses, uint256[] memory qtys)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "ZERO_ADDRESS");
            if (airdropList[addresses[i]].qty == 0) {
                airdropData memory data;
                data.qty = qtys[i];
                data.hasClaimed = false;
                airdropList[addresses[i]] = data;
            }
        }
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        virtual
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (royaltyAddress, (salePrice * royaltyFeesInBips) / 10000);
    }

    function setRoyaltyInfo(address receiver, uint8 _royaltyFeesInBips)
        public
        onlyOwner
    {
        require(_royaltyFeesInBips <= 10000, "Royalty fee high");
        royaltyAddress = receiver;
        royaltyFeesInBips = _royaltyFeesInBips;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No payout to withdraw");
        (bool success, ) = payable(msg.sender).call{value: balance}("");
        require(success, "Withdrawal failed");
    }

    function withdrawTokens(IERC20 token) public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    receive() external payable {}
}