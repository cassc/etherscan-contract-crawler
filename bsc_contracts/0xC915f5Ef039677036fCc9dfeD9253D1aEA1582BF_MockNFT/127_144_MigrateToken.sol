// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/proxy/Initializable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '../interfaces/IMasterChefV3.sol';

contract MigrateToken is ERC20, Initializable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    event SkipBalanceChanged(address account, bool available);
    event BlacklistChanged(address account, bool available);

    IMasterChefV3 public immutable masterChef;
    address public immutable masterChefMigrator;
    uint public pid;
    IERC20 public baseToken;
    //if skipBalance, then if we fetch the balance of the user, it always returns 0
    //but we can use the realBalanceOf(address) method to get the balance
    mapping(address => bool) public skipBalance;
    //the user can only withdraw once, that's emergencyWithdraw. if the user through
    //withdraw or leaveStaking and not all the amount. then he will never get his amount
    mapping(address => uint) public userWithdrawed;
    mapping(address => bool) public blacklist;

    constructor(string memory _name, string memory _symbol, IMasterChefV3 _masterChef, address _masterChefMigrator) ERC20(_name, _symbol) {
        require(address(_masterChef) != address(0), "illegal masterChef");
        masterChef = _masterChef;
        require(address(_masterChefMigrator) != address(0), "illegal masterChefMigrator address");
        masterChefMigrator = _masterChefMigrator;
    }

    modifier onlyMigrator() {
        require(msg.sender == masterChefMigrator, "only migrator can do this");
        _;
    }

    function initialize(uint _pid, IERC20 _baseToken) external initializer onlyMigrator {
        pid = _pid;
        (IERC20 lp, , , ) = masterChef.poolInfo(_pid);
        require(lp == _baseToken, "illegal baseToken");
        baseToken = _baseToken;
    }

    function setSkipBalance(address _account, bool _available) external onlyMigrator {
        skipBalance[_account] = _available;
        emit SkipBalanceChanged(_account, _available);
    }

    function addBlacklist(address _account) external onlyMigrator {
        blacklist[_account] = true;
        emit BlacklistChanged(_account, true);
    }

    function delBlacklist(address _account) external onlyMigrator {
        delete blacklist[_account];
        emit BlacklistChanged(_account, false);
    }

    function doMigrate() external onlyMigrator {
        uint balance = baseToken.balanceOf(address(this));
        _mint(address(masterChef), balance);
    }

    function unDoMigrate() external onlyMigrator {
        uint balance = balanceOf(address(masterChef));
        baseToken.approve(masterChefMigrator, balance);
        _burn(address(masterChef), balance);
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(!blacklist[recipient], "in blacklist");
        require(msg.sender == address(masterChef), "only masterChef can do this");
        (uint userAmount, ) = masterChef.userInfo(pid, recipient);
        //require(userAmount == 0 && amount > 0 && userWithdrawed[recipient] == 0, "illegal amount");
        require(amount > 0, "illegal amount");
        baseToken.safeTransfer(recipient, amount);
        _burn(address(masterChef), amount);
        userWithdrawed[recipient] += amount;
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        require(!blacklist[recipient], "in blacklist");
        require(msg.sender == address(masterChef) && sender == msg.sender, "only masterChef can do this");
        (uint userAmount, ) = masterChef.userInfo(pid, recipient);
        //require(userAmount == 0 && amount > 0 && userWithdrawed[recipient] == 0, "illegal amount");
        require(amount > 0, "illegal amount");
        baseToken.safeTransfer(recipient, amount);
        _burn(address(masterChef), amount);
        userWithdrawed[recipient] += amount;
        return true;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        if (skipBalance[address(masterChef)]) {
            return 0;
        } else {
            return ERC20.balanceOf(account);
        }
    }

    function realBalanceOf(address account) external view returns (uint256) {
        return ERC20.balanceOf(account);
    }

}