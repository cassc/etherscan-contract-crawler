// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

interface iFund {
    function initialize(address _fundsStorage, address _owner,
                        string memory name, string memory symbol) external;
}

contract Storage is Initializable, OwnableUpgradeable {
    struct FundData {
        string name;
        string avatar;
        string description;
        string tokenName;
        string tokenSymbol;
        IERC20[] allowedTokens;
        address owner;
        address resultAddress;
        uint256 fee;
        uint256 started;
        uint256 waited;
        uint256 resumed;
        uint256 goal;
        uint256 funded;
        uint256 returnValue;
        uint256 returnedValue;
    }
    struct CreateFundData {
        string name;
        string avatar;
        string description;
        string tokenSymbol;
        IERC20[] allowedTokens;
        address resultAddress;
        uint256 fee;
        uint256 goal;
    }

    /// @notice Mapping of addresses to FundData
    mapping(address => FundData) public fundsData;

    /// @notice list of all fundings addresses
    address[] public fundings;

    /// @notice Address for sending gtpFee
    address public gtpFeeAddress;

    /// @notice amount of gtp fee
    uint256 public gtpFee;

    /// @notice address of fund implementation
    address public tokenImplementation;

    /// @notice Funded event
    event Funded(address indexed _fund, uint256 _value);
    event Created(address indexed _fund);
    event Closed(address indexed _fund);
    event Resumed(address indexed _fund, uint256 _value);
    event Withdrawed(address indexed _fund, uint256 _value);
    
    /// @notice modifier for access only from fund
    modifier onlyStarted() {
        require(fundsData[msg.sender].started != 0, "FundsStorage: fund not started");
        _;
    }

    function initialize() public initializer {
        __Ownable_init();
        transferOwnership(msg.sender);
        gtpFeeAddress = msg.sender;
        gtpFee = 10;
    }

    /// @notice return fundData by address
    function getFund(address _fundAddress) public view returns (FundData memory data) {
        data = fundsData[_fundAddress];
        require(data.started != 0, "FundsStorage: fund not started");
    }

    /// @notice list of all funding addresses TODO make pagination
    function allFundings() public view returns(address[] memory) {
        return fundings;
    }

    /// @notice list of ten last active fundings
    function lastActiveFundings() public view returns(address[] memory) {
        uint maxCount = 20;
        uint256 resultCount;

        for(uint256 i; i<fundings.length; i++) {
            if(isRising(fundings[i])) {
                resultCount++;
            }
        }

        if(maxCount > resultCount) {
            maxCount = resultCount;
        }

        uint idx;
        address[] memory activeList = new address[](maxCount);

        if (maxCount>0) {
            for (uint256 i=fundings.length; i > 0; i--) {
            address funding = fundings[i-1];
            if(isRising(funding)) {
                activeList[idx] = (funding);
                idx++;
            }
            if(idx > maxCount - 1) {
                break;
            }
            }
        }
        
        return activeList;
    }

    function isRising(address _fundAddress) public view returns(bool) {
        return fundsData[_fundAddress].started != 0  && fundsData[_fundAddress].waited == 0;
    }

    function isWaiting(address _fundAddress) public view returns(bool) {
        return fundsData[_fundAddress].waited != 0  && fundsData[_fundAddress].resumed == 0;
    }

    function isReducing(address _fundAddress) public view returns(bool) {
        return fundsData[_fundAddress].resumed != 0;
    }

    function setGtpFeeAddress(address _newAddress) public onlyOwner {
        gtpFeeAddress = _newAddress;
    }

    function setImplementation(address _implementation) public onlyOwner {
        tokenImplementation = _implementation;
    }

    function setGtpFee(uint256 _newFee) public onlyOwner {
        gtpFee = _newFee;
    }

    function createFund(CreateFundData memory data) public returns (address clone) {
        clone  = Clones.clone(tokenImplementation);
        iFund(clone).initialize(address(this), msg.sender, data.name, data.tokenSymbol);
        fundsData[clone] = FundData({
                name: data.name,
                avatar: data.avatar,
                description: data.description,
                tokenName: data.name,
                tokenSymbol: data.tokenSymbol,
                allowedTokens: data.allowedTokens,
                owner: msg.sender,
                resultAddress: data.resultAddress,
                fee: data.fee,
                started: block.timestamp,
                waited: 0,
                resumed: 0,
                goal: data.goal,
                funded: 0,
                returnValue: 0,
                returnedValue: 0
                });
        fundings.push(clone);
        emit Created(clone);
        return clone;
    }


    function getFundFee() external view onlyStarted() returns (uint256 fee) {
        fee = fundsData[msg.sender].fee;
    }

    function getFundResultAddress() external view onlyStarted() returns (address resultAddress) {
        resultAddress = fundsData[msg.sender].resultAddress;
    }

    function closeFund() external onlyStarted() {
        fundsData[msg.sender].waited = block.timestamp;
        emit Closed(msg.sender);
    }

    function resumeFund(uint256 _value) external onlyStarted() {
        fundsData[msg.sender].resumed = block.timestamp;
        fundsData[msg.sender].returnValue = _value;
        emit Resumed(msg.sender, _value);
    }

    function funded(uint256 amount) external onlyStarted() {
        fundsData[msg.sender].funded += amount;
        emit Funded(msg.sender, amount);
    }

    function withdrawed(uint256 amount) external onlyStarted() {
        fundsData[msg.sender].returnedValue += amount;
        emit Withdrawed(msg.sender, amount);
    }

    function isTokenAllowed(IERC20 _token) external view onlyStarted() returns(bool allowed) {
        IERC20 [] memory _listTokens = fundsData[msg.sender].allowedTokens;
        for (uint i=0; i<_listTokens.length; i++) {
            if(_listTokens[i] == _token) {
                allowed = true;   
            }
        }
    }

    function getAllowedTokens() external view onlyStarted() returns(IERC20[] memory allowedTokens) {
        allowedTokens = fundsData[msg.sender].allowedTokens;
    }
}