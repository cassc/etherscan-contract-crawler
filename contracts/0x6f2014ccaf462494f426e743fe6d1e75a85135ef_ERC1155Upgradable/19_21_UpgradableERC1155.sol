// SPDX-License-Identifier: CLOSED - Pending Licensing Audit
pragma solidity ^0.8.4;

import "./IERC1155.sol";
import "./SafeMath.sol";
import "./EventableERC1155.sol";

interface IUpgradableERC1155 {
    function upgradeFrom(address oldContract) external;
}

abstract contract UpgradableERC1155 is IUpgradableERC1155, EventableERC1155  {
    using SafeMath for uint256;

    bool internal _isUpgrade;
    address public upgradedFrom;
    uint256 internal _totalMoved;
    mapping(address => uint256) internal _supplyMoved;
    mapping(address => bool) public seen;

    function isUpgrade() public view returns (bool) {
        return _isUpgrade;
    }

    function upgradeFrom(address oldContract) public virtual override {
        require(!_isUpgrade, "Contract already an upgrade");
        require(oldContract != address(0), "Invalid Upgrade");
        _isUpgrade = true;
        upgradedFrom = oldContract;
    }

    function transferHook(address sender, address recipient, uint256 tokenId, mapping(uint256 => mapping(address => uint256)) storage _balances) internal returns (uint256, uint256) {
        uint256 pastSenderBalance = 0;
        uint256 pastRecipientBalance = 0;
        if (!seen[sender]) {
            seen[sender] = true;
        }
        if (!seen[recipient]) {
            seen[recipient] = true;
        }
        address seenSenderAddress = tokenIdToAddress(sender, tokenId);
        address seenRecipientAddress = tokenIdToAddress(recipient, tokenId);
        if (isUpgrade()) {
            if (!seen[seenSenderAddress]) {
                seen[seenSenderAddress] = true;
                pastSenderBalance = IERC1155(upgradedFrom).balanceOf(sender, tokenId);
                _supplyMoved[sender] = _supplyMoved[sender].add(pastSenderBalance);
                _balances[tokenId][sender] = _balances[tokenId][sender].add(pastSenderBalance);
                _totalMoved = _totalMoved.add(pastSenderBalance);
            }
            if (!seen[seenRecipientAddress]) {
                seen[seenRecipientAddress] = true;
                pastRecipientBalance = IERC1155(upgradedFrom).balanceOf(recipient, tokenId);
                _supplyMoved[sender] = _supplyMoved[sender].add(pastRecipientBalance);
                _balances[tokenId][recipient] = _balances[tokenId][recipient].add(pastRecipientBalance);
            }
        } else {
            if (!seen[seenSenderAddress]) {
                seen[seenSenderAddress] = true;
            }
            if (!seen[seenRecipientAddress]) {
                seen[seenRecipientAddress] = true;
            }
        }
        return (pastSenderBalance, pastRecipientBalance);
    }

    function transferEventHook(address operator, address sender, address recipient, uint256 tokenId, uint256 pastSenderBalance, uint256 pastRecipientBalance) internal {
        if (pastSenderBalance > 0) {
                emit TransferSingle(operator, address(0), sender, tokenId, pastSenderBalance);
            }
            if (pastRecipientBalance >0) {
                emit TransferSingle(operator, address(0), recipient, tokenId, pastRecipientBalance);
            }
    }

    function balanceOfHook(address account, uint256 tokenId, mapping(uint256 => mapping(address => uint256)) storage _balances) internal view returns(uint256) {
        uint256 oldBalance = 0;
        if (isUpgrade()) {
            oldBalance = IERC1155(upgradedFrom).balanceOf(account, tokenId);
        }
        return (isUpgrade() && !seen[account]) ? IERC1155(upgradedFrom).balanceOf(account, tokenId):  _balances[tokenId][account];
    }

    function mintHook(address account, uint256 tokenId, uint256 amount) internal returns (uint256) {
        if (!seen[account]) {
            seen[account] = true;
        }
        address seenAddress = tokenIdToAddress(account, tokenId);
        if (isUpgrade()) {
            if (!seen[seenAddress]) {
                seen[seenAddress] = true;
                uint256 pastBalance = IERC1155(upgradedFrom).balanceOf(account, tokenId);
                _supplyMoved[account] = _supplyMoved[account].add(pastBalance);
                amount = amount.add(pastBalance);
                _totalMoved = _totalMoved.add(pastBalance);
            }
        } else {
            if (!seen[account]) {
                seen[account] = true;
            }
        }
        return amount;
    }

    function tokenIdToAddress(address account, uint256 tokenId) internal pure returns (address) {
        bytes32 seenHash = keccak256(abi.encodePacked(account, tokenId));
        return address(uint160(uint256(seenHash)));
    }
}