//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract SCANNERSV12 is ERC721 {
    using Strings for uint256;
    using Counters for Counters.Counter;

    struct Adata {
        uint256 closingTime;
        uint256 startTime;
        uint256 bidvalue;
        address winner;
        address scanOwner;
    }

    mapping(uint256 => Adata) public auctions;

    Counters.Counter public scanIDs;

    address public ebbdistributor = 0x02Ac45C33F71022B4b91aA10Aabd2E15770Cb95C;
    address private owner;
    address private operator;

    // 0.08
    uint256 public mPrice = 80000000000000000;
    uint256 private iPrice = 100000000000000000; // 20%

    uint256 private drops;

    uint256 private scanOwnerShare = 100;

    uint256 private sharePool;
    bytes32[3] private baseURI;

    bool isOpen;

    // Faire un Emit pour les mint des NFT, quand il y a un event faire la création du token

    event scanMint(uint256 auctionId, uint256 tokenId);
    event bidChanged(uint256 auctionId);

    constructor(address _operator) ERC721("SCANNERS V1.2", "SCANS") {
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
        require(auctions[_aid].startTime == 0, "already opened");
        Adata memory currentEntry;
        currentEntry.scanOwner = _scanOwner;
        currentEntry.closingTime = block.timestamp + 2 days;
        currentEntry.startTime = block.timestamp;
        currentEntry.bidvalue = mPrice;
        auctions[_aid] = currentEntry;
        emit bidChanged(_aid);
    }

    function directBuy(uint256 _aid) public payable {
        require(block.timestamp <= auctions[_aid].closingTime, "closed");
        require(auctions[_aid].startTime != 0, "not opened");
        require(auctions[_aid].winner == address(0), "not allowed");
        require(msg.value >= iPrice, "price too low");

        // Close the auction
        auctions[_aid].closingTime = 0;
        auctions[_aid].bidvalue = 0;
        auctions[_aid].winner = address(0);

        mintscan(msg.sender, _aid);
        updatePools(msg.value, auctions[_aid].scanOwner);
    }

    function bid(uint256 _aid) public payable {
        require(auctions[_aid].startTime != 0, "not opened");
        require(block.timestamp <= auctions[_aid].closingTime, "closed");
        uint256 previousBid = auctions[_aid].bidvalue;
        require(msg.value > previousBid, "too low");
        address previousOwner = auctions[_aid].winner;

        // + 15 minutes
        auctions[_aid].closingTime += 900;
        auctions[_aid].bidvalue = msg.value;
        auctions[_aid].winner = msg.sender;

        if (previousOwner != address(0)) {
            transferTo(previousOwner, previousBid);
        }
        emit bidChanged(_aid);
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
        uint256 npool = sharePool;
        sharePool = 0;
        (bool success, ) = ebbdistributor.call{value: npool}("");
        require(success, "Transfer failed");
    }

    function dropScan(address _winner, uint256 dropId) public onlyAllowed {
        require(drops <= 10, "Drop ended");
        drops += 1;
        mintscan(_winner, dropId);
    }

    function setAuctionPrice(uint256 _nPrice) public onlyOwner {
        mPrice = _nPrice;
    }

    function setDirectBuyPrice(uint256 _nPrice) public onlyOwner {
        iPrice = _nPrice;
    }

    function setScanOwnerShare(uint256 _sos) public onlyOwner {
        scanOwnerShare = _sos;
    }

    function setDistributor(address _nadr) public onlyAllowed {
        ebbdistributor = _nadr;
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
        if (_sowner != address(0)) {
            tso = (_v * scanOwnerShare) / 1000;
            transferTo(_sowner, tso);
        }
        sharePool += (_v - tso);
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