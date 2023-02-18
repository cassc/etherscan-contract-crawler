// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import { ERC721AQueryable, ERC721A, IERC721A } from "ERC721A/extensions/ERC721AQueryable.sol";
import { IERC721 } from "@openzeppelin/token/ERC721/IERC721.sol";
import { ERC2981 } from "@openzeppelin/token/common/ERC2981.sol";
import { Owned } from "solmate/auth/Owned.sol";
import { ReentrancyGuard } from "solmate/utils/ReentrancyGuard.sol";
import { OperatorFilterer } from "closedsea/OperatorFilterer.sol";


contract ONEBTCFP is ERC721AQueryable, ERC2981, Owned, ReentrancyGuard, OperatorFilterer {

    uint256 constant public maxSupply = 1000;
    uint256 public mintPrice = 0.07 ether;
    uint256 public maxPerTx = 10;
    bool public operatorFilteringEnabled;
    SaleState public saleState;
    address public phaseThreeContract;
    string public baseURI;

    struct SaleState {
        bool Public;
        bool Whitelist;
    }

    mapping(address => bool) public freeClaim;

    error SoldOut();
    error SaleNotActive();
    error ExceedsMaxPerTx();
    error MustBeGreaterThanZero();
    error IncorrectAmountOfETH();
    error NotEOA();
    error WithdrawFailed();
    error AlreadyClaimed();

    modifier SupplyCompliance(uint256 _amount) {
        if (totalSupply() + _amount > maxSupply) revert SoldOut();
        _;
    }

    modifier SenderCompliance() {
        if (tx.origin != msg.sender) revert NotEOA();
        _;
    }

    constructor(
        address _phaseThreeContract, 
        uint96 _royaltyFee, 
        string memory _uri
    ) ERC721A("1BTCFP", "1BTCFP") Owned(msg.sender) {
        _setDefaultRoyalty(msg.sender, _royaltyFee);
        _registerForOperatorFiltering();
        saleState.Public = false;
        saleState.Whitelist = false;
        operatorFilteringEnabled = true;
        phaseThreeContract = _phaseThreeContract;
        baseURI = _uri;
    }

    function claim() external SenderCompliance nonReentrant {
        uint256 balance = IERC721(phaseThreeContract).balanceOf(msg.sender);
        if (balance < 1) revert MustBeGreaterThanZero();
        if (totalSupply() + balance > maxSupply) revert SoldOut();
        if (freeClaim[msg.sender]) revert AlreadyClaimed();
        if (!saleState.Whitelist) revert SaleNotActive();
        _mint(msg.sender, balance);
        freeClaim[msg.sender] = true;
    }

    function mint(uint256 _amount) external payable SupplyCompliance(_amount) SenderCompliance nonReentrant {
        if (!saleState.Public) revert SaleNotActive();
        if (_amount > maxPerTx) revert ExceedsMaxPerTx();
        if (_amount <= 0) revert MustBeGreaterThanZero();
        if (msg.value != _amount * mintPrice) revert IncorrectAmountOfETH();

        _mint(msg.sender, _amount);
    }

    function teamMint(address _receiver,uint256 _amount) external onlyOwner SupplyCompliance(_amount) {
        _mint(_receiver, _amount);
    }

    function changeMintPrice(uint256 _amount) external onlyOwner {
        mintPrice = _amount;
    }

    function changeMaxPerTx(uint256 _amount) external onlyOwner {
        maxPerTx = _amount;
    }

    function changePhase3Contract(address _newAddress) external onlyOwner {
        phaseThreeContract = _newAddress;
    }

    function setOperatorFilteringEnabled(bool _value) public onlyOwner {
        operatorFilteringEnabled = _value;
    }

    function changeBaseURI(string calldata _uri) external onlyOwner {
        baseURI = _uri;
    }

    function editSaleState(bool _public, bool _whiteList) external onlyOwner {
        saleState.Public = _public;
        saleState.Whitelist = _whiteList;
    }

    function setRoyalties(address _receiver, uint96 _royaltyFee) external onlyOwner {
        _setDefaultRoyalty(_receiver, _royaltyFee);
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        if (!success) revert WithdrawFailed();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _operatorFilteringEnabled() internal view virtual override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function setApprovalForAll(
        address operator, 
        bool approved
    ) public override(IERC721A, ERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator, 
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }
    
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(bytes4 interfaceId) public view override(IERC721A, ERC721A, ERC2981) returns (bool) {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }
}