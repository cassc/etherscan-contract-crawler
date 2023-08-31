//SPDX-License-Identifier: MIT

pragma solidity >=0.5.8 <0.9.0;

import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {ERC721Psi} from "./ERC721Psi.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {DefaultOperatorFilterer} from "./operator-filter-registry/src/DefaultOperatorFilterer.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract GojaFes is
    ERC721Psi,
    ERC2981,
    DefaultOperatorFilterer,
    Ownable,
    Pausable,
    ReentrancyGuard
{
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 110;
    uint256 public constant PRICE = 0.01 ether;

    bool public isRevealed;
    string private _revealedBaseURI;
    string private _unrevealedBaseURI;

    mapping(address => uint256) public claimed;

    event minted(
        address indexed sender,
        address indexed receiver,
        uint256 indexed quantity
    );

    constructor() ERC721Psi("GojaFes", "GT") {
        _setDefaultRoyalty(owner(), 1000);
        _pause();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        if (isRevealed) {
            return _revealedBaseURI;
        } else {
            return _unrevealedBaseURI;
        }
    }

    function tokenURI(
        uint256 _tokenId
    ) public view virtual override(ERC721Psi) returns (string memory) {
        return string(abi.encodePacked(ERC721Psi.tokenURI(_tokenId), ".json"));
    }

    function mint(
        address _receiver,
        uint256 _quantity
    ) external payable nonReentrant whenNotPaused {
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Max supply exceeded");
        require(msg.value == PRICE * _quantity, "Insufficient funds");
        claimed[_receiver] += _quantity;
        _safeMint(_receiver, _quantity);
        emit minted(_msgSender(), _receiver, _quantity);
    }

    function ownerMint(
        address _receiver,
        uint256 _quantity
    ) external onlyOwner {
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Max supply exceeded");
        _safeMint(_receiver, _quantity);
        emit minted(_msgSender(), _receiver, _quantity);
    }

    function setRevealedBaseURI(string calldata _uri) external onlyOwner {
        _revealedBaseURI = _uri;
    }

    function setUnrevealedBaseURI(string calldata _uri) external onlyOwner {
        _unrevealedBaseURI = _uri;
    }

    function reveal() external onlyOwner {
        isRevealed = true;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    struct ProjectMember {
        address founder;
        address marketplace;
    }
    ProjectMember private _member;

    function setMemberAddress(
        address _founder,
        address _marketplace
    ) external onlyOwner {
        _member.founder = _founder;
        _member.marketplace = _marketplace;
    }

    function withdraw() external onlyOwner {
        require(
            _member.founder != address(0) && _member.marketplace != address(0),
            "Please set member addresses"
        );

        uint256 balance = address(this).balance;
        Address.sendValue(payable(_member.founder), ((balance * 8000) / 10000));
        Address.sendValue(
            payable(_member.marketplace),
            ((balance * 2000) / 10000)
        );
    }

    // OperatorFilterer
    function setOperatorFilteringEnabled(bool _state) external onlyOwner {
        operatorFilteringEnabled = _state;
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

    // ERC2981
    function setRoyalty(
        address _royaltyAddress,
        uint96 _feeNumerator
    ) external onlyOwner {
        _setDefaultRoyalty(_royaltyAddress, _feeNumerator);
    }

    function supportsInterface(
        bytes4 _interfaceId
    ) public view virtual override(ERC721Psi, ERC2981) returns (bool) {
        return
            ERC721Psi.supportsInterface(_interfaceId) ||
            ERC2981.supportsInterface(_interfaceId);
    }
}