// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "../dependencies/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract CoxRider is ERC721A, Ownable {
    bytes32 private _whitelistHash;

    uint256 public maxSupply = 6969;
    uint256 public freeSupply = 1234;
    uint256 public whitelistSupply = 69;

    uint256 private constant maxPerAddress = 5;
    uint256 private constant maxFreePerAddress = 1;

    uint256 public constant publicMintPrice = 0.0069 ether;

    uint256 public saleStartDate = 1656514800;
    uint256 public freeStartDate = 1656514800;

    uint256 public freeMintCounter;
    uint256 public whitelistMintCounter;

    string private baseUri =
        "https://gateway.pinata.cloud/ipfs/QmUSRkWsKm9EwJENnjf2bfPSnxcTGBewSjgLop8JgjK5KP/";

    string private baseExtension = ".json";

    constructor(bytes32 hashes) ERC721A("COX RIDER", "COX") {
        _whitelistHash = hashes;
    }

    modifier onlyEOA() {
        require(msg.sender == tx.origin, "Only EOA");
        _;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        return
            bytes(baseUri).length != 0
                ? string(
                    abi.encodePacked(
                        baseUri,
                        Strings.toString(tokenId),
                        baseExtension
                    )
                )
                : "";
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseUri = uri;
    }

    function isSaleOpen() public view returns (bool) {
        return block.timestamp >= saleStartDate;
    }

    function isFreeOpen() public view returns (bool) {
        return block.timestamp >= freeStartDate;
    }

    function setSaleStartDate(uint256 date) external onlyOwner {
        saleStartDate = date;
    }

    function setFreeStartDate(uint256 date) external onlyOwner {
        freeStartDate = date;
    }

    function setMaxSupply(uint256 amount) external onlyOwner {
        maxSupply = amount;
    }

    function setWhitelistSupply(uint256 amount) external onlyOwner {
        whitelistSupply = amount;
    }

    function setFreeSupply(uint256 amount) external onlyOwner {
        freeSupply = amount;
    }

    function setHashWhitelist(bytes32 root) external onlyOwner {
        _whitelistHash = root;
    }

    function numberminted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function freeMint(uint256 amount) external onlyEOA {
        require(isFreeOpen(), "Free not open");
        require(totalSupply() + amount <= maxSupply, "Max Supply reached");
        require(
            (amount > 0) && (amount <= maxFreePerAddress),
            "Incorrect amount"
        );
        require(
            _numberMinted(msg.sender) + amount <= maxFreePerAddress,
            "Max per address"
        );
        require(freeMintCounter + amount <= freeSupply, "Max supply reached");
        freeMintCounter++;
        _safeMint(msg.sender, amount);
    }

    function whitelistMint(bytes32[] calldata proof, uint256 amount)
        external
        onlyEOA
    {
        require(verifyWhitelist(proof, _whitelistHash), "Not whitelisted");

        require(totalSupply() + amount <= maxSupply, "Max Supply reached");
        require((amount > 0) && (amount <= maxPerAddress), "Incorrect amount");
        require(
            _numberMinted(msg.sender) + amount <= maxPerAddress,
            "Max per address"
        );
        require(
            whitelistMintCounter + amount <= whitelistSupply,
            "Max supply reached"
        );
        whitelistMintCounter++;
        _safeMint(msg.sender, amount);
    }

    function publicMint(uint256 amount) external payable onlyEOA {
        require(isSaleOpen(), "Sale not open");
        require(totalSupply() + amount <= maxSupply, "Max Supply reached");
        require((amount > 0) && (amount <= maxPerAddress), "Incorrect amount");
        require(
            _numberMinted(msg.sender) + amount <= maxPerAddress,
            "Max per address"
        );
        require(msg.value >= publicMintPrice * amount, "Incorrect Price sent");
        _safeMint(msg.sender, amount);
    }

    function verifyWhitelist(bytes32[] memory _proof, bytes32 _roothash)
        private
        view
        returns (bool)
    {
        bytes32 _leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(_proof, _roothash, _leaf);
    }

    function withdrawBalance() external onlyOwner {
        require(address(this).balance > 0, "Zero Balance");
        payable(msg.sender).transfer(address(this).balance);
    }

    function burn(uint256 tokenId) public virtual {
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr ||
            isApprovedForAll(prevOwnership.addr, _msgSender()) ||
            getApproved(tokenId) == _msgSender());

        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();

        _burn(tokenId);
    }
}