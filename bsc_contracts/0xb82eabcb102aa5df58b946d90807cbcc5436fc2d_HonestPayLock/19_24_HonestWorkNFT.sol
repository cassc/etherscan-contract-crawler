// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./Payments/HonestPayLock.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract HonestWorkNFT is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter public _tokenIds;
    uint256 public MINT_FEE = 1 ether;
    uint256 public constant TOKEN_CAP = 10000;
    uint256 public tier2Fee = 100 ether;
    uint256 public tier3Fee = 1000 ether;
    bytes32 public whitelistRoot;

    //@notice  2 1- tier1  2-tier2 3-tier3
    mapping(address => bool) public whitelistCap;
    mapping(uint256 => uint256) public tier;
    mapping(uint256 => uint256) public grossRevenue;

    event RevenueIncreased(uint256 id, uint256 revenue);
    event Upgraded(uint256 id, uint256 tier);
    event Mint(uint256 id, address user);

    HonestPayLock public honestPayLock;

    constructor() ERC721("HonestWork", "HW") {}

    modifier onlyHonestPay() {
        require(
            msg.sender == address(honestPayLock),
            "only HonestWork contract can record gross revenue"
        );
        _;
    }

    // restricted fxns

    function setWhitelistRoot(bytes32 _root) external onlyOwner {
        whitelistRoot = _root;
    }

    function changeTierTwoFee(uint256 _newFee) external onlyOwner {
        tier2Fee = _newFee;
    }

    function changeTierThreeFee(uint256 _newFee) external onlyOwner {
        tier3Fee = _newFee;
    }

    function recordGrossRevenue(
        uint256 _nftId,
        uint256 _revenue
    ) external onlyHonestPay {
        grossRevenue[_nftId] += _revenue;
        emit RevenueIncreased(_nftId, _revenue);
    }

    function setHonestPayLock(HonestPayLock _honestPayLock) external onlyOwner {
        honestPayLock = _honestPayLock;
    }

    // view fxns

    function getGrossRevenue(uint256 _tokenId) external view returns (uint256) {
        return grossRevenue[_tokenId];
    }

    function getAllGrossRevenues() external view returns (uint256[] memory) {
        uint256[] memory _grossRevenues = new uint256[](totalSupply());
        for (uint256 i = 0; i < totalSupply(); i++) {
            _grossRevenues[i] = grossRevenue[i];
        }
        return _grossRevenues;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // internal fxns

    function _baseURI() internal pure override returns (string memory) {
        return "AABDAF"; // HW URI
    }

    function _whitelistLeaf(address _address) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_address));
    }

    function _verify(
        bytes32 _leaf,
        bytes32 _root,
        bytes32[] memory _proof
    ) internal pure returns (bool) {
        return MerkleProof.verify(_proof, _root, _leaf);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        require(balanceOf(to) == 0, "only one nft at a time");
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // mutative fxns

    function publicMint(address recipient) external payable returns (uint256) {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        require(msg.value > MINT_FEE, "not enough funds");
        require(newItemId < TOKEN_CAP, "all the nfts are claimed");
        _mint(recipient, newItemId);
        tier[newItemId] = 1;
        emit Mint(newItemId, recipient);
        return newItemId;
    }

    function whitelistMint(
        address recipient,
        bytes32[] calldata _proof
    ) external returns (uint256) {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        require(newItemId < TOKEN_CAP, "all the nfts are claimed");
        require(
            _verify(_whitelistLeaf(msg.sender), whitelistRoot, _proof),
            "Invalid merkle proof"
        );

        whitelistCap[msg.sender] = true;
        _mint(recipient, newItemId);
        tier[newItemId] = 1;

        return newItemId;
    }

    //solve price fluctuation
    function upgradeToken(uint256 _tokenId, uint256 _tier) external payable {
        require(
            ownerOf(_tokenId) == msg.sender,
            "only owned tokens can be claimed"
        );
        if (_tier == 2) {
            require(msg.value > tier2Fee);
        } else if (_tier == 3) {
            require(msg.value > tier3Fee);
        } else {
            revert("only 3 tiers possible");
        }
        tier[_tokenId] = _tier;
        emit Upgraded(_tokenId, _tier);
    }
}