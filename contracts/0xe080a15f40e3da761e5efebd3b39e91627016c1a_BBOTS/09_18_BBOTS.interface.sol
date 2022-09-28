// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {BBOTSEvents, MintPhase, Ticket} from "./BBOTS.events.sol";

interface IBBOTS is IERC2981, BBOTSEvents {
    /*///////////////////////////////////////////////////////////////
                            ERRORS
    //////////////////////////////////////////////////////////////*/

    error InvalidMintPhase();
    error InvalidPayment();
    error InvalidTicket();
    error TotalSupplyExceeded();
    error AvailableSupplyExceeded();
    error MaxMintsExceeded();
    error InvalidAvailableSupply();

    /*///////////////////////////////////////////////////////////////
                        	MINTING
    //////////////////////////////////////////////////////////////*/

    function setMintPhase(MintPhase _phase) external;

    function mintTo(address _to, uint256 _amt) external;

    function mint(uint256 _amt, Ticket calldata _ticket) external payable;

    function mint(uint256 _amt) external payable;

    /*///////////////////////////////////////////////////////////////
                        	UTILS
    //////////////////////////////////////////////////////////////*/

    function updateMetadataRenderer(address _renderer) external;

    function lockMetadata() external;

    function sweep() external;
}