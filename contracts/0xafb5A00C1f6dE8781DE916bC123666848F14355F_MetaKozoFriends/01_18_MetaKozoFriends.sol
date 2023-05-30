// SPDX-License-Identifier: MIT
// ███╗   ███╗███████╗████████╗ █████╗ ██╗  ██╗ ██████╗ ███████╗ ██████╗
// ████╗ ████║██╔════╝╚══██╔══╝██╔══██╗██║ ██╔╝██╔═══██╗╚══███╔╝██╔═══██╗
// ██╔████╔██║█████╗     ██║   ███████║█████╔╝ ██║   ██║  ███╔╝ ██║   ██║
// ██║╚██╔╝██║██╔══╝     ██║   ██╔══██║██╔═██╗ ██║   ██║ ███╔╝  ██║   ██║
// ██║ ╚═╝ ██║███████╗   ██║   ██║  ██║██║  ██╗╚██████╔╝███████╗╚██████╔╝
// ╚═╝     ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝ ╚═════╝

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/Pausable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import {DefaultOperatorFilterer} from "./OperatorFilter/DefaultOperatorFilterer.sol";

contract MetaKozoFriends is
    ERC721A,
    Pausable,
    Ownable,
    DefaultOperatorFilterer
{
    // Address information
    address private team = 0xA59942593286A215c5F39F94714496608A66F5E8;

    // Collection sale information
    uint256 public collectionSize = 708;
    uint8 public maxQuantityPerTX = 6;
    uint256 public maxMintPerAllowList = 1;

    // Salestart time (imestamp second)
    uint256 public saleStartTime = 1671883200; // 2022/12/24 21:00:00 JST
    // Reveal time
    uint256 public revealTime = 1671969600; // 2022/12/25 21:00:00 JST

    // Whitelist
    bytes32 public merkleRoot;
    mapping(address => uint256) public whiteListClaimed;

    string private BaseExtention = ".json";
    string private beforeRevealUri = 'ar://kR6eDKhvTThTAHGr2B6u6RIhv7eRncKirf_M-g4LfZw';

    /**
     * Before Reveal, static URI is returned, and after Reveal, respective URI is returned.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        if (block.timestamp < revealTime) {
            return beforeRevealUri;
        }

        return string(abi.encodePacked(super.tokenURI(tokenId), BaseExtention));
    }

    constructor(string memory _name, string memory _symbol)
        ERC721A(_name, _symbol)
    {
        _baseTokenURI = "ar://-K-gTd2Wbkesq7bVVrUhCM-BETmR3NlL1Opu7U2a-V8/";
        ownerMint(50);
    }

    // Modifier
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    // Events
    event Minted(address indexed _from, uint256 _tokenId);

    function setBaseExtention(string calldata BaseExtention_)
        external
        onlyOwner
    {
        BaseExtention = BaseExtention_;
    }
    function setBeforeRevealUri(string calldata beforeRevealURL_) external onlyOwner {
        beforeRevealUri = beforeRevealURL_;
    }

    // Sale Time
    function setSaleStartTime(uint256 saleStartTime_) external onlyOwner {
        saleStartTime = saleStartTime_;
    }
    function setRevealTime(uint256 revealTime_) external onlyOwner {
        revealTime = revealTime_;
    }

    // Contract size
    function setCollectionSize(uint256 collectionSize_) external onlyOwner {
        require(
            collectionSize_ >= totalSupply(),
            "Collection size is too small"
        );
        collectionSize = collectionSize_;
    }

    // Metadata URI
    string private _baseTokenURI;

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    // Whitelist
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    // Owner Mint
    function ownerMint(uint256 _quantity) public callerIsUser onlyOwner {
        require(
            (totalSupply() + _quantity) <= collectionSize,
            "Mint amount over"
        );
        _safeMint(msg.sender, _quantity);
    }

    function checkMint(uint8 _wlCount, bytes32[] calldata _merkleProof)
        public
        view
        callerIsUser
        returns (bool isOk)
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _wlCount));

        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Invalid Merkle Proof"
        );
        return true;
    }

    function mint(
        uint256 _quantity,
        uint8 _wlCount,
        bytes32[] calldata _merkleProof
    ) public payable callerIsUser {
        commonSaleValidation(_quantity);
        require(block.timestamp >= saleStartTime, "Mint has not started yet");
        require(
            whiteListClaimed[msg.sender] + _quantity <=
                _wlCount * maxMintPerAllowList,
            "Already claimed max"
        );

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _wlCount));

        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Invalid Merkle Proof"
        );

        whiteListClaimed[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
        emit Minted(msg.sender, _quantity);
    }

    function commonSaleValidation(uint256 _quantity) private view {
        _requireNotPaused();
        require(_quantity > 0, "Mint quantity must be greater than 0");
        require(
            _quantity <= maxQuantityPerTX,
            "Mint limit exceeded for one transaction"
        );
        require(
            totalSupply() + _quantity <= collectionSize,
            "Mint amount over"
        );
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // Team wallet
    function setTeam(address _teamAddress) external onlyOwner {
        team = _teamAddress;
    }

    // Withdraw
    function withdraw() public virtual onlyOwner {
        (bool dao, ) = payable(team).call{value: address(this).balance}("");
        require(dao);
    }

    // for Opensea Loyalty
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}