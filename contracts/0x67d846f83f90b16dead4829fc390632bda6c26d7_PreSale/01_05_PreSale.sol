//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {ERC20} from "./libraries/solmate/ERC20.sol";

contract PreSale is Ownable {
    using SafeMath for uint256;

    struct PoolInfo {
        ERC20 token;
        uint256 decimals;
        uint256 rate;
    }

    ERC20 public MemeLisa;
    PoolInfo[] public poolInfo;

    address public recipient = 0xca0A878A2403349BEEe17C47D4EFdc3ED90B1D4C;
    address public treasury = 0x3b6869106b4F747fB36bB94f7089165AdD128365;

    event Swap(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(ERC20 _MemeLisa) {
        MemeLisa = _MemeLisa;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    modifier onlyOwnerOrGovernance() {
        require(
            owner() == _msgSender(),
            "Caller is not the owner, neither governance"
        );
        _;
    }

    function add(
        ERC20 _token,
        uint256 _rate
    ) public onlyOwnerOrGovernance {
        poolInfo.push(
            PoolInfo({token: _token, decimals: _token.decimals(), rate: _rate})
        );
    }

    function updateRate(
        uint256 _pid,
        uint256 _rate
    ) public onlyOwnerOrGovernance {
        PoolInfo storage pool = poolInfo[_pid];
        pool.rate = _rate;
    }

    function stopSale() public onlyOwnerOrGovernance {
        uint256 balance = MemeLisa.balanceOf(address(this));
        safeTransfer(address(treasury), balance);
    }

    function swap(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        uint256 decimals = 10 ** (18 - uint256(pool.decimals));

        uint256 amount = _amount.mul(pool.rate).mul(decimals);
        pool.token.transferFrom(msg.sender, address(recipient), _amount);
        safeTransfer(msg.sender, amount);

        emit Swap(msg.sender, _pid, _amount);
    }

    function safeTransfer(address _to, uint256 _amount) internal {
        uint256 balance = MemeLisa.balanceOf(address(this));
        if (_amount > balance) {
            MemeLisa.transfer(_to, balance);
        } else {
            MemeLisa.transfer(_to, _amount);
        }
    }
}