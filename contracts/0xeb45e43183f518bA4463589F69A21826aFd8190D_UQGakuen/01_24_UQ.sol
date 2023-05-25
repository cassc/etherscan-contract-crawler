//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
// import "erc721psi/contracts/ERC721Psi.sol"; // token IDが0開始の場合
import "./ERC721Psi.sol"; // token IDが1開始の場合
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
// import "./operator-filter-registry/src/DefaultOperatorFilterer.sol";

interface balanceOfInterface {
    function balanceOf(address addr) external view returns (uint256 holds);
}

contract UQGakuen is
    ERC721Psi,
    ERC2981,
    Ownable,
    ReentrancyGuard,
    DefaultOperatorFilterer
{
    using Strings for uint256;

    uint256 public tokenCount = 0;

    uint256 public prePrice = 0.05 ether;
    uint256 public pubPrice = 0.05 ether;

    bool public preSaleStart = false;
    bool public pubSaleStart = false;

    uint256 public mintLimit = 2;

    bytes32 public merkleRoot;

    uint256 public maxSupply = 12;

    mapping(address => uint256) public claimed;

    string public _modeATokenURI;
    string public _modeBTokenURI;
    string public _modeCTokenURI;
    string public _modeDTokenURI;
    string public _modeETokenURI;

    constructor(
        ) ERC721Psi("UQGakuen", "UQG") {
        _setDefaultRoyalty(owner(), 1000);
    }

    function pubMint(uint256 _quantity) public payable nonReentrant {
        uint256 supply = totalSupply();
        uint256 cost = pubPrice * _quantity;
        require(pubSaleStart, "Before sale begin.");
        _mintCheckForPubSale(_quantity, supply, cost);

        claimed[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function checkMerkleProof(
        bytes32[] calldata _merkleProof
    ) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verifyCalldata(_merkleProof, merkleRoot, leaf);
    }

    function preMint(
        uint256 _quantity,
        bytes32[] calldata _merkleProof
    ) public payable nonReentrant {
        uint256 supply = totalSupply();
        uint256 cost = prePrice * _quantity;
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
        require(_supply + _quantity <= maxSupply, "Max supply over");
        require(_quantity <= mintLimit, "Mint quantity over");
        require(msg.value >= _cost, "Not enough funds");
        require(
            claimed[msg.sender] + _quantity <= mintLimit,
            "Already claimed max"
        );
    }

    function _mintCheckForPubSale(
        uint256 _quantity,
        uint256 _supply,
        uint256 _cost
    ) private view {
        require(_supply + _quantity <= maxSupply, "Max supply over");
        require(msg.value >= _cost, "Not enough funds");
    }

    function ownerMint(address _address, uint256 _quantity) public onlyOwner {
        uint256 supply = totalSupply();
        require(supply + _quantity <= maxSupply, "Max supply over");
        _safeMint(_address, _quantity);
    }

    function setPresale(bool _state) public onlyOwner {
        preSaleStart = _state;
    }

    function setPubsale(bool _state) public onlyOwner {
        pubSaleStart = _state;
    }

    function setPrePrice(uint256 newPrice) external onlyOwner {
        prePrice = newPrice;
    }

    function setPubPrice(uint256 newPrice) external onlyOwner {
        pubPrice = newPrice;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setMintLimit(uint256 _quantity) public onlyOwner {
        mintLimit = _quantity;
    }

    function withdrawRevenueShare() external onlyOwner {
        uint256 sendAmount = address(this).balance;
        address artist = payable(0x45FAb1f60C45b0F401f1600BB5CCE6350eb36076);
        bool success;

        (success, ) = artist.call{value: sendAmount}("");
        require(success, "Failed to withdraw Ether");
    }

    // OperatorFilterer
    function setOperatorFilteringEnabled(bool _state) external onlyOwner {
        operatorFilteringEnabled = _state;
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

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

    function setRoyalty(
        address _royaltyAddress,
        uint96 _feeNumerator
    ) external onlyOwner {
        _setDefaultRoyalty(_royaltyAddress, _feeNumerator);
    }

    function supportsInterface(
        bytes4 _interfaceId
    ) public view virtual override(ERC721Psi, ERC2981) returns (bool) {
        return
            ERC721Psi.supportsInterface(_interfaceId) ||
            ERC2981.supportsInterface(_interfaceId);
    }

    // Supply上限設定
    function setMaxSupply(uint256 newSupply) external onlyOwner {
        require(maxSupply >= newSupply, "total supply over");
        maxSupply = newSupply;
    }

    //style Map
    mapping(uint256 => uint256) public mapTokenMode;

    //key Project 1
    address x1_address;
    balanceOfInterface x1_Contract = balanceOfInterface(x1_address);

    //key Project 2
    address x2_address;
    balanceOfInterface x2_Contract = balanceOfInterface(x2_address);

    //key Project 3
    address x3_address;
    balanceOfInterface x3_Contract = balanceOfInterface(x3_address);

    // modeごとにURIを切り替え
    function _baseURI(uint256 tokenId) internal view returns (string memory) {
        if (mapTokenMode[tokenId] == 1) {
            return _modeATokenURI;
        }
        if (mapTokenMode[tokenId] == 2) {
            return _modeBTokenURI;
        }
        if (mapTokenMode[tokenId] == 3) {
            return _modeCTokenURI;
        }
        if (mapTokenMode[tokenId] == 4) {
            return _modeDTokenURI;
        }
        if (mapTokenMode[tokenId] == 5) {
            return _modeETokenURI;
        }
        return _modeATokenURI;
    }

    //retuen BaseURI.internal.
    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Psi: URI query for nonexistent token");

        // 引数にtokenIdを追加
        string memory baseURI = _baseURI(tokenId);

        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, Strings.toString(tokenId), ".json"))
                : "";
    }

    // change mode for holder
    function ModeA(uint256 tokenId) public {
        require(
            ownerOf(tokenId) == msg.sender,
            "You are not the holder of this token."
        );
        mapTokenMode[tokenId] = 1;
    }
    function ModeB(uint256 tokenId) public {
        require(
            ownerOf(tokenId) == msg.sender,
            "You are not the holder of this token."
        );
        mapTokenMode[tokenId] = 2;
    }
    // only X1 holder
    function ModeC(uint256 tokenId) public {
        require(
            ownerOf(tokenId) == msg.sender,
            "You are not the holder of this token."
        );
        require(
            0 < x1_Contract.balanceOf(msg.sender),
            "You don't have collaboration token."
        );
        mapTokenMode[tokenId] = 3;
    }
    function ModeD(uint256 tokenId) public {
        require(
            ownerOf(tokenId) == msg.sender,
            "You are not the holder of this token."
        );
        mapTokenMode[tokenId] = 4;
    }
    // only X2 holder
    function ModeE(uint256 tokenId) public {
        require(
            ownerOf(tokenId) == msg.sender,
            "You are not the holder of this token."
        );
        require(
            0 < x2_Contract.balanceOf(msg.sender),
            "You don't have collaboration token."
        );
        mapTokenMode[tokenId] = 5;
    }

    function ModeChangeByOwner(
        uint256 tokenId,
        uint256 modeID
    ) public onlyOwner {
        mapTokenMode[tokenId] = modeID;
    }

    //set URI
    function setModeA_URI(string calldata baseURI) external onlyOwner {
        _modeATokenURI = baseURI;
    }
    function setModeB_URI(string calldata baseURI) external onlyOwner {
        _modeBTokenURI = baseURI;
    }
    function setModeC_URI(string calldata baseURI) external onlyOwner {
        _modeCTokenURI = baseURI;
    }
    function setModeD_URI(string calldata baseURI) external onlyOwner {
        _modeDTokenURI = baseURI;
    }
    function setModeE_URI(string calldata baseURI) external onlyOwner {
        _modeETokenURI = baseURI;
    }

    //set x1 address
    function setX1Adress(address c_address) external onlyOwner {
        x1_address = c_address;
        x1_Contract = balanceOfInterface(x1_address);
    }
    //set x2 address
    function setX2Adress(address c_address) external onlyOwner {
        x2_address = c_address;
        x2_Contract = balanceOfInterface(x2_address);
    }
}