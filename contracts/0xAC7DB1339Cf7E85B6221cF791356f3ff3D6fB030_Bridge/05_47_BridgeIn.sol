//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";

import "./interfaces/IGalaGameItems.sol";
import "./interfaces/IERC721GalaMintableBurnable.sol";
import "./interfaces/IGalaERC20.sol";

import "./Authority.sol";
import "./Setters.sol";

/// @title Bridge In
/// @notice Bridge in message handler allowing to process messages sent from the Play blockchain in order to mint and/or release tokens.
/// @author Piotr "pibu" Buda
contract BridgeIn is Authority, Setters {
    using SafeERC20 for IGalaERC20;

    event BridgedIn(address token, uint256 quantity, uint256 tokenId, address recipient);

    /// @notice The message handler responsible for bridging the tokens in.
    /// @param message the VSM sent from the Play blockchain with Structs.BridgeTokenIn as payload
    function bridgeIn(Structs.VSM calldata message) external {
        bytes32 messageHash = keccak256(abi.encodePacked(message.emitter, message.chainId, message.sequence, message.nonce, message.payload));
        (bool isValid, string memory reason) = verifyMessage(message, messageHash);
        require(isValid, reason);
        require(!isBridgeMessageUsed(messageHash), "BRIDGE_MESSAGE_USED");
        useBridgeMessage(messageHash);

        Structs.BridgeToken memory bt = abi.decode(message.payload, (Structs.BridgeToken));
        require(bt.destinationChainId == chainId(), "WRONG_CHAINID");
        require(bt.recipient.length == 20, "INVALID_RECIPIENT_LENGTH");

        address recipient = decodeRecipient(bt.recipient);

        (address token, uint256 baseType) = getTokenAndBaseType(bt.tokenClassKey);

        uint256 tokenId = 0;
        TokenType tokenType = getTokenType(token);
        if (tokenType == TokenType.ERC20) {
            bridgeInERC20(token, bt.quantity, recipient);
        } else if (tokenType == TokenType.ERC721) {
            tokenId = bt.instance;
            bridgeInERC721(token, tokenId, recipient);
        } else if (tokenType == TokenType.ERC1155) {
            tokenId = baseType | bt.instance;
            bridgeInERC1155(token, tokenId, bt.quantity, recipient);
        }

        emit BridgedIn(token, bt.quantity, tokenId, recipient);
    }

    function decodeRecipient(bytes memory encodedAddress) internal pure returns (address recipient) {
        assembly {
            recipient := mload(add(encodedAddress, 20))
        }
        require(recipient != address(0), "INVALID_RECIPIENT");
    }

    /// @notice Allows to bridge in ERC20 tokens.
    /// @dev When the bridge is a burning bridge, the tokens are minted to the bridge's account and only then released
    /// to the recipient. In case it's a locking bridge, the tokens are released directly. In case the bridge doesn't have enough
    /// balance, it can mint the missing amount to itself and then send the full amount.
    /// @param token address of the ERC20 token guaranteed to be a valid, non-zero address
    /// @param amount the amount of tokens to be bridged in
    /// @param recipient account to which the tokens should be minted guaranteed to be a valid, non-zero address
    function bridgeInERC20(
        address token,
        uint256 amount,
        address recipient
    ) private {
        require(amount != 0, "INVALID_AMOUNT");

        uint256 balance = IGalaERC20(token).balanceOf(address(this));

        //the tokens must be minted in two cases:
        // - the bridge works as a burning bridge
        // - the bridge doesn't have enough tokens while being a locking bridge
        //but both of these cases can be checked with the balance < amount condition
        //because if the bridge works as a burning bridge, balance will always be equal to zero
        if (balance < amount) {
            address[] memory accounts = new address[](1);
            uint256[] memory amounts = new uint256[](1);
            accounts[0] = address(this);
            amounts[0] = amount - balance;
            require(IGalaERC20(token).mintBulk(accounts, amounts), "MINT_FAILED");
        }

        IGalaERC20(token).safeTransfer(recipient, amount);
    }

    /// @notice Allows to bridge in ERC721 token.
    /// It reverts with TOKEN_EXISTS if the token with tokenId already exists.
    /// @dev The tokens are minted to the bridge's account (if bridge is a burning bridge) and then released to the recipient.
    /// @param token the address of the ERC721 token guaranteed to be a valid, non-zero address
    /// @param tokenId the id of the token to withdraw
    /// @param recipient the account to which the token should be minted guaranteed to be a valid, non-zero address
    function bridgeInERC721(
        address token,
        uint256 tokenId,
        address recipient
    ) private {
        try IERC721(token).ownerOf(tokenId) returns (address tokenOwner) {
            //the token exists, only proceed if the bridge owns it
            //this check is here because there is no other way to verify if the bridge holds the token
            //as the call to ownerOf will fail if the token doesn't exist (as would be the case for a burning bridge)
            require(tokenOwner == address(this), "TOKEN_NOT_OWNED");
        } catch {
            //this token doesn't exist, it has to be minted first
            //there are two kinds of ERC721 that this bridge aimed to support
            //they use different mint methods
            //here an attempt is made to mint tokens using one of them
            try IERC721GalaMintableBurnable(token).mint(address(this), tokenId) {
                //token minted using mint
            } catch {
                try IERC721GalaMintableBurnable(token).safeMint(address(this), tokenId) {
                    //token minted using safeMint
                } catch {
                    revert("UNKNOWN_ERC721_MINT");
                }
            }
        }

        IERC721GalaMintableBurnable(token).safeTransferFrom(address(this), recipient, tokenId);
    }

    /// @notice Allows to withdraw ERC1155 token to the recipient. Depending on the bridge mode the tokens are first minted to the bridge and then sent to the recipient's account.
    /// It reverts with TOKEN_EXISTS if the NFT with tokenId already exists.
    /// @param token address of the ERC1155 token guaranteed to be a valid, non-zero address
    /// @param tokenId the id of the token to withdraw
    /// @param amount the amount of fungible tokens to withdraw
    /// @param recipient account to which the tokens should be withdrawn guaranteed to be a valid, non-zero address
    function bridgeInERC1155(
        address token,
        uint256 tokenId,
        uint256 amount,
        address recipient
    ) private {
        require(amount != 0, "INVALID_AMOUNT");

        IGalaGameItems ggi = IGalaGameItems(token);
        bool isFungible = ggi.isFungible(tokenId);
        uint256 balance = ggi.balanceOf(address(this), tokenId);
        address[] memory _to = new address[](1);
        _to[0] = address(this);

        //this condition will be true for both cases of a burning and locking bridge
        //for burning bridge, balance will always be zero
        if (balance < amount) {
            if (isFungible) {
                uint256[] memory _quantities = new uint256[](1);
                _quantities[0] = amount - balance;
                ggi.mintFungible(tokenId, _to, _quantities, "");
            } else {
                //if the bridge is operating in locking mode and said nft is already owned
                //not by the bridge, then the minting of it will fail
                //however, if this happens, there must be some issue with token accounting
                //as in this case Play blockchain should never allow to bridge that token out
                uint256[] memory _ids = new uint256[](1);
                _ids[0] = tokenId;
                ggi.mintNonFungible(_ids, _to, "");
            }
        }

        ggi.safeTransferFrom(address(this), recipient, tokenId, amount, "");
    }
}