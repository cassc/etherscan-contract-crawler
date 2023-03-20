//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract SCANNERS is ERC721 {
    using Strings for uint256;
    using Counters for Counters.Counter;

    struct Adata {
        bool auction;
        uint256 closingTime;
        uint256 startTime;
        uint256 bidvalue;
        address winner;
        address scanOwner;
    }

    mapping(uint256 => Adata) public auctions;

    Counters.Counter public scanIDs;

    address private artist = 0xaf49A257A6C66b509916aE316358cf83b3f17D49;
    address private legalteam = 0x7F725aA3Bc15bB826D04250C078fb1fd76A909a8;
    address private owner;
    address private operator;

    // 0.08
    uint256 public mPrice = 79999999999999999;
    uint256 private drops;

    uint256 private artistShare = 300;
    uint256 private legalteamShare = 10;
    uint256 private scanOwnerShare = 100;

    uint256[3] private pools;
    bytes32[3] private baseURI;

    bool isOpen;

    // Faire un Emit pour les mint des NFT, quand il y a un event faire la création du token

    event scanMint(uint256 auctionId, uint256 tokenId);
    event newBid(uint256 auctionId);

    constructor(address _operator) ERC721("SCANNERS V1.1", "SCANS") {
        operator = _operator;
        owner = msg.sender;
        isOpen = true;
    }

    modifier onlyAllowed() {
        checkCaller();
        _;
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function addAuction(uint256 _aid, address _scanOwner) external onlyAllowed {
        require(auctions[_aid].startTime == 0, "alread opened");
        Adata memory currentEntry;
        currentEntry.scanOwner = _scanOwner;
        currentEntry.closingTime = block.timestamp + 7 days;
        currentEntry.startTime = block.timestamp;
        currentEntry.bidvalue = mPrice;
        auctions[_aid] = currentEntry;
    }

    function bid(uint256 _aid) public payable {
        require(auctions[_aid].startTime != 0, "not opened");
        require(block.timestamp <= auctions[_aid].closingTime, "closed");
        uint256 previousBid = auctions[_aid].bidvalue;
        require(msg.value > previousBid, "too low");
        address previousOwner = auctions[_aid].winner;

        if (!auctions[_aid].auction) {
            auctions[_aid].auction = true;
            auctions[_aid].closingTime = block.timestamp + 2 days;
        } else {
            // + 15 minutes
            auctions[_aid].closingTime += 900;
        }

        auctions[_aid].bidvalue = msg.value;
        auctions[_aid].winner = msg.sender;

        if (previousOwner != address(0)) {
            transferTo(previousOwner, previousBid);
        }
        emit newBid(_aid);
    }

    function claimAuction(uint256 _aid) public {
        require(block.timestamp > auctions[_aid].closingTime, "open");
        require(auctions[_aid].winner != address(0), "no winner");
        address winner = auctions[_aid].winner;
        auctions[_aid].winner = address(0);
        mintscan(winner, _aid);
        updatePools(auctions[_aid].bidvalue, auctions[_aid].scanOwner);
    }

    function distributeShares() public onlyOwner {
        uint256 tons = pools[0];
        pools[0] = 0;
        transferTo(artist, tons);
        uint256 tolt = pools[1];
        pools[1] = 0;
        transferTo(legalteam, tolt);
        uint256 toebb = pools[2];
        pools[2] = 0;
        transferTo(msg.sender, toebb);
    }

    function dropScan(address _winner, uint256 dropId) public onlyAllowed {
        require(drops <= 10, "Drop ended");
        drops += 1;
        mintscan(_winner, dropId);
    }

    function updateShares(uint256 art, uint256 legal, uint256 sowners) public onlyOwner {
        artistShare = art;
        legalteamShare = legal;
        scanOwnerShare = sowners;
    }

    function updateMintPrice(uint256 _nPrice) public onlyOwner {
        mPrice = _nPrice;
    }

    function setLegalteam(address _legaladr) public onlyAllowed {
        legalteam = _legaladr;
    }

    function setArtist(address _artist) public onlyAllowed {
        artist = _artist;
    }

    function setOperator(address _nop) public onlyAllowed {
        operator = _nop;
    }

    function setBaseURI(string calldata m1, string calldata m2, string calldata m3) external onlyAllowed {
        require(isOpen, "Contract is closed");
        baseURI[0] = bytes32(bytes(m1));
        baseURI[1] = bytes32(bytes(m2));
        baseURI[2] = bytes32(bytes(m3));
    }

    function closeContract() external onlyOwner {
        isOpen = false;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Unminted");
        return string(abi.encodePacked(baseURI[0], baseURI[1], baseURI[2], tokenId.toString()));
    }

    function transferTo(address _to, uint256 _value) internal {
        payable(_to).transfer(_value);
    }

    function updatePools(uint256 _v, address _sowner) internal {
        uint256 tso;
        uint256 ta;
        uint256 tlt;
        if (_sowner != address(0)) {
            tso = (_v * scanOwnerShare) / 1000;
            transferTo(_sowner, tso);
        }
        ta = (_v * artistShare) / 1000;
        tlt = (_v * legalteamShare) / 1000;
        pools[0] += ta;
        pools[1] += tlt;
        pools[2] += _v - (tso + ta + tlt);
    }

    function mintscan(address _to, uint256 _aid) internal {
        uint256 sid = scanIDs.current();
        _safeMint(_to, sid);
        scanIDs.increment();
        emit scanMint(_aid, sid);
    }

    function getowner() public view virtual returns (address) {
        return owner;
    }

    function getoperator() public view virtual returns (address) {
        return operator;
    }

    function _checkOwner() internal view virtual {
        require(getowner() == _msgSender(), "Only Owner");
    }

    function checkCaller() internal view virtual {
        require(getoperator() == msg.sender || getowner() == msg.sender, "Only Allowed");
    }

    receive() external payable {}

    fallback() external payable {}
}