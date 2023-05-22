// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.8.17;

import "@ERC721A/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {DefaultOperatorFilterer} from "operator-filter-registry/src/DefaultOperatorFilterer.sol";

interface ERC721Partial {
    function burn(uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external returns (address);
    function isApprovedForAll(address owner, address operator) external returns (bool);
}

contract Dreamcastle is ERC721A, ERC2981, DefaultOperatorFilterer, Ownable {
    using Strings for uint256;

    error CallerIsContractError();
    error ContractPausedError();
    error ExceedsMaxSupplyError();
    error BelowCurrentSupplyError();
    error CannotIncreaseSupplyError();
    error IncorrectDreamboxesError();
    error NotApprovedOperatorError();
    error NotOwnerError();

    ERC721Partial dreamboxContract;
    bool public paused;
    bool private _unique;
    uint256 public maxSupply = 333;
    string private _baseTokenURI;

    constructor() ERC721A("PLAY3 Dreamcastle", "PLAY3_DREAMCASTLE") {
        paused = true;
        _setDefaultRoyalty(address(0x3203617C22D58652Bbc12B2F6BD5566c365ea0d4), 1000);
    }

    modifier callerIsUser() {
        if (tx.origin != msg.sender) revert CallerIsContractError();
        _;
    }

    function flipPause() external onlyOwner {
        paused = !paused;
    }

    function setMaxSupply(uint256 _max) external onlyOwner {
        if (_max > maxSupply) revert CannotIncreaseSupplyError();
        if (_max < totalSupply()) revert BelowCurrentSupplyError();
        maxSupply = _max;
    }

    function setDreambox(address dreambox) external onlyOwner {
        dreamboxContract = ERC721Partial(dreambox);
    }

    function uniqueMetadata(bool arg) external onlyOwner {
        _unique = arg;
    }

    function buildDreamcastle(uint256[] calldata tokenIds) external callerIsUser {
        if (paused) revert ContractPausedError();
        if (_totalMinted() >= maxSupply) revert ExceedsMaxSupplyError();
        if (tokenIds.length != 3) revert IncorrectDreamboxesError();
        if (!dreamboxContract.isApprovedForAll(msg.sender, address(this))) revert NotApprovedOperatorError();
        for (uint256 index; index < tokenIds.length; index++) {
            if (msg.sender != dreamboxContract.ownerOf(tokenIds[index])) revert NotOwnerError();
        }

        for (uint256 index; index < tokenIds.length; index++) {
            dreamboxContract.burn(tokenIds[index]);
        }
        _mint(msg.sender, 1);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        if (_unique) {
            return
                string(
                    abi.encodePacked(
                        _baseURI(),
                        _toString(tokenId),
                        string(".json")
                    )
                );
        } else {
            return _baseURI();
        }
    }

    function numberMinted(address owner) external view returns (uint256) {
        return _numberMinted(owner);
    }

    function withdrawMoney() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
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
    ) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function setDefaultRoyalty(
        address payable receiver,
        uint96 numerator
    ) external onlyOwner {
        _setDefaultRoyalty(receiver, numerator);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }
}