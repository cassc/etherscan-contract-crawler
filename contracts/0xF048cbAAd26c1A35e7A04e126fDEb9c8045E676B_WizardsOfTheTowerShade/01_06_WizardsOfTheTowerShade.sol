// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract WizardsOfTheTowerShade is ERC721A, Ownable, ReentrancyGuard {
    string public baseURI;
    bool public mintActive = false;
    uint256 public supply = 10000;
    uint256 public mintLimit = 1;
    uint256 private reserve = 300;
    uint256 private freeMints = 1000;
    uint256 public cost = 5000000000000000;

    constructor() ERC721A("WizardsOfTheTowerShade", "WTS") {}

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    modifier mintActiveCompliance(uint256 _count) {
        require(mintActive, "Mint is not active");
        _;
    }

    modifier mintLimitCompliance(uint256 _count) {
        require(
            _numberMinted(msg.sender) + _count <= mintLimit,
            "Requested mint count would exceed mint limit for account"
        );
        _;
    }

    modifier supplyCompliance(uint256 _count) {
        require(
            totalSupply() + _count <= supply - reserve,
            "Requested mint count exceeds the supply"
        );
        _;
    }

    modifier mintPriceCompliance(uint256 _count) {
        require(msg.value >= cost * _count, "Not enough ETH for mint count");
        _;
    }

    function mintFree(uint256 _count)
        external
        nonReentrant
        mintActiveCompliance(_count)
        mintLimitCompliance(_count)
    {
        require(
            totalSupply() + _count <= freeMints,
            "Requested mint count exceeds free mint supply"
        );

        _safeMint(msg.sender, _count);
    }

    function mint(uint256 _count)
        external
        payable
        nonReentrant
        mintActiveCompliance(_count)
        supplyCompliance(_count)
        mintLimitCompliance(_count)
        mintPriceCompliance(_count)
    {
        _safeMint(msg.sender, _count);
    }

    function reserveTokens(address owner, uint256 _count)
        external
        nonReentrant
        onlyOwner
    {
        require(
            _count <= reserve,
            "Requested mint count exceeds reserve limit"
        );
        _safeMint(owner, _count);
        reserve = reserve - _count;
    }

    function releaseReserve() external onlyOwner {
        reserve = 0;
    }

    function setMintActive(bool _mintActive) external onlyOwner {
        mintActive = _mintActive;
    }

    function setMintLimit(uint256 _mintLimit) external onlyOwner {
        mintLimit = _mintLimit;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function withdraw() public payable onlyOwner nonReentrant {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success);
    }
}