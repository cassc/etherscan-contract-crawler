// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.9;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "../base/ERC721MultiTokenStream.sol";

interface IERC721EqualSplitExtension {
    function hasERC721EqualSplitExtension() external view returns (bool);

    function setTotalTickets(uint256 newValue) external;
}

abstract contract ERC721EqualSplitExtension is
    IERC721EqualSplitExtension,
    Initializable,
    ERC165Storage,
    Ownable,
    ERC721MultiTokenStream
{
    // Total number of ERC721 tokens to calculate their equal split share
    uint256 public totalTickets;

    /* INTERNAL */

    function __ERC721EqualSplitExtension_init(uint256 _totalTickets)
        internal
        onlyInitializing
    {
        __ERC721EqualSplitExtension_init_unchained(_totalTickets);
    }

    function __ERC721EqualSplitExtension_init_unchained(uint256 _totalTickets)
        internal
        onlyInitializing
    {
        totalTickets = _totalTickets;

        _registerInterface(type(IERC721EqualSplitExtension).interfaceId);
    }

    /* ADMIN */

    function setTotalTickets(uint256 newValue) public onlyOwner {
        require(lockedUntilTimestamp < block.timestamp, "STREAM/CONFIG_LOCKED");
        totalTickets = newValue;
    }

    /* PUBLIC */

    function hasERC721EqualSplitExtension() external pure returns (bool) {
        return true;
    }

    /* INTERNAL */

    function _totalTokenReleasedAmount(
        uint256 totalReleasedAmount_,
        uint256 ticketTokenId_,
        address claimToken_
    ) internal view virtual override returns (uint256) {
        ticketTokenId_;
        claimToken_;

        return totalReleasedAmount_ / totalTickets;
    }
}