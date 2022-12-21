//SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "./utils/slots.sol";

contract Storage {
    uint64 public holdBack;
    uint256 public lastGas;
    address public logic_contract;
    address internal feeCollector;
    address public beaconContract;
    
    iBeacon.sExchangeInfo public exchangeInfo;


    bool internal _locked;
    bool internal _initialized;
    bool internal _shared;

    bytes32 public constant HARVESTER = keccak256("HARVESTER");

    string public exchange;    
    //New Variables after this only

    slotsLib.slotStorage[] public slots;
    uint public SwapFee;
    uint public revision;
}