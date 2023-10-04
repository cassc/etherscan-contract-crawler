// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {DataTypesPeerToPeer} from "../../DataTypesPeerToPeer.sol";
import {Errors} from "../../../Errors.sol";
import {IWrappedERC721Impl} from "../../interfaces/wrappers/ERC721/IWrappedERC721Impl.sol";

contract WrappedERC721Impl is
    ERC20,
    Initializable,
    ReentrancyGuard,
    IWrappedERC721Impl
{
    string internal _tokenName;
    string internal _tokenSymbol;
    DataTypesPeerToPeer.WrappedERC721TokenInfo[] internal _wrappedTokens;
    address public lastRedeemer;
    mapping(address => mapping(uint256 => bool)) public stuckTokens;
    mapping(address => mapping(uint256 => bool)) public isTokenCountedInWrapper;
    mapping(address => mapping(uint256 => bool)) public isUnderlying;
    uint128[2] internal totalAndCurrentNumOfTokensInWrapper;

    constructor() ERC20("Wrapped ERC721 Impl", "Wrapped ERC721 Impl") {
        _disableInitializers();
    }

    function initialize(
        address minter,
        DataTypesPeerToPeer.WrappedERC721TokenInfo[] calldata wrappedTokens,
        string calldata _name,
        string calldata _symbol
    ) external initializer {
        uint128 numTokens;
        for (uint256 i; i < wrappedTokens.length; ) {
            _wrappedTokens.push(wrappedTokens[i]);
            for (uint256 j; j < wrappedTokens[i].tokenIds.length; ) {
                mapping(uint256 => bool) storage isTokenAddr = isUnderlying[
                    wrappedTokens[i].tokenAddr
                ];
                mapping(uint256 => bool)
                    storage isTokenIdInWrapper = isTokenCountedInWrapper[
                        wrappedTokens[i].tokenAddr
                    ];
                isTokenAddr[wrappedTokens[i].tokenIds[j]] = true;
                isTokenIdInWrapper[wrappedTokens[i].tokenIds[j]] = true;
                unchecked {
                    ++numTokens;
                    ++j;
                }
            }
            unchecked {
                ++i;
            }
        }
        _tokenName = _name;
        _tokenSymbol = _symbol;
        // @dev: packed storage layout to track total number of tokens and current number of tokens in wrapper
        // this is to prevent having to loop through all the tokens to get the total supply on remints with stuck tokens
        totalAndCurrentNumOfTokensInWrapper = [numTokens, numTokens];
        _mint(minter, 1);
    }

    function redeem(address account, address recipient) external nonReentrant {
        if (recipient == address(0)) {
            revert Errors.InvalidAddress();
        }
        if (msg.sender != account) {
            _spendAllowance(account, msg.sender, 1);
        }
        _burn(account, 1);
        lastRedeemer = account;
        address tokenAddr;
        uint256 tokenId;
        uint128 tokensRemoved;
        for (uint256 i; i < _wrappedTokens.length; ) {
            tokenAddr = _wrappedTokens[i].tokenAddr;
            for (uint256 j; j < _wrappedTokens[i].tokenIds.length; ) {
                tokenId = _wrappedTokens[i].tokenIds[j];
                try
                    IERC721(tokenAddr).safeTransferFrom(
                        address(this),
                        recipient,
                        tokenId
                    )
                {
                    ++tokensRemoved;
                    isTokenCountedInWrapper[tokenAddr][tokenId] = false;
                } catch {
                    stuckTokens[tokenAddr][tokenId] = true;
                    emit TransferFromWrappedTokenFailed(tokenAddr, tokenId);
                }
                unchecked {
                    ++j;
                }
            }
            unchecked {
                ++i;
            }
        }
        if (tokensRemoved == 0) {
            revert Errors.NoTokensTransferred();
        }
        unchecked {
            totalAndCurrentNumOfTokensInWrapper[1] -= tokensRemoved;
        }
        emit Redeemed(account, recipient);
    }

    function sweepTokensLeftAfterRedeem(
        address tokenAddr,
        uint256[] calldata tokenIds
    ) external nonReentrant {
        if (msg.sender != lastRedeemer) {
            revert Errors.InvalidSender();
        }
        if (tokenIds.length == 0) {
            revert Errors.InvalidArrayLength();
        }
        mapping(uint256 => bool) storage stuckTokenAddr = stuckTokens[
            tokenAddr
        ];
        mapping(uint256 => bool)
            storage isTokenIdInWrapper = isTokenCountedInWrapper[tokenAddr];
        uint128 tokensRemoved;
        for (uint256 i; i < tokenIds.length; ) {
            if (!stuckTokenAddr[tokenIds[i]]) {
                revert Errors.TokenNotStuck();
            }
            try
                IERC721(tokenAddr).safeTransferFrom(
                    address(this),
                    msg.sender,
                    tokenIds[i]
                )
            {
                delete stuckTokenAddr[tokenIds[i]];
                delete isTokenIdInWrapper[tokenIds[i]];
                ++tokensRemoved;
            } catch {
                emit TransferFromWrappedTokenFailed(tokenAddr, tokenIds[i]);
            }
            unchecked {
                ++i;
            }
        }
        if (tokensRemoved == 0) {
            revert Errors.NoTokensTransferred();
        }
        unchecked {
            totalAndCurrentNumOfTokensInWrapper[1] -= tokensRemoved;
        }
        emit TokenSweepAttempted(tokenAddr, tokenIds);
    }

    function remint(
        DataTypesPeerToPeer.WrappedERC721TokenInfo[]
            calldata _wrappedTokensForRemint,
        address recipient
    ) external nonReentrant {
        if (recipient == address(0)) {
            revert Errors.InvalidAddress();
        }
        if (totalSupply() != 0) {
            // @note: totalSupply can be zero yet there are still tokens in the wrapper due to being stuck
            revert Errors.CannotRemintUnlessZeroSupply();
        }
        // whoever remints must be able to transfer all the tokens to be reminted (all non-stuck tokens) back
        // to this contract. If even one transfer fails, then the remint fails.
        uint128 tokensNeeded = totalAndCurrentNumOfTokensInWrapper[0] -
            totalAndCurrentNumOfTokensInWrapper[1];
        totalAndCurrentNumOfTokensInWrapper[
            1
        ] = totalAndCurrentNumOfTokensInWrapper[0];
        if (tokensNeeded == 0 && msg.sender != lastRedeemer) {
            // @note: tokensNeeded = 0 is case where the wrapper through sync function has all tokens accounted for
            // in this special case, since no transfer is made, we allow only the lastRedeemer to remint to
            // avoid race conditions for anyone being able to remint. In cases where the wrapper has tokens
            // being transferred, then sender with that permission to transfer those tokens (owner or approved) can remint
            revert Errors.InvalidSender();
        }
        if (_wrappedTokensForRemint.length == 0 && tokensNeeded != 0) {
            revert Errors.InvalidArrayLength();
        }
        _mint(recipient, 1);
        uint128 tokensAdded = _wrappedTokensForRemint.length == 0
            ? 0
            : _transferTokens(_wrappedTokensForRemint);
        if (tokensAdded != tokensNeeded) {
            revert Errors.TokensStillMissingFromWrapper();
        }
    }

    function sync(address tokenAddr, uint256 tokenId) external nonReentrant {
        mapping(uint256 => bool)
            storage isTokenIdInWrapper = isTokenCountedInWrapper[tokenAddr];
        if (isTokenIdInWrapper[tokenId]) {
            revert Errors.TokenAlreadyCountedInWrapper();
        }
        if (!isUnderlying[tokenAddr][tokenId]) {
            revert Errors.TokenDoesNotBelongInWrapper(tokenAddr, tokenId);
        }
        isTokenIdInWrapper[tokenId] = true;
        unchecked {
            ++totalAndCurrentNumOfTokensInWrapper[1];
        }
        if (IERC721(tokenAddr).ownerOf(tokenId) != address(this)) {
            revert Errors.TokenNotOwnedByWrapper();
        }
    }

    function getWrappedTokensInfo()
        external
        view
        returns (DataTypesPeerToPeer.WrappedERC721TokenInfo[] memory)
    {
        return _wrappedTokens;
    }

    function getTotalAndCurrentNumOfTokensInWrapper()
        external
        view
        returns (uint128[2] memory)
    {
        return totalAndCurrentNumOfTokensInWrapper;
    }

    function name() public view virtual override returns (string memory) {
        return _tokenName;
    }

    function symbol() public view virtual override returns (string memory) {
        return _tokenSymbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 0;
    }

    // @dev: no need for ordering check here
    function _transferTokens(
        DataTypesPeerToPeer.WrappedERC721TokenInfo[] calldata tokensToBeWrapped
    ) internal returns (uint128 numTokensAdded) {
        uint256 checkedId;
        address currNftAddress;
        for (uint256 i; i < tokensToBeWrapped.length; ) {
            if (tokensToBeWrapped[i].tokenIds.length == 0) {
                revert Errors.InvalidArrayLength();
            }
            currNftAddress = tokensToBeWrapped[i].tokenAddr;
            for (uint256 j; j < tokensToBeWrapped[i].tokenIds.length; ) {
                checkedId = tokensToBeWrapped[i].tokenIds[j];
                if (!isUnderlying[currNftAddress][checkedId]) {
                    revert Errors.TokenDoesNotBelongInWrapper(
                        currNftAddress,
                        checkedId
                    );
                }
                try
                    IERC721(currNftAddress).transferFrom(
                        msg.sender,
                        address(this),
                        checkedId
                    )
                {
                    isTokenCountedInWrapper[currNftAddress][checkedId] = true;
                    unchecked {
                        ++numTokensAdded;
                        ++j;
                    }
                } catch {
                    revert Errors.TransferToWrappedTokenFailed();
                }
            }
            unchecked {
                ++i;
            }
        }
    }
}