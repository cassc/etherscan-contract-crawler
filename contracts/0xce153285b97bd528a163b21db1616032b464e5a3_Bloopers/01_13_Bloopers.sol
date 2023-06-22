// SPDX-License-Identifier: MIT
// Creator: base64.tech
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./ERC721A.sol";

/*
 _______  ___      _______  _______  _______  _______  ______    _______ 
|  _    ||   |    |       ||       ||       ||       ||    _ |  |       |
| |_|   ||   |    |   _   ||   _   ||    _  ||    ___||   | ||  |  _____|
|       ||   |    |  | |  ||  | |  ||   |_| ||   |___ |   |_||_ | |_____ 
|  _   | |   |___ |  |_|  ||  |_|  ||    ___||    ___||    __  ||_____  |
| |_|   ||       ||       ||       ||   |    |   |___ |   |  | | _____| |
|_______||_______||_______||_______||___|    |_______||___|  |_||_______|

 A METACITZN COLLECTION

 developed by base64.tech 
*/
contract Bloopers is ERC721A, Ownable {
    using ECDSA for bytes32;

    uint256 public constant TOTAL_MAX_SUPPLY = 10500 + 1; // MAX SUPPLY = 10500, +1 for gas optimization for use in conditional statements
    uint256 public constant MAX_ALLOWLIST_MINT_PER_WALLET = 3 + 1; // MAX PUBLIC MINT PER WALLET = 3, +1 for gas optimization for use in conditional statements
    uint256 public constant MAX_PUBLIC_MINT_PER_WALLET = 3 + 1; // MAX PUBLIC MINT PER WALLET = 3, +1 for gas optimization for use in conditional statements
    uint256 public constant TOKEN_PRICE = .088 ether;

    address public signatureVerifier;

    bool public publicSaleActive;
    bool public preSaleActive;
    bool public freeClaimActive;

    mapping(bytes32 => bool) public usedHashes;
    mapping(address => uint256) public numberFreeMinted;
    mapping(address => uint256) public numberAllowListMinted;
    mapping(address => uint256) public numberPublicMinted;

    string private _baseTokenURI;

    constructor() ERC721A("Bloopers", "BLOOPERS") {}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    modifier validateFreeClaimActive() {
        require(freeClaimActive, "free claim is not active");
        _;
    }

    modifier validatePreSaleActive() {
        require(preSaleActive, "pre-sale is not active");
        _;
    }

    modifier validatePublicSaleActive() {
        require(publicSaleActive, "public sale is not active");
        _;
    }

    modifier correctAmountSent(uint256 _quantity) {
        require(msg.value >= TOKEN_PRICE * _quantity, "Need to send more ETH.");
        _;
    }

    modifier underMaxSupply(uint256 _quantity) {
        require(
            _totalMinted() + _quantity < TOTAL_MAX_SUPPLY,
            "Purchase would exceed max supply"
        );
        _;
    }

    function hashMessage(
        address sender,
        uint256 nonce,
        uint256 maxAllocation
    ) public pure returns (bytes32) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(sender, nonce, maxAllocation))
            )
        );
        return hash;
    }

    function freeMint(
        bytes memory _signature,
        uint256 _quantity,
        uint256 _nonce,
        uint256 _maxAllocation
    ) external callerIsUser validateFreeClaimActive {
        uint256 quantity = numberFreeMinted[msg.sender] + _quantity;
        require(
            quantity < _maxAllocation + 1,
            "Mint would exceed maximum allocation for Free Mints for this wallet"
        );
        _bloopersMint(_signature, _quantity, _nonce, _maxAllocation);
        numberFreeMinted[msg.sender] += _quantity;
    }

    function allowListMint(
        bytes memory _signature,
        uint256 _quantity,
        uint256 _nonce
    )
        external
        payable
        callerIsUser
        validatePreSaleActive
        correctAmountSent(_quantity)
    {
        uint256 quantity = numberAllowListMinted[msg.sender] + _quantity;
        require(
            quantity < MAX_ALLOWLIST_MINT_PER_WALLET,
            "Mint would exceed maximum allowList allocation for this wallet"
        );
        _bloopersMint(_signature, _quantity, _nonce, 3);
        numberAllowListMinted[msg.sender] += _quantity;
    }

    function publicMint(
        bytes memory _signature,
        uint256 _quantity,
        uint256 _nonce
    )
        external
        payable
        callerIsUser
        validatePublicSaleActive
        correctAmountSent(_quantity)
    {
        uint256 quantity = numberPublicMinted[msg.sender] + _quantity;
        require(
            quantity < MAX_PUBLIC_MINT_PER_WALLET,
            "Mint would exceed maximum allocation for Public Mints for this wallet"
        );
        _bloopersMint(_signature, _quantity, _nonce, 3);
        numberPublicMinted[msg.sender] += _quantity;
    }

    function _bloopersMint(
        bytes memory _signature,
        uint256 _quantity,
        uint256 _nonce,
        uint256 _maxAllocation
    ) private underMaxSupply(_quantity) {
        bytes32 messageHash = hashMessage(msg.sender, _nonce, _maxAllocation);
        require(
            messageHash.recover(_signature) == signatureVerifier,
            "Unrecognizable Hash"
        );
        require(usedHashes[messageHash] == false, "Hash was already used");

        usedHashes[messageHash] = true;
        _mint(msg.sender, _quantity, "", false);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return _ownershipOf(tokenId);
    }

    /* OWNER FUNCTIONS */

    function ownerMint(uint256 _numberToMint)
        external
        onlyOwner
        underMaxSupply(_numberToMint)
    {
        _mint(msg.sender, _numberToMint, "", false);
    }

    function ownerMintToAddress(address _recipient, uint256 _numberToMint)
        external
        onlyOwner
        underMaxSupply(_numberToMint)
    {
        _mint(_recipient, _numberToMint, "", false);
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdrawFunds() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function setSignatureVerifier(address _signatureVerifier)
        external
        onlyOwner
    {
        signatureVerifier = _signatureVerifier;
    }

    function flipPublicSaleActive() external onlyOwner {
        publicSaleActive = !publicSaleActive;
    }

    function flipPreSaleActive() external onlyOwner {
        preSaleActive = !preSaleActive;
    }

    function flipFreeClaimActive() external onlyOwner {
        freeClaimActive = !freeClaimActive;
    }
}