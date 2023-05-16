// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

/**
 * @title Rareboy - Medallion Contract
 * @author @SamOsci
 * @notice This contract handles the Rareboy - Medallion mint.
 */

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {ERC721ABurnable} from "erc721a/contracts/extensions/ERC721ABurnable.sol";
import {ERC721AQueryable} from "erc721a/contracts/extensions/ERC721AQueryable.sol";
import {ERC721A, IERC721A} from "erc721a/contracts/ERC721A.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

error InvalidAddressError();
error SaleNotActiveError();
error NotOnAllowlistError();
error MaxPerSaleReachedError();
error SoldOutError();
error WrongAmountError();
error TeamAlreadyMintedError();

enum SaleType {
    Allowlist,
    Public
}

enum MedallionTier {
    Gold,
    Red
}

contract Medallion is
    Ownable,
    ERC721A,
    ERC2981,
    ERC721ABurnable,
    ERC721AQueryable,
    DefaultOperatorFilterer
{
    struct MintCounts {
        uint8 gold;
        uint8 red;
    }

    uint8 public constant MAX_GOLD_PER_SALE = 2;
    uint8 public constant MAX_RED_PER_SALE = 2;

    bool public allowlistSaleIsActive = false;
    bool public publicSaleIsActive = false;
    bool public teamMinted = false;
    uint256 public startTokenId = 1;
    string public tokenBaseURI;
    uint256 public goldPrice;
    uint16 public goldSupply;
    uint16 public maxGoldSupply;
    uint256 public redPrice;
    uint16 public redSupply;
    uint16 public maxRedSupply;
    uint16 public maxTeamSupply;
    uint96 public royaltyFee;

    mapping(address => bool) public allowlist;
    mapping(address => MintCounts) public allowlistMintCounts;
    mapping(address => MintCounts) public publicMintCounts;
    mapping(uint256 => bool) public goldMedallions;

    constructor(
        string memory _tokenName,
        string memory _symbol,
        string memory _tokenBaseURI,
        uint96 _royaltyFee
    ) ERC721A(_tokenName, _symbol) {
        tokenBaseURI = _tokenBaseURI;
        _setDefaultRoyalty(msg.sender, _royaltyFee);
    }

    function contractURI() public view returns (string memory) {
        return string.concat(_baseURI(), "contract");
    }

    function _startTokenId() internal view override returns (uint256) {
        return startTokenId;
    }

    function _baseURI() internal view override returns (string memory) {
        return tokenBaseURI;
    }

    function _getTierConfigForSale(
        SaleType saleType,
        MedallionTier tier
    )
        private
        view
        returns (
            uint8 numOfTier,
            uint8 maxPerSale,
            uint16 supply,
            uint16 maxSupply,
            uint256 price
        )
    {
        MintCounts memory counts;

        if (saleType == SaleType.Allowlist) {
            counts = allowlistMintCounts[msg.sender];
        } else if (saleType == SaleType.Public) {
            counts = publicMintCounts[msg.sender];
        }

        if (tier == MedallionTier.Gold) {
            return (
                counts.gold,
                MAX_GOLD_PER_SALE,
                goldSupply,
                maxGoldSupply,
                goldPrice
            );
        } else if (tier == MedallionTier.Red) {
            return (
                counts.red,
                MAX_RED_PER_SALE,
                redSupply,
                maxRedSupply,
                redPrice
            );
        }
    }

    function _updateGoldMedallions(uint8 quantity) private {
        uint256 currentMaxId = totalSupply();
        for (uint8 i = 1; i <= quantity; i++) {
            uint256 _tokenId = currentMaxId + i;
            goldMedallions[_tokenId] = true;
        }
    }

    function _sharedMintRequirements(
        SaleType saleType,
        MedallionTier tier,
        uint8 quantity
    ) private {
        uint8 numOfTier;
        uint8 maxPerSale;
        uint16 supply;
        uint16 maxSupply;
        uint256 price;

        (
            numOfTier,
            maxPerSale,
            supply,
            maxSupply,
            price
        ) = _getTierConfigForSale(saleType, tier);

        if (quantity + numOfTier > maxPerSale) {
            revert MaxPerSaleReachedError();
        }
        if (quantity + supply > maxSupply) {
            revert SoldOutError();
        }
        if (msg.value != (price * quantity)) {
            revert WrongAmountError();
        }
    }

    function _updateTierCounts(
        SaleType saleType,
        MedallionTier tier,
        uint8 quantity
    ) private {
        if (tier == MedallionTier.Gold) {
            if (saleType == SaleType.Allowlist) {
                allowlistMintCounts[msg.sender].gold += quantity;
            } else if (saleType == SaleType.Public) {
                publicMintCounts[msg.sender].gold += quantity;
            }
            goldSupply += quantity;
            _updateGoldMedallions(quantity);
        } else if (tier == MedallionTier.Red) {
            if (saleType == SaleType.Allowlist) {
                allowlistMintCounts[msg.sender].red += quantity;
            } else if (saleType == SaleType.Public) {
                publicMintCounts[msg.sender].red += quantity;
            }
            redSupply += quantity;
        }
    }

    function allowlistMint(
        MedallionTier tier,
        uint8 quantity
    ) external payable {
        if (!allowlistSaleIsActive) {
            revert SaleNotActiveError();
        }
        if (!isOnAllowlist(msg.sender)) {
            revert NotOnAllowlistError();
        }

        _sharedMintRequirements(SaleType.Allowlist, tier, quantity);
        _updateTierCounts(SaleType.Allowlist, tier, quantity);

        _mint(msg.sender, quantity);
    }

    function publicMint(MedallionTier tier, uint8 quantity) external payable {
        if (!publicSaleIsActive) {
            revert SaleNotActiveError();
        }

        _sharedMintRequirements(SaleType.Public, tier, quantity);
        _updateTierCounts(SaleType.Public, tier, quantity);

        _mint(msg.sender, quantity);
    }

    function teamMint() external onlyOwner {
        if (teamMinted) {
            revert TeamAlreadyMintedError();
        }
        teamMinted = true;
        redSupply += maxTeamSupply;
        _mint(owner(), maxTeamSupply);
    }

    function isGoldMedallion(uint256 tokenId) public view returns (bool) {
        return goldMedallions[tokenId];
    }

    function getAllowlistMintCounts(
        address account
    ) public view returns (MintCounts memory counts) {
        return allowlistMintCounts[account];
    }

    function getPublicMintCounts(
        address account
    ) public view returns (MintCounts memory counts) {
        return publicMintCounts[account];
    }

    // Operator Filtering
    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    )
        public
        payable
        override(ERC721A, IERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

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

    // Owner
    function setSaleData(
        uint256 _goldPrice,
        uint256 _redPrice,
        uint16 _maxGoldSupply,
        uint16 _maxRedSupply,
        uint16 _maxTeamSupply
    ) public onlyOwner {
        goldPrice = _goldPrice;
        redPrice = _redPrice;
        maxGoldSupply = _maxGoldSupply;
        maxRedSupply = _maxRedSupply;
        maxTeamSupply = _maxTeamSupply;
    }

    function startAllowlistSale() external onlyOwner {
        allowlistSaleIsActive = true;
    }

    function pauseAllowlistSale() external onlyOwner {
        allowlistSaleIsActive = false;
    }

    function startPublicSale() external onlyOwner {
        publicSaleIsActive = true;
        allowlistSaleIsActive = false;
    }

    function pausePublicSale() external onlyOwner {
        publicSaleIsActive = false;
    }

    function setTokenBaseURI(string memory newTokenBaseURI) external onlyOwner {
        tokenBaseURI = newTokenBaseURI;
    }

    function addToAllowlist(address account) external onlyOwner {
        if (account == address(0)) {
            revert InvalidAddressError();
        }
        allowlist[account] = true;
    }

    function removeFromAllowlist(address account) external onlyOwner {
        if (account == address(0)) {
            revert InvalidAddressError();
        }
        allowlist[account] = false;
    }

    function isOnAllowlist(address account) public view returns (bool) {
        return allowlist[account];
    }

    function batchAddToAllowlist(address[] memory accounts) external onlyOwner {
        for (uint i = 0; i < accounts.length; i++) {
            if (accounts[i] == address(0)) {
                revert InvalidAddressError();
            }
            allowlist[accounts[i]] = true;
        }
    }

    function setDefaultRoyalty(
        address receiver,
        uint96 _royaltyFee
    ) external onlyOwner {
        _setDefaultRoyalty(receiver, _royaltyFee);
    }

    function withdraw() external payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    // Interfaces
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, IERC721A, ERC2981) returns (bool) {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }
}