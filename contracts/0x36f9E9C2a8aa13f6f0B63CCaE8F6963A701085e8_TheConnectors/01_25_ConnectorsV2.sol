// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/draft-ERC721Votes.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./RandomlyAssigned.sol";

/**
 * @title The Connectors Contract
 */
contract TheConnectors is ERC721, ERC721Enumerable, EIP712, ERC721Votes, Ownable, ReentrancyGuard, RandomlyAssigned {

    using ECDSA for bytes32;

    uint8 constant MAX_MINTS_PER_WALLET = 20;
    uint16 constant MAX_SUPPLY = 10000;
    // Final price - 0.1 ETH
    uint256 constant FINAL_PRICE = 100000000000000000;

    // Used to validate whitelist mint addresses
    address private signerAddress = 0xd19A6eC87f54B13455089d7C1115f73561508f40;

    string public constant PROVENANCE = "cc91c82c1587adde49e77ed934fc6e10991fa84c67cf8a003ce23d0bd0292125";

    // Remember the number of mints per wallet to control max mints value
    mapping (address => uint8) public totalMintsPerAddress;

    string private baseURI;

    // Public vars
    bool public saleActive;
    bool public presaleActive;

    modifier whenSaleActive()
    {
        require(saleActive, "SALE_NOT_ACTIVE");
        _;
    }

    modifier whenPreSaleActive()
    {
        require(presaleActive, "PRESALE_NOT_ACTIVE");
        _;
    }

    constructor(string memory _baseTokenURI, string memory name, string memory symbol)
    ERC721(name, symbol)
    EIP712(name, "1")
    RandomlyAssigned(MAX_SUPPLY, 0)
    {
        baseURI = _baseTokenURI;
    }

    /**
     * @notice Contract might receive/hold ETH as part of the maintenance process.
     */
    receive() external payable {}

    /**
     * @notice Change signer address
     */
    function setSignerAddress(address _signerAddress) external onlyOwner {
        require(_signerAddress != address(0));
        signerAddress = _signerAddress;
    }

    /**
     * @notice Start public sale
     */
    function startPublicSale() external onlyOwner
    {
        require(!saleActive, "SALE_HAS_BEGUN");
        saleActive = true;
    }

    /**
     * @notice Start presale
     */
    function startPresale() external onlyOwner
    {
        require(!presaleActive, "PRESALE_HAS_BEGUN");
        presaleActive = true;
    }

    /**
     * @notice Pause public sale
     */
    function pausePublicSale() external onlyOwner
    {
        require(saleActive, "SALE_PAUSED");
        saleActive = false;
    }

    /**
     * @notice Pause presale
     */
    function pausePresale() external onlyOwner
    {
        require(presaleActive, "PRESALE_PAUSED");
        presaleActive = false;
    }

    /**
     * @notice Allow withdrawing funds
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(msg.sender), balance);
    }

    /**
     * @notice Public sale. Mint connectors
     */
    function mintPublicConnectors(uint8 numConnectors) external payable whenSaleActive nonReentrant
    {
        require(
            totalSupply() + numConnectors <= MAX_SUPPLY,
            "MAX_SUPPLY_ERROR"
        );
        require(
            totalMintsPerAddress[msg.sender] + numConnectors <= MAX_MINTS_PER_WALLET,
            "MAX_MINTS_PER_WALLET_ERROR"
        );

        uint256 costToMint = FINAL_PRICE * numConnectors;
        require(costToMint <= msg.value, "INVALID_PRICE");

        totalMintsPerAddress[msg.sender] += numConnectors;

        for (uint256 i = 0; i < numConnectors; i++) {
            uint256 mintIndex = nextToken();
            _safeMint(msg.sender, mintIndex);
        }

        if (msg.value > costToMint) {
            Address.sendValue(payable(msg.sender), msg.value - costToMint);
        }
    }

    /**
     * @notice Presale. Mint connectors
     */
    function mintPresaleConnectors(uint8 numConnectors, bytes memory signature) external payable whenPreSaleActive nonReentrant
    {
        require(
            totalSupply() + numConnectors <= MAX_SUPPLY,
            "MAX_SUPPLY_ERROR"
        );
        require(
            totalMintsPerAddress[msg.sender] + numConnectors <= MAX_MINTS_PER_WALLET,
            "MAX_MINTS_PER_WALLET_ERROR"
        );

        require(verifyAddressSigner(signature), "SIGNATURE_VALIDATION_FAILED");

        uint256 costToMint = FINAL_PRICE * numConnectors;
        require(costToMint <= msg.value, "INVALID_PRICE");

        totalMintsPerAddress[msg.sender] += numConnectors;

        for (uint256 i = 0; i < numConnectors; i++) {
            uint256 mintIndex = nextToken();
            _safeMint(msg.sender, mintIndex);
        }

        if (msg.value > costToMint) {
            Address.sendValue(payable(msg.sender), msg.value - costToMint);
        }
    }

    /**
     * @notice Verify signature
     */
    function verifyAddressSigner(bytes memory signature) private view returns (bool) {
        bytes32 messageHash = keccak256(abi.encodePacked(msg.sender));
        return signerAddress == messageHash.toEthSignedMessageHash().recover(signature);
    }

    /**
     * @notice Read the base token URI
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
     * @notice Update the base token URI
     */
    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    /**
     * @notice Add json extension to all token URI's
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory)
    {
        return string(abi.encodePacked(super.tokenURI(tokenId), '.json'));
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal
    override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _afterTokenTransfer(address from, address to, uint256 tokenId)
    internal
    override(ERC721, ERC721Votes)
    {
        super._afterTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}