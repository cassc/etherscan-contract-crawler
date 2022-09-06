// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@ensdomains/ens-contracts/contracts/registry/ENS.sol";

contract ENSFollower {
    mapping(bytes32 => uint256) public followingCount;
    mapping(bytes32 => uint256) public followerCount;
    mapping(bytes32 => mapping(bytes32 => bool)) private followingBitMap;
    ENS public immutable registry;

    constructor(ENS registry_) {
        registry = registry_;
    }

    function isFollowing(bytes32 domain, bytes32 domainFollowed)
        external
        view
        returns (bool)
    {
        return followingBitMap[domain][domainFollowed];
    }

    function follow(
        address account,
        bytes32 domain,
        bytes32 domainToFollow
    ) external {
        if (followingBitMap[domain][domainToFollow] == true) {
            revert("Domain is already followed");
        }

        if (registry.owner(domain) != account) {
            revert("Domain not owned by this account");
        }

        followingBitMap[domain][domainToFollow] = true;
        followingCount[domain] = followingCount[domain] + 1;
        followerCount[domainToFollow] = followerCount[domainToFollow] + 1;

        emit Followed(account, domain, domainToFollow);
    }

    function unfollow(
        address account,
        bytes32 domain,
        bytes32 domainToUnfollow
    ) external {
        if (followingBitMap[domain][domainToUnfollow] == false) {
            revert("Domain is already not followed");
        }

        if (registry.owner(domain) != account) {
            revert("Domain not owned by this account");
        }

        followingBitMap[domain][domainToUnfollow] = false;
        followingCount[domain] = followingCount[domain] - 1;
        followerCount[domainToUnfollow] = followerCount[domainToUnfollow] - 1;

        emit Unfollowed(account, domain, domainToUnfollow);
    }

    // This event is triggered whenever a call to #follow succeeds.
    event Followed(address account, bytes32 domain, bytes32 domainToFollow);

    // This event is triggered whenever a call to #unfollow succeeds.
    event Unfollowed(address account, bytes32 domain, bytes32 domainToFollow);
}