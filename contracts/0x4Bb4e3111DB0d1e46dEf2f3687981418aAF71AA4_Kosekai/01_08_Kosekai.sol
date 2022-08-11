// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/*
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@     @@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@            @@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@               @@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@                @@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@                 @@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@  /            @ @@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@ #              @@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@ @             @@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@       (@/#@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
*/

contract Kosekai is ERC721A, Ownable {
    enum SaleStatus {
        PAUSED,
        SPIRITLIST,
        PUBLIC,
        CLOSED
    }

    using Strings for uint256;
    using ECDSA for bytes32;

    // Set default sale state as paused
    SaleStatus public saleStatus = SaleStatus.PAUSED;

    string private preRevealURI;
    string private postRevealBaseURI;

    // Sale Settings

    // Reserved Tokens used for Ethereal Airdrops and Mods.
    uint256 public constant RESERVED_TOKENS = 200; // 200

    // Ethereals will be airdropped 1 free Kosekai for minting 2.
    uint256 public constant MAX_ETHEREAL_MINT = 2;
    uint256 public constant MAX_SPIRIT_LIST_MINT = 2;
    uint256 public constant MAX_PUBLIC_MINT = 3;
    uint256 public constant MAX_MOD_MINT = 7;
    uint256 public constant MAX_FREE_MINT = 1; // < 5 free mint winners

    uint256 public maxSupply = 5678;

    // Prices
    uint256 public spiritListCost = 0.05 ether;
    uint256 public publicCost = 0.09 ether;

    // Check Lists
    // Ethereals will be airdropped one free Kosekai for minting two.
    bytes32 public etherealListMerkleRoot;
    bytes32 public spiritListMerkleRoot;
    bytes32 public freeMintListMerkleRoot; // < 5 free mint winners
    bytes32 public modListMerkleRoot;

    // Quantity checks
    mapping(address => uint256) public etherealMintedAmount;
    mapping(address => uint256) public spiritListMintedAmount;
    mapping(address => uint256) public freeMintListMintedAmount;
    mapping(address => uint256) public publicMintedAmount;
    mapping(address => uint256) public modMintedAmount;

    // Reveal vars
    bool public revealed = false;

    event Minted(address indexed receiver, uint256 quantity);

    constructor(string memory _initNotRevealedUri)
        ERC721A("Kosekai Collective", "KOSEKAI")
    {
        preRevealURI = _initNotRevealedUri;
        _mint(msg.sender, RESERVED_TOKENS);
    }

    // ------ METADATA
    function setPreRevealURI(string memory _URI) external onlyOwner {
        preRevealURI = _URI;
    }

    function setPostRevealBaseURI(string memory _URI) external onlyOwner {
        postRevealBaseURI = _URI;
    }

    // ------ Prevention from minting off of Contract
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    // ------ TOKEN URI
    // Before reveal, return same pre-reveal URI
    // After reveal, return post-reveal URI
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        if (!revealed)
            return string(abi.encodePacked(preRevealURI, _tokenId.toString()));
        return string(abi.encodePacked(postRevealBaseURI, _tokenId.toString()));
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    // ------ SET SALE STATUS
    function setSaleStatus(SaleStatus _status) external onlyOwner {
        saleStatus = _status;
    }

    // ------ MERKLE ROOTS TO VERIFY ON LISTS
    function setMerkleRoots(
        bytes32 _spiritListMerkleRoot,
        bytes32 _modListMerkleRoot,
        bytes32 _etherealListMerkleRoot,
        bytes32 _freeMintListMerkleRoot
    ) external onlyOwner {
        spiritListMerkleRoot = _spiritListMerkleRoot;
        modListMerkleRoot = _modListMerkleRoot;
        etherealListMerkleRoot = _etherealListMerkleRoot;
        freeMintListMerkleRoot = _freeMintListMerkleRoot;
    }

    function setSpiritListMerkleRoot(bytes32 _spiritListMerkleRoot)
        external
        onlyOwner
    {
        spiritListMerkleRoot = _spiritListMerkleRoot;
    }

    function setModListMerkleRoot(bytes32 _modListMerkleRoot)
        external
        onlyOwner
    {
        modListMerkleRoot = _modListMerkleRoot;
    }

    function setEtherealListMerkleRoot(bytes32 _etherealListMerkleRoot)
        external
        onlyOwner
    {
        etherealListMerkleRoot = _etherealListMerkleRoot;
    }

    function setFreeMintListMerkleRoot(bytes32 _freeMintListMerkleRoot)
        external
        onlyOwner
    {
        freeMintListMerkleRoot = _freeMintListMerkleRoot;
    }

    //  ------ ETHEREAL SALE
    //  ------ Ethereals will be airdropped one free Kosekai for minting two
    function etherealSale(bytes32[] memory _proof, uint8 _quantity)
        external
        payable
        callerIsUser
    {
        require(
            saleStatus == SaleStatus.SPIRITLIST ||
                saleStatus == SaleStatus.PUBLIC,
            "ETHEREAL SALE NOT ACTIVE"
        );
        require(
            MerkleProof.verify(
                _proof,
                etherealListMerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "MINTER IS NOT ON ETHEREAL LIST"
        );
        require(_quantity >= 1, "QUANTITY MUST BE GREATER OR EQUAL TO 1");
        require(!revealed, "NO MINTS POSTREVEAL");
        require(
            totalSupply() + _quantity <= maxSupply,
            "MAX CAP OF KOSEKAI EXCEEDED"
        );
        require(
            etherealMintedAmount[msg.sender] + _quantity <= MAX_ETHEREAL_MINT,
            "QUANTITY EXCEEDS MAXIMUM FOR THIS WALLET"
        );

        require(msg.value == spiritListCost * _quantity, "INCORRECT ETH SENT");

        etherealMintedAmount[msg.sender] += _quantity;
        _mint(msg.sender, _quantity);

        emit Minted(msg.sender, _quantity);
    }

    function spiritListSale(bytes32[] memory _proof, uint8 _quantity)
        external
        payable
        callerIsUser
    {
        require(
            saleStatus == SaleStatus.SPIRITLIST ||
                saleStatus == SaleStatus.PUBLIC,
            "SPIRITLIST SALE NOT ACTIVE"
        );
        require(
            MerkleProof.verify(
                _proof,
                spiritListMerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "MINTER IS NOT ON SPIRIT LIST"
        );
        require(_quantity >= 1, "QUANTITY MUST BE GREATER OR EQUAL TO 1");
        require(!revealed, "NO MINTS POSTREVEAL");
        require(
            totalSupply() + _quantity <= maxSupply,
            "MAX CAP OF KOSEKAI EXCEEDED"
        );
        require(
            spiritListMintedAmount[msg.sender] + _quantity <=
                MAX_SPIRIT_LIST_MINT,
            "QUANTITY EXCEEDS MAXIMUM FOR THIS WALLET"
        );
        require(msg.value == spiritListCost * _quantity, "INCORRECT ETH SENT");

        spiritListMintedAmount[msg.sender] += _quantity;
        _mint(msg.sender, _quantity);

        emit Minted(msg.sender, _quantity);
    }

    // ------ < 5 free mint winners
    function freeMintListSale(bytes32[] memory _proof, uint8 _quantity)
        external
        callerIsUser
    {
        require(
            saleStatus == SaleStatus.SPIRITLIST ||
                saleStatus == SaleStatus.PUBLIC,
            "FREE MINT SALE NOT ACTIVE"
        );
        require(
            MerkleProof.verify(
                _proof,
                freeMintListMerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "MINTER IS NOT ON FREE MINT LIST"
        );
        require(_quantity >= 1, "QUANTITY MUST BE GREATER OR EQUAL TO 1");
        require(!revealed, "NO MINTS POSTREVEAL");
        require(
            totalSupply() + _quantity <= maxSupply,
            "MAX CAP OF KOSEKAI EXCEEDED"
        );
        require(
            freeMintListMintedAmount[msg.sender] + _quantity <= MAX_FREE_MINT,
            "QUANTITY EXCEEDS MAXIMUM FOR THIS WALLET"
        );

        freeMintListMintedAmount[msg.sender] += _quantity;
        _mint(msg.sender, _quantity);

        emit Minted(msg.sender, _quantity);
    }

    function publicListSale(uint8 _quantity) external payable callerIsUser {
        require(saleStatus == SaleStatus.PUBLIC, "PUBLIC SALE NOT ACTIVE");
        require(_quantity >= 1, "QUANTITY MUST BE GREATER OR EQUAL TO 1");
        require(!revealed, "NO MINTS POSTREVEAL");
        require(
            totalSupply() + _quantity <= maxSupply,
            "MAX CAP OF KOSEKAI EXCEEDED"
        );
        require(
            publicMintedAmount[msg.sender] + _quantity <= MAX_PUBLIC_MINT,
            "QUANTITY EXCEEDS MAXIMUM FOR THIS WALLET"
        );
        require(msg.value == publicCost * _quantity, "INCORRECT ETH SENT");

        publicMintedAmount[msg.sender] += _quantity;
        _mint(msg.sender, _quantity);

        emit Minted(msg.sender, _quantity);
    }

    function modListSale(bytes32[] memory _proof, uint8 _quantity)
        external
        callerIsUser
    {
        require(
            saleStatus == SaleStatus.SPIRITLIST ||
                saleStatus == SaleStatus.PUBLIC,
            "MOD SALE NOT ACTIVE"
        );
        require(
            MerkleProof.verify(
                _proof,
                modListMerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "MINTER IS NOT ON MOD LIST"
        );
        require(_quantity >= 1, "QUANTITY MUST BE GREATER OR EQUAL TO 1");
        require(!revealed, "NO MINTS POSTREVEAL");
        require(
            totalSupply() + _quantity <= maxSupply,
            "MAX CAP OF KOSEKAI EXCEEDED"
        );
        require(modMintedAmount[msg.sender] + _quantity <= MAX_MOD_MINT, "QUANTITY EXCEEDS MAXIMUM FOR THIS WALLET");

        modMintedAmount[msg.sender] += _quantity;
        _mint(msg.sender, _quantity);

        emit Minted(msg.sender, _quantity);
    }

    function setRevealed(bool _revealed) external onlyOwner {
        revealed = _revealed;
    }

    function numberMinted(address _owner) public view returns (uint256) {
        return _numberMinted(_owner);
    }

    function getOwnershipData(uint256 _tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return _ownershipOf(_tokenId);
    }

    // ------ DECREASE MAX SUPPLY ONLY
    function setMaxSupply(uint256 amount) external onlyOwner {
        require(
            amount < maxSupply,
            "Cannot increase supply greater than current max supply!"
        );
        maxSupply = amount;
    }

    function changeSpiritListCost(uint256 newCost) external onlyOwner {
        spiritListCost = newCost;
    }

    function changePublicCost(uint256 newCost) external onlyOwner {
        publicCost = newCost;
    }

    // ------ WITHDRAW FUNDS
    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        if (!success) {
            revert("Ether transfer failed");
        }
    }
}