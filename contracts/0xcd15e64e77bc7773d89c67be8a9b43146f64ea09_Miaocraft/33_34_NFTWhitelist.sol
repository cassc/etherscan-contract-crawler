// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../utils/Bitmap.sol";

abstract contract NFTWhitelist is Ownable, Initializable {
    uint256 public immutable SEED;

    mapping(address => uint256) public whitelistRates;

    constructor(uint256 seed) {
        SEED = seed;
    }

    function initialize() external initializer {
        _transferOwnership(msg.sender);
    }

    /*
    READ FUNCTIONS
    */

    function isWhitelisted(address token, uint256 id)
        public
        view
        virtual
        returns (bool)
    {
        return
            uint256(keccak256(abi.encodePacked(token, id, SEED))) % 1e18 <
            whitelistRates[token];
    }

    function isOwner(
        address account,
        address token,
        uint256 id
    ) public view virtual returns (bool) {
        return IERC721(token).ownerOf(id) == account;
    }

    function paginateWhitelisted(
        address token,
        uint256 start,
        uint256 count
    ) external view virtual returns (uint256[] memory) {
        uint256[] memory ids = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = start; i < start + count; i++) {
            if (isWhitelisted(token, i)) {
                ids[index] = i;
                index++;
            }
        }
        return ids;
    }

    function paginateOwnerWhitelisted(
        address account,
        address token,
        uint256 start,
        uint256 count
    ) external view virtual returns (uint256[] memory) {
        uint256[] memory ids = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = start; i < start + count; i++) {
            if (isWhitelisted(token, i) && isOwner(account, token, i)) {
                ids[index] = i;
                index++;
            }
        }
        return ids;
    }

    /*
    WRITE FUNCTIONS
    */

    function _addWhitelist(address token, uint256 whitelistRate)
        internal
        virtual
    {
        require(whitelistRate <= 1e18, "NFTWhitelist: whitelist rate too high");
        whitelistRates[token] = whitelistRate;
    }

    /*
    OWNER FUNCTIONS
    */

    function addWhitelist(address token, uint256 whitelistRate)
        external
        onlyOwner
    {
        _addWhitelist(token, whitelistRate);
    }

    /*
    MODIFIERS
    */

    modifier onlyWhitelisted(
        address account,
        address token,
        uint256 id
    ) {
        require(isWhitelisted(token, id), "Not whitelisted");
        require(isOwner(account, token, id), "Not owner");
        _;
    }
}