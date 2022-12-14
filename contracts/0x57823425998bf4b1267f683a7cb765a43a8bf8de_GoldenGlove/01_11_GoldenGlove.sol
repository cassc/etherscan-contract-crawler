// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "ERC721A/extensions/ERC721AQueryable.sol";

import "operator-filter-registry/OperatorFilterer.sol";

import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/security/Pausable.sol";
import "openzeppelin-contracts/security/ReentrancyGuard.sol";

contract GoldenGlove is Ownable, Pausable, ReentrancyGuard, ERC721AQueryable, OperatorFilterer {
    /*//////////////////////////////////////////////////////////////
                            SUPPLY CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Maximum number of mintable GoldenGlove.
    uint256 public constant MAX_SUPPLY = 3333;

    /// @notice Maximum number of mintable GoldenGlove per wallet.
    uint256 public constant MAX_MINT_PER_WALLET = 10;

    /*//////////////////////////////////////////////////////////////
                            STANDARD STATE
    //////////////////////////////////////////////////////////////*/

    string private _baseTokenURI;

    uint256 public mintPrice = 0.003 ether;

    mapping(address => bool) public filteredAddress;

    modifier onlyEOA() {
        require(msg.sender == tx.origin, "GLOVE: Only EOA wallets can mint");
        _;
    }

    constructor()
        ERC721A("GoldenGlove", "GLOVE")
        OperatorFilterer(address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6), true)
    {
        filteredAddress[0x00000000000111AbE46ff893f3B2fdF1F759a8A8] = true;
        filteredAddress[0xF849de01B080aDC3A814FaBE1E2087475cF2E354] = true;
        filteredAddress[0xf42aa99F011A1fA7CDA90E5E98b277E306BcA83e] = true;
    }

    function mint(uint256 _nums) external payable onlyEOA nonReentrant {
        require(_totalMinted() + _nums <= MAX_SUPPLY, "GLOVE: Over max supply");
        require(_numberMinted(msg.sender) + _nums <= MAX_MINT_PER_WALLET, "GLOVE: Over max mint per wallet");

        if (_numberMinted(msg.sender) == 0) {
            require(msg.value >= (_nums - 1) * mintPrice, "GLOVE: Insufficient ETH");
        } else {
            require(msg.value >= _nums * mintPrice, "GLOVE: Insufficient ETH");
        }

        _mint(msg.sender, _nums);
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setFilteredAddress(address _address, bool _isFiltered) external onlyOwner {
        filteredAddress[_address] = _isFiltered;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override (ERC721A, IERC721A)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override (ERC721A, IERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override (ERC721A, IERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function approve(address to, uint256 tokenId) public payable override (ERC721A, IERC721A) {
        require(!filteredAddress[to], "Not allowed to approve to this address");
        super.approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public override (ERC721A, IERC721A) {
        require(!filteredAddress[operator], "Not allowed to approval this address");
        super.setApprovalForAll(operator, approved);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override (ERC721A, IERC721A) returns (bool) {
        return ERC721A.supportsInterface(interfaceId);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function numberMinted(address _address) external view returns (uint256) {
        return _numberMinted(_address);
    }
}