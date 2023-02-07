// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '../interfaces/IMasterChefV3.sol';
import '../interfaces/IMigrateToken.sol';
import '../core/SafeOwnable.sol';

contract MasterChefMigrator is SafeOwnable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event MigrateTokenChanged(uint pid, IERC20 baseToken, IERC20 migrateToken, bool available);
    event DoMigrate(uint pid, IERC20 baseToken, IERC20 migrateToken, uint amount, bool migrated);

    enum TokenType {
        NONE,
        BASE_TOKEN,
        MIGRATE_TOKEN
    }
    struct MigrateTokenInfo {
        IERC20 baseToken;
        IERC20 migrateToken;
        bool migrated;
        uint migrateAmount;
        uint pid;
    }

    IMasterChefV3 immutable public masterChef;
    //each pool has two tokens:
    //  baseToken: is the token of the pool before migrate
    //  migrateToken: is the token of the pool after migrate
    //  all the two token need to record the same information,
    //  for we should fetch the information by baseToken or migrateToken
    mapping(IERC20 => TokenType) public tokenType;
    mapping(IERC20 => MigrateTokenInfo) public migrateTokenInfos;

    constructor(IMasterChefV3 _masterChef) {
        require(address(_masterChef) != address(0), "illegal masterChef");
        masterChef = _masterChef;
    }

    function addMigrateToken(uint _pid, IERC20 _migrateToken) external onlyOwner {
        (IERC20 baseToken, , , ) = masterChef.poolInfo(_pid);
        require(address(baseToken) != address(0) && address(_migrateToken) != address(0) && baseToken != _migrateToken, "illegal token");
        require(tokenType[baseToken] == TokenType.NONE && tokenType[_migrateToken] == TokenType.NONE, "already migrate");
        tokenType[baseToken] = TokenType.BASE_TOKEN;
        tokenType[_migrateToken] = TokenType.MIGRATE_TOKEN;
        migrateTokenInfos[baseToken] = MigrateTokenInfo({
            baseToken: baseToken,
            migrateToken: _migrateToken,
            migrated: false,
            migrateAmount: 0,
            pid: _pid
        });
        migrateTokenInfos[_migrateToken] = MigrateTokenInfo({
            baseToken: baseToken,
            migrateToken: _migrateToken,
            migrated: false,
            migrateAmount: 0,
            pid: _pid
        });
        IMigrateToken(address(_migrateToken)).initialize(_pid, baseToken);
        emit MigrateTokenChanged(_pid, baseToken, _migrateToken, true);
    }

    function delMigrateToken(uint _pid) external onlyOwner {
        (IERC20 baseToken, , , ) = masterChef.poolInfo(_pid);
        require(address(baseToken) != address(0), "illegal token");
        require(tokenType[baseToken] == TokenType.BASE_TOKEN, "illegal tokenType");
        MigrateTokenInfo memory migrateTokenInfo = migrateTokenInfos[baseToken];
        require(migrateTokenInfo.baseToken == baseToken, "illegal info");
        IERC20 migrateToken = migrateTokenInfo.migrateToken;
        require(!migrateTokenInfo.migrated && migrateTokenInfo.migrateAmount == 0 && migrateTokenInfo.pid == _pid, "illegal info");
        delete tokenType[baseToken];
        delete tokenType[migrateToken];
        delete migrateTokenInfos[baseToken];
        delete migrateTokenInfos[migrateToken];
        emit MigrateTokenChanged(_pid, baseToken, migrateToken, false);
    }

    function openSkipBalance(IMigrateToken _token, address _account) external onlyOwner {
        _token.setSkipBalance(_account, true); 
    }

    function closeSkipBalance(IMigrateToken _token, address _account) external onlyOwner {
        _token.setSkipBalance(_account, false);
    }

    function migrate(IERC20 _token) external returns (IERC20) {
        require(tx.origin == owner() && msg.sender == address(masterChef), "only master chef can do this");
        if (tokenType[_token] == TokenType.BASE_TOKEN) {
            MigrateTokenInfo memory migrateTokenInfo = migrateTokenInfos[_token];
            require(!migrateTokenInfo.migrated && address(migrateTokenInfo.baseToken) != address(0), "already migrated");
            uint amount = _token.balanceOf(address(masterChef));
            require(amount > 0, "balance is zero");
            IERC20 baseToken = migrateTokenInfo.baseToken;
            IERC20 migrateToken = migrateTokenInfo.migrateToken;
            (IERC20 lp, , , ) = masterChef.poolInfo(migrateTokenInfo.pid);
            require(lp == _token && baseToken == _token, "token mismatch");
            _token.safeTransferFrom(address(masterChef), address(migrateToken), amount);
            migrateTokenInfos[baseToken].migrated = true;
            migrateTokenInfos[baseToken].migrateAmount = amount;
            migrateTokenInfos[migrateToken].migrated = true;
            migrateTokenInfos[migrateToken].migrateAmount = amount;
            IMigrateToken(address(migrateToken)).doMigrate();
            emit DoMigrate(migrateTokenInfo.pid, baseToken, migrateToken, amount, true);
            return migrateToken;
        } else if (tokenType[_token] == TokenType.MIGRATE_TOKEN) {
            MigrateTokenInfo memory migrateTokenInfo = migrateTokenInfos[_token];
            require(migrateTokenInfo.migrated && address(migrateTokenInfo.baseToken) != address(0), "not migrated");
            uint amount = _token.balanceOf(address(masterChef));
            require(amount > 0, "balance is zero");
            IERC20 baseToken = migrateTokenInfo.migrateToken;
            IERC20 migrateToken = migrateTokenInfo.baseToken;
            (IERC20 lp, , , ) = masterChef.poolInfo(migrateTokenInfo.pid);
            require(lp == _token && baseToken == _token, "token mismatch");
            IMigrateToken(address(baseToken)).unDoMigrate(); 
            migrateToken.safeTransferFrom(address(baseToken), address(masterChef), amount);
            migrateTokenInfos[baseToken].migrated = false;
            migrateTokenInfos[baseToken].migrateAmount = 0;
            migrateTokenInfos[migrateToken].migrated = false;
            migrateTokenInfos[migrateToken].migrateAmount = 0;
            emit DoMigrate(migrateTokenInfo.pid, migrateToken, baseToken, amount, false);
            return migrateToken;
        } else {
            revert("illegal token");
        }
    }
}