// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {OwnableUpgradeable} from "@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {ERC721Upgradeable, IERC721Upgradeable, IERC165Upgradeable} from "@openzeppelin-upgradeable/contracts/token/ERC721/ERC721Upgradeable.sol";
import {ERC2981Upgradeable} from "@openzeppelin-upgradeable/contracts/token/common/ERC2981Upgradeable.sol";
import {StringsUpgradeable} from "@openzeppelin-upgradeable/contracts/utils/StringsUpgradeable.sol";
import {OperatorFilterer} from "@closedsea/OperatorFilterer.sol";
import {IToxicSkullsClub} from "./IToxicSkullsClub.sol";

/**
 * @title ToxicSkullsClub
 * @custom:website www.ToxicSkullsClub.com
 * @author Lozz (@lozzereth / www.allthingsweb3.com)
 * @notice Toxic Skulls Club implementation contract.
 */
contract ToxicSkullsClub is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    ERC721Upgradeable,
    ERC2981Upgradeable,
    IToxicSkullsClub,
    OperatorFilterer
{
    using StringsUpgradeable for uint256;

    /// @notice Maximum supply for the collection
    uint256 public constant MAX_SUPPLY = 9999;

    /// @notice Total supply
    uint256 private _totalMinted;

    /// @notice Base URI for the token
    string private _nftBaseURI;

    function initialize(string memory baseURI_) public initializer {
        __ERC721_init("Toxic Skulls Club", "TSC");
        __ERC2981_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        _setDefaultRoyalty(
            address(0x1ff63DF1077a40ec7A4f5a85a07eA7aC773EF368),
            750
        );
        _registerForOperatorFiltering();
        _nftBaseURI = baseURI_;
    }

    /**
     * @notice Airdrop NFTs to
     * @param owners Owners to airdrop to
     * @param tokenIds Token IDs to issue
     */
    function airdrop(
        address[] calldata owners,
        uint256[] calldata tokenIds
    ) external onlyOwner {
        uint256 inputSize = tokenIds.length;
        require(owners.length == inputSize);
        uint256 newTotalMinted = _totalMinted + inputSize;
        require(newTotalMinted <= MAX_SUPPLY);
        for (uint256 i; i < inputSize; ) {
            _mint(owners[i], tokenIds[i]);
            unchecked {
                ++i;
            }
        }
        _totalMinted = newTotalMinted;
    }

    /**
     * @notice Track the owned NFTs of an address
     * @dev Intended for off-chain computation having O(totalSupply) complexity
     * @param account Account to query
     * @return tokenIds
     */
    function tokensOfOwner(
        address account
    ) external view returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            uint256 tokenIdsLength = balanceOf(account);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            for (uint256 i; tokenIdsIdx != tokenIdsLength; ++i) {
                if (!_exists(i)) {
                    continue;
                }
                if (ownerOf(i) == account) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
    }

    /**
     * @notice Total supply of the collection
     * @return uint256 The total supply
     */
    function totalSupply() public view returns (uint256) {
        return _totalMinted;
    }

    /**
     * @inheritdoc ERC721Upgradeable
     */
    function isApprovedForAll(
        address owner,
        address operator
    )
        public
        view
        virtual
        override(ERC721Upgradeable, IERC721Upgradeable)
        returns (bool)
    {
        return super.isApprovedForAll(owner, operator);
    }

    /**
     * @inheritdoc ERC721Upgradeable
     */
    function setApprovalForAll(
        address operator,
        bool approved
    )
        public
        override(ERC721Upgradeable, IERC721Upgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @inheritdoc ERC721Upgradeable
     */
    function approve(
        address operator,
        uint256 tokenId
    )
        public
        override(ERC721Upgradeable, IERC721Upgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    /**
     * @inheritdoc ERC721Upgradeable
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        override(ERC721Upgradeable, IERC721Upgradeable)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @inheritdoc ERC721Upgradeable
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        override(ERC721Upgradeable, IERC721Upgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @inheritdoc ERC721Upgradeable
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    )
        public
        override(ERC721Upgradeable, IERC721Upgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @notice Set the Base URI
     * @param baseURI_ Base URI
     */
    function setBaseURI(string memory baseURI_) external onlyOwner {
        _nftBaseURI = baseURI_;
    }

    /**
     * @inheritdoc ERC721Upgradeable
     */
    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        _requireMinted(tokenId);
        return string(abi.encodePacked(_nftBaseURI, tokenId.toString()));
    }

    /**
     * @notice Sets the default royalty for the contract
     * @param receiver Receiving royalty address
     * @param feeNumerator Numerator of the fee (10000 = 100%)
     */
    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * @inheritdoc UUPSUpgradeable
     */
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    /**
     * @notice Return the implementation contract
     * @return address The implementation contract address
     */
    function getImplementation() external view returns (address) {
        return _getImplementation();
    }

    /**
     * @inheritdoc ERC721Upgradeable
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721Upgradeable, ERC2981Upgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}