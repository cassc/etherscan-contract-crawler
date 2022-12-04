// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./WizardsOfTheTowerShade.sol";
import "hardhat/console.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract CorruptedWizardsOfTheTowerShade is
    ERC721A,
    Ownable,
    DefaultOperatorFilterer,
    ReentrancyGuard,
    IERC721Receiver
{
    address private WTSContractAddress;
    address public nullAddress = 0x0000000000000000000000000000000000000000;
    address public burnAddress = 0x000000000000000000000000000000000000dEaD;
    string public baseURI;
    string public unrevealedURI;
    bool public mintActive = false;
    uint256 public supply = 5000;
    uint256 public mintLimit = 5;
    uint256 private reserve = 150;
    uint256 private freeMints = 2000;
    uint256 public cost = 85000000000000000;
    uint256 public sacCost = 35000000000000000;
    mapping(address => uint256[]) private sacrificedWizards;
    bool public revealed = false;
    
    WizardsOfTheTowerShade WTSContract;

    constructor(address _wtsContractAddress)
        ERC721A("CorruptedWizardsOfTheTowerShade", "CWTS")
    {
        WTSContractAddress = _wtsContractAddress;
        WTSContract = WizardsOfTheTowerShade(WTSContractAddress);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if(revealed) {
            return super.tokenURI(tokenId);
        } else {
            return unrevealedURI;
        }
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) public override nonReentrant returns (bytes4) {
        return this.onERC721Received.selector;
    }

    modifier mintActiveCompliance() {
        require(mintActive, "mint_not_active");
        _;
    }

    modifier mintLimitCompliance(uint256 _count) {
        require(
            _numberMinted(msg.sender) + _count <= mintLimit,
            "account_mint_limit"
        );
        _;
    }

    modifier supplyCompliance(uint256 _count) {
        require(
            totalSupply() + _count <= supply - reserve,
            "supply_limit"
        );
        _;
    }

    modifier reserveCompliance(uint256 _count) {
        require(
            _count <= reserve,
            "reserve_limit"
        );
        _;
    }

    modifier mintPriceCompliance(uint256 _count, uint256 _cost) {
        require(msg.value >= _cost * _count, "insufficient_funds");
        _;
    }

    modifier sacCompliance(uint256 _count, uint256 _sacPerCount) {
        require(
            sacrificedWizards[msg.sender].length >= _sacPerCount * _count,
            "insufficient_sacrifice"
        );
        _;
    }

    modifier freeMintLimitCompliance(uint256 _count) {
        require(
            freeMints - _count >= 0,
            "free_mint_supply_limit"
        );
        _;
    }

    function sacrificeWizard(uint256 _tokenId) external nonReentrant {
        WTSContract.transferFrom(msg.sender, address(this), _tokenId);
        require(
            WTSContract.ownerOf(_tokenId) == address(this),
            "nft_not_transferred"
        );
        sacrificedWizards[msg.sender].push(_tokenId);
    }

    function sacCount() external view returns(uint256) {
        return sacrificedWizards[msg.sender].length;
    }

    function spareWizards() external nonReentrant {
        for(uint256 i = 0; i < sacrificedWizards[msg.sender].length; i++) {
            WTSContract.safeTransferFrom(address(this), msg.sender, sacrificedWizards[msg.sender][i]);
        }
        delete sacrificedWizards[msg.sender];
    }

    function mintSacTwo(uint256 _count)
        external
        nonReentrant
        mintActiveCompliance
        sacCompliance(_count, 2)
        freeMintLimitCompliance(_count)
    {
        uint256 wizardsCount;
        uint256 wiz1;
        uint256 wiz2;

        for(uint256 i = 0; i < _count; i++) {
            wizardsCount = sacrificedWizards[msg.sender].length;
            wiz1 = sacrificedWizards[msg.sender][wizardsCount - 1];
            wiz2 = sacrificedWizards[msg.sender][wizardsCount - 2];
            sacrificedWizards[msg.sender].pop();
            sacrificedWizards[msg.sender].pop();
            WTSContract.transferFrom(address(this), burnAddress, wiz1);
            WTSContract.transferFrom(address(this), burnAddress, wiz2);
        }
        freeMints -= _count;
        _safeMint(msg.sender, _count);
        console.log(freeMints);
    }

    function mintSacOne(uint256 _count)
        external
        payable
        nonReentrant
        mintActiveCompliance
        mintLimitCompliance(_count)
        sacCompliance(_count, 1)
        mintPriceCompliance(_count, sacCost)
    {
        uint256 wizardsCount;
        uint256 wiz;
        for(uint256 i = 0; i < _count; i++) {
            wizardsCount = sacrificedWizards[msg.sender].length;
            wiz = sacrificedWizards[msg.sender][wizardsCount - 1];
            sacrificedWizards[msg.sender].pop();
            WTSContract.transferFrom(address(this), burnAddress, wiz);
        }
        _safeMint(msg.sender, _count);
    }

    function mint(uint256 _count)
        external
        payable
        nonReentrant
        mintActiveCompliance
        supplyCompliance(_count)
        mintLimitCompliance(_count)
        mintPriceCompliance(_count, cost)
    {
        _safeMint(msg.sender, _count);
    }

    function reserveTokens(address _owner, uint256 _count)
        external
        nonReentrant
        reserveCompliance(_count)
        onlyOwner
    {
        _safeMint(_owner, _count);
        reserve = reserve - _count;
    }

    function releaseReserve() external onlyOwner {
        reserve = 0;
    }

    function reveal() external onlyOwner {
      revealed = true;
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

    function setUnrevealedURI(string memory uri) external onlyOwner {
        unrevealedURI = uri;
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setSacCost(uint256 _cost) public onlyOwner {
        sacCost = _cost;
    }

    function withdraw() public payable onlyOwner nonReentrant {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success);
    }
}