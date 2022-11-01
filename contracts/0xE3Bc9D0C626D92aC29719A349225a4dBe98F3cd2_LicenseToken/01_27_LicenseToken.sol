//SPDX-License-Identifier: MIT
//author: Evabase core team
pragma solidity 0.8.16;
import "./lib/NFTCreator.sol";
import "./interfaces/IOriConfig.sol";
import "./interfaces/ITokenOperator.sol";
import "./interfaces/OriErrors.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./interfaces/ILicenseToken.sol";
import "./lib/ConsiderationStructs.sol";
import "./lib/ConsiderationEnums.sol";
import "./lib/ConsiderationConstants.sol";
import "./lib/NFTMetadataURI.sol";
import "./interfaces/IBatchAction.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";

/**
 * @title NFT License token
 * @author ace
 * @notice NFT License token protocol.
 */
contract LicenseToken is ERC1155Upgradeable, NFTCreator, ILicenseToken, IBatchAction {
    // using Address for address;
    mapping(bytes32 => bool) public existAuthNonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256("AtomicApproveForAll(address holder,address op,uint256 validAfter,uint256 validBefore,bytes32 salt)");

    //Start from one, create a new one, automatically add one
    uint256 public nonce;

    mapping(uint256 => LicenseMeta) private _licenseMetas;

    function uri(uint256 id) public view override(ERC1155Upgradeable, NFTMetadataURI) returns (string memory) {
        return NFTMetadataURI.uri(id);
    }

    function initialize(address creator_, address origin) external initializer {
        require(origin != address(0), "is zero");
        nonce = 1;
        // __ERC1155_init(""); // skip set URI
        _initNFT(origin, creator_);
    }

    function _beforeTokenTransfer(
        address op,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory,
        bytes memory
    ) internal view override {
        // must  mint by operator
        if (from == address(0)) {
            require(op == operator(), "should operator");
            return;
        }
        // can be burned by holder or operator.
        if (to == address(0)) {
            require(op == from || op == operator(), "should operator");
            return;
        }

        //disable transfer the expired licnese.
        for (uint256 i = 0; i < ids.length; i++) {
            // solhint-disable not-rely-on-time
            if (_licenseMetas[ids[i]].expiredAt <= block.timestamp) revert expiredError({id: ids[i]});
        }
    }

    /**
     * @notice return the license meta data.
     *
     * Requirements:
     *
     * - `id` must be exist.
     * @param id is the token id.
     * @return LicenseMeta:
     *
     *    uint256 originTokenId;
     *    uint16 earnPoint;
     *    uint64 expiredAt;
     */
    function meta(uint256 id) external view returns (LicenseMeta memory) {
        require(id < nonce && id > 0, "invalid id");
        return _licenseMetas[id];
    }

    /**
     * @notice return the license[] meta data.
     *
     * Requirements:
     *
     * - `id` must be exist.
     * @param ids is the token id.
     * @return licenseMetas
     *
     */
    function metas(uint256[] memory ids) external view returns (LicenseMeta[] memory licenseMetas) {
        licenseMetas = new LicenseMeta[](ids.length);
        for (uint256 i = 0; i < ids.length; ++i) {
            require(ids[i] < nonce && ids[i] > 0, "invalid id");
            licenseMetas[i] = _licenseMetas[ids[i]];
        }
    }

    /*
     * @notice return whether NFT has expired.
     *
     * Requirements:
     *
     * - `id` must be exist.
     *
     * @param id is the token id.
     * @return bool returns whether NFT has expired.
     */
    function expired(uint256 id) external view returns (bool isExpired) {
        require(id < nonce && id > 0, "invalid id");
        // solhint-disable not-rely-on-time
        isExpired = _licenseMetas[id].expiredAt < block.timestamp;
    }

    /**
     * @notice Creates `amount` tokens of token type `id`, and assigns them to `to`.
     * @param licenseMeta is the token meta information.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function create(
        address to,
        bytes calldata licenseMeta,
        uint256 amount
    ) external override onlyOperator {
        _create(to, licenseMeta, amount);
    }

    function _create(
        address to,
        bytes calldata licenseMeta,
        uint256 amount
    ) internal {
        require(to != address(0), "addess is 0x");
        if (amount == 0) revert amountIsZero();
        (uint256 originTokenId, uint16 earnPoint, uint64 expiredAt) = abi.decode(
            licenseMeta,
            (uint256, uint16, uint64)
        );

        require(expiredAt > block.timestamp, "invalid time");

        require(earnPoint >= 0 && earnPoint < 10000, "invalid earn");

        _licenseMetas[nonce].originTokenId = originTokenId;
        _licenseMetas[nonce].earnPoint = earnPoint;
        _licenseMetas[nonce].expiredAt = expiredAt;

        _mint(to, nonce, amount, "");
        nonce++;
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
        bytes[] calldata licenseMetas,
        uint256[] calldata amounts
    ) external {
        require(licenseMetas.length == amounts.length, "invalid length");
        _batchCreate(to, licenseMetas, amounts);
    }

    function _batchCreate(
        address to,
        bytes[] calldata licenseMetas,
        uint256[] calldata amounts
    ) internal {
        require(to != address(0), "addess is 0x");

        uint256[] memory ids = new uint256[](licenseMetas.length);
        uint256 originTokenId;
        uint16 earnPoint;
        uint64 expiredAt;
        for (uint256 i = 0; i < licenseMetas.length; i++) {
            ids[i] = nonce++;
            (originTokenId, earnPoint, expiredAt) = abi.decode(licenseMetas[i], (uint256, uint16, uint64));

            require(expiredAt > block.timestamp, "invalid time");
            require(earnPoint >= 0 && earnPoint < 10000, "invalid earn");
            _licenseMetas[ids[i]].originTokenId = originTokenId;
            _licenseMetas[ids[i]].earnPoint = earnPoint;
            _licenseMetas[ids[i]].expiredAt = expiredAt;
        }
        _mintBatch(to, ids, amounts, "");
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
    ) external override {
        // TODO: check power
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
    ) external {
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
    ) external override {
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
    ) external {
        _mintBatch(to, ids, amounts, "");
    }

    function approveForAllAuthorization(
        address holder,
        address op,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 salt,
        bytes memory signature
    ) external {
        require(block.timestamp < validBefore, "valid before");
        require(block.timestamp > validAfter, "valid after");
        require(msg.sender == op && op != holder, "only op");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, holder, op, validAfter, validBefore, salt));
        // TODO: test sign
        _useSign(holder, structHash, signature);
        _setApprovalForAll(holder, op, true);
    }
}