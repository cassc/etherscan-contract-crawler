// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is disstributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.6.12;
import "../base/WhiteToken.sol";
import "../base/LiquidityPool.sol";
import "../interfaces/IBFactory.sol";
import "../libraries/SafeERC20.sol";

contract Factory is BBronze, WhiteToken {
    using SafeERC20 for IERC20;

    event LOG_NEW_POOL(address indexed caller, address indexed pool);
    event LOG_BLABS(address indexed caller, address indexed blabs);
    event LOG_ROUTER(address indexed caller, address indexed router);
    event LOG_VAULT(address indexed vault, address indexed caller);
    event LOG_USER_VAULT(address indexed vault, address indexed caller);
    event LOG_MANAGER(address indexed manager, address indexed caller);
    event LOG_ORACLE(address indexed caller, address indexed oracle);
    event MODULE_STATUS_CHANGE(address etf, address module, bool status);
    event PAUSED_STATUS(bool state);

    mapping(address => bool) private _isLiquidityPool;
    mapping(address => mapping(address => bool)) private _isModuleRegistered;
    uint private counters;
    bytes public bytecodes = type(LiquidityPool).creationCode;
    bool public isPaused;

    function addTokenToWhitelist(uint[] memory sort, address[] memory token) external onlyBlabs {
        require(sort.length == token.length, "ERR_SORT_TOKEN_MISMATCH");
        for (uint i = 0; i < sort.length; i++) {
            _addTokenToWhitelist(sort[i], token[i]);
        }
    }

    function removeTokenFromWhitelist(uint[] memory sort, address[] memory token) external onlyBlabs {
        require(sort.length == token.length, "ERR_SORT_TOKEN_MISMATCH");
        for (uint i = 0; i < sort.length; i++) {
            _removeTokenFromWhitelist(sort[i], token[i]);
        }
    }

    function isTokenWhitelistedForVerify(uint sort, address token) external view returns (bool) {
        return _isTokenWhitelistedForVerify(sort, token);
    }

    function isTokenWhitelistedForVerify(address token) external view returns (bool) {
        return _queryIsTokenWhitelisted(token);
    }

    function isLiquidityPool(address b) external view returns (bool) {
        return _isLiquidityPool[b];
    }

    function createPool() internal returns (address base) {
        bytes memory bytecode = bytecodes;
        bytes32 salt = keccak256(abi.encodePacked(counters++));

        assembly {
            base := create2(0, add(bytecode, 32), mload(bytecode), salt)
            if iszero(extcodesize(base)) {
                revert(0, 0)
            }
        }
        counters++;
    }

    function newLiquidityPool() external returns (IBPool) {
        address lpool = createPool();
        _isLiquidityPool[lpool] = true;
        emit LOG_NEW_POOL(msg.sender, lpool);
        IBPool(lpool).setController(msg.sender);
        return IBPool(lpool);
    }

    address private _blabs;
    address private _swapRouter;
    address private _vault;
    address private _oracle;
    address private _managerOwner;
    address private _vaultAddress;
    address private _userVaultAddress;

    constructor() public {
        _blabs = msg.sender;
    }

    function getBLabs() external view returns (address) {
        return _blabs;
    }

    function setBLabs(address b) external onlyBlabs {
        require(b != address(0),"ERR_ZERO_ADDRESS");
        emit LOG_BLABS(msg.sender, b);
        _blabs = b;
    }

    function getSwapRouter() external view returns (address) {
        return _swapRouter;
    }

    function getModuleStatus(address etf, address module) external view returns (bool) {
        return _isModuleRegistered[etf][module];
    }

    function getOracleAddress() external view returns (address) {
        return _oracle;
    }

    function setSwapRouter(address router) external onlyBlabs {
        require(router != address(0),"ERR_ZERO_ADDRESS");
        emit LOG_ROUTER(msg.sender, router);
        _swapRouter = router;
    }

    function registerModule(address etf, address module) external onlyBlabs {
        require(etf != address(0), "ZERO ETF ADDRESS");
        require(module != address(0), "ZERO ADDRESS");

        _isModuleRegistered[etf][module] = true;

        emit MODULE_STATUS_CHANGE(etf, module, true);
    }

    function removeModule(address etf, address module) external onlyBlabs {
        require(etf != address(0), "ZERO ETF ADDRESS");
        require(module != address(0), "ZERO ADDRESS");

        _isModuleRegistered[etf][module] = false;

        emit MODULE_STATUS_CHANGE(etf, module, false);
    }

    function setOracle(address oracle) external onlyBlabs {
        require(oracle != address(0),"ERR_ZERO_ADDRESS");
        emit LOG_ORACLE(msg.sender, oracle);
        _oracle = oracle;
    }

    function collect(IERC20 token) external onlyBlabs {
        uint collected = token.balanceOf(address(this));
        token.safeTransfer(_blabs, collected);
    }

    function getVault() external view returns (address) {
        return _vaultAddress;
    }

    function setVault(address newVault) external onlyBlabs {
        require(newVault != address(0),"ERR_ZERO_ADDRESS");
        _vaultAddress = newVault;
        emit LOG_VAULT(newVault, msg.sender);
    }

    function getUserVault() external view returns (address) {
        return _userVaultAddress;
    }

    function setUserVault(address newVault) external onlyBlabs {
        require(newVault != address(0),"ERR_ZERO_ADDRESS");
        _userVaultAddress = newVault;
        emit LOG_USER_VAULT(newVault, msg.sender);
    }

    function getManagerOwner() external view returns (address) {
        return _managerOwner;
    }

    function setManagerOwner(address newManagerOwner) external onlyBlabs {
        require(newManagerOwner != address(0),"ERR_ZERO_ADDRESS");
        _managerOwner = newManagerOwner;
        emit LOG_MANAGER(newManagerOwner, msg.sender);
    }

    function setProtocolPaused(bool state) external onlyBlabs {
        isPaused = state;
        emit PAUSED_STATUS(state);
    }

    modifier onlyBlabs() {
        require(msg.sender == _blabs, "ERR_NOT_BLABS");
        _;
    }
}