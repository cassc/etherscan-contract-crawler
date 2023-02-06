// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../Erc20/Ownable.sol";

contract Erc20C09FeatureLper is
Ownable
{
    using EnumerableSet for EnumerableSet.AddressSet;

    bool public isUseFeatureLper;
    uint256 public maxTransferCountPerTransactionForLper;
    uint256 public minimumTokenForRewardLper;
    mapping(address => bool) public isExcludedFromLperAddresses;

    uint256 internal lastIndexOfProcessedLperAddresses;
    EnumerableSet.AddressSet internal lperAddresses;

    //    function setLastIndexOfProcessedLperAddresses(uint256 lastIndexOfProcessedLperAddresses_)
    //    external
    //    onlyOwner
    //    {
    //        lastIndexOfProcessedLperAddresses = lastIndexOfProcessedLperAddresses_;
    //    }

    function setIsUseFeatureLper(bool isUseFeatureLper_)
    external
    onlyOwner
    {
        isUseFeatureLper = isUseFeatureLper_;
    }

    function setMaxTransferCountPerTransactionForLper(uint256 maxTransferCountPerTransactionForLper_)
    external
    onlyOwner
    {
        maxTransferCountPerTransactionForLper = maxTransferCountPerTransactionForLper_;
    }

    function setMinimumTokenForRewardLper(uint256 minimumTokenForRewardLper_)
    external
    onlyOwner
    {
        minimumTokenForRewardLper = minimumTokenForRewardLper_;
    }

    function setIsLperAddress(address account, bool isLperAddress_)
    external
    onlyOwner
    {
        if (isLperAddress_) {
            lperAddresses.add(account);
        } else {
            lperAddresses.remove(account);
        }
    }

    function batchSetIsLperAddresses(address[] memory accounts, bool isLperAddress_)
    external
    onlyOwner
    {
        uint256 length = accounts.length;

        if (isLperAddress_) {
            for (uint256 i = 0; i < length; i++) {
                lperAddresses.add(accounts[i]);
            }
        } else {
            for (uint256 i = 0; i < length; i++) {
                lperAddresses.remove(accounts[i]);
            }
        }
    }

    function isLperAddress(address account)
    external
    view
    returns (bool)
    {
        return lperAddresses.contains(account);
    }

    function getLperAddresses()
    external
    view
    returns (address[] memory)
    {
        return lperAddresses.values();
    }

    function setIsExcludedFromLperAddress(address account, bool isExcludedFromLperAddress)
    public
    onlyOwner
    {
        isExcludedFromLperAddresses[account] = isExcludedFromLperAddress;

        if (lperAddresses.contains(account)) {
            lperAddresses.remove(account);
        }
    }
}