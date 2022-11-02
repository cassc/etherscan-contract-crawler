//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

import "./interfaces/IGalaGameItems.sol";
import "./interfaces/IGalaERC20.sol";
import "./interfaces/IERC721GalaMintableBurnable.sol";

import "./TokenHolder.sol";
import "./Getters.sol";
import "./Setters.sol";

/// @title Bridge Out
/// @notice This contract allows to bridge tokens out from EVM blockchain to the Play blockchain.
/// @author Piotr "pibu" Buda
contract BridgeOut is Getters, Setters, TokenHolder {
    using SafeERC20 for IERC20;

    //this is the address of the old Gala contract that uses fungible tokens to represent game items
    address public constant FUNGIBLE_CONTRACT = 0xc36cF0cFcb5d905B8B513860dB0CFE63F6Cf9F5c;

    event BridgeTokens(bytes32 emitter, uint16 chainId, uint64 sequence, bytes32 nonce, bytes payload);

    /// @notice Interact with this method to start the bridging out process
    /// @param token the address of the token contract, must be non-zero
    /// @param amount the amount of tokens to bridge out, disregarded for ERC-721 tokens
    /// @param tokenId the id of the token to bridge out, disregarded for ERC-20 tokens
    /// @param recipient the recipient on the Play blockchain, formatted in a way understandable by it
    function bridgeOut(
        address token,
        uint256 amount,
        uint256 tokenId,
        bytes calldata recipient
    ) external whenNotPaused {
        require(token != address(0), "INVALID_TOKEN");
        require(recipient.length > 0, "INVALID_RECIPIENT");
        TokenType tokenType = getTokenType(token);

        if (tokenType == TokenType.ERC20) {
            //in case of ERC20 the tokenId parameter is disregarded
            bridgeOutERC20(token, amount, recipient);
        } else if (tokenType == TokenType.ERC721) {
            //in case of ERC721 the amount parameter is disregarded
            bridgeOutERC721(token, tokenId, recipient);
        } else if (tokenType == TokenType.ERC1155) {
            bridgeOutERC1155(token, tokenId, amount, recipient);
        } else {
            revert("UNKNOWN_TOKEN_TYPE");
        }
    }

    /// @notice Allows to bridge out ERC20 tokens. The tokens are first transferred to the bridge and if the burning flag
    /// is set to true, then the tokens are burnt.
    /// The caller needs to approve the bridge to allow it to transfer funds.
    /// @param token address of the ERC20 token
    /// @param amount the amount to be bridged out
    /// @param recipient the id of the recipient on the other side of the bridge
    function bridgeOutERC20(
        address token,
        uint256 amount,
        bytes calldata recipient
    ) private {
        require(amount != 0, "INVALID_AMOUNT");
        require(isEnabled(token, DEFAULT_TOKEN_BASE_TYPE), "DISABLED");

        publishBridgeOutMessage(token, DEFAULT_TOKEN_BASE_TYPE, amount, 0, recipient);

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        if (isBurningBridge(token, DEFAULT_TOKEN_BASE_TYPE)) {
            //this bridge assumes that all burnable ERC-20 assets will implement this burn method
            IGalaERC20(token).burn(amount);
        }
    }

    /// @notice Allows to bridge out ERC721 tokens. The tokens are first transferred to the bridge
    /// and then burnt if it is configured as burning.
    /// The caller needs to approve the bridge to allow it to transfer tokens.
    /// @param token address of the ERC721 token
    /// @param tokenId the id of the token to bridge
    /// @param recipient the id of the recipient on the other side of the bridge
    function bridgeOutERC721(
        address token,
        uint256 tokenId,
        bytes calldata recipient
    ) private {
        require(isEnabled(token, DEFAULT_TOKEN_BASE_TYPE), "DISABLED");

        publishBridgeOutMessage(token, DEFAULT_TOKEN_BASE_TYPE, 1, tokenId, recipient);

        IERC721GalaMintableBurnable(token).safeTransferFrom(msg.sender, address(this), tokenId);

        if (isBurningBridge(token, DEFAULT_TOKEN_BASE_TYPE)) {
            //this bridge assumes that all burnable ERC-721 assets will implement this burn method
            IERC721GalaMintableBurnable(token).burn(tokenId);
        }
    }

    /// @notice Allows to deposit ERC1155 tokens to the bridge.
    /// The caller needs to approve the bridge to allow it to transfer the token(s).
    /// @param token address of the ERC1155 token
    /// @param tokenId the id of the token to bridge
    /// @param amount the amount of the said token to be bridged
    /// @param recipient the id of the recipient on the other side of the bridge
    function bridgeOutERC1155(
        address token,
        uint256 tokenId,
        uint256 amount,
        bytes calldata recipient
    ) private {
        require(amount != 0, "INVALID_AMOUNT");

        uint256 baseType;
        uint256 instance;
        IGalaGameItems ggi = IGalaGameItems(token);
        if (ggi.isFungible(tokenId)) {
            //In case of a fungible token from the "old" ERC1155 contract 
            //which will be converted to a non-fungible token in Gyri and then "new" ERC1155 contract
            //bridge should only accept 1 token for conversion
            if (token == FUNGIBLE_CONTRACT) {
                require(amount == 1, "ONLY_1_FUNGIBLE_ALLOWED");
            }
            baseType = tokenId;
            instance = 0;
        } else {
            baseType = ggi.getNonFungibleBaseType(tokenId);
            instance = ggi.getNonFungibleIndex(tokenId);
        }

        require(isEnabled(token, baseType), "DISABLED");

        publishBridgeOutMessage(token, baseType, amount, instance, recipient);

        IERC1155(token).safeTransferFrom(msg.sender, address(this), tokenId, amount, "");

        if (isBurningBridge(token, baseType)) {
            uint256[] memory _ids = new uint256[](1);
            uint256[] memory _values = new uint256[](1);
            _ids[0] = tokenId;
            _values[0] = amount;
            //this bridge assumes that all burnable ERC-1155 assets will implement this burn method
            IGalaGameItems(token).burn(address(this), _ids, _values);
        }
    }

    /// @dev This method allows to publish an event in a specific format. Other parts of the bridge (i.e. the Validator nodes)
    /// can pick up this event and process it.
    function publishBridgeOutMessage(
        address token,
        uint256 baseType,
        uint256 amount,
        uint256 instance,
        bytes calldata recipient
    ) internal {
        bytes memory tokenClassKey = getTokenClassKey(token, baseType);
        Structs.BridgeToken memory payload = Structs.BridgeToken(tokenClassKey, hubChainId(), amount, instance, recipient);

        bytes32 emitter = bytes32(uint256(uint160(address(this))));
        uint64 msgSequence = useSequence();

        emit BridgeTokens(emitter, chainId(), msgSequence, keccak256(abi.encodePacked(emitter, chainId(), msgSequence)), abi.encode(payload));
    }
}