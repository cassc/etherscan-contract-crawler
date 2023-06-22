// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./AccountWhitelist.sol";
import "../utils/Bitmap.sol";

contract AccountWhitelistManager is AccountWhitelist, Initializable {
    using Bitmap for mapping(uint256 => uint256);

    address public approvedCaller;

    mapping(address => bool) public claimed;

    function initialize(bytes32 root, string calldata uri)
        external
        initializer
    {
        _transferOwnership(msg.sender);
        whitelistMerkleRoot = root;
        whitelistURI = uri;
    }

    /*
    WRITE FUNCTIONS
    */

    function _setClaimed(address account) internal {
        claimed[account] = true;
    }

    function claim(address account, bytes32[] calldata proof)
        external
        onlyApprovedCaller
        onlyWhitelisted(account, proof)
        onlyNotClaimed(account)
    {
        _setClaimed(account);
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

    modifier onlyNotClaimed(address account) {
        require(!claimed[account], "Already claimed");
        _;
    }

    modifier onlyApprovedCaller() {
        require(
            msg.sender == approvedCaller,
            "AccountWhitelist: not approved caller"
        );
        _;
    }
}