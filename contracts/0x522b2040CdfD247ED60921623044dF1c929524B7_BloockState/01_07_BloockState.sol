pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract BloockState is AccessControl {

    // bytes32(keccak245(bytes("STATE_MANAGER")));
    bytes32 public constant STATE_MANAGER = 0x7c0c08811839d3a8bfad3f26fd05feea7daf5d75bf9d6f3fe140cd8f62b7af38;

    // Map containing a relation of the state roots and the timestamp they where published on. 0 if not present.
    mapping (bytes32 => uint256) private states;

    /**
     * @dev Constructor function.
     * @param role_manager is the address granted the default_admin role.
     * @param state_manager is the address granted the state_manager role.
     */
    constructor(address role_manager, address state_manager) {
        _setupRole(DEFAULT_ADMIN_ROLE, role_manager);
        _setupRole(STATE_MANAGER, state_manager);
    }

    /**
     * @dev Appends a new state to the states map with the current timestamp.
     * @param state_root the new state_root to append.
     */
    function updateState(bytes32 state_root) external {
        require(
            hasRole(STATE_MANAGER, msg.sender),
            "BloockState::updateState: ONLY_ALLOWED_ROLE"
        );
        states[state_root] = block.timestamp;
    }

    /**
     * @dev Checks whether the state_root is present in the state_machine or not.
     * @param state_root the state_root to check.
     */
    function isStatePresent(bytes32 state_root) public view returns (bool) {
        return states[state_root] != 0;
    }

    /**
     * @dev Gets the value of an specific state_root.
     * @param state_root the state_root to get.
     * @return the timestamp of the anchor.
     */
    function getState(bytes32 state_root) public view returns (uint256) {
        return states[state_root];
    }

    struct InternalStack {
        bytes32 hash;
        uint32 depth;
    }

    /**
     * @dev Checks the validity of the inclusion proof for a set of contents.
     * @param content the hashes of the content to test (keccak).
     * @param hashes the minimal set of keys required, aside from the ones in `content` to compute the root key value. They are ordered following a post-order tree traversal.
     * @param bitmap Bitmap representing whether an element of `depths` belong `content` set (value 0) or `hashes` set (value 1).
     * @param depths Vector containing the depth of each node whose keys belongs to `leaves` or `hashes` set relative to the tree root node. It also follows the post-order traversal order.
     * @return the timestamp of the anchor. 0 if not present.
     */

    function verifyInclusionProof(bytes32[] calldata content, bytes32[] calldata hashes, bytes calldata bitmap, uint32[] calldata depths) public view returns (uint256) {

        uint256 it_content = 0;
        uint256 it_hashes = 0;

        InternalStack[] memory stack = new InternalStack[](content.length + hashes.length);
        uint256 len_stack = 0;

        while (it_hashes < hashes.length || it_content < content.length) {
            uint32 act_depth = depths[it_hashes + it_content];
            bytes32 act_hash;
            if (bitmap[(it_hashes+it_content)/8] & bytes1(uint8(0x01) * uint8(2) ** uint8(7-(it_hashes+it_content)%8)) != 0) {
                it_hashes  = it_hashes + 1;
                act_hash = hashes[it_hashes - 1];
            } else {
                it_content = it_content + 1;
                act_hash = content[it_content - 1];
            }
            while (len_stack != 0 && stack[len_stack-1].depth == act_depth) {
                bytes32 last_hash = stack[len_stack-1].hash;
                len_stack = len_stack - 1;
                act_hash = keccak256(abi.encode(last_hash, act_hash));
                act_depth = act_depth - 1;
            }
            stack[len_stack] = InternalStack(act_hash, act_depth);
            len_stack = len_stack + 1;
        }
        return states[stack[0].hash];
    }

}