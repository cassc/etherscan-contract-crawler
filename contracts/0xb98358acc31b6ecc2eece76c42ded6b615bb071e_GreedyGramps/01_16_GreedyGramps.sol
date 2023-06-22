// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.6;

import "erc721a/contracts/extensions/ERC721AOwnersExplicit.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./interfaces/IERC2981.sol";
import "./interfaces/IGreedyFeeSplitter.sol";

/// @title GreedyGramps
/// @author GreedyDev
/// @notice ERC721 contract for Greedy Gramps collection
contract GreedyGramps is ERC721AOwnersExplicit, Ownable, IERC2981 {
    using Strings for uint256;

    uint256 public constant MAX_GRAMPS = 10000;
    uint256 public constant RESERVED_GRAMPS = 200;
    bool public reservedUsed = false;

    bytes4 internal constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    // Private Sale
    bytes32 public private_merkleRoot;
    uint256 public private_price;
    uint256 public private_start;
    uint256 public private_end;
    mapping(address => uint256) public private_usedAllocation;

    // Pre Sale
    bytes32 public pre_merkleRoot;
    uint256 public pre_maxAllocation;
    uint256 public pre_price;
    uint256 public pre_start;
    uint256 public pre_end;
    mapping(address => uint256) public pre_usedAllocation;

    // Public Sale
    uint256 public public_start;
    uint256 public public_price;

    string public _baseTokenUri;
    uint256 public royaltyFee;

    IGreedyFeeSplitter public feeSplitter;

    modifier validateAmount(uint256 amount) {
        require(amount > 0, "GreedyGramps: Invalid amount");
        require(
            totalSupply() + amount <= MAX_GRAMPS,
            "GreedyGramps: Sold out!"
        );
        _;
    }

    constructor() ERC721A("GreedyGramps", "GG") {}

    function mintReserved() external onlyOwner {
        require(!reservedUsed, "GreedyGramps: Reserved already minted");
        reservedUsed = true;

        _safeMint(owner(), RESERVED_GRAMPS);
    }

    /// @notice Buy Greedy Gramps during private sale
    /// @dev ...
    /// @param amount The number of gramps the user wants to purchase
    /// @param amount Merke proof
    function buyPrivateSale(
        uint256 amount,
        uint256 allocation,
        bytes32[] calldata merkleProof
    ) external payable validateAmount(amount) {
        uint256 timestamp = block.timestamp; // safe gas
        require(
            timestamp >= private_start && timestamp <= private_end,
            "GreedyGramps: sale not active"
        );
        require(
            msg.value >= amount * private_price,
            "GreedyGramps: Insufficient funds"
        );

        // Check whitelist
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender(), allocation));
        require(
            MerkleProof.verify(merkleProof, private_merkleRoot, leaf),
            "GreedyGramps: Merkle proof invalid"
        );

        // Check if user has already used his quota
        require(
            private_usedAllocation[_msgSender()] + amount <= allocation,
            "GreedyGramps: max allocation reached"
        );
        private_usedAllocation[_msgSender()] += amount;

        // Mint NFT's
        _safeMint(_msgSender(), amount);
    }

    /// @notice Buy Greedy Gramps during pre sale
    /// @dev ...
    /// @param amount The number of gramps the user wants to purchase
    /// @param amount Merke proof
    function buyPreSale(uint256 amount, bytes32[] calldata merkleProof)
        external
        payable
        validateAmount(amount)
    {
        uint256 timestamp = block.timestamp; // safe gas
        require(
            timestamp >= pre_start && timestamp <= pre_end,
            "GreedyGramps: sale not active"
        );
        require(
            msg.value >= amount * pre_price,
            "GreedyGramps: Insufficient funds"
        );

        // Check whitelist
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(
            MerkleProof.verify(merkleProof, pre_merkleRoot, leaf),
            "GreedyGramps: Merkle proof invalid"
        );

        // Check if user has already used his quota
        require(
            pre_usedAllocation[_msgSender()] + amount <= pre_maxAllocation,
            "GreedyGramps: max allocation reached"
        );
        pre_usedAllocation[_msgSender()] += amount;

        // Mint NFT's
        _safeMint(_msgSender(), amount);
    }

    /// @notice Buy Greedy Gramps during public sale
    /// @dev
    /// @param amount The number of gramps the user wants to purchase
    function buyPublicSale(uint256 amount)
        external
        payable
        validateAmount(amount)
    {
        require(
            block.timestamp >= public_start,
            "GreedyGramps: Public sale has not started"
        );
        require(
            msg.value >= amount * public_price,
            "GreedyGramps: Insufficient funds"
        );

        // Mint NFT's
        _safeMint(_msgSender(), amount);
    }

    /// @notice Return information about royalty amounts and receivers
    /// @dev
    /// @param _tokenId Id of the token that has been sold
    /// @param _salePrice Price the item was sold for
    /// @return receiver Address of the royalty recipient
    /// @return royaltyAmount Amount of royalty payout
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        override
        returns (address, uint256)
    {
        uint256 royaltyAmount = (royaltyFee * _salePrice) / 1 ether;
        return (address(feeSplitter), royaltyAmount);
    }

    /// @notice Return the uri for the metadata to this token id
    /// @dev ...
    /// @param _tokenId Id of the token
    /// @return tokenUri Uri leading to the id's attached metadata
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return string(abi.encodePacked(_baseTokenUri, _tokenId.toString()));
    }

    // @notice EIP165 Implementation
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override
        returns (bool)
    {
        return
            interfaceId == _INTERFACE_ID_ERC2981 ||
            super.supportsInterface(interfaceId);
    }

    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override(ERC721A) {
        if (address(feeSplitter) != address(0)) {
            feeSplitter.logSale(msg.value, startTokenId, msg.sender);
        }
    }

    // Administrative functions
    function setPrivateSale(
        uint256 _start,
        uint256 _end,
        uint256 _price,
        bytes32 _merkleRoot
    ) external onlyOwner {
        require(
            _start > private_start && _end > _start,
            "GreedyGramps: New timestamp has to be in the future"
        );

        private_start = _start;
        private_end = _end;
        private_price = _price;
        private_merkleRoot = _merkleRoot;
    }

    function setPreSale(
        uint256 _start,
        uint256 _end,
        uint256 _price,
        bytes32 _merkleRoot,
        uint256 _allocationPerWallet
    ) external onlyOwner {
        require(
            _start > pre_start && _end > _start,
            "GreedyGramps: New timestamp has to be in the future"
        );

        pre_start = _start;
        pre_end = _end;
        pre_price = _price;
        pre_merkleRoot = _merkleRoot;
        pre_maxAllocation = _allocationPerWallet;
    }

    function setPublicSale(uint256 _start, uint256 _price) external onlyOwner {
        require(
            _start > public_start,
            "GreedyGramps: New timestamp has to be in the future"
        );
        require(
            _start > pre_end,
            "GreedyGramps: New timestamp has to be behind the presSaleEndin the future"
        );

        public_start = _start;
        public_price = _price;
    }

    function setBaseTokenUri(string memory _uri) external onlyOwner {
        _baseTokenUri = _uri;
    }

    function setRoyaltyFee(uint256 _royaltyFee) external onlyOwner {
        royaltyFee = _royaltyFee;
    }

    function setFeeSplitter(address _feeSplitter) external onlyOwner {
        feeSplitter = IGreedyFeeSplitter(_feeSplitter);
    }

    function setPrivateRoot(bytes32 root) external onlyOwner {
        private_merkleRoot = root;
    }

    function setPreRoot(bytes32 root) external onlyOwner {
        pre_merkleRoot = root;
    }

    function getEther() external onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success);
    }
}