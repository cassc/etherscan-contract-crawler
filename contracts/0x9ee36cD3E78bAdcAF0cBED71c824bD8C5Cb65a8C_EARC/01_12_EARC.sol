pragma solidity ^0.8.0;

//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract EARC is ERC721, Ownable {
    uint256 public _mintPrice = 0.055 ether;
    uint256 public _maxMintPerTx = 4;
    uint256 public _maxToMintPreSale = 2;
    uint256 public MAX_SUPPLY = 10000;

    using MerkleProof for bytes32[];
    bytes32 merkleRoot;

    bool public _saleIsActive = false;
    bool public _preSaleIsActive = false;

    mapping(address => bool) private _preSaleList;
    mapping(address => uint256) private _preSaleListClaimed;

    uint256 public startTimePreSale = 1640120400;
    uint256 public endTimePreSale = 1640203200;

    uint256 public startTimeSale = 1640206800;

    address[] private _team;
    uint256[] private _shares;

    string public baseURI;

    uint256 private _t = 0;

    constructor(
        string memory uriBASE,
        address[] memory team,
        uint256[] memory team_shares,
        bytes32 root
    ) ERC721("Elderly Ape Retirement Club", "EARC") {
        baseURI = uriBASE;
        _team = team;
        _shares = team_shares;
        merkleRoot = root;
    }

    function _mint(uint256 toMint, address to) internal {
        uint256 t = _t;
        for (uint256 i = 0; i < toMint; i++) {
            _t += 1;
            _safeMint(to, t + i);
        }
        delete t;
    }

    function mint(uint256 toMint) external payable {
        require(_saleIsActive, "Sale is not active");
        require(toMint <= _maxMintPerTx, "You requested too many Apes");
        require(block.timestamp >= startTimeSale, "Sale did not start yet");
        require(_mintPrice * toMint <= msg.value, "ETH value not correct");
        require(_t + toMint <= MAX_SUPPLY, "Purchase exceeds max supply");
        _mint(toMint, _msgSender());
    }

    function preMint(uint256 toMint, bytes32[] memory proof) external payable {
        require(
            proof.verify(merkleRoot, keccak256(abi.encodePacked(msg.sender))) ||
                _preSaleList[_msgSender()],
            "You are not on the list"
        );
        require(_preSaleIsActive, "Pre Sale is not active");
        require(_mintPrice * toMint <= msg.value, "ETH value not correct");
        require(
            block.timestamp >= startTimePreSale,
            "Pre-Sale did not start yet"
        );
        require(block.timestamp <= endTimePreSale, "Pre-Sale is finished");
        require(
            _preSaleListClaimed[_msgSender()] + toMint <= _maxToMintPreSale,
            "Purchase exceeds max allowed"
        );
        require(_t + toMint <= MAX_SUPPLY, "Purchase exceeds max supply");

        _preSaleListClaimed[msg.sender] += toMint;
        _mint(toMint, _msgSender());
    }

    function reserve(uint256 toMint, address to) external onlyOwner {
        require(_t + toMint <= MAX_SUPPLY, "Purchase exceeds max supply");
        _mint(toMint, to);
    }

    function setMerkleRoot(bytes32 root) public onlyOwner {
        merkleRoot = root;
    }

    function setSaleState(bool val) external onlyOwner {
        _saleIsActive = val;
    }

    function setPreSaleState(bool val) external onlyOwner {
        _preSaleIsActive = val;
    }

    function setPrice(uint256 price) external onlyOwner {
        _mintPrice = price;
    }

    function setMaxPerTX(uint256 maxValue) external onlyOwner {
        _maxMintPerTx = maxValue;
    }

    function setPreSaleMaxMint(uint256 maxMint) external onlyOwner {
        _maxToMintPreSale = maxMint;
    }

    function setStartAndEndTimePreSale(uint256 start, uint256 end)
        external
        onlyOwner
    {
        startTimePreSale = start;
        endTimePreSale = end;
    }

    function setStartTimeSale(uint256 startSale) external onlyOwner {
        startTimeSale = startSale;
    }

    function setBaseURI(string memory newURI) public onlyOwner {
        baseURI = newURI;
    }

    function cut(uint256 max) external onlyOwner {
        uint256 previous = MAX_SUPPLY;
        if (max < previous) {
            MAX_SUPPLY = max;
        }
    }

    function onAccesslist(bytes32[] memory proof, address add)
        external
        view
        returns (bool)
    {
        return proof.verify(merkleRoot, keccak256(abi.encodePacked(add)));
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        for (uint256 i = 0; i < _shares.length; i++) {
            address wallet = _team[i];
            uint256 share = _shares[i];
            payable(wallet).transfer((balance * share) / 1000);
        }
    }

    function emergencyWithdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    function setShares(address[] memory team, uint256[] memory team_shares)
        public
        onlyOwner
    {
        _team = team;
        _shares = team_shares;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function addToPreSaleList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Address can not be null");

            _preSaleList[addresses[i]] = true;
        }
    }

    function onList(address addr) external view returns (bool) {
        return _preSaleList[addr];
    }

    function totalSupply() external view returns (uint256) {
        return _t;
    }

    function removeFromPreSaleList(address[] calldata addresses)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Address can not be null");
            _preSaleList[addresses[i]] = false;
        }
    }
}