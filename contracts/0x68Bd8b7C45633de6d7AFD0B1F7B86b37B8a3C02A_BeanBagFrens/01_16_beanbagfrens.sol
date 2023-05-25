//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract BeanBagFrens is ERC721, Ownable, ReentrancyGuard, VRFConsumerBase {
    using ECDSA for bytes32;

    bytes32 internal immutable LINK_KEY_HASH;
    uint256 internal immutable LINK_FEE;
    uint256 internal TOKEN_OFFSET;
    string internal PROVENANCE_HASH;
    string internal _baseTokenURI;

    uint256 public constant MAX_RESERVED = 123;
    uint256 public constant MAX_SUPPLY = 7777;
    uint256 public constant MINT_PRICE = 0.0777 ether;

    bool public revealed;
    address public signer;
    string public metadataURI;
    string public placeholderURI;
    uint256 public totalSupply;
    uint256 public reserved;
    uint256 public maxPerAddress = 2;

    mapping(address => uint256) public minted;
    mapping(bytes4 => bool) public locked;

    constructor(
        address vrfCoordinator,
        address linkToken,
        bytes32 keyHash,
        uint256 linkFee
    )
        ERC721("BeanBagFrens", "BBFRENS")
        VRFConsumerBase(vrfCoordinator, linkToken)
    {
        LINK_KEY_HASH = keyHash;
        LINK_FEE = linkFee;
    }

    /**
     * @notice Modifier applied to functions that will be disabled when they're no longer needed
     */
    modifier lockable() {
        require(!locked[msg.sig], "Function is locked");
        _;
    }

    /**
     * @notice Lock individual functions that are no longer needed
     * @dev Only affects functions with the lockable modifier
     * @param id First 4 bytes of the calldata (i.e. function identifier)
     */
    function lockFunction(bytes4 id) public onlyOwner {
        locked[id] = true;
    }

    /**
     * @notice Override ERC721 _baseURI function to use base URI pattern
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @notice Return token metadata
     * @param tokenId to return metadata for
     * @return token URI for the specified token
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return revealed ? ERC721.tokenURI(tokenId) : placeholderURI;
    }

    /**
     * @notice Token offset is added to the token ID (wrapped on overflow) to get metadata asset index
     */
    function tokenOffset() public view returns (uint256) {
        require(TOKEN_OFFSET != 0, "Offset is not set");

        return TOKEN_OFFSET;
    }

    /**
     * @notice Provenance hash is used as proof that token metadata has not been modified
     */
    function provenanceHash() public view returns (string memory) {
        require(bytes(PROVENANCE_HASH).length != 0, "Provenance hash is not set");

        return PROVENANCE_HASH;
    }

    /**
     * @notice Set token offset using Chainlink VRF
     * @dev https://docs.chain.link/docs/chainlink-vrf/
     * @dev Can only be set once
     * @dev Provenance hash must already be set
     */
    function setTokenOffset() public onlyOwner {
        require(TOKEN_OFFSET == 0, "Offset is already set");
        provenanceHash();

        requestRandomness(LINK_KEY_HASH, LINK_FEE);
    }

    /**
     * @notice Set provenance hash
     * @dev Can only be set once
     * @param _provenanceHash metadata proof string
     */
    function setProvenanceHash(string memory _provenanceHash) public onlyOwner {
        require(bytes(PROVENANCE_HASH).length == 0, "Provenance hash is already set");

        PROVENANCE_HASH = _provenanceHash;
    }

    /**
     * @notice Flip token metadata to revealed
     * @dev Can only be revealed after token offset has been set
     */
    function flipRevealed() public lockable onlyOwner {
        tokenOffset();

        revealed = !revealed;
    }

    /**
     * @notice Reserves to various addresses
     * @dev Can be locked
     * @param amount of tokens to be reserved
     * @param to address to receive reserved tokens
     */
    function reserve(uint256 amount, address to) public lockable onlyOwner {
        require(reserved + amount <= MAX_RESERVED,  "Exceeds maximum number of reserved tokens");
        require(totalSupply + amount <= MAX_SUPPLY, "Insufficient supply");

        for (uint256 i = 0; i < amount; i++) {
            _safeMint(to, totalSupply);
            totalSupply += 1;
        }

        reserved += amount;
    }

    /**
     * @notice Set signature signing address
     * @param _signer address of account used to create mint signatures
     */
    function setSigner(address _signer) public lockable onlyOwner {
        signer = _signer;
    }

    /**
     * @notice Set base token URI
     * @param URI base metadata URI to be prepended to token ID
     */
    function setBaseTokenURI(string memory URI) public lockable onlyOwner {
        _baseTokenURI = URI;
    }

    /**
     * @notice Set base token URI
     * @param URI base metadata URI to be prepended to token ID
     */
    function setMetadataURI(string memory URI) public lockable onlyOwner {
        metadataURI = URI;
    }

    /**
     * @notice Set placeholder token URI
     * @param URI placeholder metadata returned before reveal
     */
    function setPlaceholderURI(string memory URI) public onlyOwner {
        placeholderURI = URI;
    }

    /**
     * @notice Set max mints per address
     * @param amount of mints a single signature is valid for
     */
    function setMaxPerAddress(uint256 amount) public onlyOwner {
        maxPerAddress = amount;
    }

    /**
     * @notice Callback function for Chainlink VRF request randomness call
     * @dev Maximum offset value is the maximum token supply - 1
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        TOKEN_OFFSET = randomness % MAX_SUPPLY;
    }

    /**
     * @notice Mint a Fren using a signature
     * @param amount of Fren to mint
     * @param signature created by signer account
     */
    function mint(uint256 amount, bytes memory signature) public payable nonReentrant {
        require(signer == ECDSA.recover(
            ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(_msgSender()))),
            signature
        ), "Invalid signature");

        require(totalSupply + amount <= MAX_SUPPLY,             "Insufficient supply");
        require(msg.value == MINT_PRICE * amount,               "Invalid Ether amount sent");
        require(minted[_msgSender()] + amount <= maxPerAddress, "Insufficient mints available");

        for (uint256 i = 0; i < amount; i++) {
            _safeMint(_msgSender(), totalSupply);
            totalSupply += 1;
        }

        minted[_msgSender()] += amount;
    }

    /**
     * @notice Withdraw all ETH transferred to the contract
     */
    function withdraw() external onlyOwner {
        Address.sendValue(payable(_msgSender()), address(this).balance);
    }

    /**
     * @notice Reclaim any unused LINK
     * @param amount of LINK to withdraw
     */
    function withdrawLINK(uint256 amount) external onlyOwner {
        LINK.transfer(_msgSender(), amount);
    }
}