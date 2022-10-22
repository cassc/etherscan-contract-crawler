//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721psi/contracts/ERC721Psi.sol";

contract TOKEN is ERC721Psi, ERC2981, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 1200;
    uint256 public constant PRE_PRICE = 0.02 ether;
    uint256 public constant PUB_PRICE = 0.04 ether;

    bool public preSaleStart;
    bool public pubSaleStart;
    bool public isFinalize;

    uint256 public mintLimit = 2;

    bytes32 public merkleRoot;

    address public royaltyAddress = 0xCba45385799dCE6B93AC2C1c3c1E93F0f710db78;
    uint96 public royaltyFee = 1000;

    string private _baseTokenURI;
    string private _podURI;

    mapping(address => uint256) public claimed;
    mapping(uint256 => uint256) public revealed;
    mapping(uint256 => uint256) private _mintType;
    mapping(uint256 => address) private _owner;

    constructor() ERC721Psi("BDPGenX", "BDPGENX") {
        _setDefaultRoyalty(msg.sender, royaltyFee);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override(ERC721Psi)
        returns (string memory)
    {
        if (revealed[_tokenId] == 1) {
            return
                string(abi.encodePacked(ERC721Psi.tokenURI(_tokenId), ".json"));
        } else {
            if (!_exists(_tokenId)) return "";
            return
                string(abi.encodePacked(_podURI, _tokenId.toString(), ".json"));
        }
    }

    function pubMint(uint256 _quantity) public payable nonReentrant {
        uint256 supply = totalSupply();
        uint256 cost = PUB_PRICE * _quantity;
        require(pubSaleStart, "Before sale begin.");
        _mintCheck(_quantity, supply, cost);

        claimed[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);

        for (uint256 i = 0; i < _quantity; ) {
            uint256 tokenId = supply + i;
            _mintType[tokenId] = 1;
            unchecked {
                i++;
            }
        }
    }

    function checkMerkleProof(bytes32[] calldata _merkleProof)
        public
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verifyCalldata(_merkleProof, merkleRoot, leaf);
    }

    function preMint(uint256 _quantity, bytes32[] calldata _merkleProof)
        public
        payable
        nonReentrant
    {
        uint256 supply = totalSupply();
        uint256 cost = PRE_PRICE * _quantity;
        require(preSaleStart, "Before sale begin.");
        _mintCheck(_quantity, supply, cost);

        require(checkMerkleProof(_merkleProof), "Invalid Merkle Proof");

        claimed[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function _mintCheck(
        uint256 _quantity,
        uint256 _supply,
        uint256 _cost
    ) private view {
        require(_supply + _quantity <= MAX_SUPPLY, "Max supply over");
        require(_quantity <= mintLimit, "Mint quantity over");
        require(msg.value >= _cost, "Not enough funds");
        require(
            claimed[msg.sender] + _quantity <= mintLimit,
            "Already claimed max"
        );
    }

    function ownerMint(address _address, uint256 _quantity) public onlyOwner {
        uint256 supply = totalSupply();
        require(supply + _quantity <= MAX_SUPPLY, "Max supply over");
        _safeMint(_address, _quantity);
    }

    function checkMintType(uint256 _tokenId) external view returns (uint256) {
        require(_exists(_tokenId), "nonexistent token");
        return _mintType[_tokenId];
    }

    // only owner
    function setPodURI(string memory _uri) public onlyOwner {
        require(!isFinalize, "finalize is declared");
        _podURI = _uri;
    }

    function setBaseURI(string calldata _uri) external onlyOwner {
        require(!isFinalize, "finalize is declared");
        _baseTokenURI = _uri;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setPresale(bool _state) public onlyOwner {
        preSaleStart = _state;
    }

    function setPubsale(bool _state) public onlyOwner {
        pubSaleStart = _state;
    }

    function setMintType(uint256 _tokenId, uint256 _type) public onlyOwner {
        require(!isFinalize, "finalize is declared");
        _mintType[_tokenId] = _type;
    }

    function setMintLimit(uint256 _quantity) public onlyOwner {
        mintLimit = _quantity;
    }

    function reveal(uint256 _tokenId) public {
        address owner = ownerOf(_tokenId);
        require(owner == msg.sender, "only the owner can reveal");
        if (revealed[_tokenId] != 1) {
            revealed[_tokenId] = 1;
        }
    }

    function batchReveal(uint256[] calldata _tokenIds) public {
        uint256 n = _tokenIds.length;
        for (uint256 i = 0; i < n; ) {
            reveal(_tokenIds[i]);
            unchecked {
                i++;
            }
        }
    }

    function finalize() public onlyOwner {
        isFinalize = true;
    }

    address private _fnd;
    address private _dev;
    address private _mar;

    function setMemberAddress(
        address _founder,
        address _developer,
        address _marketer
    ) public onlyOwner {
        _fnd = _founder;
        _dev = _developer;
        _mar = _marketer;
    }

    function withdraw() external onlyOwner {
        require(
            _fnd != address(0) && _dev != address(0) && _mar != address(0),
            "Please set member address"
        );

        uint256 balance = address(this).balance;

        Address.sendValue(payable(_fnd), ((balance * 7000) / 10000));
        Address.sendValue(payable(_dev), ((balance * 2500) / 10000));
        Address.sendValue(payable(_mar), ((balance * 500) / 10000));
    }

    // Royality
    function setRoyaltyFee(uint96 _feeNumerator) external onlyOwner {
        _setDefaultRoyalty(royaltyAddress, _feeNumerator);
    }

    function setRoyaltyAddress(address _royaltyAddress) external onlyOwner {
        _setDefaultRoyalty(_royaltyAddress, royaltyFee);
    }

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(ERC721Psi, ERC2981)
        returns (bool)
    {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return
            ERC721Psi.supportsInterface(_interfaceId) ||
            ERC2981.supportsInterface(_interfaceId);
    }
}