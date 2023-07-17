// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract Bottle is ERC721A, Ownable, EIP712, Pausable {

    //SUPPLY
    uint256 public immutable MAX_SUPPLY;
    uint256 public immutable MAX_MINT_PER_WALLET;

    //METADATA
    string public baseURI;
    string private collectionURI;

    //MALARTIC SALE CONTRACT ADDRESS
    address public saleAddress;

    //REDEEM MAPPING
    mapping(uint8 => uint256) public redeemedTimestamp;

    //MINT PER ADDRESS COUNTER MAPPING
    mapping(address => uint256) public mintedPerWallet;

    //MINT EVENT
    event Mint(address to, uint256 amount, uint256 firstTokenId, uint256 orderID);

    //DROP EVENT
    event Drop(address to, uint256 amount, uint256 firstTokenId);

    //METADATA UPDATE EVENT
    event MetadataUpdate(uint256 _tokenId);

    //MODIFIERS
    modifier checkMintPerAddress(address account_, uint256 amount_) {
        require(
            mintedPerWallet[account_] + amount_ <= MAX_MINT_PER_WALLET,
            "Bottle: mint limit per wallet was exceeded"
        );
        _;
    }

    modifier checkSupply(uint256 amount_) {
        require(
            totalSupply() + amount_ <= MAX_SUPPLY,
            "Bottle: Mint supply limit was exceeded"
        );
        _;
    }

    constructor(string memory _name, string memory _symbol, uint256 _maxSupply, uint256 _maxMintPerWallet)
        ERC721A(_name, _symbol)
        EIP712(_name, "1")
    {
        MAX_SUPPLY = _maxSupply;
        MAX_MINT_PER_WALLET = _maxMintPerWallet;
    }

    function batchMint(
        address to_,
        uint256 amount_,
        uint256 orderId_
    ) external checkMintPerAddress(to_, amount_) checkSupply(amount_) {
        require(msg.sender == saleAddress, "Not allowed");
        uint256 _firstTokenId = totalSupply() + 1;
        mintedPerWallet[to_] = mintedPerWallet[to_] + amount_;
        _safeMint(to_, amount_);
        emit Mint(to_, amount_, _firstTokenId, orderId_);
    }

    function drop(
        address to_,
        uint256 amount_
    ) public onlyOwner checkSupply(amount_) {
        uint256 _firstTokenId = totalSupply() + 1;
        _safeMint(to_, amount_);
        emit Drop(to_, amount_, _firstTokenId);
    }

    //REDEEM FUNCTIONS

    // EIP-712 typed structured data signature
    bytes32 private constant SHIPPING_DATA_TYPEHASH =
        keccak256(
            "ShippingData(bytes32 hashdata,uint64 timestamp)"
        );

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
                abi.encode(
                    SHIPPING_DATA_TYPEHASH,
                    hashdata,
                    timestamp
                )
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
        require(ownerOf(tokenId) == msg.sender, "Bottle: Not allowed");
        require(
            redeemedTimestamp[tokenId] == 0,
            "Bottle: NFT already redeemed"
        );
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

    function contractURI() public view returns (string memory) {
        return collectionURI;
    }

    //SETTERS
    function setBaseURI(string calldata uri) external onlyOwner {
        baseURI = uri;
    }

    function setContractURI(string calldata uri) external onlyOwner {
        collectionURI = uri;
    }

    function setSaleAddress(address _saleAddress) public onlyOwner {
        saleAddress = _saleAddress;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
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