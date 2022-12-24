// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@1inch/solidity-utils/contracts/libraries/UniERC20.sol";
import "@1inch/solidity-utils/contracts/libraries/AddressSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IVotable.sol";

/// @title Contract with trades resolvers whitelist
contract WhitelistRegistry is Ownable {
    using UniERC20 for IERC20;
    using AddressSet for AddressSet.Data;
    using AddressArray for AddressArray.Data;

    error BalanceLessThanThreshold();
    error NotEnoughBalance();
    error AlreadyRegistered();
    error NotWhitelisted();

    event Registered(address addr);
    event Unregistered(address addr);
    event ResolverThresholdSet(uint256 resolverThreshold);
    event WhitelistLimitSet(uint256 whitelistLimit);
    event Promotion(address promoter, uint256 chainId, address promotee);

    IVotable public immutable token;

    mapping(address => mapping(uint256 => address)) public promotions;
    uint256 public resolverThreshold;
    uint256 public whitelistLimit;

    AddressSet.Data private _whitelist;

    constructor(
        IVotable token_,
        uint256 resolverThreshold_,
        uint256 whitelistLimit_
    ) {
        token = token_;
        _setResolverThreshold(resolverThreshold_);
        _setWhitelistLimit(whitelistLimit_);
    }

    function rescueFunds(IERC20 token_, uint256 amount) external onlyOwner {
        token_.uniTransfer(payable(msg.sender), amount);
    }

    function setResolverThreshold(uint256 resolverThreshold_) external onlyOwner {
        _setResolverThreshold(resolverThreshold_);
    }

    function setWhitelistLimit(uint256 whitelistLimit_) external onlyOwner {
        uint256 whitelistLength = _whitelist.length();
        if (whitelistLimit_ < whitelistLength) {
            _shrinkPoorest(_whitelist, whitelistLength - whitelistLimit_);
        }
        _setWhitelistLimit(whitelistLimit_);
    }

    function register() external {
        if (token.votingPowerOf(msg.sender) < resolverThreshold) revert BalanceLessThanThreshold();
        uint256 whitelistLength = _whitelist.length();
        if (whitelistLength == whitelistLimit) {
            address minResolver = msg.sender;
            uint256 minBalance = token.balanceOf(msg.sender);
            for (uint256 i = 0; i < whitelistLength; ++i) {
                address curWhitelisted = _whitelist.at(i);
                uint256 balance = token.balanceOf(curWhitelisted);
                if (balance < minBalance) {
                    minResolver = curWhitelisted;
                    minBalance = balance;
                }
            }
            if (minResolver == msg.sender) revert NotEnoughBalance();
            _removeFromWhitelist(minResolver);
        }
        if (!_whitelist.add(msg.sender)) revert AlreadyRegistered();
        emit Registered(msg.sender);
    }

    function promote(uint256 chainId, address promotee) external {
        promotions[msg.sender][chainId] = promotee;
        emit Promotion(msg.sender, chainId, promotee);
    }

    function clean() external {
        uint256 whitelistLength = _whitelist.length();
        unchecked {
            for (uint256 i = 0; i < whitelistLength; ) {
                address curWhitelisted = _whitelist.at(i);
                if (token.votingPowerOf(curWhitelisted) < resolverThreshold) {
                    _removeFromWhitelist(curWhitelisted);
                    whitelistLength--;
                } else {
                    i++;
                }
            }
        }
    }

    function getWhitelist() external view returns (address[] memory) {
        return _whitelist.items.get();
    }

    function getPromotees(uint256 chainId) external view returns (address[] memory promotees) {
        promotees = _whitelist.items.get();
        unchecked {
            uint256 len = promotees.length;
            for (uint256 i = 0; i < len; ++i) {
                promotees[i] = promotions[promotees[i]][chainId];
            }
        }
    }

    function _shrinkPoorest(AddressSet.Data storage set, uint256 size) private {
        uint256 richestIndex = 0;
        address[] memory addresses = set.items.get();
        uint256 addressesLength = addresses.length;
        uint256[] memory balances = new uint256[](addressesLength);
        for (uint256 i = 0; i < addressesLength; ++i) {
            balances[i] = token.balanceOf(addresses[i]);
            if (balances[i] > balances[richestIndex]) {
                richestIndex = i;
            }
        }

        for (uint256 i = size; i < addressesLength; ++i) {
            if (balances[i] <= balances[richestIndex]) {
                // Swap i-th and richest-th elements
                (addresses[i], addresses[richestIndex]) = (addresses[richestIndex], addresses[i]);
                (balances[i], balances[richestIndex]) = (balances[richestIndex], balances[i]);

                // Find new richest in first size elements
                richestIndex = 0;
                for (uint256 j = 1; j < size; ++j) {
                    if (balances[j] > balances[richestIndex]) {
                        richestIndex = j;
                    }
                }
            }
        }

        // Remove poorest elements from set
        for (uint256 i = 0; i < size; ++i) {
            _removeFromWhitelist(addresses[i]);
        }
    }

    function _setResolverThreshold(uint256 resolverThreshold_) private {
        resolverThreshold = resolverThreshold_;
        emit ResolverThresholdSet(resolverThreshold_);
    }

    function _setWhitelistLimit(uint256 whitelistLimit_) private {
        whitelistLimit = whitelistLimit_;
        emit WhitelistLimitSet(whitelistLimit_);
    }

    function _removeFromWhitelist(address account) private {
        _whitelist.remove(account);
        emit Unregistered(account);
    }
}