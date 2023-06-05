// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./ERC721A.sol";

contract WorldOfMen is ERC721A, Ownable, PaymentSplitter, ReentrancyGuard {
    uint256 public immutable MAX_PER_ADDRESS;
    uint256 public constant PRICE = 0.069 ether;
    uint256 public immutable MAX_SUPPLY;
    uint256 public whitelistCount = 1;
    bytes32 public whitelistMerkleRoot;
    string public _baseTokenURI;
    bool public isWhitelistSaleActive;
    bool public isPublicSaleActive;

    // keep track of how many WL user has claimed
    mapping(address => uint256) public claimed;

    constructor(
        uint256 maxBatchSize_,
        address[] memory _payees,
        uint256[] memory _shares
    )
        payable
        PaymentSplitter(_payees, _shares)
        ERC721A("WorldOfMen", "WOM", maxBatchSize_)
    {
        isWhitelistSaleActive = false;
        isPublicSaleActive = false;
        MAX_SUPPLY = 10_000;
        MAX_PER_ADDRESS = maxBatchSize_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    modifier isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address does not exist in list"
        );
        _;
    }

    function mintWhitelist(bytes32[] calldata merkleProof, uint256 count)
        public
        payable
        isValidMerkleProof(merkleProof, whitelistMerkleRoot)
        callerIsUser
        nonReentrant
    {
        require(isWhitelistSaleActive, "Sale has not started");
        require(count != 0, "Must pass in number");
        require(PRICE * count == msg.value, "Incorrect ETH value sent");
        require(
            claimed[msg.sender] + count <= MAX_PER_ADDRESS,
            "Already minted max address allocation"
        );
        require(totalSupply() + count <= MAX_SUPPLY, "Max tokens minted");
        whitelistCount += count;
        claimed[msg.sender] += count;
        _safeMint(msg.sender, count);
    }

    function mintPublicSale(uint256 count)
        external
        payable
        callerIsUser
        nonReentrant
    {
        require(isPublicSaleActive, "Sale has not started");
        require(count != 0, "Must pass in number");
        require(totalSupply() + count <= MAX_SUPPLY, "Max tokens minted");
        require(PRICE * count == msg.value, "Incorrect ETH value sent");
        require(
            _numberMinted(msg.sender) + count <= MAX_PER_ADDRESS,
            "Already minted max address allocation"
        );
        _safeMint(msg.sender, count);
    }

    function setWhitelistSaleActive(bool _isSalePublic) external onlyOwner {
        isWhitelistSaleActive = _isSalePublic;
    }

    function setPublicSaleActive(bool _isSalePublic) external onlyOwner {
        isPublicSaleActive = _isSalePublic;
    }

    function hasWhitelistSaleStarted() public view returns (bool) {
        return isWhitelistSaleActive;
    }

    function hasPublicSaleStarted() public view returns (bool) {
        return isPublicSaleActive;
    }

    function setWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        whitelistMerkleRoot = merkleRoot;
    }

    function setOwnersExplicit(uint256 quantity)
        external
        onlyOwner
        nonReentrant
    {
        _setOwnersExplicit(quantity);
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }
}