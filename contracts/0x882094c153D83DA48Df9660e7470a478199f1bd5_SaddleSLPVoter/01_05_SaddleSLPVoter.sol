// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "SafeMath.sol";
import "IERC20.sol";
import "Address.sol";
import "SafeERC20.sol";

interface Controller {
    function vaults(address) external view returns (address);
    function rewards() external view returns (address);
}

/*

 A strategy must implement the following calls;
 
 - deposit()
 - withdraw(address) must exclude any tokens used in the yield - Controller role - withdraw should return to Controller
 - withdraw(uint) - Controller | Vault role - withdraw should always return to vault
 - withdrawAll() - Controller | Vault role - withdraw should always return to vault
 - balanceOf()
 
 Where possible, strategies must remain as immutable as possible, instead of updating variables, we update the contract by linking it in the controller
 
*/

interface Gauge {
    function deposit(uint) external;
    function balanceOf(address) external view returns (uint);
    function withdraw(uint) external;
}

interface Mintr {
    function mint(address) external;
}

interface Uni {
    function swapExactTokensForTokens(uint, uint, address[] calldata, address, uint) external;
}

interface yERC20 {
  function deposit(uint256 _amount) external;
  function withdraw(uint256 _amount) external;
}

interface ICurveFi {

  function get_virtual_price() external view returns (uint);
  function add_liquidity(
    uint256[4] calldata amounts,
    uint256 min_mint_amount
  ) external;
  function remove_liquidity_imbalance(
    uint256[4] calldata amounts,
    uint256 max_burn_amount
  ) external;
  function remove_liquidity(
    uint256 _amount,
    uint256[4] calldata amounts
  ) external;
  function exchange(
    int128 from, int128 to, uint256 _from_amount, uint256 _min_to_amount
  ) external;
}

interface VoteEscrow {
    function create_lock(uint, uint) external;
    function increase_amount(uint) external;
    function withdraw() external;
}

contract SaddleSLPVoter {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;
    
    address constant public want = address(0x0C6F06b32E6Ae0C110861b8607e67dA594781961); //Sushiswap: SDL/WETH
    address constant public pool = address(0xc64F8A9fe7BabecA66D3997C9d15558BF4817bE3); //Saddle.finance: SLP liquidity gauge
    address constant public mintr = address(0x358fE82370a1B9aDaE2E3ad69D6cF9e503c96018); // Saddle.finance: minter
    address constant public sdl = address(0xf1Dc500FdE233A4055e25e5BbF516372BC4F6871);
    
    address constant public escrow = address(0xD2751CdBED54B87777E805be36670D7aeAe73bb2); //veSDL
    
    address public governance;
    address public strategy;
    
    constructor() {
        governance = msg.sender;
    }
    
    function getName() external pure returns (string memory) {
        return "SaddleSLPVoter";
    }
    
    function setStrategy(address _strategy) external {
        require(msg.sender == governance, "!governance");
        strategy = _strategy;
    }
    
    function deposit() public {
        uint _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(pool, 0);
            IERC20(want).safeApprove(pool, _want);
            Gauge(pool).deposit(_want);
        }
    }
    
    // Controller only function for creating additional rewards from dust
    function withdraw(IERC20 _asset) external returns (uint balance) {
        require(msg.sender == strategy, "!controller");
        balance = _asset.balanceOf(address(this));
        _asset.safeTransfer(strategy, balance);
    }
    
    // Withdraw partial funds, normally used with a vault withdrawal
    function withdraw(uint _amount) external {
        require(msg.sender == strategy, "!controller");
        uint _balance = IERC20(want).balanceOf(address(this));
        if (_balance < _amount) {
            _amount = _withdrawSome(_amount.sub(_balance));
            _amount = _amount.add(_balance);
        }
        IERC20(want).safeTransfer(strategy, _amount);
    }
    
    // Withdraw all funds, normally used when migrating strategies
    function withdrawAll() external returns (uint balance) {
        require(msg.sender == strategy, "!controller");
        _withdrawAll();
        
        
        balance = IERC20(want).balanceOf(address(this));
        IERC20(want).safeTransfer(strategy, balance);
    }
    
    function _withdrawAll() internal {
        Gauge(pool).withdraw(Gauge(pool).balanceOf(address(this)));
    }
    
    function createLock(uint _value, uint _unlockTime) external {
        require(msg.sender == strategy || msg.sender == governance, "!authorized");
        IERC20(sdl).safeApprove(escrow, 0);
        IERC20(sdl).safeApprove(escrow, _value);
        VoteEscrow(escrow).create_lock(_value, _unlockTime);
    }
    
    function increaseAmount(uint _value) external {
        require(msg.sender == strategy || msg.sender == governance, "!authorized");
        IERC20(sdl).safeApprove(escrow, 0);
        IERC20(sdl).safeApprove(escrow, _value);
        VoteEscrow(escrow).increase_amount(_value);
    }
    
    function release() external {
        require(msg.sender == strategy || msg.sender == governance, "!authorized");
        VoteEscrow(escrow).withdraw();
    }
    
    function _withdrawSome(uint256 _amount) internal returns (uint) {
        Gauge(pool).withdraw(_amount);
        return _amount;
    }
    
    function balanceOfWant() public view returns (uint) {
        return IERC20(want).balanceOf(address(this));
    }
    
    function balanceOfPool() public view returns (uint) {
        return Gauge(pool).balanceOf(address(this));
    }
    
    function balanceOf() public view returns (uint) {
        return balanceOfWant()
               .add(balanceOfPool());
    }
    
    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }
    
    function execute(address to, uint _value, bytes calldata _data) external returns (bool, bytes memory) {
        require(msg.sender == strategy || msg.sender == governance, "!governance");
        (bool success, bytes memory result) = to.call{value: _value}(_data);
        
        return (success, result);
    }
}