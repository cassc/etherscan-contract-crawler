// SPDX-License-Identifier: MIT

/*
                      _          _ _        _           _                  
  _ _ _____ _____ _ _(_)___   __| (_)___ __| |  _ _ ___| |__  ___ _ _ _ _  
 | '_/ -_) V / -_) '_| / -_) / _` | / -_) _` | | '_/ -_) '_ \/ _ \ '_| ' \ 
 |_| \___|\_/\___|_| |_\___| \__,_|_\___\__,_| |_| \___|_.__/\___/_| |_||_|
*/
pragma solidity ^0.8.13;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";

import "operator-filter-registry/src/OperatorFilterer.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract ReveriesByRem is
    Ownable,
    Pausable,
    ReentrancyGuard,
    ERC721AQueryable,
    OperatorFilterer
{
    /* ============ Constants ============= */
    uint256 public constant MAX_SUPPLY = 360;

    /* ============ State Variables ============ */
    // metadata URI
    string private _baseTokenURI;
    // mint price
    uint256 public mintPrice = 0.02 ether;
    // filter marketplaces
    mapping(address => bool) public filteredAddress;

    /* ============ Modifiers ============ */
    modifier onlyEOA() {
        require(msg.sender == tx.origin, "Only EOA wallets can mint");
        _;
    }

    /* ============ Constructor ============ */
    constructor()
        ERC721A("Reveries by rem", "RBYR")
        OperatorFilterer(
            address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6),
            true
        )
    {
        filteredAddress[0x00000000000111AbE46ff893f3B2fdF1F759a8A8] = true;
        filteredAddress[0xF849de01B080aDC3A814FaBE1E2087475cF2E354] = true;
        filteredAddress[0xf42aa99F011A1fA7CDA90E5E98b277E306BcA83e] = true;

        _pause();
    }

    function mint() external payable nonReentrant onlyEOA whenNotPaused {
        require(_numberMinted(msg.sender) == 0, "Over max mint per wallet");
        require(msg.value >= mintPrice, "Insufficient ETH");
        require(_totalMinted() + 1 <= MAX_SUPPLY, "Over max supply");

        _mint(msg.sender, 1);
    }

    function devMint() external onlyOwner {
        require(_numberMinted(owner()) == 0, "Over max dev mint");
        _mint(owner(), 1);
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setFilteredAddress(address _address, bool _isFiltered)
        external
        onlyOwner
    {
        filteredAddress[_address] = _isFiltered;
    }

    function setMintPrice(uint256 _newPrice) external onlyOwner {
        mintPrice = _newPrice;
    }

    function setPause() external onlyOwner {
        if (paused()) _unpause();
        else _pause();
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    /* ============ ERC721A ============ */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function approve(address to, uint256 tokenId)
        public
        payable
        override(ERC721A, IERC721A)
    {
        require(!filteredAddress[to], "Not allowed to approve to this address");
        super.approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721A, IERC721A)
    {
        require(
            !filteredAddress[operator],
            "Not allowed to approval this address"
        );
        super.setApprovalForAll(operator, approved);
    }

    /* ============ External Getter Functions ============ */

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, IERC721A)
        returns (bool)
    {
        return ERC721A.supportsInterface(interfaceId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
}