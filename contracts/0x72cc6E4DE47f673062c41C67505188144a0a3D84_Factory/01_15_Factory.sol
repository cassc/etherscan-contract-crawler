/*
██   ██ ██████   █████   ██████      ███████  █████   ██████ ████████  ██████  ██████  ██    ██ 
 ██ ██  ██   ██ ██   ██ ██    ██     ██      ██   ██ ██         ██    ██    ██ ██   ██  ██  ██  
  ███   ██   ██ ███████ ██    ██     █████   ███████ ██         ██    ██    ██ ██████    ████   
 ██ ██  ██   ██ ██   ██ ██    ██     ██      ██   ██ ██         ██    ██    ██ ██   ██    ██    
██   ██ ██████  ██   ██  ██████      ██      ██   ██  ██████    ██     ██████  ██   ██    ██    
*/
// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./Dao.sol";

contract Factory is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;

    address public immutable shop;

    address public immutable xdao;

    mapping(address => uint256) public subscriptions;

    uint256 public monthlyCost;

    uint256 public freeTrial;

    function subscribe(address _dao) external returns (bool) {
        require(daos.contains(_dao));

        if (subscriptions[_dao] < block.timestamp) {
            subscriptions[_dao] = block.timestamp + 30 days;
        } else {
            subscriptions[_dao] += 30 days;
        }

        IERC20(xdao).safeTransferFrom(msg.sender, owner(), monthlyCost);

        return true;
    }

    function changeMonthlyCost(uint256 _m) external onlyOwner returns (bool) {
        monthlyCost = _m;

        return true;
    }

    function changeFreeTrial(uint256 _freeTrial)
        external
        onlyOwner
        returns (bool)
    {
        freeTrial = _freeTrial;

        return true;
    }

    event DaoCreated(address indexed dao);

    constructor(address _shop, address _xdao) {
        shop = _shop;
        xdao = _xdao;
    }

    EnumerableSet.AddressSet private daos;

    function create(
        string memory _daoName,
        string memory _daoSymbol,
        uint8 _quorum,
        address[] memory _partners,
        uint256[] memory _shares
    ) external returns (bool) {
        Dao dao = new Dao(_daoName, _daoSymbol, _quorum, _partners, _shares);

        subscriptions[address(dao)] = block.timestamp + freeTrial;

        require(daos.add(address(dao)));

        emit DaoCreated(address(dao));

        return true;
    }

    /*----VIEW FUNCTIONS---------------------------------*/

    function daoAt(uint256 _i) external view returns (address) {
        return daos.at(_i);
    }

    function containsDao(address _dao) external view returns (bool) {
        return daos.contains(_dao);
    }

    function numberOfDaos() external view returns (uint256) {
        return daos.length();
    }

    function getDaos() external view returns (address[] memory) {
        uint256 daosLength = daos.length();

        if (daosLength == 0) {
            return new address[](0);
        } else {
            address[] memory daosArray = new address[](daosLength);

            for (uint256 i = 0; i < daosLength; i++) {
                daosArray[i] = daos.at(i);
            }

            return daosArray;
        }
    }
}