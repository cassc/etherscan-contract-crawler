// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "./interfaces.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/extensions/IERC721AQueryable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract TailsTravelsNFT is DefaultOperatorFilterer, ERC721AQueryable, Initializable, ReentrancyGuard {
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 4444;
    uint256 public constant WALLET_MINT_LIMIT = 60;
    uint256 public constant MINT_PRICE = 0.01 ether;
    uint256 public constant TOTAL_CLAIMABLE_TOKENS = 300; // 1-to-1 for 300 HEEL NFTs v1

    IERC721AQueryable public constant HEEL_NFT = IERC721AQueryable(0x7eEbC5fCC4020e0A72365Aae47B3998b5c71Ed4c);
    address public constant BENEFICIARY = 0x1Af73CA2e9bf3A138f0FA24C3Cc59Ae24C13A565;
    address public constant ADMIN = 0xC68a90AAdF4eC0ec24833684Ea394eb9cF43de90;

    bool public mintOpen;
    uint256 public claimedCount;
    mapping(uint256 => bool) private _heelNFTClaims;
    string private _metadataBaseURI;
    mapping(uint256 => string) private _customMetadataURI;

    modifier isAuthorized() {
        require(msg.sender == ADMIN, "Not authorized");
        _;
    }

    constructor() ERC721A("", "") {}

    function name() public pure override(ERC721A, IERC721A) returns (string memory) {
        return "Tails & Travels";
    }

    function symbol() public pure override(ERC721A, IERC721A) returns (string memory) {
        return "TAILS";
    }

    function owner() public pure returns (address) {
        return ADMIN;
    }

    function claimableTokens(address user) public view returns (uint256[] memory) {
        uint256[] memory userHeelNFTs = HEEL_NFT.tokensOfOwner(user);
        uint256[] memory claimableUserHeelNFTs = new uint256[](userHeelNFTs.length);

        uint256 filteredClaimableSize;
        for (uint256 i = 0; i < userHeelNFTs.length; i++)
            if (!_heelNFTClaims[userHeelNFTs[i]]) {
                claimableUserHeelNFTs[filteredClaimableSize] = userHeelNFTs[i];
                filteredClaimableSize += 1;
            }

        uint256[] memory result = new uint256[](filteredClaimableSize);
        for (uint256 i = 0; i < filteredClaimableSize; i++)
            result[i] = claimableUserHeelNFTs[i];

        return result;
    }

    function claimableCount() public view returns (uint256) {
        if (TOTAL_CLAIMABLE_TOKENS <= claimedCount) return 0;

        uint256 claimable = TOTAL_CLAIMABLE_TOKENS - claimedCount;
        uint256 remaining = MAX_SUPPLY - totalSupply();
        return claimable > remaining ? remaining : claimable;
    }

    function mintableCount() public view returns (uint256) {
        return MAX_SUPPLY - _totalMinted() - claimableCount();
    }

    function claim(uint256[] memory tokenIds) external nonReentrant {
        // We allow smart contract claims - so that ppl can claim directly from multisigs / vaults.
        // Also, we do not impose wallet limits to those claims
        require(mintOpen, "Mint not open");

        uint256 amountToClaim;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 heelNft = tokenIds[i];
            if (!_heelNFTClaims[heelNft]) {
                require(
                    HEEL_NFT.ownerOf(heelNft) == msg.sender,
                    string(
                        abi.encodePacked(
                            "Not an owner of HEEL NFT v1 #",
                            heelNft.toString()
                        )
                    )
                );
                _heelNFTClaims[heelNft] = true;
                claimedCount += 1;
                amountToClaim += 1;
            }
        }

        require(amountToClaim > 0, "Nothing to claim");
        require(_totalMinted() + amountToClaim <= MAX_SUPPLY, "Sold out!");

        _mint(msg.sender, amountToClaim);
    }

    function mint(uint256 qty) external payable nonReentrant {
        require(tx.origin == msg.sender, "Smart contract mints not allowed");
        require(mintOpen, "Mint not open");
        require(qty <= mintableCount(), "Sold out!");
        require(
            balanceOf(msg.sender) + qty <= WALLET_MINT_LIMIT,
            "Wallet mint limit exceeded!"
        );

        uint256 total = qty * MINT_PRICE;
        require(msg.value >= total, "Insufficient funds!");

        _mint(msg.sender, qty);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721A, IERC721A) returns (string memory) {
        if (bytes(_customMetadataURI[tokenId]).length > 0)
            return _customMetadataURI[tokenId];
        else
            return string(abi.encodePacked(_metadataBaseURI, tokenId.toString(), ".json"));
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    // OPERATOR FILTERING

    function setApprovalForAll(address operator, bool approved) public override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override(ERC721A, IERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // ADMIN STUFF

    function mintFor(uint256 qty, address addr) external isAuthorized {
        require(_totalMinted() + qty <= MAX_SUPPLY, "Sold out!");

        _safeMint(addr, qty);
    }

    function ownerWithdraw() external isAuthorized {
        require(address(this).balance > 0, "Nothing to withdraw!");
        (bool sent, ) = BENEFICIARY.call{value: address(this).balance}("");
        require(sent, "Can't withdraw");
    }

    function ownerWithdrawToken(address token) external isAuthorized {
        IERC20(token).transfer(
            BENEFICIARY,
            IERC20(token).balanceOf(address(this))
        );
    }

    function setMetadataBaseUri(string memory uri) external isAuthorized {
        _metadataBaseURI = uri;
    }

    function setCustomMetadataUri(uint256 tokenIdx, string memory uri) external isAuthorized {
        _customMetadataURI[tokenIdx] = uri;
    }

    function toggleMintState() external isAuthorized {
        mintOpen = !mintOpen;
    }
}