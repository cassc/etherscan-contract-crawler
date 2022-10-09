// SPDX-License-Identifier: UNLICENSED

/*

ETH WITCHES                                                                                                          

*/

pragma solidity ^0.8.10;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OnchainBirbs is ERC721A, Ownable {
    bool public saleEnabled;
    uint256 public price;
    string public metadataBaseURL;

    uint256 public constant WL_SUPPLY = 333;
    uint256 public constant PAID_SUPPLY = 1999;
    uint256 public constant MAX_SUPPLY = WL_SUPPLY + PAID_SUPPLY;
    mapping(address => uint256) public WL_Claims;
    mapping(address => uint256) public Claims;

    bytes32 public rootHex;

    constructor() ERC721A("0nchainBirbs", "OCBRB", MAX_SUPPLY) {
        saleEnabled = false;
        price = 0.0088 ether;
        rootHex = 0x0;
    }

    function setRootHex(bytes32 _merkleRoot) external onlyOwner {
        rootHex = _merkleRoot;
    }

    function setBaseURI(string memory baseURL) external onlyOwner {
        metadataBaseURL = baseURL;
    }

    function toggleSaleStatus() external onlyOwner {
        saleEnabled = !(saleEnabled);
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
        require(saleEnabled, "Sale must be active.");
        require(Claims[msg.sender] + numOfTokens <= 2, "Exceed mint amount");
        require(totalSupply() + numOfTokens <= MAX_SUPPLY, "Exceed max supply");
        require(
            (price * numOfTokens) <= msg.value,
            "Insufficient funds to claim."
        );

        Claims[msg.sender] += numOfTokens;
        _safeMint(msg.sender, numOfTokens);
    }

    function mintWL(uint256 numOfTokens)
        external
        payable
    {
        require(WL_Claims[msg.sender] + numOfTokens <= 2, "Exceed mint amount");
        require(saleEnabled, "Sale must be active.");
        require(totalSupply() + numOfTokens <= WL_SUPPLY, "Exceed max supply");
        require(
            (price * numOfTokens) <= msg.value,
            "Insufficient funds to claim."
        );

        WL_Claims[msg.sender] += numOfTokens;
        _safeMint(msg.sender, numOfTokens);
    }
}