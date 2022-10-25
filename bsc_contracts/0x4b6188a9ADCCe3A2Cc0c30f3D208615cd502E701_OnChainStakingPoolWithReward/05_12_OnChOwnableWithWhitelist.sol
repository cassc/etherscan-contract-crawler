// SPDX-License-Identifier: MIT

pragma solidity >=0.8.1;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract OnChOwnableWithWhitelist is Ownable {

    using SafeERC20 for IERC20;

    address unWithdrawableToken = 0x8c18ffD66d943C9B0AD3DC40E2D64638F1e6e1ab;

    mapping(address => bool) internal _whitelisted;

    constructor () {
        _whitelisted[msg.sender] = true;
    }

    function isWhitelisted(address addressToCheck) public view returns (bool) {
        return _whitelisted[addressToCheck];
    }

    function addToWhitelist(address allowedAddress) public onlyOwner {
        _whitelisted[allowedAddress] = true;
    }

    function addToWhitelistBulk(address[] calldata allowedAddresses) public onlyOwner {
        for (uint256 i = 0; i < allowedAddresses.length; i++) {
            _whitelisted[allowedAddresses[i]] = true;
        }
    }

    function removeFromWhitelist(address allowedAddress) public onlyOwner {
        _whitelisted[allowedAddress] = false;
    }

    function removeFromWhitelistBulk(address[] calldata allowedAddresses) public onlyOwner {
        for (uint256 i = 0; i < allowedAddresses.length; i++) {
            _whitelisted[allowedAddresses[i]] = false;
        }
    }

    modifier whitelistedOnly() {
        require(_whitelisted[msg.sender], "OnChOwnableWithWhitelist: Not allowed");
        _;
    }

    function setUnWithdrawableToken(address token) external onlyOwner {
        unWithdrawableToken = token;
    }

    function withdrawResidualErc20(address token, address to) external onlyOwner {
        require(token != unWithdrawableToken, "OnChOwnableWithWhitelist: HER token cannot be withdraw");
        uint256 erc20balance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(to, erc20balance);
    }
}