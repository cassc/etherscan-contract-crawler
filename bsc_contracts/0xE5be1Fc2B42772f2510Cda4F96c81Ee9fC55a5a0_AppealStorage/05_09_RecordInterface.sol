// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./RestStorage.sol";
import "./OrderStorage.sol";
import "./UserStorage.sol";
import "./RecordStorage.sol";
import "./AppealStorage.sol";
interface RecordInterface {
    function getErcBalance(string memory _coinType, address _addr)
        external
        returns (uint256);
    function getAvailableTotal(address _addr, string memory _coinType)
        external
        returns (uint256);
    function getFrozenTotal(address _addr, string memory _coinType)
        external
        returns (uint256);
    function addAvailableTotal(
        address _addr,
        string memory _coinType,
        uint256 remainHoldCoin
    ) external;
    function subAvaAppeal(
        address _from,
        address _to,
        AppealStorage.Appeal memory _al,
        uint256 _amt,
        uint256 _type,
        uint256 _self
    ) external;
    function subWitnessAvailable(address _addr) external;
    function getERC20Address(string memory _coinType)
        external
        returns (TokenTransfer);
    function subFrozenTotal(uint256 _orderNo, address _addr) external;
    function addRecord(
        address _addr,
        string memory _tradeHash,
        string memory _coinType,
        uint256 _hostCount,
        uint256 _hostStatus,
        uint256 _hostType,
        uint256 _hostDirection
    ) external;
    function getAppealFee() external view returns (uint256);
    function getAppealFeeFinal() external view returns (uint256);
    function getWitnessHandleReward() external view returns (uint256);
    function getObserverHandleReward() external view returns (uint256);
    function getWitnessHandleCredit() external view returns (uint256);
    function getObserverHandleCredit() external view returns (uint256);
    function getSubWitCredit() external view returns (uint256);
    function getOpenTrade() external view returns (bool);
    function getTradeCredit() external view returns (uint256);
    function getSubTCredit() external view returns (uint256);
    function getSubWitFee() external view returns (uint256);
    function getLPCoinPrive() external view returns (uint256);
}
interface RestInterface {
    function searchRest(uint256 _restNo)
        external
        returns (RestStorage.Rest memory rest);
    function getRestFrozenTotal(address _addr, uint256 _restNo)
        external
        returns (uint256);
    function updateRestFinishCount(uint256 _restNo, uint256 _coinCount)
        external
        returns (uint256);
    function addRestRemainCount(uint256 _restNo, uint256 _remainCount)
        external
        returns (uint256);
}
interface OrderInterface {
    function searchOrder(uint256 _orderNo)
        external
        returns (OrderStorage.Order memory order);
}
interface UserInterface {
    function searchUser(address _addr)
        external
        view
        returns (UserStorage.User memory user);
    function searchUserList(uint256 _userFlag)
        external
        returns (UserStorage.User[] memory userList);
    function updateTradeStats(
        address _addr,
        UserStorage.TradeStats memory _tradeStats,
        uint256 _credit
    ) external;
    function updateMorgageStats(
        address _addr,
        UserStorage.MorgageStats memory _morgageStats
    ) external;
    function updateUserRole(address _addr, uint256 _userFlag) external;
}
interface AppealInterface {
    function searchAppeal(uint256 _o)
        external
        view
        returns (AppealStorage.Appeal memory appeal);
}
