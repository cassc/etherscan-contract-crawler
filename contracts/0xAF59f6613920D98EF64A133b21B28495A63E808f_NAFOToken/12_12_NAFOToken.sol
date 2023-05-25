// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';

contract NAFOToken is ERC20, Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public _WETH;
    uint256 public lockedDonate = 0;
    uint256 public donatedTotal = 0;
    uint256 public fee = 4;
    uint256 private limitDiv = 1;

    mapping(address => uint256) pools;

    constructor(uint256 initialSupply, string memory _name, string memory _symbol, address _token) ERC20(_name, _symbol) {
        _mint(_msgSender(), initialSupply);
        _WETH = _token;
    }

    // Check address fee
    function checkPool (
        address _pool
    ) public view returns (
            uint256
        )
    {
        return pools[_pool];
    }

    // Check current transfer limit
    function getLimit () 
        public view returns (
            uint256
        )
    {
        if (limitDiv == 1) {
            return 199124800000000000000000000000001;
        } else {
            return totalSupply().div(limitDiv);
        }
    }

    // Withdraw token to charity
    function sendDonate (
        uint256 _amount,
        address _to
    )   external onlyOwner
    {
        require(_amount > 0, "Not enought token");
        require(lockedDonate >= _amount, "Not enought token");
        _mint(_to, _amount);
        _unlockDonate(_amount);
    }

    // Initial Uniswap pools with WETH
    function initialPool ()
       external onlyOwner
    {
        require(limitDiv == 1);
        //Create a uniswap V2 pair for this new token
        _setFee(IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f).createPair(
            _WETH,
            address(this)
        ));

        //Create a uniswap V3 pair 0.3% fee
        _setFee(IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984).createPool(
            address(this),
            _WETH,
            3000
        ));
    }

    // Set anti whale limit after lock pool
    function setAmountLimit ()
       external onlyOwner
    {
        _setLimit(100);
    }

    // Set Uni Pool
    function addUniPool (
        address _pool
    )
       external onlyOwner
    {
        require(checkPool(_pool) == 0, "Pool exists");
        _setFee(_pool);
    }

    // Override ERC20 transfer token rule
    function _beforeTokenTransfer (
        address ,
        address ,
        uint256 amount
    ) internal override {
        require(amount < getLimit(), "Amount limited");
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (from != address(0) && checkPool(from) != 0) {
            _burn(to, amount.div(100).mul(fee));
            _newDonate(amount.div(100).mul(fee));
        }
    }

    // Set Limits
    function _setLimit (
        uint256 _div
    )   internal 
    {
        limitDiv = _div;
    }

    function _setFee (
        address _pool
    )   internal 
    {
        pools[_pool] = fee;
    }

    function _newDonate (
        uint256 _amount
    ) internal {
        lockedDonate = lockedDonate.add(_amount);
        donatedTotal = donatedTotal.add(_amount);
    }

    function _unlockDonate (
        uint256 _amount
    ) internal {
        lockedDonate = lockedDonate.sub(_amount);
    }
}