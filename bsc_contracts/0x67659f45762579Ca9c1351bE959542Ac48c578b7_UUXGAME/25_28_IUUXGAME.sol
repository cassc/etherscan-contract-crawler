// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../structs/UUXDATA.sol";

abstract contract IUUXGAME is UUXDATA {

    address public USDTAddress;

    address public TokenAddress;

    address public USERAddress;

    address public RechargeAddress;
    
    address public WithdrawAddress;

    address public RegAddress;

    mapping(address => uint256) public WhiteAddress;

    mapping(address => uint256) public BlackAddress;

    mapping(address => uint256) public NoAddress;

    mapping(address => RechargeStruct[]) public _userRecharge;

    mapping (address => AssetStruct[]) public _userAssets;

    mapping(address => UserRebateStruct[]) public _userRebate;

    mapping(address => address) public userReferer;

    mapping(address => UserTeamStruct[]) public _userTeam;

    mapping(uint256 => mapping(uint256=>address)) public noTeam;

    uint256 public maxNo;
    uint256 public minNo;

    bytes public constant GOLD_NAME = bytes("gold");

    mapping(address => uint256) public userLevel;

    mapping(address => uint256) public userValid;

    mapping(address => uint256) public userStatusValid;

    mapping(address => uint256) public userProfit;

    mapping(address => uint256) public userRecharge;
    
    mapping(address => uint256) public userWithdraw;

    bytes public constant HOLDER_NAME = bytes("hoder");

    SysConfigStruct public SysConfig;

    LevelStruct[] public _levelStruct;

    mapping(bytes => address[]) public userHolder;

    mapping(address => uint256) public userHolders;

    uint256[50] private __gap;
}