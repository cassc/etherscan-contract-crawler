// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "./IMintable.sol";

contract ERC721YieldUpgradeable is ERC721Upgradeable {
    IMintable                   public token;
    uint256                     private _defaultRate;
    mapping(uint256 => uint256) private _tokenBoost;
    mapping(address => uint256) private _accountRate;
    mapping(address => uint256) private _lastUpdate;

    event TokenBoost(uint256 indexed tokenId, uint256 boost);

    function __ERC721Yield_init(IMintable __token, uint256 __defaultRate) internal {
        token        = __token;
        _defaultRate = __defaultRate;
    }

    function pending(address account) public view returns (uint256) {
        uint256 duration = block.timestamp - _lastUpdate[account];
        return duration == 0 ? 0 : duration * accountRate(account);
    }

    function accrue(address account) public {
        uint256 value = pending(account);
        if (value > 0) {
            token.mint(account, value);
        }
        _lastUpdate[account] = block.timestamp;
    }

    function accountRate(address account) public view returns (uint256) {
        return _accountRate[account];
    }

    function defaultRate() public view returns (uint256) {
        return _defaultRate;
    }

    function tokenBoost(uint256 tokenId) public view returns (uint256) {
        return _tokenBoost[tokenId];
    }

    function tokenRate(uint256 tokenId) public view returns (uint256) {
        return _defaultRate * (100 + tokenBoost(tokenId)) / 100;
    }

    function _setBoost(uint256 tokenId, uint256 boost) internal {
        address owner = ownerOf(tokenId);

        accrue(owner);

        uint256 oldTokenRate = tokenRate(tokenId);
        _tokenBoost[tokenId] = boost;
        uint256 newTokenRate = tokenRate(tokenId);

        _accountRate[owner] = _accountRate[owner] - oldTokenRate + newTokenRate;

        emit TokenBoost(tokenId, boost);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from != address(0) || to != address(0)) {
            uint256 rate = tokenRate(tokenId);
            if (from != address(0)) {
                accrue(from);
                _accountRate[from] -= rate;
            }
            if (to != address(0)) {
                accrue(to);
                _accountRate[to] += rate;
            }
        }
    }

    uint256[45] private __gap;
}