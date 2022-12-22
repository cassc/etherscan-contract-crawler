// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {OperatorFilterer} from "closedsea/OperatorFilterer.sol";

error InvalidInput();
error NotOwnerOfToken();
error MaxSupplyReached();

/// @notice Updated KPR contract that includes marketplace filtering features.
/// @notice The original contract can be found at 0x05da517B1bf9999B7762EaEfa8372341A1a47559.
contract KPRV2 is Ownable, OperatorFilterer, ERC2981, ERC721 {
    using Strings for uint256;

    // Values copied from the original contract
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant TOKEN_ID_SHIFT = 5022;
    string public constant PROVENANCE_HASH = "e0dad7bc28b31465903aee7b0fa3d2d1c6b28ec74f05de33ec682d85127428c4";
    string public baseURI = "https://metadata.kprverse.com/metadata/";

    address public constant KPR_MULTISIG = 0xF250d5584d682ba2F555197Bd26B58E83d7CA4C6;

    bool public operatorFilteringEnabled = true;
    uint256 public numberAirdropped;

    constructor() ERC721("Keepers V2", "KPRV2") {
        _registerForOperatorFiltering();

        // Set initial 5% royalty
        _setDefaultRoyalty(KPR_MULTISIG, 500);
    }

    // =========================================================================
    //                              Token Logic
    // =========================================================================

    /// @notice Owner-only function to airdrop tokens to users. The number of airdropped
    /// @notice tokens cannot exceed the original contract's supply.
    /// @dev OZ's ERC721 is used here so tokenIds can be easily minted to match up 1:1 with the old contract.
    function airdrop(address[] calldata owners, uint256[] calldata tokenIds) external onlyOwner {
        uint256 inputSize = tokenIds.length;
        if (owners.length != inputSize) {
            revert InvalidInput();
        }
        if (numberAirdropped + inputSize > MAX_SUPPLY) {
            revert MaxSupplyReached();
        }

        for (uint256 i; i < inputSize;) {
            _mint(owners[i], tokenIds[i]);
            unchecked {
                ++i;
            }
        }
        unchecked {
            numberAirdropped += inputSize;
        }
    }

    /// @dev Function to set the metadata uri.
    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    /// @dev The tokenURI logic here is copied 1:1 with the old contract to
    /// @dev keep the metadata the same for each tokenId.
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        uint256 shiftedTokenId = (_tokenId + TOKEN_ID_SHIFT) % MAX_SUPPLY;
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, shiftedTokenId.toString(), ".json")) : "";
    }

    // =========================================================================
    //                           Operator filtering
    // =========================================================================

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
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
    //                                 ERC2891
    // =========================================================================

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function deleteDefaultRoyalty() public onlyOwner {
        _deleteDefaultRoyalty();
    }

    // =========================================================================
    //                                  ERC165
    // =========================================================================

    function supportsInterface(bytes4 interfaceId) public view virtual override (ERC2981, ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}