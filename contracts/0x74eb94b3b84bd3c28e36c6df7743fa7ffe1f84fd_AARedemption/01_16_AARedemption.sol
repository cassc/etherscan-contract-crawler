// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";

error ChunkAlreadyProcessed();
error MismatchedArrays();
error RedemptionNotLive();

contract AARedemption is ERC2981, ERC1155Pausable, ERC1155Burnable, Ownable {
    mapping(uint256 => bool) private _processedChunksForAirdrop;

    // Represents different types of tickets. The 1155 ids will be uint(ProductVariant.GOLD_PENDANT)
    enum ProductVariant {
        GOLD_PENDANT,
        SILVER_PENDANT,
        BLACK_HOODIE_XS,
        BLACK_HOODIE_S,
        BLACK_HOODIE_M,
        BLACK_HOODIE_L,
        BLACK_HOODIE_XL,
        BLACK_HOODIE_XXL,
        CLOUD_HOODIE_XS,
        CLOUD_HOODIE_S,
        CLOUD_HOODIE_M,
        CLOUD_HOODIE_L,
        CLOUD_HOODIE_XL,
        CLOUD_HOODIE_XXL
    }
    uint256 constant NUM_PRODUCT_VARIANTS = 14;
    bool public redemptionLive;

    mapping(address => mapping(ProductVariant => uint256)) public numRedeemed;

    string private _name = "Azuki Ambush Redemption";
    string private _symbol = "AAREDEMPTION";

    constructor() ERC1155("") {}

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function setNameAndSymbol(
        string calldata _newName,
        string calldata _newSymbol
    ) external onlyOwner {
        _name = _newName;
        _symbol = _newSymbol;
    }

    function airdrop(
        address[] calldata receivers,
        ProductVariant[] calldata productVariants,
        uint256 chunkNum
    ) external onlyOwner {
        if (receivers.length != productVariants.length || receivers.length == 0)
            revert MismatchedArrays();
        if (_processedChunksForAirdrop[chunkNum])
            revert ChunkAlreadyProcessed();
        for (uint256 i; i < receivers.length; ) {
            _mint(receivers[i], uint256(productVariants[i]), 1, "");
            unchecked {
                ++i;
            }
        }
        _processedChunksForAirdrop[chunkNum] = true;
    }

    function redeem(
        ProductVariant[] calldata productVariants,
        uint256[] calldata amounts
    ) external {
        if (!redemptionLive) {
            revert RedemptionNotLive();
        }

        for (uint256 i; i < productVariants.length; ) {
            ProductVariant productVariant = productVariants[i];
            uint256 productVariantTokenId = uint256(productVariant);
            uint256 amount = amounts[i];

            _burn(msg.sender, productVariantTokenId, amount);
            unchecked {
                numRedeemed[msg.sender][productVariant] += amount;
                ++i;
            }
        }
    }

    function setRedemptionLive(bool value) external onlyOwner {
        redemptionLive = value;
    }

    function getNumRedeemed(address addr)
        external
        view
        returns (uint256[NUM_PRODUCT_VARIANTS] memory)
    {
        uint256[NUM_PRODUCT_VARIANTS] memory result;

        for (uint256 i; i < NUM_PRODUCT_VARIANTS; ) {
            result[i] = numRedeemed[addr][ProductVariant(i)];
            unchecked {
                ++i;
            }
        }
        return result;
    }

    function getNumTokens(address addr)
        external
        view
        returns (uint256[NUM_PRODUCT_VARIANTS] memory)
    {
        uint256[NUM_PRODUCT_VARIANTS] memory result;

        for (uint256 i; i < NUM_PRODUCT_VARIANTS; ) {
            result[i] = balanceOf(addr, i);
            unchecked {
                ++i;
            }
        }
        return result;
    }

    function ownerMint(
        address to,
        uint256 amount,
        ProductVariant productVariant
    ) external onlyOwner {
        _mint(to, uint256(productVariant), amount, "");
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Pausable) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setTokenUri(string calldata newUri) external onlyOwner {
        _setURI(newUri);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}