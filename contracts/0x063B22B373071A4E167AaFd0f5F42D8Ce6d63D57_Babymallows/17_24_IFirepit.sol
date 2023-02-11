// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.4;
import "./Ownable.sol";
import "./IERC721Receiver.sol";

interface IFirepit is IERC721Receiver{
    function isOwnerOfStakedTokens(uint256[] calldata _tokenIds, address _owner) external view returns (bool);
}