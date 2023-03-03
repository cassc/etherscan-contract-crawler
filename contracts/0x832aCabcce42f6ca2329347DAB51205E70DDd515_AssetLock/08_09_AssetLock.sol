// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ISugarNFT.sol";

library IterableMapping {
    // Iterable mapping from address to uint;
    struct Map {
        address[] keys;
        mapping(address => uint256) values;
        mapping(address => uint256) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) public view returns (uint256) {
        return map.values[key];
    }

    function getIndexOfKey(Map storage map, address key)
        public
        view
        returns (int256)
    {
        if (!map.inserted[key]) {
            return -1;
        }
        return int256(map.indexOf[key]);
    }

    function getKeyAtIndex(Map storage map, uint256 index)
        public
        view
        returns (address)
    {
        return map.keys[index];
    }

    function size(Map storage map) public view returns (uint256) {
        return map.keys.length;
    }

    function set(
        Map storage map,
        address key,
        uint256 val
    ) public {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) public {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint256 index = map.indexOf[key];
        uint256 lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}

contract AssetLock is Ownable, Pausable, ReentrancyGuard {
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private assets;
    uint256 public lockTime;
    ISugarNFT public sugarNFT;
    bool public isWithdraw = true;

    mapping(uint256 => bool) private isNFTClaimed;

    event AssetDeposited(address asset, uint256 amount);

    constructor(address _sugarNFT) {
        sugarNFT = ISugarNFT(_sugarNFT);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function getAssetBalance(address _asset) external view returns (uint256) {
        require(isAssetApproved(_asset), "Not approved");
        return assets.get(_asset);
    }

    function setLockTime(uint256 timeInDay) external onlyOwner {
        require(lockTime == 0, "Lock time is already set");
        lockTime = block.timestamp + timeInDay * 10 minutes;
    }

    function setSugarNFT(address _sugarNFT) external onlyOwner {
        sugarNFT = ISugarNFT(_sugarNFT);
    }

    function approveAsset(address _asset) external onlyOwner {
        assets.set(_asset, 0);
    }

    function disapproveAsset(address _asset) external onlyOwner {
        if (assets.get(_asset) > 0) {
            bool success = IERC20(_asset).transfer(
                msg.sender,
                assets.get(_asset)
            );
            require(success, "Transfer Failed");
        }
        assets.remove(_asset);
    }

    function isAssetApproved(address _asset) public view returns (bool) {
        return assets.inserted[_asset];
    }

    function deposit(address _asset, uint256 _amount) external {
        require(isAssetApproved(_asset), "Asset is not approved");
        require(
            IERC20(_asset).balanceOf(msg.sender) >= _amount,
            "Insufficient Asset"
        );
        bool success = IERC20(_asset).transferFrom(
            msg.sender,
            address(this),
            _amount
        );
        require(success, "Transfer Failed");
        assets.set(_asset, assets.get(_asset) + _amount);

        emit AssetDeposited(_asset, _amount);
    }

    function _claim(uint256 shareAmount) internal {
        uint256 totalShare = sugarNFT.getTotalSupply();
        for (uint256 i = 0; i < assets.size(); i++) {
            address _asset = assets.getKeyAtIndex(i);
            IERC20(_asset).transfer(
                msg.sender,
                shareAmount * (assets.get(_asset) / totalShare)
            );
        }
    }

    function claim(uint256[] calldata tokenIds) external whenNotPaused nonReentrant {
        require(block.timestamp > lockTime, "Locking Period");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256[] memory idsOfOwner = sugarNFT.getTokenIdsOf(msg.sender);
            require(
                !isNFTClaimed[tokenIds[i]] &&
                    isExisting(idsOfOwner, tokenIds[i]),
                "Not owner of token id or already claimed"
            );
        }
        for (uint256 i = 0; i < tokenIds.length; i++) {
            isNFTClaimed[tokenIds[i]] = true;
        }
        _claim(tokenIds.length);
    }

    function withdraw() external onlyOwner {
        require(isWithdraw, "Already Withdraw");
        require(block.timestamp > lockTime, "Locking Period");
        uint256 totalShare = sugarNFT.getTotalSupply();
        uint256 soldShare = sugarNFT.getCurrentTokenId();
        uint256 remainedShare = totalShare - soldShare;
        for (uint256 i = 0; i < assets.size(); i++) {
            address _asset = assets.getKeyAtIndex(i);
            IERC20(_asset).transfer(
                msg.sender,
                remainedShare * (assets.get(_asset) / totalShare)
            );
        }
        isWithdraw = false;
    }

    function isExisting(uint256[] memory array, uint256 value)
        internal
        pure
        returns (bool)
    {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == value) return true;
        }
        return false;
    }
}