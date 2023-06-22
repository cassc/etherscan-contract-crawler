// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {Owned} from "solmate/auth/Owned.sol";
import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";
import {IERC165} from "openzeppelin/utils/introspection/IERC165.sol";
import {IERC2981} from "openzeppelin/interfaces/IERC2981.sol";

error InvalidPayees();
error InvalidAccount();
error NoFundsAvailable();
error WithdrawalFailed();

struct Payee {
    address payable account;
    uint64 shares;
}

abstract contract Banker is IERC2981, Owned, ReentrancyGuard {
    uint256 constant TOTAL_SHARES = 10_000;
    address payable _teamAccount;
    uint64 _teamShares;
    address payable _devAccount;
    uint64 _devShares;
    address payable _royaltiesAccount;
    uint64 _royalties;

    constructor(
        Payee memory team,
        Payee memory dev,
        Payee memory royalties
    ) {
        if ((team.shares + dev.shares != TOTAL_SHARES) || royalties.shares > TOTAL_SHARES) {
            revert InvalidPayees();
        }

        _teamAccount = team.account;
        _teamShares = team.shares;
        _devAccount = dev.account;
        _devShares = dev.shares;
        _royaltiesAccount = royalties.account;
        _royalties = royalties.shares;
    }

    function withdraw() external nonReentrant {
        if (address(this).balance < 10_000) {
            revert NoFundsAvailable();
        }

        // Shares are verified in constructor to accumulate to 10_000,
        // the possibility of an overflow is unrealistic
        uint256 devFunds;
        uint256 teamFunds;
        unchecked {
            devFunds = (address(this).balance * _devShares) / TOTAL_SHARES;
            teamFunds = (address(this).balance * _teamShares) / TOTAL_SHARES;
        }

        /// Transfer the amount to the account
        (bool devSuccess, ) = _devAccount.call{value: devFunds}("");
        (bool teamSuccess, ) = _teamAccount.call{value: teamFunds}("");
        if (!devSuccess || !teamSuccess) revert WithdrawalFailed();
    }

    /// @inheritdoc IERC2981
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        virtual
        override
        returns (address, uint256)
    {
        return (_royaltiesAccount, (_salePrice * _royalties) / TOTAL_SHARES);
    }

    /// ADMIN

    function setDevAccount(address payable account) external onlyOwner {
        _devAccount = account;
    }

    function setTeamAccount(address payable account) external onlyOwner {
        _teamAccount = account;
    }

    function setRoyaltiesAccount(address payable account) external onlyOwner {
        _royaltiesAccount = account;
    }

    function setShares(uint64 team, uint64 dev) external onlyOwner {
        if (team + dev != TOTAL_SHARES) {
            revert InvalidPayees();
        }

        _teamShares = team;
        _devShares = dev;
    }

    function setRoyalties(uint64 royalties) external onlyOwner {
        if (royalties > TOTAL_SHARES) {
            revert InvalidPayees();
        }

        _royalties = royalties;
    }

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId || interfaceId == type(IERC165).interfaceId;
    }
}