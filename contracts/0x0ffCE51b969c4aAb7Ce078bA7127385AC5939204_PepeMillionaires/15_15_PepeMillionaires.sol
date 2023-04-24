// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IERC721A, ERC721A} from "erc721a/ERC721A.sol";
import {ERC721AQueryable} from "erc721a/extensions/ERC721AQueryable.sol";
import {ERC721ABurnable} from "erc721a/extensions/ERC721ABurnable.sol";
import {OperatorFilterer} from "closedsea/OperatorFilterer.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {IERC2981, ERC2981} from "openzeppelin-contracts/token/common/ERC2981.sol";

contract PepeMillionaires is
    ERC721AQueryable,
    ERC721ABurnable,
    OperatorFilterer,
    ERC2981
{
    bool public operatorFilteringEnabled;
    string private _baseUri;
    uint256 public maxSupply = 6969;
    bool private _isSaleActive = true;
    uint256 public mintPrice = 0.003 ether;
    IERC20 public constant pepeContract =
        IERC20(0x6982508145454Ce325dDbE47a25d4ec3d2311933);

    constructor(string memory baseUri) ERC721A("Pepe Millionaires", "PEPEMIL") {
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
        _setDefaultRoyalty(msg.sender, 420);
        _baseUri = baseUri;
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
    )
        public
        payable
        override(IERC721A, ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
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

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC721A, ERC721A, ERC2981) returns (bool) {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(
        address operator
    ) internal pure override returns (bool) {
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseUri;
    }

    modifier canMint(uint256 mintAmount) {
        require(_nextTokenId() + mintAmount <= maxSupply, "SOLD_OUT");
        require(mintAmount > 0, "INVALID_AMOUNT");
        _;
    }

    function mint(uint256 mintAmount) public payable canMint(mintAmount) {
        require(_isSaleActive, "SALE_NOT_ACTIVE");
        uint256 price = mintPrice * mintAmount;
        uint256 pepeBalance = pepeContract.balanceOf(msg.sender);
        if (pepeBalance >= 10000000 ether) {
            uint minted = _numberMinted(msg.sender);
            price = price - (mintPrice * 2) + (minted * mintPrice);
        }
        require(msg.value >= price, "INVALID_PRICE");
        _safeMint(msg.sender, mintAmount);
    }

    function airdrop(
        address to,
        uint256 mintAmount
    ) public canMint(mintAmount) onlyOwner {
        _safeMint(to, mintAmount);
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{
            value: address(this).balance,
            gas: 30000
        }(new bytes(0));
        require(success, "WITHDRAW_FAILED");
    }

    function setBaseUri(string memory baseUri) external onlyOwner {
        _baseUri = baseUri;
    }

    function toggleSale() external onlyOwner {
        _isSaleActive = !_isSaleActive;
    }

    function setMintPrice(uint256 price) external onlyOwner {
        mintPrice = price;
    }

    function lowerMaxSupply(uint256 supply) external onlyOwner {
        if (supply < maxSupply && supply >= _nextTokenId()) {
            maxSupply = supply;
        }
    }
}