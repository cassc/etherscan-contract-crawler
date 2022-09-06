pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TimithBeta is Ownable, ERC721A, ReentrancyGuard {
    using ECDSA for bytes32;
    /**
     *
     * Contract Events
     *
     */
    event Minted(address indexed sender);

    /**
     *
     * Contract Values
     *
     */
    mapping(address => bool) public hasMinted;

    address public signatureVerifier;
    string public _baseTokenURI;
    uint256 public mintPrice = 0.000 ether;

    constructor(string memory baseURI, address verifier)
        payable
        ERC721A("TimithBeta", "TimithBeta")
    {
        _baseTokenURI = baseURI;
        signatureVerifier = verifier;
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
    function mithWithSignature(address to, bytes memory _signature)
        public
        callerIsUser
        nonReentrant
    {
        require(!hasMinted[to], "You have already claimed your nft");
        bytes memory message = abi.encodePacked(to);
        bytes32 messageHash = ECDSA.toEthSignedMessageHash(keccak256(message));
        address signer = ECDSA.recover(messageHash, _signature);

        require(signer == signatureVerifier, "Unrecognizable Hash");
        _mint(to, 1);

        hasMinted[to] = true;
        emit Minted(to);
    }

    function ownerMint(uint256 amount) public payable onlyOwner {
        require(amount > 0, "You must send an amount");
        _mint(msg.sender, amount);
    }

    /**
     *
     * Setting Functions
     *
     */
    function setBaseURI(string memory newUri) public onlyOwner {
        _baseTokenURI = newUri;
    }

    function setMintPrice(uint256 newPrice) public onlyOwner {
        mintPrice = newPrice;
    }

    function setSignatureVerifier(address _signatureVerifier)
        external
        onlyOwner
    {
        signatureVerifier = _signatureVerifier;
    }

    /**
     *
     * Getters Functions
     *
     */
    function getAddressHasMinted(address addr)
        public
        view
        virtual
        returns (bool)
    {
        return hasMinted[addr];
    }

    /**
     *
     * Overriding Functions
     *
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "That token doesn't exist");
        return
            bytes(_baseTokenURI).length > 0
                ? string(abi.encodePacked(_baseTokenURI))
                : "";
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
}