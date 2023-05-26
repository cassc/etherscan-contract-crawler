//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract AspreyStudioClub is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;
    Counters.Counter private _tokenIdCounter;
    string public baseURI;
    bytes32 public root;
    uint256 public constant totalTokenCount = 1781;
    uint256 public supply = 45;
    uint256 public mintPrice;
    uint256 public drop;
    bool public saleIsActive;

    mapping(uint256 => uint256) public redeemTime;
    mapping(address => bool) public claimed;
    mapping(uint256 => address) public redeemed;
    mapping(uint256 => uint256) public dropSupply;

    constructor() ERC721("Asprey Studio Club", "ASC:C1") {
        baseURI = "https://asprey-nft-minting-metadata-ab-01.s3.eu-west-2.amazonaws.com/ads-club/";
        redeemTime[0] = 1752408000; // GMT: Sunday, 13 July 2025 12:00:00
        dropSupply[0] = supply;
        for (uint256 i; i < supply; ++i) {
            _tokenIdCounter.increment();
            uint256 tokenId = _tokenIdCounter.current();
            _safeMint(msg.sender, tokenId);
        }
    }

    function setSaleState(bool newState) external onlyOwner {
        saleIsActive = newState;
    }

    function createDrop(
        uint256 _redeemTime,
        uint256 _price,
        uint256 _tokenAmount
    ) external onlyOwner {
        require(_redeemTime >= block.timestamp, "Invalid Redeem Time");
        require(_price > 0, "Invalid price");
        require(_tokenAmount > 0, "Invalid Supply");
        require(
            supply + _tokenAmount <= totalTokenCount,
            "Total Supply Reached"
        );
        drop += 1;
        redeemTime[drop] = _redeemTime;
        supply += _tokenAmount;
        dropSupply[drop] = _tokenAmount;
        mintPrice = _price;
    }

    function updateRedeemTime(uint256 _drop, uint256 _redeemTime)
        external
        onlyOwner
    {
        require(_redeemTime > block.timestamp, "Invalid Redeem Time ");
        redeemTime[_drop] = _redeemTime;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function updateBaseURI(string calldata _URI) external onlyOwner {
        baseURI = _URI;
    }

    function updateMerkleRoot(bytes32 _root) external onlyOwner {
        root = _root;
    }

    function mintPreSale(bytes32[] calldata proof)
        external
        payable
        nonReentrant
    {
        require(saleIsActive, "Sale is inactive");
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        require(msg.value == mintPrice, "Purchase: Incorrect payment");
        require(tokenId <= supply, "Current Drop supply reached");
        require(claimed[msg.sender] == false, "already claimed");
        claimed[msg.sender] = true;
        require(_verify(_leaf(msg.sender), proof), "Invalid merkle proof");
        (bool success, ) = payable(owner()).call{value: msg.value}("");
        require(success, "Transfer failed");
        _safeMint(msg.sender, tokenId);
    }

    function adminMint() external onlyOwner {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId <= supply, "Total supply reached");
        _safeMint(msg.sender, tokenId);
    }

    function redeem(uint256 tokenId) external {
        require(totalSupply() >= tokenId, "Invalid TokenId");
        require(
            ownerOf(tokenId) == _msgSender(),
            "Not the current owner of token"
        );
        require(redeemed[tokenId] == address(0), "Token redeemed");

        uint256 dropId;
        uint256 previousDropSupply = 0;
        for (uint256 index = 0; index <= drop; index++) {
            if (dropSupply[index] + previousDropSupply >= tokenId) {
                dropId = index;
                break;
            }
            previousDropSupply = previousDropSupply + dropSupply[index];
        }
        require(block.timestamp <= redeemTime[dropId], "Redeem time finished");
        redeemed[tokenId] = msg.sender;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    function getIdsOwnedUnRedeemed(address user)
        public
        view
        returns (uint256[] memory)
    {
        uint256 numTokens = balanceOf(user);
        uint256[] memory uriList = new uint256[](numTokens);
        for (uint256 i; i < numTokens; i++) {
            uint256 tok = tokenOfOwnerByIndex(user, i);
            if (redeemed[tok] == address(0)) {
                uriList[i] = tok;
            } else {
                uriList[i] = 0;
            }
        }
        return (uriList);
    }

    function _leaf(address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof)
        internal
        view
        returns (bool)
    {
        return MerkleProof.verify(proof, root, leaf);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}