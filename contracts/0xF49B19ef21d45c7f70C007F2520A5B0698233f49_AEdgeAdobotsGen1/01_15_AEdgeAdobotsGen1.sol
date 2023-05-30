// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721Tradable.sol";

// *************************************************
//    _____   ___________    .___
//   /  _  \  \_   _____/  __| _/  ____    ____
//  /  /_\  \  |    __)_  / __ |  / ___\ _/ __ \
// /    |    \ |        \/ /_/ | / /_/  >\  ___/
// \____|__  //_______  /\____ | \___  /  \___  >
//         \/         \/      \//_____/       \/
// **************************************************

contract AEdgeAdobotsGen1 is ERC721Tradable, IERC2981, ReentrancyGuard {

    uint256 public MINT_PRICE = 0.3 ether;
    uint256 public WHITELIST_PRICE = 0.25 ether;

    uint256 public maxSupply = 4096;
    uint256 public maxPerWallet = 6;

    bytes32 public merkleRoot;

    string private baseURI = "https://adobots.mypinata.cloud/ipfs/QmYTAxCo2M54jTtXKC1VeNrMxsqaTtqfV1gCDL6vfivzLD/";

    address public constant WITHDRAW_ADDRESS = 0xe37E7F684c38daCA4628f2C418366BA43FE2525D;
    address public constant ROYALTY_RECEIVER = 0xe37E7F684c38daCA4628f2C418366BA43FE2525D;

    bool private mintingClosed = false;
    bool private mintingEnabled = false;

    struct MintSettings {
        uint256 maxSupply;
        uint256 maxPerWallet;
        uint256 mintPrice;
        uint256 whitelistPrice;
        uint256 count;
        bytes32 merkleRoot;
        bool mintingEnabled;
        bool mintingClosed;
    }

    constructor()
    ERC721Tradable(
        "AEdge Adobots Generation One",
        "AEdgeAdobotsGen1",
        0xa5409ec958C83C3f309868babACA7c86DCB077c1
    )
    {

    }

    function setMintPrice(uint256 newMintPrice, uint256 newWhitelistPrice) external onlyOwner {
        MINT_PRICE = newMintPrice;
        WHITELIST_PRICE = newWhitelistPrice;
    }

    function whitelistMint(
        uint256 num,
        bytes32[] calldata merkleProof
    )
    external
    nonReentrant
    payable
    returns (uint256)
    {
        require(isMintingEnabled(), "Minting is not enabled");
        bulkRequire(num, WHITELIST_PRICE);

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(merkleProof, merkleRoot, leaf),
            "Your address is not whitelisted"
        );

        _safeMint(msg.sender, num);

        return _totalMinted();
    }

    function payToMint(uint256 num) external nonReentrant payable returns (uint256) {
        require(isMintingEnabled(), "Minting is not enabled");
        bulkRequire(num, MINT_PRICE);

        _safeMint(msg.sender, num);

        return _totalMinted();
    }

    function ownerMint(uint256 num, address to) external onlyOwner returns (uint256) {
        require(_totalMinted() + num <= maxSupply, "Maximum number of tokens minted");

        _safeMint(to, num);

        return _totalMinted();
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function closeMinting() external onlyOwner {
        mintingClosed = true;
    }

    function setMaxPerWallet(uint256 maxPerWalletValue) external onlyOwner {
        maxPerWallet = maxPerWalletValue;
    }

    function setMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        merkleRoot = newMerkleRoot;
    }

    function setNewMaxSupply(uint256 newMaxSupply) external onlyOwner {
        require(newMaxSupply <= 4096, "New max supply can not be over 4096");
        require(newMaxSupply >= totalSupply(), "New max must be greater than current supply");

        maxSupply = newMaxSupply;
    }

    function setMintingEnabled(bool mintingEnabledValue) external onlyOwner {
        mintingEnabled = mintingEnabledValue;
    }

    function withdrawAll() external onlyOwner returns (bool)
    {
        (bool sent,) = WITHDRAW_ADDRESS.call{value: address(this).balance}("");
        require(sent, "WITHDRAW_FAILED");

        return sent;
    }

    function getAddressTokens(address addr) external view returns (uint256[] memory) {
        uint256[] memory myTokenIds = new uint256[](balanceOf(addr));
        uint256 c = 0;
        for (uint256 i = _startTokenId(); i < _nextTokenId(); i++) {
            if (ownerOf(i) == addr) {
                myTokenIds[c++] = i;
            }
        }
        return myTokenIds;
    }

    function getTokenHolders() external view returns (address[] memory) {
        address[] memory tokenHolders = new address[](totalSupply());
        uint256 c = 0;
        for (uint256 i = _startTokenId(); i < _nextTokenId(); i++) {
            tokenHolders[c++] = ownerOf(i);
        }
        return tokenHolders;
    }

    function getMintSettings() external view returns (MintSettings memory) {
        MintSettings memory mintSettings = MintSettings(
            maxSupply, maxPerWallet, MINT_PRICE, WHITELIST_PRICE, totalSupply(), merkleRoot, mintingEnabled, mintingClosed
        );

        return mintSettings;
    }

    function isWhitelisted(address addr, bytes32[] calldata merkleProof) external view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(addr));

        return MerkleProof.verify(merkleProof, merkleRoot, leaf);
    }

    /**
     * @dev Interface implementation for the NFT Royalty Standard (ERC-2981).
     * Called by marketplaces that supports the standard with the sale price to determine how much royalty
     * is owed and to whom.
     * The first parameter tokenId (the NFT asset queried for royalty information) is not used as royalties
     * are calculated equally for all tokens.
     * @param salePrice - the sale price of the NFT asset specified by `tokenId`
     * @return receiver - address of who should be sent the royalty payment
     * @return royaltyAmount - the royalty payment amount for `salePrice`
     */
    function royaltyInfo(uint256, uint256 salePrice) external pure override returns (address, uint256) {
        return (ROYALTY_RECEIVER, salePrice / 10);
    }

    function isMintingEnabled() public view returns (bool) {
        return mintingEnabled && !mintingClosed;
    }

    function supportsInterface(
        bytes4 interfaceId
    )
    public
    view
    override(ERC721A, IERC165)
    returns (bool)
    {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function bulkRequire(uint256 num, uint256 mintPrice) private {
        require(msg.value == (mintPrice * num), "Incorrect amount of ether provided for the mint!");
        require(_totalMinted() + num <= maxSupply, "Maximum number of tokens minted");
        require(num + _numberMinted(msg.sender) <= maxPerWallet, "Max mints per wallet reached");
    }
}