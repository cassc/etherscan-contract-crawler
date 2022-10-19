//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "../interfaces/IAttribute.sol";

import "../libraries/AttributeLib.sol";
import "../libraries/StringsLib.sol";

enum TokenType {
    ERC721,
    ERC1155
}

struct AttributeMutationPoolContract {
    TokenType tokenType;
    address tokenAddress;
    string _attributeKey;
    uint256 _attributeValuePerPeriod;
    uint256 _attributeBlocksPerPeriod;
    uint256 _totalValueThreshold;
    mapping(address => mapping(uint256 => uint256)) _tokenConvertedHeight;
    mapping(address => mapping(uint256 => uint256)) _tokenDepositHeight;
}

// attribute mutatiom pool storage
struct AttributeMutationPoolStorage {
    AttributeMutationPoolContract attributeMutationPool;
}

library AttributeMutationPoolLib {
    using AttributeLib for AttributeContract;

    bytes32 internal constant DIAMOND_STORAGE_POSITION =
        keccak256(
            "diamond.nextblock.bitgem.app.AttributeMutationPoolStorage.storage"
        );

    /// @notice get the attribute mutation pool storage
    /// @return ds the attribute mutation pool storage
    function attributeMutationPoolStorage()
        internal
        pure
        returns (AttributeMutationPoolStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    /// @notice set the attribute mutation pool settings
    /// @param attributeKey the attribute key
    /// @param updateValuePerPeriod the attribute value per period
    /// @param blocksPerPeriod the attribute blocks per period
    /// @param totalValueThreshold the total value threshold
    function _setAttributeMutationSettings(
        AttributeMutationPoolContract storage attributeMutationPool,
        string memory attributeKey,
        uint256 updateValuePerPeriod,
        uint256 blocksPerPeriod,
        uint256 totalValueThreshold
    ) internal {
        require(bytes(attributeKey).length > 0, "noempty");
        require(updateValuePerPeriod > 0, "zerovalue");
        attributeMutationPool._attributeKey = attributeKey;
        attributeMutationPool._attributeValuePerPeriod = updateValuePerPeriod;
        attributeMutationPool._attributeBlocksPerPeriod = blocksPerPeriod;
        attributeMutationPool._totalValueThreshold = totalValueThreshold;
    }

    /// @notice get the accrued value for a token
    /// @param attributeMutationPool the attribute mutation pool storage
    /// @param attributes attributes storage
    /// @param tokenId the token id
    /// @return _currentAccruedValue the accrued value
    function _getAccruedValue(
        AttributeMutationPoolContract storage attributeMutationPool,
        AttributeContract storage attributes,
        uint256 tokenId
    ) internal view returns (uint256 _currentAccruedValue) {
        // get the current accrued value for the token
        uint256 currentAccruedValue = StringsLib.parseInt(
            attributes
                ._getAttribute(tokenId, attributeMutationPool._attributeKey)
                .value
        );

        // get the block deposit height for the token
        uint256 depositBlockHeight = attributeMutationPool._tokenDepositHeight[msg.sender][
            tokenId
        ];
        require(
            depositBlockHeight > 0 && depositBlockHeight <= block.number,
            "notdeposited"
        );

        // calculate the current accrued value for the token
        uint256 blocksDeposited = block.number - depositBlockHeight;
        uint256 accruedValue = (blocksDeposited *
            attributeMutationPool._attributeValuePerPeriod) /
            attributeMutationPool._attributeBlocksPerPeriod;

        // add the accrued value to the current accrued value
        _currentAccruedValue = accruedValue + currentAccruedValue;
    }

    /// @notice require that the token owns the token id
    /// @param tokenType the token type
    /// @param tokenAddress the token address
    /// @param tokenId the token id
    function _requireCallerOwnsTokenId(
        address caller,
        TokenType tokenType,
        address tokenAddress,
        uint256 tokenId
    ) internal view {
        if (tokenType == TokenType.ERC721) {
            // require that the user have a quantity of the tokenId they specify
            require(
                IERC721(tokenAddress).ownerOf(tokenId) == caller,
                "needtoken"
            );
        } else if (tokenType == TokenType.ERC1155) {
            // require that the user have a quantity of the tokenId they specify
            require(
                IERC1155(tokenAddress).balanceOf(caller, tokenId) >= 1,
                "nofunds"
            );
        }
    }

    /// @notice transfer token being staked to contract
    /// @param tokenType the token type
    /// @param tokenAddress the token address
    /// @param tokenId the token id
    /// @param sender the sender
    function _transferStakedTokenToContract(
        TokenType tokenType,
        address tokenAddress,
        uint256 tokenId,
        address sender
    ) internal {
        if (tokenType == TokenType.ERC721) {
            // transfer the token to this contract
            IERC721(tokenAddress).transferFrom(sender, address(this), tokenId);
        } else if (tokenType == TokenType.ERC1155) {
            // transfer the token to this contract
            IERC1155(tokenAddress).safeTransferFrom(
                sender,
                address(this),
                tokenId,
                1,
                ""
            );
        }
    }

    /// @notice transfer token being staked to staker
    /// @param tokenType the token type
    /// @param tokenAddress the token address
    /// @param tokenId the token id
    /// @param staker the sender
    function _transferStakedTokenBackToStaker(
        TokenType tokenType,
        address tokenAddress,
        uint256 tokenId,
        address staker
    ) internal {
        if (tokenType == TokenType.ERC721) {
            // transfer the token to this contract
            IERC721(tokenAddress).transferFrom(address(this), staker, tokenId);
        } else if (tokenType == TokenType.ERC1155) {
            // transfer the token to this contract
            IERC1155(tokenAddress).safeTransferFrom(
                address(this),
                staker,
                tokenId,
                1,
                ""
            );
        }
    }

    /// @notice stake a token
    /// @param attributeMutationPool the attribute mutation pool storage
    /// @param attributeContract attributes storage
    /// @param tokenId the token id
    function _stake(
        AttributeMutationPoolContract storage attributeMutationPool,
        AttributeContract storage attributeContract,
        uint256 tokenId
    ) internal {
        uint256 currentAccruedValue = StringsLib.parseInt(
            attributeContract
                ._getAttribute(tokenId, attributeMutationPool._attributeKey)
                .value
        );

        // require that this be a valid token with the correct attribute set to at least 1
        require(currentAccruedValue > 0, "needvalue");

        // require that this token not be already deposited
        uint256 tdHeight = attributeMutationPool._tokenDepositHeight[
            msg.sender
        ][tokenId];
        require(tdHeight == 0, "alreadydeposited");

        _requireCallerOwnsTokenId(
            msg.sender,
            attributeMutationPool.tokenType,
            attributeMutationPool.tokenAddress,
            tokenId
        );

        _transferStakedTokenToContract(
            attributeMutationPool.tokenType,
            attributeMutationPool.tokenAddress,
            tokenId,
            msg.sender
        );

        // record the deposit in the variables to track it
        attributeMutationPool._tokenDepositHeight[msg.sender][tokenId] = block
            .number;
    }

    /// @notice unstake a token
    /// @param attributeMutationPool the attribute mutation pool storage
    /// @param attributeContract attributes storage
    /// @param tokenId the token id
    function _unstake(
        AttributeMutationPoolContract storage attributeMutationPool,
        AttributeContract storage attributeContract,
        uint256 tokenId
    ) public {
        // require that this token be owned by the caller
        _requireCallerOwnsTokenId(
            msg.sender,
            attributeMutationPool.tokenType,
            attributeMutationPool.tokenAddress,
            tokenId
        );

        // get the accrued valie of the token
        uint256 currentAccruedValue = AttributeMutationPoolLib._getAccruedValue(
            attributeMutationPool,
            attributeContract,
            tokenId
        );

        attributeMutationPool._tokenDepositHeight[msg.sender][tokenId] = 0;

        // set the attribute to the value, or the total value if value > total value
        uint256 val = currentAccruedValue >
            attributeMutationPool._totalValueThreshold
            ? attributeMutationPool._totalValueThreshold
            : currentAccruedValue;

        // set the attribute value to the accrued value
        attributeContract._setAttribute(
            tokenId,
            Attribute({
                key: attributeMutationPool._attributeKey,
                attributeType: AttributeType.String,
                value: Strings.toString(val)
            })
        );

        // send the token back to the user
        _transferStakedTokenBackToStaker(
            attributeMutationPool.tokenType,
            attributeMutationPool.tokenAddress,
            tokenId,
            msg.sender
        );
    }
}