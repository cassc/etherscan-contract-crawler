// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./SundayClubWhitelist.sol";

contract SundayClubBlobs is
    SundayClubWhitelist,
    ERC721,
    ERC721Enumerable,
    ERC721Burnable,
    AccessControl
{
    using Counters for Counters.Counter;
    using Strings for uint256;
    uint256 public constant MAX_SUPPLY = 5000;
    uint256 public constant MINTING_COST = 0.06 ether;
    uint256 public constant MINTING_LIMIT = 35;
    uint256 public constant TR_1 = 75;
    uint256 public constant TR_2 = 75;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    address payable public ma =
        payable(0xEbf35a32b76F11211F4ccD5e7E2dAA7DB8e5b86F); // marketing team
    address payable public de; // development team

    string public baseURI;

    bool public whitelistIsLive = true;
    bool public saleIsLive = false;
    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _TRCounter;

    bool internal locked;

    modifier noReentrancy() {
        require(!locked, "No reentrancy");
        locked = true;
        _;
        locked = false;
    }

    constructor(address payable _owner2, bytes32 whitelistRoot_)
        SundayClubWhitelist(whitelistRoot_)
        ERC721("Blobs", "Blob")
    {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        de = payable(msg.sender);
        grantRole(DEFAULT_ADMIN_ROLE, _owner2);
        grantRole(ADMIN_ROLE, _owner2);
    }

    function whitelistMint(uint256 qty, bytes32[] calldata proof)
        public
        payable
        noReentrancy
    {
        require(whitelistIsLive, "Minting not yet started");
        require(isWhitelisted(msg.sender, proof), "You are not white listed");
        require(msg.value >= MINTING_COST * qty, "Send more ether");

        (qty > 1) ? _mintBatch(msg.sender, qty) : safeMint(msg.sender);
    }

    function mintGiveaway(address to, uint256 qty) public onlyRole(ADMIN_ROLE) {
        require(qty <= 10, "chill");
        for (uint256 i = 0; i < qty; i++) {
            reservedMint(to);
        }
    }

    function mintGiveawayBatch(address[] memory to, uint256[] memory qty)
        public
        onlyRole(ADMIN_ROLE)
    {
        require(to.length == qty.length);
        for (uint256 i = 0; i < to.length; i++) {
            require(qty[i] <= 10, "chill");
            reservedMint(to[i]);
        }
    }

    function mint() public payable noReentrancy {
        require(saleIsLive, "Sale not started");
        require(msg.value >= MINTING_COST, "Send more ether");
        safeMint(msg.sender);
    }

    function mintBatch(address to, uint256 qty) public payable noReentrancy {
        require(saleIsLive, "Sale not started");
        _mintBatch(to, qty);
    }

    function burnBlob(uint256 tokenId) public {
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "You don't have permission"
        );
        _burn(tokenId);
    }

    function updateRoot(bytes32 newRoot_) public onlyRole(ADMIN_ROLE) {
        whitelistRoot = newRoot_;
    }

    function setBaseURI(string memory _newBaseURI) public onlyRole(ADMIN_ROLE) {
        baseURI = _newBaseURI;
    }

    function startWhitelist() public onlyRole(ADMIN_ROLE) {
        whitelistIsLive = true;
    }

    function startSale() public onlyRole(ADMIN_ROLE) {
        saleIsLive = true;
    }

    function endSale() public onlyRole(ADMIN_ROLE) {
        saleIsLive = false;
    }

    function endWhitelist() public onlyRole(ADMIN_ROLE) {
        whitelistIsLive = false;
    }

    function withdraw() public onlyRole(ADMIN_ROLE) noReentrancy {
        _withdraw();
    }

    function _withdraw() internal {
        uint256 balance = address(this).balance;
        require(balance > 0, "Nothing to withdraw");
        uint256 marketing = (balance * 7) / 10;
        uint256 development = balance - marketing;

        require(de.send(development));
        require(ma.send(marketing));
    }

    function _mintBatch(address to, uint256 qty) internal {
        require(msg.value >= MINTING_COST * qty, "Send more ether");
        require(qty <= MINTING_LIMIT, "chill");
        for (uint256 i = 0; i < qty; i++) {
            safeMint(to);
        }
    }

    function reservedMint(address to) internal {
        require(_TRCounter.current() < TR_1 + TR_2);
        while (_exists(_TRCounter.current() + (MAX_SUPPLY - TR_1 - TR_2))) {
            _TRCounter.increment();
        }
        _safeMint(to, _TRCounter.current() + (MAX_SUPPLY - TR_1 - TR_2));
        _TRCounter.increment();
    }

    function safeMint(address to) internal {
        require(_tokenIdCounter.current() < (MAX_SUPPLY - TR_1 - TR_2));
        while (_exists(_tokenIdCounter.current())) {
            _tokenIdCounter.increment();
        }
        _safeMint(to, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : tokenId.toString();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}