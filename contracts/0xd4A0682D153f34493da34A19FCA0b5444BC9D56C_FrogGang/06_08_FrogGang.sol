// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

// The Froggang Genesis Pass is the OG collection of Froggang.
// It consists of 300 brave, intelligent, and passionate frog masters,
// leading the gang towards the final revolution. We are all about discovering, sharing,
// and building the next big thing. Together, we are strong.

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract FrogGang is ERC721A, Ownable {
    using ECDSA for bytes32;

    uint256 public constant MAX_SUPPLY = 300;
    uint256 public constant MAX_MINT_PER_ADDR = 1;
    uint256 public constant MINT_START = 17018840;
    uint256 public constant MINT_END = 17025924;
    bytes32 public constant MINTER_TYPEHASH =
        keccak256("Minter(address wallet)");

    bytes32 public DOMAIN_SEPARATOR;
    address public whitelistSigningKey;
    string public baseURI;

    event Minted(address minter, uint256 amount);

    constructor(
        string memory initBaseURI,
        address newSigningKey
    ) ERC721A("Froggang OG Genesis Pass", "Froggang OG") {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f, // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
                0x67525be21ad3a04503ef1b08b573fc4caf585d3b06b0c602ed12a5b90c24ad41, // keccak256(bytes("FrogGang"))
                0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6, // keccak256(bytes("1")) for versionId = 1
                block.chainid,
                address(this)
            )
        );

        baseURI = initBaseURI;
        whitelistSigningKey = newSigningKey;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, "0.json"))
                : "";
    }

    function whitelistMint(
        uint256 quantity,
        bytes calldata signature
    ) external requiresWhitelist(signature) {
        require(block.number >= MINT_START, "FrogGang: Not start yet.");
        require(block.number < MINT_END, "FrogGang: Mint has ended.");
        require(tx.origin == msg.sender, "FrogGang: Call is not allowed.");
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "FrogGang: Insufficient remaining supply."
        );
        require(
            numberMinted(msg.sender) + quantity <= MAX_MINT_PER_ADDR,
            "FrogGang: Over max mint per address."
        );

        _safeMint(msg.sender, quantity);
        emit Minted(msg.sender, quantity);
    }

    function numberMinted(address _owner) public view returns (uint256) {
        return _numberMinted(_owner);
    }

    modifier requiresWhitelist(bytes calldata signature) {
        require(whitelistSigningKey != address(0), "whitelist not enabled");
        // Verify EIP-712 signature by recreating the data structure
        // that we signed on the client side, and then using that to recover
        // the address that signed the signature for this data.
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(MINTER_TYPEHASH, msg.sender))
            )
        );
        // Use the recover method to see what address was used to create
        // the signature on this data.
        // Note that if the digest doesn't exactly match what was signed we'll
        // get a random recovered address.
        address recoveredAddress = digest.recover(signature);
        require(recoveredAddress == whitelistSigningKey, "Invalid Signature");
        _;
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function setWhitelistSigningAddress(
        address newSigningKey
    ) external onlyOwner {
        whitelistSigningKey = newSigningKey;
    }

    function ownerMint(address minter) external onlyOwner {
        _safeMint(minter, 150);
    }

    function withdraw(address payable recipient) external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = recipient.call{value: balance}("");
        require(success, "FrogGang: OPS.");
    }
}