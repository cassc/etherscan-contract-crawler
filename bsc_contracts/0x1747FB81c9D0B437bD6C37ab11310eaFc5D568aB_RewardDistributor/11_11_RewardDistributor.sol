// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./interfaces/ICollection.sol";

contract RewardDistributor is Ownable {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 private constant MAX_TOP_HOLDERS_AMOUNT = 50;
    
    address public immutable bunniesBattleToken;
    address public collection;
    uint256 public topHoldersAmount = 50;

    EnumerableSet.AddressSet private _nftHolders;

    modifier onlyCollection {
        require(
            msg.sender == collection,
            "BBT: caller is not the NFT collection contract"
        );
        _;
    }

    constructor(address bunniesBattleToken_) {
        bunniesBattleToken = bunniesBattleToken_;
    }

    function setCollection(address collection_) external onlyOwner {
        require(
            collection_ != address(this) && collection_ != address(0),
            "BBT: invalid collection address"
        );
        collection = collection_;
    }

    function setTopHoldersAmount(uint256 topHoldersAmount_) external onlyOwner {
        require(
            topHoldersAmount_ <= MAX_TOP_HOLDERS_AMOUNT,
            "BBT: amount exceeds the maximum permissible value"
        );
        topHoldersAmount = topHoldersAmount_;
    }

    function distributeTokensBetweenHolders(address[] calldata accounts_) external onlyOwner {
        require(
            accounts_.length == topHoldersAmount,
            "BBT: invalid array length"
        );
        uint256 distributionAmount = IERC20(bunniesBattleToken).balanceOf(address(this));
        if (distributionAmount != 0) {
            uint256 amountToDistributeBetweenEachOfTopHolder = distributionAmount / (2 * topHoldersAmount);
            for (uint256 i = 0; i < accounts_.length; i++) {
                IERC20(bunniesBattleToken).safeTransfer(accounts_[i], amountToDistributeBetweenEachOfTopHolder);
            }
            uint256 amountToDistributeBetweenNftHolders = distributionAmount / 2;
            uint256 supply = ICollection(collection).totalSupply();
            for (uint256 i = 0; i < _nftHolders.length(); i++) {
                address holder = _nftHolders.at(i);
                uint256 share = 
                    amountToDistributeBetweenNftHolders 
                    * ICollection(collection).balanceOf(holder)
                    / supply;
                IERC20(bunniesBattleToken).safeTransfer(holder, share);
            }
        }
    }

    function addToNftHoldersList(address account_) external onlyCollection {
        require(
            _nftHolders.add(account_),
            "BBT: the account is already in the list of NFT holders"
        );
    }

    function removeFromNftHoldersList(address account_) external onlyCollection {
        require(
            _nftHolders.remove(account_),
            "BBT: the account is not in the list of NFT holders"
        );
    }

    function isNftHolder(address account_) external view returns (bool) {
        return _nftHolders.contains(account_);
    }

    function getNftHoldersLength() external view returns (uint256) {
        return _nftHolders.length();
    }

    function getNftHolderAt(uint256 index_) external view returns (address) {
        return _nftHolders.at(index_);
    }
}