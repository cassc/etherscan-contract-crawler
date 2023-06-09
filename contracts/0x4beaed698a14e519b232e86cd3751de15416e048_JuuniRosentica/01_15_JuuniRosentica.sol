// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

//   _  _ _  _ _  _  _  _
//  | || | || | || \| || |
//  n_|||U || U || \\ || |
// \__/|___||___||_|\_||_|

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "closedsea/src/OperatorFilterer.sol";

abstract contract QuestReward {
    // QuestReward contract must implement this function
    // to is used for mint destination
    // zodiaTokenId is used for pulling zodia metadata
    function claimQuestReward(
        address to,
        uint256 zodiaTokenId
    ) external virtual;
}

contract JuuniRosentica is
    ERC721,
    ReentrancyGuard,
    Ownable,
    ERC2981,
    OperatorFilterer
{
    address public zodiaAddress;
    bool public operatorFilteringEnabled;

    string private _baseTokenURI;

    error InvalidMintSource();

    event QuestClaimed(uint256 tokenId, address owner);

    constructor() ERC721("JUUNI ROSENTICA", "JUUNIROSENTICA") {
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;

        // Set royalty receiver to the contract creator,
        // at 5% (default denominator is 10000).
        _setDefaultRoyalty(msg.sender, 500);
    }

    function claimQuestReward(
        address to,
        uint256 zodiaTokenId
    ) external nonReentrant {
        if (msg.sender != zodiaAddress) revert InvalidMintSource();

        _mint(to, zodiaTokenId);

        emit QuestClaimed(zodiaTokenId, to);
    }

    function setZodiaAddress(address newZodiaAddress) external onlyOwner {
        zodiaAddress = newZodiaAddress;
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        _baseTokenURI = baseURI_;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721, ERC2981) returns (bool) {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return
            ERC721.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function _isPriorityOperator(
        address operator
    ) internal pure override returns (bool) {
        // OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }
}