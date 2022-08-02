// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.10;

error NotOwner();

// https://github.com/m1guelpf/erc721-drop/blob/main/src/LilOwnable.sol
abstract contract Ownable {
    address internal _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    modifier onlyOwner() {
        require(_owner == msg.sender);
        _;
    }

    constructor() {
        _owner = msg.sender;
    }

    function owner() external view returns (address) {
        return _owner;
    }

    function transferOwnership(address _newOwner) external {
        if (msg.sender != _owner) revert NotOwner();

        _owner = _newOwner;
    }

    function renounceOwnership() public {
        if (msg.sender != _owner) revert NotOwner();

        _owner = address(0);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        virtual
        returns (bool)
    {
        return interfaceId == 0x7f5828d0; // ERC165 Interface ID for ERC173
    }
}