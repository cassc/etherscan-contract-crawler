// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// 𝗨𝗡𝗟𝗢𝗖𝗞 𝗧𝗛𝗘 𝗣𝗢𝗪𝗘𝗥 𝗢𝗙 𝗣𝗜𝗫𝗘𝗟𝗦 
// ¶¶¶¶¶``¶¶`````¶¶``¶¶`¶¶¶¶¶``¶¶¶¶¶``¶¶¶¶¶¶`¶¶``¶¶
// ¶¶``¶¶`¶¶`````¶¶``¶¶`¶¶`````¶¶``¶¶```¶¶````¶¶¶¶
// ¶¶¶¶¶``¶¶`````¶¶``¶¶`¶¶¶¶```¶¶¶¶¶````¶¶`````¶¶
// ¶¶``¶¶`¶¶`````¶¶``¶¶`¶¶`````¶¶```````¶¶````¶¶¶¶
// ¶¶¶¶¶``¶¶¶¶¶¶``¶¶¶¶``¶¶¶¶¶``¶¶`````¶¶¶¶¶¶`¶¶``¶¶


import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {OperatorFilterer} from "closedsea/src/OperatorFilterer.sol";

contract BLUEPIX is ERC2981, ERC721A, OperatorFilterer, Ownable, ReentrancyGuard {

    using SafeMath for uint256;

    string public contractURI;

    uint256 public maxSupply = 4444;
    uint256 public maxWhitelistMintsPerWallet = 3;
    uint256 public maxMintsPerWallet = 5;

    bool public isMetaDataFrozen = false;

    bool public operatorFilteringEnabled = true;

    string public ghostTokenURI;
    string public baseTokenURI = "";

    uint256 public whitelistMintPrice = 0.004444 ether;
    uint256 public publicMintPrice = 0.008888 ether;

    uint256 public whitelistMintTime = 1698073200;
    uint256 public whitelistMintEndTime = 1698080400;
    uint256 public startTime = 1698080400;
    uint256 public endTime = 1698246000;
    uint256 public revealTime = 1698246000;

    mapping(address => uint256) public mintedPerAddress;

    string private _name = "BLUEPIX";
    string private _symbol = "BLUE";
    bytes32[] private _whitelistMerkleForest;

    modifier notFrozenMetaData {
        require(
            !isMetaDataFrozen,
            "metadata frozen"
        );
        _;
    }

    modifier canMint {
        require(
            block.timestamp >= startTime && block.timestamp <= endTime,
            "Minting is not active"
        );
        _;
    }

    modifier canWhitelistMint {
        require(
            block.timestamp >= whitelistMintTime && block.timestamp <= whitelistMintEndTime,
            "WhiteList Minting is not active"
        );
        _;
    }

    constructor(string memory _ghostTokenURI) ERC721A(_name, _symbol) {
        ghostTokenURI = _ghostTokenURI;
        
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
    }

    function _startTokenId() internal override pure returns (uint256) {
        return 1;
    }

    function whitelistMint(uint32 merkleTreeIndex, bytes32[] memory merkleProof, uint256 mintCount) public payable canWhitelistMint {
        uint256 paidCount = mintCount;
        if (mintedPerAddress[msg.sender] == 0) {
            paidCount = mintCount - 1;
        }
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(merkleProof, _whitelistMerkleForest[merkleTreeIndex], leaf), "Not WL");
        require(msg.value == (paidCount * whitelistMintPrice), "Wrong price");
        require(mintedPerAddress[msg.sender] + mintCount <= maxWhitelistMintsPerWallet, "WL Wallet Max");
        require(mintCount > 0 && mintCount <= 5, "Wrong amount");

        buyAmount(mintCount);
        mintedPerAddress[msg.sender] += mintCount;
    }

    function publicMint(uint256 mintCount) external payable canMint {
        uint256 paidCount = mintCount;
        if (mintedPerAddress[msg.sender] == 0) {
            paidCount = mintCount - 1;
        }
        require(msg.value == (paidCount * publicMintPrice), "Wrong amount");
        require(mintCount > 0 && mintCount <= 10, "Wrong amount");
        require(mintedPerAddress[msg.sender] + mintCount <= maxMintsPerWallet, "Wallet Max");

        buyAmount(mintCount);
        mintedPerAddress[msg.sender] += mintCount;
    }

    function buyAmount(uint256 count) private {
        require(totalSupply() + count <= maxSupply, "Max Public Supply");
        _safeMint(_msgSender(), count);
    }

    function mintMany(uint256 num, address _to) public onlyOwner {
        require(num <= 20, "Max 20 Per TX.");
        require(totalSupply() + num < maxSupply, "Max Supply");
        _safeMint(_to, num);
    }

    function mintTo(address _to) public onlyOwner {
        require(totalSupply() < maxSupply, "Max Supply");
        _safeMint(_to, 1);
    }

    // withdraw function for the contract owner
    function withdraw() external nonReentrant onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function setRevealTime(uint256 time) external onlyOwner {
        revealTime = time;
    }

    function setWhitelistMintTime(uint256 _startTime, uint256 _endTime) external onlyOwner {
        whitelistMintTime = _startTime;
        whitelistMintEndTime = _endTime;
    }

    function setMintTime(uint256 _startTime, uint256 _endTime) external onlyOwner {
        startTime = _startTime;
        endTime = _endTime;
    }

    function setMintPrices(uint256 newWhitelistMintPrice, uint256 newPublicMintPrice)  external nonReentrant onlyOwner {
        whitelistMintPrice = newWhitelistMintPrice;
        publicMintPrice = newPublicMintPrice;
    }

    function setBaseUri(string memory _uri) external onlyOwner notFrozenMetaData {
        baseTokenURI = _uri;
    }

    function setGhostUri(string memory _uri) external onlyOwner notFrozenMetaData {
        ghostTokenURI = _uri;
    }

    function setContractUri(string memory uri) external onlyOwner {
        contractURI = uri;
    }

    function plantMerkleForest(bytes32[] memory merkleForest) external onlyOwner {
        _whitelistMerkleForest = merkleForest;
    }

    function plantMerkleTree(bytes32 merkleTree) external onlyOwner {
        _whitelistMerkleForest.push(merkleTree);
    }

    // in case the contract is not fully minted out have the ability to cut the supply
    function shrinkSupply(uint256 newMaxSupply) external nonReentrant onlyOwner {
        require(totalSupply() <= newMaxSupply, "ERR: minted > new!");
        require(newMaxSupply <= maxSupply, "ERR: cant increase max supply");
        maxSupply = newMaxSupply;
    }

    function freezeMetaData() public onlyOwner {
        require(block.timestamp > revealTime, "Freeze after reveal");
        isMetaDataFrozen = true;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (block.timestamp < revealTime) {
            return string(abi.encodePacked(ghostTokenURI));
        }
        return
            string(
                abi.encodePacked(
                    baseTokenURI,
                    Strings.toString(_tokenId),
                    ".json"
                )
            );
    }

    // ---------------------------------------------------
    // OperatorFilterer overrides (overrides, values etc.)
    // ---------------------------------------------------
    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    // ----------------------------------------------
    // EIP-165
    // ----------------------------------------------
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    function _isPriorityOperator(address operator) internal pure override returns (bool) {
        // OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }
}