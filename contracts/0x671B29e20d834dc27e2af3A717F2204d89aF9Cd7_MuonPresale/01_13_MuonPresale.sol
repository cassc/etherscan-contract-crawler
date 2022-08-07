// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IMuonV02.sol";
import "./IMRC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract MuonPresale is Ownable {
    using ECDSA for bytes32;

    IMuonV02 public muon;

    mapping(address => uint256) public balances;
    mapping(address => uint256) public lastTimes;

    mapping(address => mapping(uint8 => uint256)) public roundBalances;

    uint32 public APP_ID = 0x2031768f;

    bool public running = true;

    uint256 public maxMuonDelay = 5 minutes;

    // Total USD amount
    uint256 public totalBalance = 0;

    uint256 public startTime = 1659886200;

    event Deposit(
        address token,
        address fromAddress,
        address forAddress,
        uint8 round,
        uint256[5] extraParameters
    );

    modifier isRunning() {
        require(running && startTime < block.timestamp, "!running");
        _;
    }

    constructor(address _muon) {
        muon = IMuonV02(_muon);
    }

    function getChainID() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    function deposit(
        address token,
        address forAddress,
        uint8 round,
        uint256[5] memory extraParameters,
        // [0]=allocation,[1]=chainId,[2]=tokenPrice, [3]=amount ,[4]=time,
        bytes calldata reqId,
        IMuonV02.SchnorrSign[] calldata sigs
    ) public payable isRunning {
        require(sigs.length > 0, "!sigs");
        require(extraParameters[1] == getChainID(), "Invalid Chain ID");

        bytes32 hash = keccak256(
            abi.encodePacked(
                APP_ID,
                token,
                round,
                extraParameters[3],
                extraParameters[4],
                forAddress,
                extraParameters[0],
                extraParameters[1],
                extraParameters[2]
            )
        );

        bool verified = muon.verify(reqId, uint256(hash), sigs);
        require(verified, "!verified");

        // check max
        uint256 usdAmount = token != address(0)
            ? (extraParameters[3] * extraParameters[2]) /
                (10**IMRC20(token).decimals())
            : (extraParameters[3] * extraParameters[2]) / (10**18);

        balances[forAddress] += usdAmount;
        roundBalances[forAddress][round] += usdAmount;

        require(roundBalances[forAddress][round] <= extraParameters[0], ">max");

        totalBalance += usdAmount;

        require(
            extraParameters[4] + maxMuonDelay > block.timestamp,
            "muon: expired"
        );

        require(
            extraParameters[4] - lastTimes[forAddress] > maxMuonDelay,
            "duplicate"
        );

        lastTimes[forAddress] = extraParameters[4];

        require(
            token != address(0) || extraParameters[3] == msg.value,
            "amount err"
        );

        if (token != address(0)) {
            IMRC20(token).transferFrom(
                address(msg.sender),
                address(this),
                extraParameters[3]
            );
        }

        emit Deposit(token, msg.sender, forAddress, round, extraParameters);
    }

    function setMuonContract(address addr) public onlyOwner {
        muon = IMuonV02(addr);
    }

    function setIsRunning(bool val) public onlyOwner {
        running = val;
    }

    function setMaxMuonDelay(uint256 delay) public onlyOwner {
        maxMuonDelay = delay;
    }

    function setMuonAppID(uint32 appid) public onlyOwner {
        APP_ID = appid;
    }

    function setStartTime(uint256 _time) public onlyOwner {
        startTime = _time;
    }

    function withdrawETH(uint256 amount, address addr) public onlyOwner {
        require(addr != address(0));
        payable(addr).transfer(amount);
    }

    function withdrawERC20Tokens(
        address _tokenAddr,
        address _to,
        uint256 _amount
    ) public onlyOwner {
        require(_to != address(0));
        IMRC20(_tokenAddr).transfer(_to, _amount);
    }

    function userInfo(address _user, uint8 rounds) public view returns (
        uint256 _totalBalance,
        uint256 _startTime,
        uint256 _userBalance,
        uint256 _lastTime,
        uint256[] memory _roundBalances
    ) {
        _startTime = startTime;
        _totalBalance = totalBalance;
        _userBalance = balances[_user];
        _lastTime = lastTimes[_user];
        _roundBalances = new uint256[](rounds);
        for(uint8 i=0; i<rounds; i++){
            _roundBalances[i] = roundBalances[_user][i+1];
        }
    }
}