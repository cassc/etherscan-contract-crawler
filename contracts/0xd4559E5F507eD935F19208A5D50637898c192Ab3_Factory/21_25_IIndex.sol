// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./IIndexStruct.sol";

interface IndexInterface is IndexStruct {
    // will return the index info

    // will update the index with the supplied inputs, can only be called by factory contract
    function udpateindex(
        uint16[] calldata _percentages,
        address[] calldata _tokens
    ) external;

    function viewaddress() external view returns (address);

    function updatename(string calldata _name) external;

    function updatepercent(uint16[] calldata _percentages) external;

    function updatetokens(address[] calldata _tokens) external;

    // returns index info after destructuring
    function getCurrentTokensInfo()
        external
        view
        returns (address[] calldata, uint16[] calldata);

    function getPreviousTokensInfo()
        external
        view
        returns (address[] calldata, uint16[] calldata);

    function deposit(uint256 amountin, address depositer) external;

    function indextokenbalance() external view returns (uint256[] calldata);

    function purchase(
        uint256 amount,
        uint256[] calldata slippageallowed
    ) external;

    function sell(
        uint256[] calldata amounts,
        uint256[] calldata slippageallowed
    ) external;

    function rebalancesell(
        uint256[] calldata amounts,
        uint256[] calldata slippageallowed
    ) external;

    function rebalancepurchase(
        uint256 amount,
        uint256[] calldata slippageallowed
    ) external;

    function getpurchasetoken() external returns (address _ptoken);

    function initialize(
        uint16[] memory _percentages,
        address[] memory _tokens,
        uint256 _thresholdamout,
        uint256 _depositendingtime,
        uint256 _indexendingtime,
        address _ptoken,
        address _dex,
        feeData memory _feedata
    ) external;

    function updateindexowner(address newowner) external;

    function distributeamount(uint n) external;

    function returnstates() external view returns (State memory currentstate);

    function unstake(address token, address target, bytes memory data) external;

    function stakewithapprove(
        address token,
        address target,
        bytes memory data
    ) external;

    function approvetoken(
        address _stakingContract,
        address token,
        uint256 amount
    ) external;

    function anycontractcall(
        address target,
        string calldata _func,
        bytes memory _data
    ) external;

    function addrewardtokens(address token) external;

    function setmanagementfeeaddress(address _managementfeeaddress) external;

    function setperformancefeeaddress(address _performancefeeaddress) external;

    function currenttokenbalance() external view returns (uint256[] memory);

    function previoustokenbalance() external view returns (uint256[] memory);

    function ptokenbalance() external view returns (uint256);

    function gettotaldeposit() external view returns (uint256);

    function getdepositbyuser(address user) external view returns (uint256);

    function sellrewardtokens(
        uint256[] calldata _amounts,
        uint256[] calldata allowedslippage
    ) external;

    function rewardtokenbalance() external view returns (uint256[] memory);

    function distributebeforepurchase(uint n) external;

    function updatesellstate() external;

    function updatepurchasestate() external;

    function updaterebalancesellstate() external;

    function updatetokenupdatestate() external;

    function updaterebalancepurchasestate() external;

    function userlefttowithdraw() external view returns (uint users);

    function updatedex(address _dex) external;
}