// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "../interfaces/IERC721Mint.sol";
import "../interfaces/IMintImplement.sol";
import "../libraries/SafeOwnable.sol";
import "../libraries/Verifier.sol";

contract SpiritEgg is ERC721EnumerableUpgradeable, SafeOwnable, Verifier, ReentrancyGuardUpgradeable {
    using StringsUpgradeable for uint256;
    using ECDSAUpgradeable for bytes32;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    string private constant _HEX_SYMBOLS = "ETHEREUM_CUSTOM_EXTERNAL_SIGN_MSG_PREFIX";

    IERC721Mint public beastCategory1;
    IMintImplement public mintImplement;

    string private baseTokenURI;

    mapping(bytes32 => bool) public signatureVerified;

    function initialize(string memory name_, string memory symbol_) public initializer {
        __ERC721_init(name_, symbol_);
        _transferOwnership(msg.sender);
    }

    modifier onlyMintImplement(){
        require(msg.sender == address(mintImplement), "Mint sender not allowed");
        _;
    }

    function setBaseURI(string calldata _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory){
        require(_exists(tokenId), "TokenURI: URI query for nonexistent token");

        return bytes(baseTokenURI).length > 0 ? string(abi.encodePacked(baseTokenURI, tokenId.toString(), ".json")) : "";
    }

    function setMintImplement(IMintImplement addr) external onlyOwner {
        mintImplement = addr;
    }

    function setBeastCategory1(IERC721Mint addr) external onlyOwner {
        beastCategory1 = addr;
    }

    function convertHash(bytes32 _hash) private pure returns (bytes32 hash) {
        uint256 value = uint256(_hash);
        string memory hexMsg = value.toHexString(32);
        hash = sha256(abi.encodePacked(_HEX_SYMBOLS, hexMsg));
    }

    function verifyMintParam(address account, uint128 period, uint128 round, uint256[] calldata tokenIds, address nftAddress, uint8 v, bytes32 r, bytes32 s) internal returns (bool){
        bytes32 hash = keccak256(abi.encodePacked(account, "_", tokenIds, "_", period, "_", round, "_", block.chainid, "_", nftAddress));
        require(!signatureVerified[hash], "have minted");
        bytes32 cHash = convertHash(hash);
        signatureVerified[hash] = true;
        return verifier == cHash.recover(v, r, s);
    }

    function verifyBatchMintParam(address account, uint128 period, uint128 round, uint256 startTokenId, uint128 amount, address nftAddress, uint8 v, bytes32 r, bytes32 s) internal returns (bool){
        bytes32 hash = keccak256(abi.encodePacked(account, "_", startTokenId, "_", amount, "_", period, "_", round, "_", block.chainid, "_", nftAddress));
        require(!signatureVerified[hash], "have minted");
        bytes32 cHash = convertHash(hash);
        signatureVerified[hash] = true;
        return verifier == cHash.recover(v, r, s);
    }

    function verifyOpenBlindBoxParam(address account, uint256 tokenId, uint256 beastTokenId, address nftAddress, uint8 v, bytes32 r, bytes32 s) internal returns (bool){
        bytes32 hash = keccak256(abi.encodePacked(account, "_", tokenId, "_", beastTokenId, "_", block.chainid, "_", nftAddress));
        require(!signatureVerified[hash], "have minted");
        bytes32 cHash = convertHash(hash);
        signatureVerified[hash] = true;
        return verifier == cHash.recover(v, r, s);
    }

    function verifyAirdropParam(address account, uint256 tokenId, address nftAddress, uint8 v, bytes32 r, bytes32 s) internal returns (bool){
        bytes32 hash = keccak256(abi.encodePacked(account, "_", tokenId, "_", block.chainid, "_", nftAddress));
        require(!signatureVerified[hash], "have minted");
        bytes32 cHash = convertHash(hash);
        signatureVerified[hash] = true;
        return verifier == cHash.recover(v, r, s);
    }

    function mint(address to, uint256 tokenId) public onlyMintImplement {
        _mint(to, tokenId);
    }

    function mint() external nonReentrant {
        mintImplement.mint(msg.sender);
    }

    function whitelistMint(uint128 period, uint128 round, uint256[] calldata tokenIds, uint8 v, bytes32 r, bytes32 s) external {
        require(verifyMintParam(msg.sender, period, round, tokenIds, address(this), v, r, s), "Mint: from not allowed");

        mintImplement.mint(msg.sender, period, round, tokenIds);
    }

    function batchMint(uint128 period, uint128 round, uint256 startTokenId, uint128 amount, uint8 v, bytes32 r, bytes32 s) external {
        require(verifyBatchMintParam(msg.sender, period, round, startTokenId, amount, address(this), v, r, s), "Mint: from not allowed");

        mintImplement.batchMint(msg.sender, period, round, startTokenId, amount);
    }

    function airdrop(address to, uint256 tokenId, uint8 v, bytes32 r, bytes32 s) external {
        require(verifyAirdropParam(to, tokenId, address(this), v, r, s), "Airdrop: access verify failed");

        mintImplement.airdrop(to, tokenId);
    }

    function burn(uint256 tokenId) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _burn(tokenId);
    }

    function batchTransfer(address to, uint256 startTokenId, uint256 amount) external {
        for (uint i = 0; i < amount; i ++) {
            transferFrom(msg.sender, to, startTokenId + i);
        }
    }

    function openBlindBox(uint256 tokenId, uint256 beastTokenId, uint8 v, bytes32 r, bytes32 s) external {
        require(verifyOpenBlindBoxParam(msg.sender, tokenId, beastTokenId, address(this), v, r, s), "openBlindBox: verify failed");

        address owner = ownerOf(tokenId);
        burn(tokenId);
        beastCategory1.mint(owner, beastTokenId);
    }

    function recoverWrongToken(address token, address to) public onlyOwner {
        if (token == address(0)) {
            payable(to).transfer(address(this).balance);
        } else {
            uint256 balance = IERC20Upgradeable(token).balanceOf(address(this));
            IERC20Upgradeable(token).safeTransfer(to, balance);
        }
    }
}