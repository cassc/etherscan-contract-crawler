// SPDX-License-Identifier: UNLICENSED

/*

ETH WITCHES                                                                                                          

*/

pragma solidity ^0.8.10;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract ethWitches is ERC721A, Ownable {
    bool public saleEnabled;
    bool public ogSaleEnabled;
    uint256 public price;
    string public metadataBaseURL;

    uint256 public constant WL_SUPPLY = 250;
    uint256 public constant OG_SUPPLY = 20;
    uint256 public constant PAID_SUPPLY = 1618;
    uint256 public constant MAX_SUPPLY = WL_SUPPLY + OG_SUPPLY + PAID_SUPPLY;
    mapping(address => uint256) public OG_Claims;
    mapping(address => bool) public WL_Claims;
    mapping(address => uint256) public Public_Claims;

    bytes32 public OgRootHex;
    bytes32 public WlRootHex;

    constructor() ERC721A("ethWitches", "WTCH", MAX_SUPPLY) {
        saleEnabled = false;
        ogSaleEnabled = false;
        price = 0.0088 ether;
        OgRootHex = 0x0;
        WlRootHex = 0x0;
    }

    function setOgRootHex(bytes32 _merkleRoot) external onlyOwner {
        OgRootHex = _merkleRoot;
    }

    function setWlRootHex(bytes32 _merkleRoot) external onlyOwner {
        WlRootHex = _merkleRoot;
    }

    function setBaseURI(string memory baseURL) external onlyOwner {
        metadataBaseURL = baseURL;
    }

    function toggleSaleStatus() external onlyOwner {
        saleEnabled = !(saleEnabled);
    }

    function toggleOGSaleStatus() external onlyOwner {
        ogSaleEnabled = !(ogSaleEnabled);
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return metadataBaseURL;
    }

    function withdraw() external onlyOwner {
        uint256 _balance = address(this).balance;
        address payable _sender = payable(_msgSender());
        _sender.transfer(_balance);
    }

    function reserve(uint256 num) external onlyOwner {
        require((totalSupply() + num) <= MAX_SUPPLY, "Exceed max supply");
        _safeMint(msg.sender, num);
    }

    function mint(uint256 numOfTokens) external payable {
        require(
            Public_Claims[msg.sender] + numOfTokens <= 2,
            "Exceed mint amount"
        );
        require(saleEnabled, "Sale must be active.");
        require(totalSupply() + numOfTokens <= MAX_SUPPLY, "Exceed max supply");
        require(
            (price * numOfTokens) <= msg.value,
            "Insufficient funds to claim."
        );

        Public_Claims[msg.sender] += numOfTokens;
        _safeMint(msg.sender, numOfTokens);
    }

    function mintWL(uint256 numOfTokens, bytes32[] calldata _merkleProof)
        external
        payable
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, WlRootHex, leaf),
            "Invalid proof"
        );

        require(!WL_Claims[msg.sender], "Already claimed mint");
        require(saleEnabled, "Sale must be active.");
        require(
            totalSupply() + numOfTokens <= (WL_SUPPLY + OG_SUPPLY),
            "Exceed max supply"
        );

        WL_Claims[msg.sender] = true;
        _safeMint(msg.sender, numOfTokens);
    }

    function mintOG(uint256 numOfTokens, bytes32[] calldata _merkleProof)
        external
        payable
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, OgRootHex, leaf),
            "Invalid proof"
        );

        require(ogSaleEnabled, "Sale must be active.");
        require(OG_Claims[msg.sender] + numOfTokens <= 2, "Exceed mint amount");
        require(totalSupply() + numOfTokens <= OG_SUPPLY, "Exceed max supply");

        OG_Claims[msg.sender] += numOfTokens;
        _safeMint(msg.sender, numOfTokens);
    }
}