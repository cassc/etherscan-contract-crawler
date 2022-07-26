// SPDX-License-Identifier: MIT

/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity ^0.8.0;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { SafeMathUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { Multicall } from "./base/Multicall.sol";

interface IPool {
    function getCondition(bytes calldata _args) external view returns (uint256);
}

contract DepegShield is Multicall, Initializable, ReentrancyGuardUpgradeable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address public owner;
    address public governance;

    mapping(address => uint256[]) public routes; //  pool => (curve pool)

    event UpdateRoute(address indexed _pool, uint256[] routes);
    event SetOwner(address owner);
    event SetGovernance(address governance);

    modifier onlyOwner() {
        require(owner == msg.sender, "DepegShield: Caller is not the owner");
        _;
    }

    modifier onlyGovernance() {
        require(governance == msg.sender, "DepegShield: Caller is not the governance");
        _;
    }

    // @custom:oz-upgrades-unsafe-allow constructor
    // solhint-disable-next-line no-empty-blocks
    constructor() initializer {}

    function initialize(address _owner) external initializer {
        owner = _owner;
        governance = _owner;

        __ReentrancyGuard_init();
    }

    function setOwner(address _owner) public onlyOwner {
        owner = _owner;

        emit SetOwner(_owner);
    }

    function setGovernance(address _governance) public onlyOwner {
        governance = _governance;

        emit SetGovernance(_governance);
    }

    // solhint-disable-next-line no-empty-blocks
    // receive() external payable {}

    function updateRoute(address _curvePool, uint256[] calldata _routes) public onlyGovernance {
        delete routes[_curvePool];

        routes[_curvePool] = _routes;

        emit UpdateRoute(_curvePool, _routes);
    }

    function isTriggered(address _pool, bytes calldata _args) public view returns (bool) {
        uint256[] memory _routes = routes[_pool];

        require(_routes.length > 0, "DepegShield: Route unavailable");

        uint256 result;

        for (uint256 i = 0; i < _routes.length; i++) {
            result = _trigger(_routes[i], _args, result);
        }

        return result == 1 ? true : false;
    }

    function _trigger(
        uint256 _route,
        bytes calldata _args,
        uint256 _result
    ) internal view returns (uint256) {
        address pool = address(uint160(_route & uint256(1461501637330902918203684832716283019655932542975)));

        if (_result > 0) {
            uint256[] memory oldArgs = abi.decode(_args, (uint256[]));
            uint256[] memory newArgs = new uint256[](oldArgs.length + 1);

            for (uint256 i = 0; i < oldArgs.length; i++) {
                newArgs[i] = oldArgs[i];
            }

            newArgs[oldArgs.length] = _result;

            return IPool(pool).getCondition(abi.encode(newArgs));
        }

        return IPool(pool).getCondition(_args);
    }
}