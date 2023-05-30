// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../util/Strings.sol";
import "../util/MerkleVerify.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

/**
 * Implements whitelist support based on merkle trees. The user's
 * address and nft allowence (quantity that can be purchased) is configured
 * on an external to the contract JSON file.  The root of the merkle tree for
 * this data is configured in the contract and is then used along with proof
 * presented by the client to check on the membership.
 */
abstract contract WhiteListV2 is MerkleVerify, StringsF, AccessControlEnumerable {
    bytes32 public constant SU_ROLE = keccak256("SU_ROLE");

    event WhiteListCompare(string, string);
    event WhiteListCheck(string, string);

    // id to root of whitelist lookup
    mapping(string => bytes32) public lists;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    modifier onlySU() {
        require(hasRole(SU_ROLE, msg.sender), "Caller is not SU");
        _;
    }

    /**
     * Set merkle root for target white list
     */
    function setRoot(string memory id, bytes32 root) external onlySU {
        require(hasRole(SU_ROLE, msg.sender), "Caller is not SU");
        lists[id] = root;
    }

    /**
     * Fetches merkle root for target white list
     */
    function getRoot(string memory id) public view returns (bytes32) {
        return lists[id];
    }

    /**
     * @dev for Client to check, to light up ui of entry into the sales
     * phase.  Actual enforcemned is done via isAllowed function (which
     * is internal) and is done prior to nft purchase
     */
    function isOnWhiteList(
        string memory wListID,
        bytes32[] memory proof,
        string memory leafSource
    ) public view returns (bool authorized, uint256 quantity) {
        require(lists[wListID] != bytes32(0x0), "Merkle root not found");

        // to check that "address:<number>" is present in the merkele tree.
        if (!verify(proof, lists[wListID], leafSource)) {
            return (false, 0);
        }
        // verify the that the sender is really in the claimed "address:<number>"
        string[] memory pairs = split(leafSource, ":", 2);
        require(pairs.length == 2, "expecting <address>:<number>");

        authorized = true;
        quantity = parseInt(pairs[1]);
    }

    function verifyAndReturnTargetAddress(
        string memory wListID,
        bytes32[] memory proof,
        string memory leafSource
    ) internal returns (bool authorized, address targetAddress, uint256 quantity) {
        require(lists[wListID] != bytes32(0x0), "Merkle root not found");

        emit WhiteListCheck(wListID, leafSource);

        // to check that "address:<number>" is present in the merkele tree.
        if (!verify(proof, lists[wListID], leafSource)) {
            return (false, address(0), 0);
        }

        string[] memory pairs = split(leafSource, ":", 2);
        require(pairs.length == 2, "expecting <address>:<number>");

        authorized = true;
        targetAddress = parseAddr(pairs[0]);
        quantity = parseInt(pairs[1]);
    }

    /**
     * Called for actual enofrcement of who gets to access target sales phasese
     */
    function isAllowed(
        string memory wListID,
        bytes32[] memory proof,
        string memory leafSource
    ) internal returns (bool authorized, uint256 quantity) {
        require(lists[wListID] != bytes32(0x0), "Merkle root not found");

        emit WhiteListCheck(wListID, leafSource);

        // to check that "address:<number>" is present in the merkele tree.
        if (!verify(proof, lists[wListID], leafSource)) {
            return (false, 0);
        }
        // verify the ate sender is really in the claimed "address:<number>"
        string[] memory pairs = split(leafSource, ":", 2);
        require(pairs.length == 2, "expecting <address>:<number>");

        // convert address to string and compare with msg.sender
        emit WhiteListCompare(addressToString(msg.sender), pairs[0]);

        authorized = compare(toUpper(addressToString(msg.sender)), toUpper(pairs[0]));
        quantity = parseInt(pairs[1]);
    }

    /**
     * Called for actual enofrcement of who gets to access target sales phasese
     */
    function isUserAllowed(
        string memory wListID,
        bytes32[] memory proof,
        string memory leafSource,
        address targetUsr
    ) internal view returns (bool authorized, uint256 quantity) {
        require(lists[wListID] != bytes32(0x0), "Merkle root not found");

        // to check that "address:<number>" is present in the merkele tree.
        if (!verify(proof, lists[wListID], leafSource)) {
            return (false, 0);
        }
        // verify the ate sender is really in the claimed "address:<number>"
        string[] memory pairs = split(leafSource, ":", 2);
        require(pairs.length == 2, "expecting <address>:<number>");

        authorized = compare(toUpper(addressToString(targetUsr)), toUpper(pairs[0]));
        quantity = parseInt(pairs[1]);
    }
}