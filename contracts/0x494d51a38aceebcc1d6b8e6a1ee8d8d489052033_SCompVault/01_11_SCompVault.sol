// SPDX-License-Identifier: ISC

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../controller/interface/IController.sol";
import "./ERC20SCompVault.sol";

contract SCompVault is ERC20SCompVault {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    IERC20 public token;

    uint256 public min = 9500;
    uint256 public constant max = 10000;

    address public governance;
    address public controller;

    address public treasuryFee;
    uint public depositFee; // 1500 -> 15% ; 150 -> 1.5% ; 15 -> 0.15
    uint256 public constant MAX_FEE = 10000;

    event Deposit(address indexed _receiver, uint _amount, uint256 _timestamp);
    event Withdraw(address indexed _receiver, uint _amount, uint256 _timestamp);

    uint public constant MINIMUM_LIQUIDITY = 10**3;

    constructor(address _token, address _controller, address _treasuryFee, uint _depositFee)
    ERC20SCompVault(
        string(abi.encodePacked("sComp ", ERC20SCompVault(_token).name())),
        string(abi.encodePacked("s", ERC20SCompVault(_token).symbol()))
    )
    {
        token = IERC20(_token);
        governance = msg.sender;
        controller = _controller;
        depositFee = _depositFee;
        treasuryFee = _treasuryFee;

    }

    function balance() public view returns (uint256) {
        return token.balanceOf(address(this)).add(IController(controller).balanceOf(address(token)));
    }

    function setMin(uint256 _min) external {
        require(msg.sender == governance, "SCompVault: !governance");
        min = _min;
    }

    function setGovernance(address _governance) public {
        require(msg.sender == governance, "SCompVault: !governance");
        governance = _governance;
    }

    function setController(address _controller) public {
        require(msg.sender == governance, "SCompVault: !governance");
        controller = _controller;
    }

    // Custom logic in here for how much the vault allows to be borrowed
    // Sets minimum required on-hand to keep small withdrawals cheap
    function available() public view returns (uint256) {
        return token.balanceOf(address(this)).mul(min).div(max);
    }

    function earn() public {
        uint256 _bal = available();
        token.safeTransfer(controller, _bal);
        IController(controller).earn(address(token), _bal);
    }

    function depositAll() external returns(uint){
        return deposit(token.balanceOf(msg.sender));
    }

    function deposit(uint256 _amount) public returns(uint) {
        uint256 _pool = balance();

        // deposit fee
        if(depositFee > 0) {
            uint256 amountFee =
            _amount.mul(depositFee).div(
                MAX_FEE
            );
            token.safeTransferFrom(msg.sender, treasuryFee, amountFee);
            _amount = _amount - amountFee;
        }

        uint256 _before = token.balanceOf(address(this));
        token.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 _after = token.balanceOf(address(this));
        _amount = _after.sub(_before); // Additional check for deflationary tokens
        uint256 shares = 0;
        if (totalSupply() == 0) {
            shares = _amount - MINIMUM_LIQUIDITY;
            _mint(address(0), MINIMUM_LIQUIDITY);
        } else {
            shares = (_amount.mul(totalSupply())).div(_pool);
        }
        _mint(msg.sender, shares);

        emit Deposit(msg.sender, shares, block.timestamp);

        return shares;
    }

    function depositAllFor(address _receiver) external returns(uint){
        return depositFor(token.balanceOf(msg.sender), _receiver);
    }

    function depositFor(uint256 _amount, address _receiver) public returns(uint) {
        uint256 _pool = balance();

        // deposit fee
        if(depositFee > 0) {
            uint256 amountFee =
            _amount.mul(depositFee).div(
                MAX_FEE
            );
            token.safeTransferFrom(msg.sender, treasuryFee, amountFee);
            _amount = _amount - amountFee;
        }

        uint256 _before = token.balanceOf(address(this));
        token.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 _after = token.balanceOf(address(this));
        _amount = _after.sub(_before); // Additional check for deflationary tokens
        uint256 shares = 0;
        if (totalSupply() == 0) {
            shares = _amount;
        } else {
            shares = (_amount.mul(totalSupply())).div(_pool);
        }
        _mint(_receiver, shares);

        emit Deposit(_receiver, shares, block.timestamp);

        return shares;
    }

    function withdrawAll() external returns(uint) {
        return withdraw(balanceOf(msg.sender));
    }


    // No rebalance implementation for lower fees and faster swaps
    function withdraw(uint256 _shares) public returns(uint) {
        uint256 r = (balance().mul(_shares)).div(totalSupply());
        _burn(msg.sender, _shares);

        // Check balance
        uint256 b = token.balanceOf(address(this));
        if (b < r) {
            uint256 _withdraw = r.sub(b);
            IController(controller).withdraw(address(token), _withdraw);
            uint256 _after = token.balanceOf(address(this));
            uint256 _diff = _after.sub(b);
            if (_diff < _withdraw) {
                r = b.add(_diff);
            }
        }

        token.safeTransfer(msg.sender, r);
        emit Withdraw(msg.sender, r, block.timestamp);

        return r;
    }

    function withdrawAllFor(address _receiver) external returns(uint) {
        return withdrawFor(balanceOf(msg.sender), _receiver);
    }


    // No rebalance implementation for lower fees and faster swaps
    function withdrawFor(uint256 _shares, address _receiver) public returns(uint) {
        uint256 r = (balance().mul(_shares)).div(totalSupply());
        _burn(msg.sender, _shares);

        // Check balance
        uint256 b = token.balanceOf(address(this));
        if (b < r) {
            uint256 _withdraw = r.sub(b);
            IController(controller).withdraw(address(token), _withdraw);
            uint256 _after = token.balanceOf(address(this));
            uint256 _diff = _after.sub(b);
            if (_diff < _withdraw) {
                r = b.add(_diff);
            }
        }

        token.safeTransfer(_receiver, r);
        emit Withdraw(_receiver, r, block.timestamp);

        return r;
    }

    // this function is supposed to use only for the zapper contract
    function withdrawOneClick(uint256 _shares, address _receiver) public returns(uint) {
        uint256 r = (balance().mul(_shares)).div(totalSupply());
        _burn(msg.sender, _shares);

        // Check balance
        uint256 b = token.balanceOf(address(this));
        if (b < r) {
            uint256 _withdraw = r.sub(b);
            IController(controller).withdraw(address(token), _withdraw);
            uint256 _after = token.balanceOf(address(this));
            uint256 _diff = _after.sub(b);
            if (_diff < _withdraw) {
                r = b.add(_diff);
            }
        }

        token.safeTransfer(msg.sender, r);
        emit Withdraw(_receiver, r, block.timestamp);

        return r;
    }

    // Used to swap any borrowed reserve ovaer the debt limit to liquidate to 'token'
    function harvest(address reserve, uint256 amount) external {
        require(msg.sender == controller, "!controller");
        require(reserve != address(token), "token");
        IERC20(reserve).safeTransfer(controller, amount);
    }

    function getPricePerFullShare() public view returns (uint256) {
        if(totalSupply() == 0) {
            return 1e18;
        }
        return balance().mul(1e18).div(totalSupply());
    }
}