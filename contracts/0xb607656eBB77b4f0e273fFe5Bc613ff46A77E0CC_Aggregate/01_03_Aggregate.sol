// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Aggregate is Ownable {
    mapping(address => bool) internal _members;

    event MemberRegistered(address indexed member);

    event MemberDeregistered(address indexed member);

    event Executed(
        address indexed member,
        address indexed to,
        uint256 value,
        bytes data
    );

    modifier onlyMember() {
        require(_members[msg.sender], "Aggregate: caller is not a member");
        _;
    }

    function isMember(address member_) external view returns (bool) {
        return _members[member_];
    }

    function registerMembers(address[] calldata members_) external onlyOwner {
        for (uint256 i = 0; i < members_.length; i++) {
            address member_ = members_[i];

            if (_members[member_]) {
                continue;
            }

            _members[member_] = true;

            emit MemberRegistered(member_);
        }
    }

    function deregisterMembers(address[] calldata members_) external onlyOwner {
        for (uint256 i = 0; i < members_.length; i++) {
            address member_ = members_[i];

            if (!_members[member_]) {
                continue;
            }

            delete _members[member_];

            emit MemberDeregistered(member_);
        }
    }

    function execute(
        address to_,
        uint256 value_,
        bytes calldata data_
    ) external onlyMember returns (bytes memory) {
        (bool success, bytes memory result) = to_.call{value: value_}(data_);
        if (!success) {
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        emit Executed(msg.sender, to_, value_, data_);

        return result;
    }
}