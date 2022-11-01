//SPDX-License-Identifier: MIT
//author: Evabase core team
pragma solidity 0.8.16;

import "./interfaces/IOriConfig.sol";
import "./interfaces/IDerivativeToken.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./lib/ConsiderationStructs.sol";
import "./lib/ConsiderationEnums.sol";
import "./lib/ConfigHelper.sol";
import "./lib/ConsiderationConstants.sol";
import "./interfaces/IMintFeeSettler.sol";
import "./interfaces/OriErrors.sol";
import "./lib/NFTCreator.sol";
import "./lib/NFTMetadataURI.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

/**
 * @title NFT Derivative token
 * @author ace
 * @notice NFT Derivative token protocol.
 */
contract Derivative721Token is ERC721Upgradeable, NFTCreator, IDerivativeToken {
    using ConfigHelper for IOriConfig;

    //Start from one, create a new one, automatically add one
    uint256 public nonce;

    mapping(uint256 => NFT[]) private _derivativeLicenses;

    function initialize(
        address creator_,
        address originNft_,
        string memory name_,
        string memory symbol_
    ) external override initializer {
        nonce = 1;
        __ERC721_init(name_, symbol_);
        _initNFT(originNft_, creator_);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721Upgradeable, NFTMetadataURI) returns (string memory) {
        return NFTMetadataURI.tokenURI(tokenId);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        if (from == address(0) || to == address(0)) {
            return;
        }
        address house = IOriConfig(CONFIG).settlementHouse();
        if (house != address(0)) {
            IMintFeeSettler(house).afterTokenTransfer(_msgSender(), from, to, tokenId);
        }
    }

    /**
     * @notice return the derivative meta data.
     *
     * Requirements:
     *
     * - `id` must be exist.
     * @param id is the token id.
     * @return DerivativeMeta:
     *
     */
    function meta(uint256 id) public view override returns (DerivativeMeta memory) {
        require(id < nonce && id > 0, "invalid id");
        return DerivativeMeta({licenses: _derivativeLicenses[id], supplyLimit: 1, totalSupply: 1});
    }

    /**
     * @notice return the license meta data.
     *
     * Requirements:
     *
     * - `id` must be exist.
     * @param ids is the token ids.
     * @return derivativeMetas
     *
     */
    function metas(uint256[] memory ids) external view override returns (DerivativeMeta[] memory derivativeMetas) {
        derivativeMetas = new DerivativeMeta[](ids.length);
        for (uint256 i = 0; i < ids.length; ++i) {
            derivativeMetas[i] = meta(ids[i]);
        }
    }

    /**
     * @notice Creates `amount` tokens of token type `id`, and assigns them to `to`.
     * @param derivativeMeta is the token meta information.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function create(
        address to,
        bytes calldata derivativeMeta,
        uint256 amount
    ) external override onlyOperator {
        _create(to, derivativeMeta, amount);
    }

    function _create(
        address to,
        bytes calldata derivativeMeta,
        uint256 amount
    ) internal {
        require(to != address(0), "addess is 0x");
        (NFT[] memory licenses, uint256 supplyLimit, ) = abi.decode(derivativeMeta, (NFT[], uint256, uint256));
        require(supplyLimit == 1, "supply == 1");
        require(amount == 1, "amount == 1");
        uint256 _nonce = nonce;
        nonce++;
        for (uint256 i = 0; i < licenses.length; i++) {
            _derivativeLicenses[_nonce].push(licenses[i]);
        }
        _mint(to, _nonce);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function burn(
        address from,
        uint256 id,
        uint256
    ) external override onlyOperator {
        require(ownerOf(id) == from, "owner invalid");
        _burn(id);
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *  Not Support
     *
     */
    function mint(
        address,
        uint256,
        uint256
    ) external pure override {
        revert notSupportFunctionError();
    }
}