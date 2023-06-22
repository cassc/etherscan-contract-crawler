// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./NFTWhitelist.sol";
import "../utils/Bitmap.sol";

contract NFTWhitelistManager is NFTWhitelist {
    using Bitmap for mapping(uint256 => uint256);

    address public approvedCaller;

    mapping(address => mapping(uint256 => uint256)) public claimed;

    constructor(uint256 seed) NFTWhitelist(seed) {}

    /*
    READ FUNCTIONS
    */

    function isClaimed(address token, uint256 id) public view returns (bool) {
        return claimed[token].get(id);
    }

    function filterUnclaimed(address token, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory unclaimedIds = new uint256[](ids.length);
        uint256 index = 0;
        for (uint256 i = 0; i < ids.length; i++) {
            if (isWhitelisted(token, ids[i]) && !isClaimed(token, ids[i])) {
                unclaimedIds[index] = ids[i];
                index++;
            }
        }

        return slice(unclaimedIds, 0, index);
    }

    function paginateUnclaimed(
        address token,
        uint256 start,
        uint256 count
    ) external view returns (uint256[] memory) {
        uint256[] memory ids = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = start; i < start + count; i++) {
            if (isWhitelisted(token, i) && !isClaimed(token, i)) {
                ids[index] = i;
                index++;
            }
        }

        return slice(ids, 0, index);
    }

    function paginateOwnerUnclaimed(
        address account,
        address token,
        uint256 start,
        uint256 count
    ) external view returns (uint256[] memory) {
        uint256[] memory ids = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = start; i < start + count; i++) {
            if (
                isWhitelisted(token, i) &&
                !isClaimed(token, i) &&
                isOwner(account, token, i)
            ) {
                ids[index] = i;
                index++;
            }
        }

        return slice(ids, 0, index);
    }

    /*
    WRITE FUNCTIONS
    */

    function claim(
        address account,
        address token,
        uint256 id
    ) external onlyApprovedCaller {
        _claim(account, token, id);
    }

    function claim(
        address account,
        address token,
        uint256[] calldata ids
    ) external onlyApprovedCaller {
        for (uint256 i = 0; i < ids.length; i++) {
            _claim(account, token, ids[i]);
        }
    }

    function _claim(
        address account,
        address token,
        uint256 id
    ) internal onlyWhitelisted(account, token, id) onlyNotClaimed(token, id) {
        _setClaimed(token, id);
    }

    function _setClaimed(address token, uint256 id) internal {
        claimed[token].set(id, true);
    }

    /*
    OWNER FUNCTIONS
    */

    function setApprovedCaller(address _approvedCaller) external onlyOwner {
        approvedCaller = _approvedCaller;
    }

    /*
    MODIFIERS
    */

    modifier onlyNotClaimed(address token, uint256 id) {
        require(!claimed[token].get(id), "Already claimed");
        _;
    }

    modifier onlyApprovedCaller() {
        require(
            msg.sender == approvedCaller,
            "NFTWhitelist: not approved caller"
        );
        _;
    }
}

function slice(
    uint256[] memory array,
    uint256 start,
    uint256 end
) pure returns (uint256[] memory) {
    uint256[] memory result = new uint256[](end - start);
    for (uint256 i = start; i < end; i++) {
        result[i - start] = array[i];
    }
    return result;
}