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
import "./interfaces/IBatchAction.sol";
import "./lib/NFTCreator.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";

/**
 * @title NFT Derivative token
 * @author ace
 * @notice NFT Derivative token protocol.
 */
contract Derivative1155Token is ERC1155Upgradeable, NFTCreator, IDerivativeToken, IBatchAction {
    using ConfigHelper for IOriConfig;

    //Start from one, create a new one, automatically add one
    uint256 public nonce;

    mapping(uint256 => DerivativeMeta) private _derivativeMetas;

    function initialize(
        address creator_,
        address originNft_,
        string memory,
        string memory
    ) external override initializer {
        nonce = 1;
        _initNFT(originNft_, creator_);
    }

    function uri(uint256 id) public view override(ERC1155Upgradeable, NFTMetadataURI) returns (string memory) {
        return NFTMetadataURI.uri(id);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    // solhint-disable
    function _afterTokenTransfer(
        address op,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory
    ) internal override {
        for (uint256 i = 0; i < ids.length; i++) {
            if (to == address(0)) _derivativeMetas[ids[i]].totalSupply -= amounts[i];

            if (from == address(0)) {
                uint256 afterTotalSupply = _derivativeMetas[ids[i]].totalSupply + amounts[i];
                require(_derivativeMetas[ids[i]].supplyLimit >= afterTotalSupply, "Exceed maximum");
                _derivativeMetas[ids[i]].totalSupply = afterTotalSupply;
            }
        }

        if (ids.length > 0) {
            address hook = IOriConfig(CONFIG).settlementHouse();
            if (hook != address(0)) {
                IMintFeeSettler(hook).afterTokenTransfer(op, from, to, ids);
            }
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
    function meta(uint256 id) external view returns (DerivativeMeta memory) {
        require(id < nonce && id > 0, "invalid id");
        return _derivativeMetas[id];
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
    function metas(uint256[] memory ids) external view returns (DerivativeMeta[] memory derivativeMetas) {
        derivativeMetas = new DerivativeMeta[](ids.length);
        for (uint256 i = 0; i < ids.length; ++i) {
            require(ids[i] < nonce && ids[i] > 0, "invalid id");
            derivativeMetas[i] = _derivativeMetas[ids[i]];
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
    ) external onlyOperator {
        _create(to, derivativeMeta, amount);
    }

    function _create(
        address to,
        bytes calldata derivativeMeta,
        uint256 amount
    ) internal {
        require(to != address(0), "addess is 0x");
        (NFT[] memory licenses, uint256 supplyLimit, ) = abi.decode(derivativeMeta, (NFT[], uint256, uint256));
        require(supplyLimit > 1, "supply > 1");
        uint256 _nonce = nonce;
        for (uint256 i = 0; i < licenses.length; i++) {
            _derivativeMetas[_nonce].licenses.push(licenses[i]);
        }
        _derivativeMetas[_nonce].supplyLimit = supplyLimit;

        _mint(to, _nonce, amount, "");
        nonce++;
    }

    function _batchCreate(
        address to,
        bytes[] calldata derivativeMetas,
        uint256[] calldata amounts
    ) internal {
        require(to != address(0), "addess is 0x");
        uint256[] memory ids = new uint256[](derivativeMetas.length);

        for (uint256 i = 0; i < derivativeMetas.length; i++) {
            ids[i] = nonce++;
            (NFT[] memory licenses, uint256 supplyLimit, ) = abi.decode(derivativeMetas[i], (NFT[], uint256, uint256));
            require(supplyLimit > 1, "supply > 1");
            for (uint256 k = 0; k < licenses.length; k++) {
                _derivativeMetas[ids[i]].licenses.push(licenses[k]);
            }
            _derivativeMetas[ids[i]].supplyLimit = supplyLimit;
        }
        _mintBatch(to, ids, amounts, "");
    }

    /**
     * @dev batch-operations version of `create`.
     *
     * Requirements:
     *
     * - `metas` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function batchCreate(
        address to,
        bytes[] calldata derivativeMetas,
        uint256[] calldata amounts
    ) external onlyOperator {
        require(derivativeMetas.length == amounts.length, "invalid length");
        _batchCreate(to, derivativeMetas, amounts);
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
        uint256 amount
    ) external onlyOperator {
        _burn(from, id, amount);
    }

    /**
     * @dev batch-operations version of `burn`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     * - `ids` and `amounts` must have the same length.
     */
    function batchBurn(
        address from,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external onlyOperator {
        _burnBatch(from, ids, amounts);
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) external onlyOperator {
        _mint(to, id, amount, "");
    }

    /**
     * @dev batch-operations version of `mint`
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     * - `ids` and `amounts` must have the same length.
     */
    function batchMint(
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external onlyOperator {
        _mintBatch(to, ids, amounts, "");
    }
}