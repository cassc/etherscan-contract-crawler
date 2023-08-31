// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./IIndexStruct.sol";

interface IndexInterface is IndexStruct {
    function udpateIndex(uint16[] calldata _percentages) external;

    function transferOwnership(address newOwner) external;

    function viewaddress() external view returns (address);

    function updatePercent(uint16[] calldata _percentages) external;

    function updatetokens(address[] calldata _tokens) external;

    function getCurrentTokensInfo()
        external
        view
        returns (address[] calldata, uint16[] calldata);

    function getPreviousTokensInfo()
        external
        view
        returns (address[] calldata, uint16[] calldata);

    function deposit(uint amountin, address depositer) external;

    function indextokenbalance() external view returns (uint[] calldata);

    function purchase(uint amount, uint[] calldata slippageallowed) external;

    function sell(
        uint[] calldata amounts,
        uint[] calldata slippageallowed
    ) external;

    function rebalanceSell(
        uint[] calldata amounts,
        uint[] calldata slippageallowed
    ) external;

    function rebalancePurchase(
        uint amount,
        uint[] calldata slippageallowed
    ) external;

    function getPurchaseToken() external returns (address _ptoken);

    function initialize(
        IndexData calldata _index,
        address _dex,
        FeeData memory _feedata,
        uint minPtokenVal
    ) external;

    function updateIndexOwner(address newowner) external;

    function distributeAmount(uint numofwithdrawers) external;

    function returnstates() external view returns (State memory currentstate);

    function tokensbalances() external view returns (uint[] memory);

    function setmanagementfeeaddress(address _managementfeeaddress) external;

    function setperformancefeeaddress(address _performancefeeaddress) external;

    function tokensBalances() external view returns (uint[] memory);

    function pTokenBalance() external view returns (uint);

    function totalDeposit() external view returns (uint);

    function getDepositByUser(address user) external view returns (uint);

    function distributeBeforePurchase(uint n) external;

    function updateSellState() external;

    function updatePurchaseState() external;

    function updateRebalanceSellState() external;

    function updateTokenUpdateState() external;

    function updateRebalancePurchaseState() external;

    function userLeftToWithdraw() external view returns (uint users);

    function updateDex(address _dex) external;

    function getCurrenttokens() external returns (address[] memory);

    function performaneFeesTransfer() external;

    function feeData() external view returns (FeeData memory);

    function state() external view returns (State memory);

    function percentages() external view returns (uint16[] memory);

    function previousPercentageArray() external view returns (uint16[] memory);

    function currentPercentageArray() external view returns (uint16[] memory);

    function tokensLength() external view returns (uint);

    function indexTokens() external view returns (address[] memory);
}