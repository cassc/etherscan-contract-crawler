pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "hardhat/console.sol";

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TimithTestContract is Ownable, ERC721A, ReentrancyGuard {
    using ECDSA for bytes32;
    /**
     *
     * Contract Events
     *
     */
    event SetPurpose(address sender, string purpose);
    event DegenMinted(address indexed sender);

    /**
     *
     * Contract Values
     *
     */
    address public signatureVerifier;
    string public _baseDegenURI;
    uint256 public maxFree = 100;
    uint256 public maxSupply = 1000;
    uint256 public maxPerTx = 10;
    uint256 public mintPrice = 0.003 ether;
    bool public isMintingPublic = false;

    constructor(string memory baseURI) payable ERC721A("Test", "TST") {
        _baseDegenURI = baseURI;
    }

    /**
     *
     * Modifiers
     *
     */
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    /**
     *
     * Minting Functions
     *
     */
    function mithWithSignature(bytes memory _signature) public callerIsUser {
        bytes memory message = abi.encodePacked(msg.sender);
        bytes32 messageHash = ECDSA.toEthSignedMessageHash(keccak256(message));

        require(
            messageHash.recover(_signature) == signatureVerifier,
            "Unrecognizable Hash"
        );
        _mint(msg.sender, 1);
        emit DegenMinted(msg.sender);
    }

    function mint(uint256 amount) public payable callerIsUser nonReentrant {
        require(amount > 0, "You must send an amount");
        require(amount <= maxPerTx, "You cannot mint this many per Txn");

        require(isMintingPublic, "Public Sale has not begun.");
        require(
            (totalSupply() + amount) <= maxSupply,
            "Not enough remaining supply"
        );
        require(msg.value == (amount * mintPrice), "You must send enough eth");

        _mint(msg.sender, amount);
        emit DegenMinted(msg.sender);
    }

    function ownerMint(uint256 amount) public payable onlyOwner {
        require(amount > 0, "You must send an amount");
        require(
            (totalSupply() + amount) <= maxSupply,
            "Not enough remaining supply"
        );
        _mint(msg.sender, amount);
    }

    /**
     *
     * Setting Functions
     *
     */
    function setBaseURI(string memory newUri) public onlyOwner {
        _baseDegenURI = newUri;
    }

    function toggleMinting(bool isPublic) public onlyOwner {
        isMintingPublic = isPublic;
    }

    function setMaxTxnAmount(uint256 maxAmount) public onlyOwner {
        maxPerTx = maxAmount;
    }

    function setMintPrice(uint256 newPrice) public onlyOwner {
        mintPrice = newPrice;
    }

    function setMaxSupply(uint256 newSupply) public onlyOwner {
        maxSupply = newSupply;
    }

    function setMaxFree(uint256 newFreeSupply) public onlyOwner {
        maxFree = newFreeSupply;
    }

    function setSignatureVerifier(address _signatureVerifier)
        external
        onlyOwner
    {
        signatureVerifier = _signatureVerifier;
    }

    /**
     *
     * Overriding Functions
     *
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseDegenURI;
    }

    /**
     *
     * Owner Functions
     *
     */
    function withdraw() public onlyOwner {
        require(address(this).balance > 0, "Insufficient balance");
        Address.sendValue(payable(msg.sender), address(this).balance);
    }

    function withdrawTo(uint256 amount, address payable to) public onlyOwner {
        require(address(this).balance > 0, "Insufficient balance");
        Address.sendValue(to, amount);
    }

    // TODO: Delete This later
    // to support receiving ETH by default
    receive() external payable {}

    fallback() external payable {}
}