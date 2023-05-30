// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "https://github.com/chiru-labs/ERC721A/blob/main/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Dream is ERC721A, Ownable {
    uint256 public TOTAL_SUPPLY = 8888;
    uint256 public RESERVED_SUPPLY = 1600; // reserved for free mint
    bytes32 public presaleRoot;
    bytes32 public freeMintRoot;
    uint256 public presalePrice = 0.08 ether;
    uint256 public mintPrice = 0.10 ether;
    bool public isPublicSale;
    bool public isPresale;
    bool public isFreeMint;
    uint256 public maxPublicMint = 6;

    bool isRevealed = false;
    string public baseURI = "";
    string public preRevealedURI = "";

    mapping(address => uint256) public publicMintCount;
    mapping(address => uint256) public freeMintCount;
    mapping(address => uint256) public presaleMintCount;

    constructor() ERC721A("Dream", "DREAM") {}

    // ======== PUBLIC MINTING FUNCTIONS ========

    function presaleMint(
        uint256 _quantity,
        bytes32[] calldata _proof,
        uint256 _maxQuantity
    ) external payable {
        require(isPresale, "presale has not started");
        require(
            _quantity + totalSupply() <= TOTAL_SUPPLY - RESERVED_SUPPLY,
            "Exceed total supply"
        );
        require(
            _quantity + presaleMintCount[msg.sender] <= _maxQuantity,
            "Exceed max mint amount"
        );
        require(msg.value >= presalePrice * _quantity, "Not enough eth sent");
        require(
            MerkleProof.verify(
                _proof,
                presaleRoot,
                _convertLeaf(msg.sender, _maxQuantity)
            ),
            "Invalid proof"
        );
        presaleMintCount[msg.sender] += _quantity;
        _mint(msg.sender, _quantity);
    }

    function publicSaleMint(uint256 _quantity) public payable {
        require(isPublicSale, "Public sale has not started");
        require(msg.value >= mintPrice * _quantity, "Not enough eth sent");
        require(
            publicMintCount[msg.sender] + _quantity <= maxPublicMint,
            "Max public mint"
        );
        require(
            _quantity + totalSupply() <= TOTAL_SUPPLY - RESERVED_SUPPLY,
            "Exceed total supply"
        );
        publicMintCount[msg.sender] += _quantity;
        _mint(msg.sender, _quantity);
    }

    function freeMint(
        uint256 _quantity,
        bytes32[] calldata _proof,
        uint256 _maxQuantity
    ) external {
        require(isFreeMint, "Free mint has not started");
        require(
            _quantity + totalSupply() <= TOTAL_SUPPLY,
            "Exceed total supply"
        );
        require(
            _quantity + freeMintCount[msg.sender] <= _maxQuantity,
            "Exceed max mint amount"
        );
        require(
            MerkleProof.verify(
                _proof,
                freeMintRoot,
                _convertLeaf(msg.sender, _maxQuantity)
            ),
            "Invalid proof"
        );
        freeMintCount[msg.sender] += _quantity;
        _mint(msg.sender, _quantity);
    }

    // ======== UTILS ========

    function _convertLeaf(address _user, uint256 _quantity)
        internal
        pure
        returns (bytes32)
    {
        string memory quantity_string = Strings.toString(_quantity);
        string memory address_string = Strings.toHexString(
            uint256(uint160(_user)),
            20
        );
        return keccak256(abi.encodePacked(quantity_string, address_string));
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!isRevealed) {
            return preRevealedURI;
        }
        return
            string(
                abi.encodePacked(baseURI, Strings.toString(tokenId), ".json")
            );
    }

    function _startTokenId()
        internal
        view
        virtual
        override(ERC721A)
        returns (uint256)
    {
        return 1;
    }

    // ======== WITHDRAW ========

    function withdraw() external onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    // ======== SETTERS ========

    function teamMint(uint256 _quantity) external onlyOwner {
        require(_quantity + totalSupply() <= TOTAL_SUPPLY, "Exceed total supply");
        _mint(msg.sender, _quantity);
    }

    function setRevealed(bool _isRevealed) external onlyOwner {
        isRevealed = _isRevealed;
    }

    function setMaxPublicMint(uint256 _max) external onlyOwner {
        maxPublicMint = _max;
    }

    function setFreeMintRoot(bytes32 _root) public onlyOwner {
        freeMintRoot = _root;
    }

    function setPresaleRoot(bytes32 _root) public onlyOwner {
        presaleRoot = _root;
    }

    function setMintPrice(uint256 _presale, uint256 _public) public onlyOwner {
        presalePrice = _presale;
        mintPrice = _public;
    }

    function setBaseURI(string calldata _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function setPrerevealedURI(string calldata _preRevealedURI)
        public
        onlyOwner
    {
        preRevealedURI = _preRevealedURI;
    }

    function setTotalSupply(uint256 _supply) public onlyOwner {
        TOTAL_SUPPLY = _supply;
    }

    function setReservedSupply(uint256 _supply) public onlyOwner {
        RESERVED_SUPPLY = _supply;
    }

    function setMintBatch(
        bool _public,
        bool _presale,
        bool _free
    ) public onlyOwner {
        isPublicSale = _public;
        isPresale = _presale;
        isFreeMint = _free;
    }
}