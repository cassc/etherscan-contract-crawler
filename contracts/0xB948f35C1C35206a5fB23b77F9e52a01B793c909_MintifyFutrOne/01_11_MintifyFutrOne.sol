// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC721A} from "erc721a/contracts/ERC721A.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {BitMaps} from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import {OperatorFilterer} from "closedsea/src/OperatorFilterer.sol";

error InvalidSaleState();
error NotTokenOwner();
error TokenAlreadyClaimed();
error MaxSupplyReached();
error NotOnAllowlist();
error InvalidQuantity();
error CannotIncreaseSupply();

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract MintifyFutrOne is Ownable, OperatorFilterer, ERC2981, ERC721A {
    using BitMaps for BitMaps.BitMap;

    enum SaleStates {
        CLOSED,
        CLAIM,
        ALLOWLIST,
        PUBLIC
    }

    address public constant DEPLOYER = 0x2DCC7c4Ab800bF67380e2553BE1E6891A36F18E7;
    // TODO: make these constant before deployment
    IERC721 public LIFETIME_PASS = IERC721(0x6712545A0d1d8595D1045Ea18f2f386ffcA7CA90);
    IERC721 public LITE_PASS = IERC721(0x0eB82f969ff477AdC95F7f17Eb4099c6CBF14912);

    uint256 public maxSupply = 5000;
    uint256 public mintLimit = 5;

    SaleStates public saleState;
    BitMaps.BitMap private lifetimePassClaims;
    BitMaps.BitMap private litePassClaims;
    mapping(address => bool) public allowlist;

    bool public operatorFilteringEnabled = true;
    string public _baseTokenURI = "ipfs://QmaWXn2GzQuqVVFXzH8DQgZfYRoeUg2jCub3u2j2dB8BEJ/";

    constructor() ERC721A("Mintify FUTR One", "MNFUTRONE") {
        _registerForOperatorFiltering();

        // Set initial 5% royalty
        _setDefaultRoyalty(DEPLOYER, 500);
    }

    function claim(uint256 tokenId, bool isLifetime) external {
        if (saleState != SaleStates.CLAIM) revert InvalidSaleState();

        uint256 quantity;
        if (isLifetime) {
            if (LIFETIME_PASS.ownerOf(tokenId) != msg.sender) {
                revert NotTokenOwner();
            }
            if (lifetimePassClaims.get(tokenId)) {
                revert TokenAlreadyClaimed();
            }
            lifetimePassClaims.set(tokenId);
            quantity = 2;
        } else {
            if (LITE_PASS.ownerOf(tokenId) != msg.sender) {
                revert NotTokenOwner();
            }
            if (litePassClaims.get(tokenId)) {
                revert TokenAlreadyClaimed();
            }
            litePassClaims.set(tokenId);
            quantity = 1;
        }

        if (_totalMinted() + quantity > maxSupply) {
            revert MaxSupplyReached();
        }
        _mint(msg.sender, quantity);
    }


    function bulkClaim(uint256[] calldata lifeTimeIds, uint256[] calldata litePassIds) external {

        if (saleState != SaleStates.CLAIM) revert InvalidSaleState();
        uint256 quantity = 0;

        if (lifeTimeIds.length > 0) {
            for (uint256 i; i < lifeTimeIds.length;) {

                if (LIFETIME_PASS.ownerOf(lifeTimeIds[i]) == msg.sender && !lifetimePassClaims.get(lifeTimeIds[i])) {
                    quantity += 2;
                    lifetimePassClaims.set(lifeTimeIds[i]);
                }
                unchecked {
                    ++i;
                }

            }
        }
  
        if (litePassIds.length > 0) {
            for (uint256 i; i < litePassIds.length;) {

                if (LITE_PASS.ownerOf(litePassIds[i]) == msg.sender && !litePassClaims.get(litePassIds[i])) {
                    quantity += 1;
                    litePassClaims.set(litePassIds[i]);
                }
                unchecked {
                    ++i;
                }

            }
        }

        if (quantity < 1) {
            revert TokenAlreadyClaimed();
        }

        if (_totalMinted() + quantity > maxSupply) {
            revert MaxSupplyReached();
        }
        _mint(msg.sender, quantity);
        
    }

    function allowlistMint() external {
        if (saleState != SaleStates.ALLOWLIST) revert InvalidSaleState();
        if (!allowlist[msg.sender]) revert NotOnAllowlist();
        if (_totalMinted() + 1 > maxSupply) {
            revert MaxSupplyReached();
        }

        delete allowlist[msg.sender];
        _mint(msg.sender, 1);
    }

    function publicMint(uint256 quantity) external {
        if (saleState != SaleStates.PUBLIC) revert InvalidSaleState();
        if (quantity > mintLimit) revert InvalidQuantity();
        if (_totalMinted() + quantity > maxSupply) {
            revert MaxSupplyReached();
        }
        _mint(msg.sender, quantity);
    }

    // =========================================================================
    //                           Owner Only Functions
    // =========================================================================

    function ownerMint(address to, uint256 quantity) external onlyOwner {
        if (_totalMinted() + quantity > maxSupply) {
            revert MaxSupplyReached();
        }
        _mint(to, quantity);
    }

    function setSaleState(uint256 newSaleState) external onlyOwner {
        saleState = SaleStates(newSaleState);
    }

    function setMaxSupply(uint256 newSupply) external onlyOwner {
        if (newSupply >= maxSupply) revert CannotIncreaseSupply();
        maxSupply = newSupply;
    }

    function setMintLimit(uint256 newLimit) external onlyOwner {
        mintLimit = newLimit;
    }

    function setAllowlist(address[] calldata addresses) external onlyOwner {
        for (uint256 i; i < addresses.length;) {
            allowlist[addresses[i]] = true;
            unchecked {
                ++i;
            }
        }
    }

    function removeAllowlist(address[] calldata addresses) external onlyOwner {
        for (uint256 i; i < addresses.length;) {
            delete allowlist[addresses[i]];
            unchecked {
                ++i;
            }
        }
    }

    // =========================================================================
    //                             ERC721A Misc
    // =========================================================================

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    // =========================================================================
    //                           Operator filtering
    // =========================================================================

    function setApprovalForAll(address operator, bool approved)
        public
        override (ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override (ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override (ERC721A)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override (ERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override (ERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    // =========================================================================
    //                                  ERC165
    // =========================================================================

    function supportsInterface(bytes4 interfaceId) public view override (ERC721A, ERC2981) returns (bool) {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    // =========================================================================
    //                                 ERC2891
    // =========================================================================

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    // =========================================================================
    //                                 Metadata
    // =========================================================================

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json")) : "";
    }
}