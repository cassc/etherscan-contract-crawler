// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract TrackerUpgradeable is Initializable {
    struct Token {
        address owner;
        uint256 timestamp;
        uint256 accrued;
    }

    function __Tracker_init() internal onlyInitializing {}

    mapping(uint256 => Token) private _tokens;
    mapping(address => uint256) private _balances;

    function token(uint256 id_) public view returns (Token memory) {
        return _tokens[id_];
    }

    function _setToken(Token memory token_, uint256 id_) internal {
        _tokens[id_] = token_;
    }

    function _increaseBalance(address owner_, uint256 amount_) internal {
        _balances[owner_] += amount_;
    }

    function _decreaseBalance(address owner_, uint256 amount_) internal {
        _balances[owner_] -= amount_;
    }

    function balanceOf(address owner_) public view returns (uint256) {
        return _balances[owner_];
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        return token(tokenId).owner;
    }

    /**
        @dev for offchain purposes
     */
    function tokensOfOwner(address owner) external view virtual returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            for (uint256 i = 0; tokenIdsIdx != tokenIdsLength; ++i) {
                Token memory data = _tokens[i];
                if (data.owner == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
    }
}