pragma solidity ^0.8.7;

interface IControllerBase {
    /**
     * @param operator The account address that initiated the action
     * @param from The account address sending the membership token
     * @param to The account address recieving the membership token
     * @param ids An array of membership token ids to be transfered
     * @param amounts The amount of each membership token type to transfer
     * @param data Arbitrary data
     */
    function beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;

    function updatePodState(
        uint256 _podId,
        address _podAdmin,
        address _safeAddress
    ) external;
}