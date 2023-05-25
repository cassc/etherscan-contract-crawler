// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract Malartic is ERC721A, Ownable, EIP712, Pausable {
    using Strings for uint256;

    //SUPPLY
    uint8 public constant MAX_SUPPLY = 150;
    uint8 public constant MAX_MINT_PER_WALLET = 4;

    //METADATA
    string public baseURI;
    string private collectionURI;

    //MALARTIC SALE CONTRACT ADDRESS
    address private malarticSaleAddress;

    //REDEEM MAPPING
    mapping(uint8 => uint256) public redeemedTimestamp;

    //MINT PER ADDRESS COUNTER MAPPING
    mapping(address => uint8) public addressMints;

    //MINT EVENT
    event Mint(address to, uint256 amount);

    //METADATA UPDATE EVENT
    event MetadataUpdate(uint256 _tokenId);

    //MODIFIERS
    modifier checkMintPerAddress(address minter, uint256 amount) {
        require(
            addressMints[minter] + amount <= MAX_MINT_PER_WALLET,
            "Mint limit per wallet was exceeded"
        );
        _;
    }

    modifier checkSupply(uint256 amount) {
        require(
            totalSupply() + amount <= MAX_SUPPLY,
            "Mint supply limit was exceeded"
        );
        _;
    }

    constructor(
        address _receiverAddress
    ) ERC721A("Malartic", "Malartic") EIP712("Malartic", "1") {
        _safeMint(_receiverAddress, 6);
    }

    /**
     * @dev Function that allows the Sale contract to mint in batch
     * @param to Address that will receive the NFTs after the payment
     * @param amount The amount of NFTs to be minted
     */
    function batchMint(
        address to,
        uint8 amount
    ) external checkMintPerAddress(to, amount) checkSupply(amount) {
        require(msg.sender == malarticSaleAddress, "Not allowed");
        _safeMint(to, amount);
        addressMints[to] = addressMints[to] + amount;
        emit Mint(to, amount);
    }

    /**
     * @dev Function that allows the owner of the contract to drop NFTs for free
     * @param to Address that will receive the NFTs
     * @param amount The amount of NFTs to be minted
     */
    function drop(
        address to,
        uint256 amount
    ) public onlyOwner checkSupply(amount) {
        _safeMint(to, amount);
    }

    //REDEEM FUNCTIONS

    // EIP-712 typed structured data signature
    bytes32 private constant MALARTIC_SHIPPING_DATA_TYPEHASH =
        keccak256("MalarticShippingData(bytes32 hashdata,uint64 timestamp)");

    /**
     * @dev Utility function for EIP712
     * @param hashdata The hash of the redeem data
     * @param timestamp The redeem timestamp
     * @param signer The wallet who signed the hashdata
     * @param signature The result of when the "signer" signs the "hashdata"
     */
    function verifyShippingData(
        bytes32 hashdata,
        uint64 timestamp,
        address signer,
        bytes calldata signature
    ) public view returns (bool) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(MALARTIC_SHIPPING_DATA_TYPEHASH, hashdata, timestamp)
            )
        );
        (address a, ECDSA.RecoverError e) = ECDSA.tryRecover(digest, signature);
        return (a == signer) && (e == ECDSA.RecoverError.NoError);
    }

    /**
     * @dev Utility function for EIP712
     * @param tokenId The token Id to be redeemed
     * @param hashdata The hash of the redeem data
     * @param timestamp The redeem timestamp
     * @param signature The result of when the "signer" signs the "hashdata"
     */
    function redeem(
        uint8 tokenId,
        bytes32 hashdata,
        uint64 timestamp,
        bytes calldata signature
    ) public {
        require(ownerOf(tokenId) == msg.sender, "Not allowed");
        require(redeemedTimestamp[tokenId] == 0, "NFT already redeemed");
        require(
            verifyShippingData(hashdata, timestamp, msg.sender, signature),
            "Invalid signature"
        );
        redeemedTimestamp[tokenId] = block.timestamp;
        emit MetadataUpdate(tokenId);
    }

    //PAUSE/UNPAUSE FUNCTIONS
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    //GETTERS
    function tokenURI(
        uint256 tokenId
    ) public view virtual override(ERC721A) returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    function contractURI() public view returns (string memory) {
        return collectionURI;
    }

    //SETTERS
    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function setContractURI(string memory uri) external onlyOwner {
        collectionURI = uri;
    }

    function setMalarticSaleAddress(
        address _malarticSaleAddress
    ) public onlyOwner {
        malarticSaleAddress = _malarticSaleAddress;
    }

    //OVERRIDES
    function _startTokenId()
        internal
        view
        virtual
        override(ERC721A)
        returns (uint256)
    {
        return 1;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override(ERC721A) {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
        require(!paused(), "Pausable: token transfer while paused");
    }

    //supports ERC4906
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A) returns (bool) {
        return
            interfaceId == bytes4(0x49064906) ||
            super.supportsInterface(interfaceId);
    }
}