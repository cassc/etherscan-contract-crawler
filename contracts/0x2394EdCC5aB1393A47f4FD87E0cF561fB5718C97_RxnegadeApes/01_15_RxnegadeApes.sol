// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "erc721a/contracts/ERC721A.sol";

import "../RxnegadeCollection/RxnegadeCollection.sol";

/**
 * @title RxnegadeApes
 */
contract RxnegadeApes is IERC2981, ERC721A, Ownable, RxnegadeCollection {
    address private SIGNER_ADDRESS;

    bool public PUBLIC_MINTING_ACTIVE = false;
    bool public FROZEN = false;

    mapping(uint256 => bool) public freeTokenMinted;
    mapping(bytes32 => bool) private nonceUsed;

    string private BASE_URI;
    string public contractURI;

    uint256 public ownerMinted = 0;
    uint256 private constant MAX_OWNER_MINTS = 200;

    uint256 private constant MAX_TOKENS_PER_MEMBER = 100;
    uint256 private constant MAX_TOKENS_PER_MINT = 100;
    uint256 private constant MAX_TOTAL_SUPPLY = 19946;

    uint256 public constant TOKEN_PRICE = 0.01 ether;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _contractURI,
        address rxngd_,
        address signer_
    ) ERC721A(_name, _symbol) {
        _init(rxngd_, _startTokenId(), MAX_TOTAL_SUPPLY);
        
        BASE_URI = _initBaseURI;
        contractURI = _contractURI;

        SIGNER_ADDRESS = signer_;
    }

    modifier onlyEOA() {
        require(msg.sender == tx.origin, "Only EOA");
        _;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    // EXTERNAL

    receive() external payable {}

    // PUBLIC

    /**
     * Mint Tokens
     * @dev mints the quantity of tokens to the sender, requires a signature from a message signed by the RXAPE Signer
     * @param quantity the number of tokens to mint
     * @param nonce the nonce used to form the signature
     */
    function mint(
        uint256 quantity,
        uint256 rxId,
        string memory nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable onlyEOA onlyRx {
        _checkPublicMinting();
        _checkRx(rxId);
        _checkQuantity(quantity, rxId);
        _checkValue(quantity);
        _verifySignature(nonce, v, r, s);

        _setMintedByRx(_currentIndex, quantity, rxId);
        _safeMint(msg.sender, quantity);
    }

    /**
     * Mint Complimentary Token
     * @dev mints a token to the sender without paying, requires a signature from a message signed by the RXAPE Signer
     * @param nonce the nonce used to form the signature
     */
    function mintComplimentary(
        uint256 rxId,
        string memory nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public onlyEOA onlyRx {
        _checkPublicMinting();
        _checkRx(rxId);
        _checkQuantity(1, rxId);
        require(
            !freeTokenMinted[rxId],
            "RXAPE: complimentary token already minted"
        );
        _verifySignature(nonce, v, r, s);

        freeTokenMinted[rxId] = true;
        _setMintedByRx(_currentIndex, 1, rxId);
        _safeMint(msg.sender, 1);
    }

    /**
     * Gift Tokens
     * @dev mints tokens to the provided address, requires a signature from a message signed by the RXAPE Signer
     * @param to address to mint the tokens to
     * @param nonce the nonce used to form the signature
     */
    function mintGift(
        address to,
        uint256 quantity,
        uint256 rxId,
        string memory nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable onlyEOA onlyRx {
        _checkPublicMinting();
        _checkRx(rxId);
        _checkQuantity(quantity, rxId);
        _checkValue(quantity);
        _verifySignature(nonce, v, r, s);

        _setMintedByRx(_currentIndex, quantity, rxId);
        _safeMint(to, quantity);
    }

    /**
     * Royalty Info
     * @dev provides the amount and address to send royalties to for a token sale
     * @param tokenId the ID of the token sold
     * @param salePrice the full price paid in the sale of the token
     * @return address the address to send royalties to
     * @return uint256 the royalty value in the same denomination provided for salePrice
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address, uint256)
    {
        address recipient = tokenRxOwner(tokenId);
        uint256 royaltyPts = tokenRoyaltyPts(tokenId);

        uint256 safePrice = salePrice - (salePrice % 10000);
        uint256 royaltyAmount = (safePrice / 10000) * royaltyPts;

        return (recipient, royaltyAmount);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
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

    // ONLY OWNER

    /**
     * Freeze Contract
     * @dev prevents further changes to the metadata URI
     */
    function freeze() public onlyOwner {
        _checkFrozen();
        require(
            !PUBLIC_MINTING_ACTIVE || _currentIndex > MAX_TOTAL_SUPPLY,
            "RXAPE: Public minting still active"
        );
        FROZEN = true;
    }

    /**
     * Owner Mint
     * @dev mints quantity of tokens to the owner of the specified RXNGD token
     * @param rxId the id of the Rxnegades member token
     * @param quantity the quantity of tokens to mint to the Rxngades member
     */
    function ownerMint(uint256 rxId, uint256 quantity) public onlyOwner {
        require(
            ownerMinted + quantity <= MAX_OWNER_MINTS,
            "RXAPE: too many minted as owner"
        );
        _checkQuantity(quantity, rxId);

        ownerMinted += quantity;
        _setMintedByRx(_currentIndex, quantity, rxId);
        _safeMint(_rxOwner(rxId), quantity);
    }

    /**
     * Set Base URI
     * @dev updates the base URI used for providing token metadata
     */
    function setBaseURI(string memory uri) public onlyOwner {
        _checkFrozen();
        BASE_URI = uri;
    }

    /**
     * Set Signer Address
     * @dev updates the address of the wallet used to sign server messages
     */
    function setSignerAddress(address address_) public onlyOwner {
        SIGNER_ADDRESS = address_;
    }

    /**
     * Toogle Public Minting
     * @dev ollows the owner to turn public minting on and off
     */
    function togglePublicMinting() public onlyOwner {
        PUBLIC_MINTING_ACTIVE = !PUBLIC_MINTING_ACTIVE;
    }

    /**
     * Withdraw
     * @dev allows the owner to withdraw contract balance to the given address
     */
    function withdraw(address address_) public onlyOwner {
        payable(address_).transfer(address(this).balance);
    }

    // PUBLIC VIEWS

    /**
     * Token URI
     * @param tokenId the ID of the token to retrieve the metadata location for
     * @return string the metadata location of the specified token ID
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(tokenId < _currentIndex, "RXAPE: nonexistent token");
        return string(abi.encodePacked(BASE_URI, Strings.toString(tokenId)));
    }

    // INTERNAL

    function _baseURI() internal view override returns (string memory) {
        return BASE_URI;
    }

    // PRIVATE

    function _checkFrozen() internal view {
        require(!FROZEN, "RXAPE: contract frozen");
    }

    function _checkPublicMinting() internal view {
        require(PUBLIC_MINTING_ACTIVE, "RXAPE: Public minting not active");
    }

    function _checkQuantity(uint256 quantity, uint256 rxId) internal view {
        require(quantity <= MAX_TOKENS_PER_MINT, "RXAPE: quantity too high");
        require(
            _currentIndex - _startTokenId() + quantity <= MAX_TOTAL_SUPPLY,
            "RXAPE: not enough supply left"
        );
        _checkRxCollectionSize(rxId, quantity);
    }

    function _checkRx(uint256 rxId) internal view {
        require(
            _rxOwner(rxId) == msg.sender,
            "RXAPE: caller is not the RXNGD token owner"
        );
    }

    function _checkRxCollectionSize(uint256 rxId, uint256 quantity)
        internal
        view
    {
        require(
            rxCollectionSize[rxId] + quantity <= MAX_TOKENS_PER_MEMBER,
            "RxnegadeCollection: more than total allowed per Rxnegade"
        );
    }

    function _checkValue(uint256 quantity) internal view {
        uint256 requiredValue = TOKEN_PRICE * quantity;
        require(msg.value >= requiredValue, "RXAPE: not enough ETH sent");
    }

    function _verifySignature(
        string memory nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) private {
        bytes32 message = keccak256(abi.encodePacked(nonce, msg.sender));

        require(!nonceUsed[message], "RXAPE: nonce already used");

        bytes32 hash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", message)
        );
        require(
            ecrecover(hash, v, r, s) == SIGNER_ADDRESS,
            "RXAPE: invalid signature"
        );

        nonceUsed[message] = true;
    }
}