//SPDX-License-Identifier: MIT
//author: Evabase core team
pragma solidity 0.8.16;
import "./interfaces/IOriConfig.sol";
import "./interfaces/ITokenOperator.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./interfaces/ILicenseToken.sol";
import "./interfaces/IDerivativeToken.sol";
import "./interfaces/IMintFeeSettler.sol";
import "./interfaces/IOriFactory.sol";
import "./interfaces/IApproveAuthorization.sol";
import "./lib/ConsiderationStructs.sol";
import "./lib/ConsiderationConstants.sol";
import "./lib/ConfigHelper.sol";
import "./lib/OriginMulticall.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "./interfaces/IBatchAction.sol";

/**
 * @title NFT Mint  Manager
 * @author ace
 * @notice Just work for Mint or Burn token.
 */
contract TokenOperator is ITokenOperator, IERC1155Receiver, OriginMulticall {
    using ConfigHelper for IOriConfig;
    IOriConfig internal constant _CONFIG = IOriConfig(CONFIG);

    /*
     * @dev Returns the mint fee settler address.
     * If no Mint fee is charged, return the zero address.
     */
    function settlementHouse() external view returns (address) {
        return _CONFIG.settlementHouse();
    }

    /*
     * @dev Returns the ori config address.
     */
    function config() external pure returns (address) {
        return address(_CONFIG);
    }

    function receiveApproveAuthorization(ApproveAuthorization[] calldata approves) external {
        for (uint256 i = 0; i < approves.length; i++) {
            address tokenAdd = approves[i].token;
            IApproveAuthorization(tokenAdd).approveForAllAuthorization(
                approves[i].from,
                approves[i].to,
                approves[i].validAfter,
                approves[i].validBefore,
                approves[i].salt,
                approves[i].signature
            );
        }
    }

    /**
     * @notice calcute the mint fee for license token.
     * @dev The default formula see `allowMint` function.
     *
     *  >    Fee (ETH) =  BaseFactor  * amount * (expiredAt - now)
     *
     * @param amount is the amount of minted.
     * @param expiredAt is the expiration tiem of the given license token `token`.`id`.
     */
    function calculateMintFee(uint256 amount, uint64 expiredAt) public view returns (uint256) {
        uint256 baseF = _CONFIG.mintFeeBP();
        // solhint-disable-next-line not-rely-on-time
        return ((baseF * amount * (expiredAt - block.timestamp)) / 1 days);
    }

    /**
     * @notice Deploy dtoken smart contract & Creates `amount` tokens of token, and assigns them to `msg.sender`.
     * @param meta is the token meta information.
     *
     * Requirements:
     *
     * - If `msg.sender` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function createDerivativeToNew(
        string memory dName,
        string memory dSymbol,
        uint256 amount,
        bytes calldata meta
    ) external {
        address dToken = _factory().deployDerivative721(dName, dSymbol);
        _createDerivative(ITokenActionable(dToken), amount, meta);
    }

    /**
     * @notice Creates `amount` tokens of token, and assigns them to `_msgsender()`.
     *
     * Requirements:
     *
     * - `token` must be enabled on ori protocol.
     * - If `_msgsender()` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function createDerivative(
        ITokenActionable dToken,
        uint256 amount,
        bytes calldata meta
    ) external {
        bool isLic = _factory().requireRegistration(address(dToken));
        if (isLic) revert invalidTokenType();

        _createDerivative(dToken, amount, meta);
    }

    function createLicense(
        address originToken,
        uint256 amount,
        bytes calldata meta
    ) external payable {
        IOriFactory factory = _factory();
        address license = factory.licenseToken(originToken);
        if (license == address(0)) {
            factory.createOrignPair(originToken);
            license = factory.licenseToken(originToken);
            if (license == address(0)) revert notFoundLicenseToken();
        }
        _createLicense(ITokenActionable(license), amount, meta);
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `_msgsender()`.
     *
     * Requirements:
     * - `token` must be enabled on ori protocol.
     * - If `_msgsender()` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function mint(
        ITokenActionable token,
        uint256 id,
        uint256 amount
    ) external payable {
        _mint(token, id, amount);
    }

    /**
     * @dev Destroys `amount` tokens of `token` type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `token` must be enabled on ori protocol.
     */
    function burn(
        ITokenActionable token,
        uint256 id,
        uint256 amount
    ) external {
        _factory().requireRegistration(address(token));
        token.burn(_msgsender(), id, amount);
    }

    function _mint(
        ITokenActionable token,
        uint256 id,
        uint256 amount
    ) internal {
        bool isLic = _factory().requireRegistration(address(token));
        address origin = token.originToken();
        if (isLic) {
            LicenseMeta memory lMeta = ILicenseToken(address(token)).meta(id);
            require(lMeta.earnPoint <= _CONFIG.maxEarnBP(), "over 10%");
            _handellicenseMintFee(amount, lMeta.expiredAt);
        } else {
            DerivativeMeta memory dmeta = IDerivativeToken(address(token)).meta(id);
            _useLicese(dmeta.licenses, origin);
        }

        token.mint(_msgsender(), id, amount);
        emit Mint(msg.sender, address(token), id, amount);
    }

    function _createLicense(
        ITokenActionable token,
        uint256 amount,
        bytes calldata meta
    ) internal {
        (uint256 originTokenId, uint256 earnPoint, uint64 expiredAt) = abi.decode(meta, (uint256, uint16, uint64));
        require(earnPoint <= _CONFIG.maxEarnBP(), "over 10%");
        //must have 721 origin NFT
        address origin = token.originToken();
        if (IERC165(origin).supportsInterface(ERC721_IDENTIFIER)) {
            require(IERC721(origin).ownerOf(originTokenId) == _msgsender(), "origin NFT721 is 0");
        } else if (IERC165(origin).supportsInterface(ERC1155_IDENTIFIER)) {
            require(
                IERC1155(origin).balanceOf(_msgsender(), originTokenId) > 0 && earnPoint == 0,
                "origin NFT1155=0 && earnPoint!=0"
            );
        } else {
            revert notSupportNftTypeError();
        }
        _handellicenseMintFee(amount, expiredAt);
        token.create(_msgsender(), meta, amount);
        emit Mint(msg.sender, address(token), token.nonce() - 1, amount);
    }

    function _createDerivative(
        ITokenActionable token,
        uint256 amount,
        bytes calldata meta
    ) internal {
        address origin = token.originToken();
        (NFT[] memory licenses, , ) = abi.decode(meta, (NFT[], uint256, uint256));
        _useLicese(licenses, origin);
        token.create(_msgsender(), meta, amount);
        emit Mint(msg.sender, address(token), token.nonce() - 1, amount);
    }

    //Note that when OToken is 0 address
    function _useLicese(NFT[] memory licenses, address origin) internal {
        require(licenses.length > 0, "invalid length");
        bool isHaveOrigin = origin == address(0);
        //use licese to create
        for (uint256 i = 0; i < licenses.length; i++) {
            IERC1155(licenses[i].token).safeTransferFrom(_msgsender(), address(this), licenses[i].id, 1, "");
            if (!isHaveOrigin) {
                isHaveOrigin = origin == ITokenActionable(licenses[i].token).originToken();
            }
        }

        require(isHaveOrigin, "need match license");
    }

    function _handellicenseMintFee(uint256 amount, uint64 expiredAt) internal {
        address feeTo = _CONFIG.mintFeeReceiver();
        if (feeTo == address(0)) {
            Address.sendValue(payable(msg.sender), msg.value);
        } else {
            uint256 totalFee = calculateMintFee(amount, expiredAt);
            require(msg.value >= totalFee, "invalid fee");
            Address.sendValue(payable(feeTo), totalFee);
            if (msg.value > totalFee) {
                Address.sendValue(payable(msg.sender), msg.value - totalFee);
            }
        }
    }

    function _factory() internal view returns (IOriFactory) {
        address factory = _CONFIG.oriFactory();
        require(factory != address(0), "factory is empty");
        return IOriFactory(factory);
    }

    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    //solhint-disable no-unused-vars
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC1155Receiver.onERC1155Received.selector;
    }

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    //solhint-disable no-unused-vars
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == ERC1155_TOKEN_RECEIVER_IDENTIFIER;
    }
}