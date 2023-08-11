// SPDX-License-Identifier: MIT
// By @marcu5aurelius
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

contract Morpheu5Series is ERC1155Supply, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private seriesCounter;

    // Public
    mapping(uint256 => Series) public series;
    struct Series {
        bytes32 merkleRoot;
        bool paused;
        uint256 mintPrice;
        uint256 maxSupply;
        uint256 maxPerWallet;
        uint256 maxMintPerTxn;
        string metadataLink;
        bool isWhitelist;
        mapping(address => uint256) hasMinted;
    }

    string public _contractURI;
    string public name_;
    string public symbol_;

    constructor(string memory _name, string memory _symbol) ERC1155("Series") {
        name_ = _name;
        symbol_ = _symbol;
    }

    function addSeries(
        bytes32 _merkleRoot,
        uint256 _mintPrice,
        uint256 _maxSupply,
        uint256 _maxMintPerTxn,
        string memory _metadataLink,
        uint256 _maxPerWallet,
        bool _isWhitelist
    ) external onlyOwner {
        Series storage current = series[seriesCounter.current()];
        current.paused = true;
        current.merkleRoot = _merkleRoot;
        current.mintPrice = _mintPrice;
        current.maxSupply = _maxSupply;
        current.maxMintPerTxn = _maxMintPerTxn;
        current.maxPerWallet = _maxPerWallet;
        current.metadataLink = _metadataLink;
        current.isWhitelist = _isWhitelist;
        seriesCounter.increment();
    }

    function editSeries(
        uint256 _seriesIndex,
        bytes32 _merkleRoot,
        uint256 _mintPrice,
        uint256 _maxSupply,
        uint256 _maxMintPerTxn,
        string memory _metadataLink,
        uint256 _maxPerWallet,
        bool _isWhitelist,
        bool _paused
    ) external onlyOwner {
        series[_seriesIndex].merkleRoot = _merkleRoot;
        series[_seriesIndex].mintPrice = _mintPrice;
        series[_seriesIndex].maxSupply = _maxSupply;
        series[_seriesIndex].maxMintPerTxn = _maxMintPerTxn;
        series[_seriesIndex].metadataLink = _metadataLink;
        series[_seriesIndex].maxPerWallet = _maxPerWallet;
        series[_seriesIndex].isWhitelist = _isWhitelist;
        series[_seriesIndex].paused = _paused;
    }

    function toggleSeriesPaused(uint256 _seriesIndex) external onlyOwner {
        series[_seriesIndex].paused = !series[_seriesIndex].paused;
    }

    function mintWhitelist(
        uint256 seriesIndex,
        uint256 amount,
        bytes32[] calldata _proof
    ) external payable {
        isValidMint(seriesIndex, amount, false);
        isAllowedToMint(seriesIndex, _proof);
        require(
            msg.value >= amount.mul(series[seriesIndex].mintPrice),
            "Insufficient funds"
        );
        _mint(msg.sender, seriesIndex, amount, "");
        series[seriesIndex].hasMinted[msg.sender] = series[seriesIndex]
            .hasMinted[msg.sender]
            .add(amount);
    }

    function mintPublic(uint256[] memory seriesIndexes, uint256 amount)
        external
        payable
    {
        uint256 totalCost = 0;
        for (uint256 i = 0; i < seriesIndexes.length; i++) {
            isValidMint(seriesIndexes[i], amount, true);
            totalCost =
                totalCost +
                amount.mul(series[seriesIndexes[i]].mintPrice);
        }
        require(msg.value >= totalCost, "Insufficient funds");
        for (uint256 i = 0; i < seriesIndexes.length; i++) {
            _mint(msg.sender, seriesIndexes[i], amount, "");
            series[seriesIndexes[i]].hasMinted[msg.sender] = series[
                seriesIndexes[i]
            ].hasMinted[msg.sender].add(amount);
        }
    }

    function isAllowedToMint(uint256 seriesIndex, bytes32[] memory _proof)
        internal
        view
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_proof, series[seriesIndex].merkleRoot, leaf),
            "Invalid proof"
        );
    }

    function isValidMint(
        uint256 seriesIndex,
        uint256 amount,
        bool publicMint
    ) internal view {
        require(series[seriesIndex].maxSupply != 0, "Series does not exist");
        require(!series[seriesIndex].paused, "Series is paused");
        require(
            series[seriesIndex].hasMinted[msg.sender].add(amount) <=
                series[seriesIndex].maxPerWallet,
            "Exceeds maximum per wallet"
        );
        require(
            amount <= series[seriesIndex].maxMintPerTxn,
            "Exceeds maximum per transaction"
        );
        require(
            totalSupply(seriesIndex) + amount <= series[seriesIndex].maxSupply,
            "Exceeds maximum token supply"
        );
        if (series[seriesIndex].isWhitelist) {
            require(!publicMint, "Whitelist minting only");
        }
    }

    function uri(uint256 _id) public view override returns (string memory) {
        require(totalSupply(_id) > 0, "Token doesn't exist");
        return string(series[_id].metadataLink);
    }

    function name() public view returns (string memory) {
        return name_;
    }

    function symbol() public view returns (string memory) {
        return symbol_;
    }

    // For Opensea
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    // Only owner
    function setContractURI(string memory newURI) external onlyOwner {
        _contractURI = newURI;
    }

    // Only owner
    function withdraw(address payable _to, uint256 _amount) public onlyOwner {
        _to.transfer(_amount);
    }

    // based on contracts by @georgefatlion, @bitcoinski and @ultra_dao
}