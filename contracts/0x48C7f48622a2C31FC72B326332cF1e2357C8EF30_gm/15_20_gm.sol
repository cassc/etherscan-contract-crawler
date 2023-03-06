// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

import "./IgmRenderer.sol";

contract gm is ERC721("say gm", "SAYGM"), IERC2981, Ownable, DefaultOperatorFilterer {

    using Counters for Counters.Counter;

    /* Constants */
    uint256 public constant MAX_SUPPLY = 5401; // TTY_MAGIC
    uint256 public constant ROYALTY_PERCENTAGE = 5;
    uint256 public constant WALLET_LIMIT = 5;
    uint256 public constant PRICE = 5000000000000000;
    
    /* Variables */
    Counters.Counter private _tokenIdCounter;
    bool public isSaleActive = false;
    mapping(address => uint8) public hasMintedCount;
    IgmRenderer public renderer;

    /* Errors */
    error LimitReachedForWallet();
    error IncorrectAmountForMint();
    error MaxSupplyReached();
    error NotEnoughAllowance(uint256 available, uint256 required);
    error SaleNotActive();
    error SendToAddressZero();
    error TokenDoesNotExist(uint256 id);
    error WithdrawSendFailed();

    constructor(IgmRenderer _renderer) {
        renderer = _renderer;
    }

    function mint(uint8 quantity) payable public {
        if (!isSaleActive) {
            revert SaleNotActive();
        }

        if (_tokenIdCounter.current()+quantity > MAX_SUPPLY) {
            revert MaxSupplyReached();
        }

        if (hasMintedCount[msg.sender] == WALLET_LIMIT || hasMintedCount[msg.sender]+quantity > WALLET_LIMIT) {
            revert LimitReachedForWallet();
        }

        if (msg.value != PRICE*quantity) {
            revert IncorrectAmountForMint();
        }

        hasMintedCount[msg.sender] += quantity;

        // set params in renderer
        for (uint8 i = 0; i < quantity; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            renderer.applyStyle(uint16(tokenId));
            renderer.addAddress(uint16(tokenId), msg.sender);
            _safeMint(msg.sender, tokenId);
        }
    }

    function currentCounterId() external view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function setSaleActive(bool _isSaleActive) public onlyOwner {
        isSaleActive = _isSaleActive;
    }

    function setRenderer(address rendererAddress) public onlyOwner {
        renderer = IgmRenderer(rendererAddress);
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        if (id > MAX_SUPPLY || _tokenIdCounter.current() < id) {
            revert TokenDoesNotExist(id);
        }
        
        return renderer.tokenUri(uint16(id));
    }

    /* ERC 2891 */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        if (!_exists(tokenId)) {
            revert TokenDoesNotExist(tokenId);
        }

        return (address(0x44B3D1Ea9732CaE53164D9D17c5b25c3644aa76D), SafeMath.div(SafeMath.mul(salePrice, ROYALTY_PERCENTAGE), 100));
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, IERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /* Operator Filter */
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        renderer.addAddress(uint16(tokenId), to);
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        renderer.addAddress(uint16(tokenId), to);
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        renderer.addAddress(uint16(tokenId), to);
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function withdraw(address to) public onlyOwner {
        if (to == address(0)) {
            revert SendToAddressZero();
        }

        uint256 amount = address(this).balance;

        (bool sent,) = payable(to).call{value: amount}("");
        if (!sent) {
            revert WithdrawSendFailed();
        }
        
    }
}