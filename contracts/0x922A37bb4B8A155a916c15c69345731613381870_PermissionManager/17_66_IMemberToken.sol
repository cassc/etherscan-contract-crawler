pragma solidity ^0.8.7;

import "lib/openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol";

interface IMemberToken is IERC1155 {
    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) external view returns (uint256);

    /**
     * @dev Indicates weither any token exist with a given id, or not.
     */
    function exists(uint256 id) external view returns (bool);

    function getNextAvailablePodId() external view returns (uint256);

    /**
     * @param _podId The pod id number
     * @param _newController The address of the new controller
     */
    function migrateMemberController(uint256 _podId, address _newController)
        external;

    /**
     * @param _account The account address to transfer the membership token to
     * @param _id The membership token id to mint
     * @param data Arbitrary data
     */
    function mint(
        address _account,
        uint256 _id,
        bytes memory data
    ) external;

    /**
     * @param _accounts The account addresses to transfer the membership tokens to
     * @param _id The membership token id to mint
     * @param data Arbitrary data
     */
    function mintSingleBatch(
        address[] memory _accounts,
        uint256 _id,
        bytes memory data
    ) external;

    function burnSingleBatch(address[] memory _accounts, uint256 _id) external;

    function createPod(address[] memory _accounts, bytes memory data)
        external
        returns (uint256);
}