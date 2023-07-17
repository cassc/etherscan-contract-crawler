// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/*
     ____  ___  _________   ____
 __ / / / / / |/ / ___/ /  / __/
/ // / /_/ /    / (_ / /__/ _/  
\___/\____/_/|_/\___/____/___/  

*/

contract ForestRanger is ERC721Enumerable, Ownable {
    using Address for address payable;
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounterOG;
    Counters.Counter private _tokenIdCounterNormal;

    IERC20 public immutable _tigerCoin;

    struct RangeSpec {
        uint256 preEthPrice;
        uint256 publicEthPrice;
        uint256 preTigerPrice;
        uint256 publicTigerPrice;
        uint256 maxSupply;
        uint256 startTokenId;
    }

    enum Size {
        OG,
        Normal
    }

    enum Stage {
        NotStarted,
        FreeMint,
        PreSale,
        PublicSale
    }

    mapping (Size => RangeSpec) rangerSpecs;
    mapping (address => uint256) freeList;
    mapping (address => uint256) OGWl;
    mapping (address => uint256) NormalWl;

    uint256 public maxMintPerTx = 10;
    uint256 public maxMintPerWl = 10;
    uint256 public maxFreeMint = 1;
    uint256 public maxSupply = 9990;

    bool public revealed;
    string public metadataURI;
    Stage public currentStage = Stage.NotStarted;
    address public _signer;

    constructor(address signer, address tigerCoin) ERC721("ForestRanger", "FR") {
        rangerSpecs[Size.OG] = RangeSpec(0.05 ether, 0.06 ether, 4000000000 ether, 4800000000 ether, 4990, 1);
        rangerSpecs[Size.Normal] = RangeSpec(0.025 ether, 0.03 ether, 2000000000 ether, 2400000000 ether, 5000, 4991);

        _signer = signer;
        _tigerCoin = IERC20(tigerCoin);
    }

    function setMaxMintPerTx(uint256 _maxMintPerTx) external onlyOwner {
        maxMintPerTx = _maxMintPerTx;
    }

    function setMaxMintPerWl(uint256 _maxMintPerWl) external onlyOwner {
        maxMintPerWl = _maxMintPerWl;
    }

    function setRevealed(bool _revealed) external onlyOwner {
        revealed = _revealed;
    }

    function setMetadataURI(string memory uri) external onlyOwner {
        metadataURI = uri;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");

        string memory baseURI = metadataURI;
        return revealed ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")): baseURI;
    }

    function setStage(Stage _stage) external onlyOwner {
        currentStage = _stage;
    }

    function getSpec(Size size) public view returns (RangeSpec memory) {
        return rangerSpecs[size];
    }

    function setPrice(
        Size size,
        uint256 _preEthPrice,
        uint256 _publicEthPrice,
        uint256 _preTigerPrice,
        uint256 _publicTigerPrice
    ) external onlyOwner {
        rangerSpecs[size].preEthPrice = _preEthPrice;
        rangerSpecs[size].publicEthPrice = _publicEthPrice;
        rangerSpecs[size].preTigerPrice = _preTigerPrice;
        rangerSpecs[size].publicTigerPrice = _publicTigerPrice;
    }

    function setEthPrice(
        Size size,
        uint256 _preEthPrice,
        uint256 _publicEthPrice
    ) external onlyOwner {
        rangerSpecs[size].preEthPrice = _preEthPrice;
        rangerSpecs[size].publicEthPrice = _publicEthPrice;
    }

    function setTigerPrice(
        Size size,
        uint256 _preTigerPrice,
        uint256 _publicTigerPrice
    ) external onlyOwner {
        rangerSpecs[size].preTigerPrice = _preTigerPrice;
        rangerSpecs[size].publicTigerPrice = _publicTigerPrice;
    }

    modifier onlyEOA() {
        require(msg.sender == tx.origin, "no contracts please");
        _;
    }

    function freeMint(bytes memory signature) external payable {
        require(msg.sender == tx.origin, "no contracts please");
        require(currentStage == Stage.FreeMint, "free mint not start");
        require(_signer == signatureWallet(msg.sender, signature), "not in white list");
        require(freeList[msg.sender] == 0, "just once");
        RangeSpec memory s = rangerSpecs[Size.Normal];
        require(
            totalSupplyBySize(Size.Normal) + maxFreeMint <= s.maxSupply,
            "over size limit"
        );
        freeList[msg.sender] = 1;
        _safeMintLoop(Size.Normal, maxFreeMint, msg.sender);
    }

    function preMintOG(uint256 amount,bool useEth,bytes memory signature) external payable {
        _preMint(Size.OG, amount, useEth, signature);
        _safeMintLoop(Size.OG, amount, msg.sender);
    }

    function publicMintOG(uint256 amount, bool useEth) external payable {
        _publicMint(Size.OG, amount, useEth);
        _safeMintLoop(Size.OG, amount, msg.sender);
    }

    function devOG(uint256 amount, address to) external onlyOwner {
        devMint(Size.OG, amount, to);
    }

    function preMintNormal(uint256 amount,bool useEth,bytes memory signature) external payable {
        _preMint(Size.Normal, amount, useEth, signature);
        _safeMintLoop(Size.Normal, amount, msg.sender);
    }

    function publicMintNormal(uint256 amount, bool useEth) external payable {
        _publicMint(Size.Normal, amount, useEth);
        _safeMintLoop(Size.Normal, amount, msg.sender);
    }

    function devNormal(uint256 amount, address to) external onlyOwner {
        devMint(Size.Normal, amount, to);
    }

    function devMint(Size size, uint256 amount, address to) internal onlyOwner {
        RangeSpec memory s = rangerSpecs[size];
        require(
            totalSupplyBySize(size) + amount <= s.maxSupply,
            "over max supply"
        );
        _safeMintLoop(size, amount, to);
    }

    function _preMint(Size size,uint256 amount,bool useEth, bytes memory signature) internal onlyEOA {
        require(currentStage == Stage.PreSale, "pre sale not start");
        require(_signer == signatureWallet(msg.sender, signature), "not in white list");
        require(amount <= maxMintPerTx, "over per tx limit");
        RangeSpec memory s = rangerSpecs[size];
        require(totalSupplyBySize(size) + amount <= s.maxSupply, "over size limit");
        if (size == Size.OG) {
            require(amount + OGWl[msg.sender] <= maxMintPerWl, "over per wl limit");
            OGWl[msg.sender] += amount;
        } else {
            require(amount + NormalWl[msg.sender] <= maxMintPerWl, "over per wl limit");
            NormalWl[msg.sender] += amount;
        }
        if (useEth) {
            require(msg.value == s.preEthPrice * amount, "insufficient fund");
        } else {
            require(
                _tigerCoin.transferFrom(
                    msg.sender,
                    address(this),
                    s.preTigerPrice * amount
                ),
                "insufficient fund"
            );
        }
    }

    function _publicMint(Size size, uint256 amount, bool useEth) internal onlyEOA {
        require(currentStage == Stage.PublicSale, "public sale not start");
        require(amount <= maxMintPerTx, "over per tx limit");
        RangeSpec memory s = rangerSpecs[size];
        require(
            totalSupplyBySize(size) + amount <= s.maxSupply,
            "over size limit"
        );
        if (useEth) {
            require(
                msg.value == s.publicEthPrice * amount,
                "insufficient fund"
            );
        } else {
            require(
                _tigerCoin.transferFrom(
                    msg.sender,
                    address(this),
                    s.publicTigerPrice * amount
                ),
                "insufficient fund"
            );
        }
    }

    function signatureWallet(address sender, bytes memory signature) private pure returns (address){
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(sender))
            )
        );
        return ECDSA.recover(hash, signature);
    }

    function _safeMintLoop(Size size, uint256 amount, address to) internal {
        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenId = totalSupplyBySize(size) + getSpec(size).startTokenId;
            increaseSupplyBySize(size);
            _safeMint(to, tokenId);
        }
    }

    function getCounter(Size size) private view returns (Counters.Counter storage) {
        if (size == Size.OG) {
            return _tokenIdCounterOG;
        }
        if (size == Size.Normal) {
            return _tokenIdCounterNormal;
        }
        revert("invalid size");
    }

    function totalSupplyBySize(Size size) public view returns (uint256) {
        return getCounter(size).current();
    }

    function increaseSupplyBySize(Size size) internal {
        getCounter(size).increment();
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).sendValue(address(this).balance);
    }
}