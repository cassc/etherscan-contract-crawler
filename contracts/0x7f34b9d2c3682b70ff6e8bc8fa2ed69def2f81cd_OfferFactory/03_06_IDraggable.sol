// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../ERC20/IERC20.sol";
import "./IOffer.sol";
interface IDraggable {
    
    function wrapped() external view returns (IERC20);
    function unwrap(uint256 amount) external;
    function offer() external view returns (IOffer);
    function oracle() external view returns (address);
    function drag(address buyer, IERC20 currency) external;
    function notifyOfferEnded() external;
    function votingPower(address voter) external returns (uint256);
    function totalVotingTokens() external view returns (uint256);
    function notifyVoted(address voter) external;
    function setTerms(string calldata _terms) external;

}