// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import {UpdatableOperatorFilterer} from "operator-filter-registry/src/UpdatableOperatorFilterer.sol";
import {RevokableDefaultOperatorFilterer} from "operator-filter-registry/src/RevokableDefaultOperatorFilterer.sol";

contract Maschine is
    ERC721,
    ERC2981,
    Ownable,
    RevokableDefaultOperatorFilterer,
    Pausable
{
    uint16 public currentTokenId = 0;
    uint16 public tokenIdMax;
    string public baseURIValue;
    address public payoutAddress;
    address public minterContractAddress;

    uint96 public constant royaltyFee = 850; // 8.5%

    constructor(
        address _payoutAddress,
        address _minterContractAddress,
        uint16 _tokenIdMax,
        string memory _baseURIValue
    ) ERC721("Maschine", unicode"✇") {
        _setDefaultRoyalty(_payoutAddress, royaltyFee);
        payoutAddress = _payoutAddress;
        minterContractAddress = _minterContractAddress;
        tokenIdMax = _tokenIdMax;
        baseURIValue = _baseURIValue;
    }

    function owner()
        public
        view
        virtual
        override(Ownable, UpdatableOperatorFilterer)
        returns (address)
    {
        return Ownable.owner();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function pause() external onlyOwner {
        _pause();
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC2981, ERC721) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function endMint() external onlyOwner {
        tokenIdMax = currentTokenId;
    }

    function mint(address recipient) external whenNotPaused {
        require(
            msg.sender == minterContractAddress || msg.sender == owner(),
            "Only minter contract and owner can mint"
        );
        require(currentTokenId < tokenIdMax, "Max. supply reached");
        return _safeMint(recipient, ++currentTokenId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();

        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, Strings.toString(tokenId)))
                : "";
    }

    function setPayoutAddress(
        address payable newPayoutAddress
    ) external onlyOwner {
        require(address(0) != newPayoutAddress, "Invalid address");
        payoutAddress = newPayoutAddress;
        _setDefaultRoyalty(payoutAddress, royaltyFee);
    }

    function setMinterAddress(address newMinter) external onlyOwner {
        require(address(0) != newMinter, "Invalid address");
        minterContractAddress = newMinter;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURIValue;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURIValue = newBaseURI;
    }

    function totalSupply() public view returns (uint256) {
        return currentTokenId;
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
}