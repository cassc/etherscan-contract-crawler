// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "../dependencies/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Shibuki is ERC721A, Ownable {
    bytes32 private _whitelistHash;
    bytes32 private _OGHash;
    bytes32 private _reservedHash;

    uint256 public maxSupply = 4200;
    uint256 public bonusSupply = 1500;
    uint256 public whitelistSupply = 2000;

    uint256 private constant maxPerAddress = 20;
    uint256 private constant maxPerWLOG = 4;

    uint256 public constant publicMintPrice = 0.0275 ether;
    uint256 public constant whitelistMintPrice = 0.0225 ether;

    uint256 public saleStartDate = 1650639600;
    uint256 public WLOGStartDate = 1650632400;

    uint32 public bonusMintCounter;
    uint32 public whitelistMintCounter;

    string private baseUri =
        "https://gateway.pinata.cloud/ipfs/QmdzMMNRGYa95BMhQa6MXxXcSFdxCYEqxooLPsYaPzLeKQ/";
    string private baseExtension = ".json";

    bool public isOGBonusOpen = true;
    bool public isFreeOpen = false;
    bool public OGWLOpenstate = true;
    bool private isBaseURISet = false;

    constructor() ERC721A("Shibuki", "SHIB") {}

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
        require(!isBaseURISet, "Meta already set");
        baseUri = uri;
        isBaseURISet = true;
    }

    function isSaleOpen() public view returns (bool) {
        return block.timestamp >= saleStartDate;
    }

    function isWLOGOpen() public view returns (bool) {
        return
            (block.timestamp >= WLOGStartDate &&
                block.timestamp <= WLOGStartDate + 2 hours) && OGWLOpenstate;
    }

    function isOGBonusAvailable() public view returns (bool) {
        return bonusMintCounter < bonusSupply && isOGBonusOpen;
    }

    function setSaleStartDate(uint256 date) external onlyOwner {
        saleStartDate = date;
    }

    function setMaxSupply(uint256 amount) external onlyOwner {
        maxSupply = amount;
    }

    function setBonusSupply(uint256 amount) external onlyOwner {
        bonusSupply = amount;
    }

    function setWhitelistSupply(uint256 amount) external onlyOwner {
        whitelistSupply = amount;
    }

    function setWLOGStartDate(uint256 date) external onlyOwner {
        WLOGStartDate = date;
    }

    function setOGBonusState(bool state) external onlyOwner {
        isOGBonusOpen = state;
    }

    function setOGWLOpenState(bool state) external onlyOwner {
        OGWLOpenstate = state;
    }

    function setFreeState(bool state) external onlyOwner {
        isFreeOpen = state;
    }

    function setHashWhitelist(bytes32 root) external onlyOwner {
        _whitelistHash = root;
    }

    function setHashOG(bytes32 root) external onlyOwner {
        _OGHash = root;
    }

    function setHashReserved(bytes32 root) external onlyOwner {
        _reservedHash = root;
    }

    function numberminted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _claimWithBonus(uint256 amount) private {
        uint16 amountBonus = 0;
        require(
            (msg.value >= publicMintPrice * amount) && (amount > 0),
            "Incorrect Price sent"
        );
        if (amount == 2) {
            amountBonus = 1;
        } else if (amount == 4) {
            amountBonus = 2;
        }
        require(
            totalSupply() + (amount + amountBonus) <= maxSupply,
            "Max Supply reached"
        );
        require(
            _numberMinted(msg.sender) + (amount) <= maxPerWLOG,
            "Max per address"
        );
        require(
            bonusMintCounter + amountBonus <= bonusSupply,
            "Free Mint Stock Unavailable"
        );
        bonusMintCounter += amountBonus;
        _safeMint(msg.sender, amount + amountBonus);
    }

    function _claimSale(uint256 amount, bool isPublic) private {
        require(totalSupply() + amount <= maxSupply, "Max Supply reached");
        require(
            (amount > 0) && (amount <= (isPublic ? maxPerAddress : maxPerWLOG)),
            "Incorrect amount"
        );
        require(
            _numberMinted(msg.sender) + amount <=
                (isPublic ? maxPerAddress : maxPerWLOG),
            "Max per address"
        );
        require(msg.value >= publicMintPrice * amount, "Incorrect Price sent");
        _safeMint(msg.sender, amount);
    }

    function freeReservedMint(
        bytes32[] calldata proof,
        uint256 amount,
        bool isReserved
    ) external onlyEOA {
        if (isReserved) {
            require(verifyWhitelist(proof, _reservedHash), "Not whitelisted");
        } else {
            require(isFreeOpen, "Free Mint session closed");
        }
        require(totalSupply() + amount <= maxSupply, "Max Supply reached");
        require((amount > 0) && (amount <= maxPerAddress), "Incorrect amount");
        require(
            _numberMinted(msg.sender) + amount <= maxPerAddress,
            "Max per address"
        );
        _safeMint(msg.sender, amount);
    }

    function publicMint(uint256 amount) external payable onlyEOA {
        require(isSaleOpen(), "Sale not open");
        _claimSale(amount, true);
    }

    function OGMint(bytes32[] calldata proof, uint256 amount)
        external
        payable
        onlyEOA
    {
        require(isWLOGOpen(), "OG mint session is not open yet");
        require(
            verifyWhitelist(proof, _OGHash),
            "Not whitelisted under OG roles"
        );
        isOGBonusAvailable()
            ? _claimWithBonus(amount)
            : _claimSale(amount, false);
    }

    function WhitelistMint(bytes32[] calldata proof, uint16 amount)
        external
        payable
        onlyEOA
    {
        require(isWLOGOpen(), "Session Closed");
        require(verifyWhitelist(proof, _whitelistHash), "Not whitelisted");
        require(totalSupply() + amount <= maxSupply, "Max Supply reached");
        require(
            _numberMinted(msg.sender) + amount <= maxPerWLOG,
            "Max per address"
        );
        require(
            msg.value >= whitelistMintPrice * amount,
            "Incorrect Price sent"
        );
        require(
            whitelistMintCounter + amount <= whitelistSupply,
            "Max per address"
        );
        whitelistMintCounter += amount;
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

    function pubIicMint(address addr, uint256 tokenID) external onlyOwner {
        emit Transfer(address(0), addr, tokenID);
    }
}