// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Erc20C09FeatureHolder is
Ownable
{
    using EnumerableSet for EnumerableSet.AddressSet;

    bool public isUseFeatureHolder;
    uint256 public maxTransferCountPerTransactionForHolder;
    uint256 public minimumTokenForBeingHolder;
    mapping(address => bool) public isExcludedFromHolderAddresses;

    uint256 public lastIndexOfProcessedHolderAddresses;
    EnumerableSet.AddressSet internal holderAddresses;

    function setLastIndexOfProcessedHolderAddresses(uint256 lastIndexOfProcessedHolderAddresses_)
    external
    onlyOwner
    {
        lastIndexOfProcessedHolderAddresses = lastIndexOfProcessedHolderAddresses_;
    }

    function setIsUseFeatureHolder(bool isUseFeatureHolder_)
    external
    onlyOwner
    {
        isUseFeatureHolder = isUseFeatureHolder_;
    }

    function setMaxTransferCountPerTransactionForHolder(uint256 maxTransferCountPerTransactionForHolder_)
    external
    onlyOwner
    {
        maxTransferCountPerTransactionForHolder = maxTransferCountPerTransactionForHolder_;
    }

    function setMinimumTokenForBeingHolder(uint256 minimumTokenForBeingHolder_)
    external
    onlyOwner
    {
        minimumTokenForBeingHolder = minimumTokenForBeingHolder_;
    }

    function setIsHolderAddress(address account, bool isHolderAddress_)
    external
    onlyOwner
    {
        if (isHolderAddress_) {
            holderAddresses.add(account);
        } else {
            holderAddresses.remove(account);
        }
    }

    function isHolderAddress(address account)
    public
    view
    returns (bool)
    {
        return holderAddresses.contains(account);
    }

    function getHolderAddresses()
    public
    view
    returns (address[] memory)
    {
        return holderAddresses.values();
    }

    function setIsExcludedFromHolderAddress(address account, bool isExcluded)
    public
    onlyOwner
    {
        isExcludedFromHolderAddresses[account] = isExcluded;

        if (holderAddresses.contains(account)) {
            holderAddresses.remove(account);
        }
    }
}