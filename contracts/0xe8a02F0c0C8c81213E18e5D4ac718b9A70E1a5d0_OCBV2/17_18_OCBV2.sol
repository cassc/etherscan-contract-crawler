// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {ERC2981Upgradeable} from "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {OperatorFilterer} from "./OperatorFilterer.sol";

error InvalidInput();
error NotOwnerOfToken();
error MaxSupplyReached();

/// @notice Updated OCB contract that includes marketplace filtering features.
/// @notice The original contract can be found at 0x132189D34365e92FE45A461E9f74259FE73176B9.
contract OCBV2 is OwnableUpgradeable, OperatorFilterer, ERC2981Upgradeable, ERC721Upgradeable {
    using Strings for uint256;

    uint256 public constant maxSupply = 888;
    address public constant oldContract = 0x132189D34365e92FE45A461E9f74259FE73176B9;

    uint256 public numberAirdropped;
    string public baseURI;
    bool public operatorFilteringEnabled;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address royaltyAddress) public initializer {

        // inits
        __ERC721_init("OnChain Buccaneers V2", "OCBV2");
        __ERC2981_init();
        __Ownable_init();

        // filterer
        _registerForOperatorFiltering();

        // royalties
        _setDefaultRoyalty(royaltyAddress, 1000);

        // defaults
        operatorFilteringEnabled = true;
        baseURI = "ipfs://QmUJtZxqHhrPfZmkKt4m5MSkompmUtC4h1BVoFDydNdUNw/";

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

        if (numberAirdropped + inputSize > maxSupply) {
            revert MaxSupplyReached();
        }

        for (uint256 i; i < inputSize;) {
            _mint(owners[i], tokenIds[i]);
            unchecked {
                ++i;
            }
        }
    }

    /// @dev Function to set the metadata uri.
    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
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

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override onlyAllowedOperator(from) {
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

    function supportsInterface(bytes4 interfaceId) public view virtual override (ERC2981Upgradeable, ERC721Upgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // =========================================================================
    //                              Upgradable stuff
    // =========================================================================

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

}