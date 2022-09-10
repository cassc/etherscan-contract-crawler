//SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./utils/poolUtil.sol";
import "./Interfaces.sol";
contract Storage {
    uint256 public lastGas;
    uint256 public SwapFee; // 8 decimal places
    uint256 public revision;
    uint256 public expUint1;
    uint256 public expUint2;
    
    address internal feeCollector;
    address public beaconContract;
    address public logic_contract;
    address public intToken0;
    address public intToken1;
    address public expAddr1;
    address public expAddr2;
            
    bool internal _locked;
    bool internal _initialized;
    bool internal _shared;
    bool bitflip;
    bool tmp1;


    bytes32 public constant HARVESTER = keccak256("HARVESTER");
    string internal exchange;

    bool internal liquidationFee;
    bool public paused;

    stData public iData;
    stHolders internal mHolders;
    iBeacon.sExchangeInfo public exchangeInfo;
}