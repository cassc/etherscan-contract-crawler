// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import { IViewERC721_Functions } from "./interfaces/IViewERC721.sol";

import { IERC721OpenSea } from "./interfaces/IERC721OpenSea.sol";

// prettier-ignore
import {
    V721_BalanceCollection,
    V721_BalanceData,
    V721_ContractData,
    V721_ErrorData,
    V721_TokenCollection,
    V721_TokenData,
    IViewERC721_Events,
    IViewERC721_Functions
} from "./interfaces/IViewERC721.sol";

/// @title On-chain functions to collect contract data for off-chain callers
/// @author S0AndS0
/// @custom:link https://boredbox.io/
contract ViewERC721 is IViewERC721_Events, IViewERC721_Functions {
    /// Owner of this contract instance
    address public owner;

    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
    /* ↑            Storage          ↑ */
    /* ↓  Modifiers and constructor  ↓ */
    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

    /// Require message sender to be instance owner
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    //
    constructor(address owner_) {
        owner = owner_ == address(0) ? msg.sender : owner_;
    }

    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
    /* ↑  Modifiers and constructor  ↑ */
    /* ↓      mutations external     ↓ */
    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

    /// @dev See {IViewERC721_Functions-transferOwnership}
    function transferOwnership(address newOwner) external payable virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /// @dev See {IViewERC721_Functions-withdraw}
    function withdraw(address payable to, uint256 amount) external payable virtual onlyOwner {
        (bool success, ) = to.call{ value: amount }("");
        require(success, "Transfer failed");
    }

    /// @dev see (IViewERC721_Functions-tip)
    function tip() external payable virtual {}

    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
    /* ↑      mutations external     ↑ */
    /* ↓            public           ↓ */
    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

    /// @dev See {IViewERC721_Functions-getTokenData}
    function getTokenData(address ref, uint256 tokenId) public view returns (V721_TokenData memory) {
        V721_TokenData memory token_data;
        token_data.id = tokenId;

        try IERC721OpenSea(ref).ownerOf(tokenId) returns (address token_owner) {
            token_data.owner = token_owner;
        } catch Error(string memory reason) {
            token_data.errors = _appendErrorData(
                token_data.errors,
                V721_ErrorData({ called: "ownerOf", reason: reason })
            );
        } catch (bytes memory reason) {
            token_data.errors = _appendErrorData(
                token_data.errors,
                V721_ErrorData({ called: "ownerOf", reason: string(reason) })
            );
        }

        try IERC721OpenSea(ref).getApproved(tokenId) returns (address approved) {
            token_data.approved = approved;
        } catch Error(string memory reason) {
            token_data.errors = _appendErrorData(
                token_data.errors,
                V721_ErrorData({ called: "approved", reason: reason })
            );
        } catch (bytes memory reason) {
            token_data.errors = _appendErrorData(
                token_data.errors,
                V721_ErrorData({ called: "approved", reason: string(reason) })
            );
        }

        try IERC721OpenSea(ref).tokenURI(tokenId) returns (string memory uri) {
            token_data.uri = uri;
        } catch Error(string memory reason) {
            token_data.errors = _appendErrorData(
                token_data.errors,
                V721_ErrorData({ called: "tokenURI", reason: reason })
            );
        } catch (bytes memory reason) {
            token_data.errors = _appendErrorData(
                token_data.errors,
                V721_ErrorData({ called: "tokenURI", reason: string(reason) })
            );
        }

        return token_data;
    }

    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
    /* ↑            public           ↑ */
    /* ↓       internal mutations    ↓ */
    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

    /// @dev See {ViewERC721-transferOwnership}
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = owner;
        owner = newOwner;

        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
    /* ↑       internal mutations    ↑ */
    /* ↓       internal viewable     ↓ */
    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

    /// @dev Note this is a sub-optimal workaround for fixed sized memory arrays
    function _appendErrorData(V721_ErrorData[] memory target, V721_ErrorData memory entry)
        internal
        pure
        virtual
        returns (V721_ErrorData[] memory)
    {
        uint256 length = target.length;

        V721_ErrorData[] memory result = new V721_ErrorData[](length + 1);
        uint256 index;
        while (index < length) {
            result[index] = target[index];
            unchecked {
                ++index;
            }
        }

        result[index] = entry;

        return result;
    }

    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
    /* ↑       internal viewable     ↑ */
    /* ↓       external viewable     ↓ */
    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

    /// @dev See {IViewERC721_Functions-balancesOf}
    function balancesOf(address ref, address[] memory accounts) external view returns (V721_BalanceCollection memory) {
        uint256 length = accounts.length;
        V721_BalanceCollection memory account_balances;
        account_balances.ref = ref;
        account_balances.time.start = block.timestamp;
        account_balances.accounts = new V721_BalanceData[](length);

        V721_BalanceData memory balance_data;
        for (uint256 i; i < length; ) {
            address account = accounts[i];
            balance_data = account_balances.accounts[i];
            balance_data.owner = account;
            balance_data.balance = IERC721OpenSea(ref).balanceOf(account);
            unchecked {
                ++i;
            }
        }

        account_balances.time.stop = block.timestamp;
        return account_balances;
    }

    /// @dev See {IViewERC721_Functions-dataOfTokenIds}
    function dataOfTokenIds(address ref, uint256[] memory tokenIds)
        external
        view
        returns (V721_TokenCollection memory)
    {
        uint256 limit = tokenIds.length;

        V721_TokenCollection memory token_collection;
        token_collection.ref = ref;
        token_collection.length = limit;
        token_collection.time.start = block.timestamp;
        token_collection.tokens = new V721_TokenData[](limit);

        for (uint256 i; i < limit; ) {
            token_collection.tokens[i] = getTokenData(ref, tokenIds[i]);
            unchecked {
                ++i;
            }
        }

        token_collection.time.stop = block.timestamp;

        return token_collection;
    }

    /// @dev See {IViewERC721_Functions-paginateTokens}
    function paginateTokens(
        address ref,
        uint256 tokenId,
        uint256 limit
    ) external view returns (V721_TokenCollection memory) {
        V721_TokenCollection memory token_collection;
        token_collection.ref = ref;
        token_collection.length = ++limit;
        token_collection.time.start = block.timestamp;
        token_collection.tokens = new V721_TokenData[](limit);

        for (uint256 i; i < limit; ) {
            token_collection.tokens[i] = getTokenData(ref, tokenId);
            unchecked {
                ++i;
                ++tokenId;
            }
        }

        token_collection.time.stop = block.timestamp;

        return token_collection;
    }

    /// @dev See {IViewERC721_Functions-paginateTokensOwnedBy}
    function paginateTokensOwnedBy(
        address ref,
        address account,
        uint256 tokenId,
        uint256 limit
    ) external view returns (V721_TokenCollection memory) {
        V721_TokenCollection memory token_collection;
        token_collection.ref = ref;
        token_collection.time.start = block.timestamp;

        uint256 balance = IERC721OpenSea(ref).balanceOf(account);
        token_collection.tokens = new V721_TokenData[](balance);

        uint256 index;
        uint256 last__tokenId = tokenId + limit;
        V721_TokenData memory token_data;
        while (tokenId <= last__tokenId) {
            token_data = getTokenData(ref, tokenId);
            if (token_data.owner == account) {
                token_collection.tokens[index] = token_data;

                unchecked {
                    ++index;
                }
            }

            unchecked {
                ++tokenId;
            }
        }

        token_collection.length = index;
        token_collection.time.stop = block.timestamp;

        return token_collection;
    }

    /// @dev See {IViewERC721_Functions-getContractData}
    function getContractData(address ref) external view returns (V721_ContractData memory) {
        V721_ContractData memory contract_data;

        try IERC721OpenSea(ref).name() returns (string memory name) {
            contract_data.name = name;
        } catch Error(string memory reason) {
            contract_data.errors = _appendErrorData(
                contract_data.errors,
                V721_ErrorData({ called: "name", reason: reason })
            );
        } catch (bytes memory reason) {
            contract_data.errors = _appendErrorData(
                contract_data.errors,
                V721_ErrorData({ called: "name", reason: string(reason) })
            );
        }

        try IERC721OpenSea(ref).symbol() returns (string memory symbol) {
            contract_data.symbol = symbol;
        } catch Error(string memory reason) {
            contract_data.errors = _appendErrorData(
                contract_data.errors,
                V721_ErrorData({ called: "symbol", reason: reason })
            );
        } catch (bytes memory reason) {
            contract_data.errors = _appendErrorData(
                contract_data.errors,
                V721_ErrorData({ called: "symbol", reason: string(reason) })
            );
        }

        try IERC721OpenSea(ref).contractURI() returns (string memory uri) {
            contract_data.uri = uri;
        } catch Error(string memory reason) {
            contract_data.errors = _appendErrorData(
                contract_data.errors,
                V721_ErrorData({ called: "contractURI", reason: reason })
            );
        } catch (bytes memory reason) {
            contract_data.errors = _appendErrorData(
                contract_data.errors,
                V721_ErrorData({ called: "contractURI", reason: string(reason) })
            );
        }

        return contract_data;
    }
}