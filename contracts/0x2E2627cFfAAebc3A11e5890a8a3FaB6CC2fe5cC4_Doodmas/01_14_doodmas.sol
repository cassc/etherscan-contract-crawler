// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./ERC721.sol";

contract Doodmas is ReentrancyGuard, Ownable, EIP712, ERC721 {
    using ECDSA for bytes32;

    enum MintState {
        Stop,
        PreSale,
        PublicSale
    }

    struct Minter {
        uint128 mintedInPreSale;
        uint128 mintedInPublicSale;
    }

    bytes32 private constant MINT_CALL_HASH_TYPE = keccak256("mint(address receiver,uint256 amount)");

    mapping(address => Minter) public minters;

    address public signer = 0x65ea50feFCCb114d2130d9cCD0561a67F717a2fE;
    uint256 public immutable maxSupply;
    uint256 public maxMintPerAddress = 10;
    uint256 public totalSupply;

    MintState public mintState;

    string public contractURI = "ipfs://QmZHhdZc6hGYKqPZ6bw6aS4zQpRb1Z7yYSBAM1nhaoURi5";
    string public baseURI = "ipfs://QmZXtaHgfMBKbtWtuPmDY6ZeWUABByskeAgwMB9oWcXUnz/";

    constructor(uint256 _maxSupply) ERC721("Doodmas", "Doodmas") EIP712("Doodmas", "1") {
        maxSupply = _maxSupply;

        batchMint(10);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function mint(uint256 _amount) external nonReentrant {
        require(tx.origin == msg.sender, "Doodmas: Minting from contract is forbidden");
        require(mintState == MintState.PublicSale, "Doodmas: Public sale is not started");
        validateMintAmount(_amount);
        require(_amount > 0, "Doodmas: At least mint something");

        Minter memory minter = minters[msg.sender];
        require(minter.mintedInPublicSale == 0, "Doodmas: You can only mint once");
        require(minter.mintedInPublicSale + _amount <= maxMintPerAddress, "Doodmas: Address has exceeded mint limit");

        minter.mintedInPublicSale += uint128(_amount);
        minters[msg.sender] = minter;
        batchMint(_amount);
    }

    function presaleMint(
        uint256 _amountV,
        bytes32 _r,
        bytes32 _s
    ) external nonReentrant {
        require(mintState == MintState.PreSale, "Doodmas: Pre-sale is not started");

        uint256 amount = validateAndGetAmount(_amountV, _r, _s);
        validateMintAmount(amount);

        Minter memory minter = minters[msg.sender];
        require(minter.mintedInPreSale == 0, "Doodmas: You can only mint once");

        minter.mintedInPreSale += uint128(amount);
        minters[msg.sender] = minter;
        batchMint(amount);
    }

    function validateMintAmount(uint256 _amount) internal view {
        require(totalSupply + _amount <= maxSupply, "Doodmas: Mint amount exceeds limit");
    }

    function validateAndGetAmount(
        uint256 _amountV,
        bytes32 _r,
        bytes32 _s
    ) internal view returns (uint256) {
        uint256 amount = uint248(_amountV);
        uint8 v = uint8(_amountV >> 248);
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                _domainSeparatorV4().toTypedDataHash(keccak256(abi.encode(MINT_CALL_HASH_TYPE, msg.sender, amount)))
            )
        );
        require(ecrecover(digest, v, _r, _s) == signer, "Doodmas: Invalid signer");

        return amount;
    }

    function batchMint(uint256 amount) internal {
        uint256 tokenId = totalSupply;
        totalSupply += amount;
        _safeBatchMint(msg.sender, tokenId, amount);
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function setMintState(MintState _mintStat) external onlyOwner {
        mintState = _mintStat;
    }

    function setMaxMintPerAddress(uint256 _maxMintPerAddress) external onlyOwner {
        maxMintPerAddress = _maxMintPerAddress;
    }

    function setBaseURI(string calldata _uri) external onlyOwner {
        baseURI = _uri;
    }

    function setContractURI(string calldata _uri) external onlyOwner {
        contractURI = _uri;
    }
}