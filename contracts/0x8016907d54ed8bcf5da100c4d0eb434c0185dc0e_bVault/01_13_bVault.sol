pragma solidity 0.5.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/IController.sol";
import "../libraries/WhiteListChecker.sol";

/**
 * @title bVault
 * @dev btoken vault, a typical mining aggregator's vault
 */
contract bVault is ERC20, ERC20Detailed, WhiteListChecker, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    IERC20 public token;
  
    // buffer size 10%
    uint public min = 9000;
    uint public constant max = 10000;

    uint public withdrawalFee = 25; // 0.25%
    uint constant public withdrawalMax = 10000;
  
    address public governance;
    address public controller;

    bool public paused = false;
    mapping(address => bool) public pauseRoles;

    modifier notPaused() {
        require(!IController(controller).paused(), "Global paused!");
        require(!paused, "Local paused!");
        _;
    }

    constructor (address _token, address _controller, address whiteList) public ERC20Detailed(
        string(abi.encodePacked("bella ", ERC20Detailed(_token).name())),
        string(abi.encodePacked("b", ERC20Detailed(_token).symbol())),
        ERC20Detailed(_token).decimals()
    ) WhiteListChecker(whiteList) {
        token = IERC20(_token);
        governance = msg.sender;
        controller = _controller;
    }

    function setPauseRole(address admin) external {
        require(msg.sender == governance, "!governance");
        pauseRoles[admin] = true;
    }

    function unSetPauseRole(address admin) external {
        require(msg.sender == governance, "!governance");
        pauseRoles[admin] = false;
    }

    function pause() external {
        require(pauseRoles[msg.sender], "no right to pause!");
        paused = true;
    }

    function unpause() external {
        require(pauseRoles[msg.sender], "no right to pause!");
        paused = false;
    }
    
    function balance() public view returns (uint) {
        return token.balanceOf(address(this))
            .add(IController(controller).balanceOf(address(token)));
    }

    function underlyingBalance() public view returns (uint) {
        return token.balanceOf(address(this))
            .add(IController(controller).underlyingBalanceOf(address(token)));
    }
    
    function setMin(uint _min) external {
        require(msg.sender == governance, "!governance");
        require(_min <= max, "invalid min!");
        min = _min;
    }

    function setWithdrawalFee(uint _withdrawalFee) external {
        require(msg.sender == governance, "!governance");
        require(_withdrawalFee <= withdrawalMax, "invalid withdrawal fee");
        withdrawalFee = _withdrawalFee;
    }
    
    function setGovernance(address _governance) public {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }
    
    function setController(address _controller) public {
        require(msg.sender == governance, "!governance");
        controller = _controller;
    }
    
    /**
     * @dev View function to check how much the vault allows to invest (due to buffer)
     */
    function available() public view returns (uint) {
        return balance().mul(min).div(max).sub(IController(controller).balanceOf(address(token)));
    }

    /**
     * @dev Rebalance the buffer to make withdraw cheaper
     */
    function rebalance() public onlyWhiteListed notPaused {
        uint256 amount = IController(controller).balanceOf(address(token)).sub(balance().mul(min).div(max));
        IController(controller).withdraw(address(token), amount);
    }
    
    function earn() public onlyWhiteListed notPaused {
        require(msg.sender == tx.origin ,"!contract");

        uint _bal = available();
        token.safeTransfer(controller, _bal);
        IController(controller).earn(address(token), _bal);
    }

    function deposit(uint _amount) external onlyWhiteListed notPaused nonReentrant {
        uint _pool = balance();
        uint _before = token.balanceOf(address(this));
        token.safeTransferFrom(msg.sender, address(this), _amount);
        uint _after = token.balanceOf(address(this));
        _amount = _after.sub(_before); // Additional check for deflationary tokens
        uint shares = 0;
        if (totalSupply() == 0) {
            shares = _amount;
        } else {
            shares = (_amount.mul(totalSupply())).div(_pool);
        }
        _mint(msg.sender, shares);
    }

    function withdraw(uint _shares) external notPaused nonReentrant {
        _withdraw(msg.sender, _shares);
    }

    function withdrawAll() external notPaused nonReentrant {
        _withdraw(msg.sender, balanceOf(msg.sender));
    }

    function getPricePerFullShare() public view returns (uint) {
        return balance().mul(1e18).div(totalSupply());
    }

    function _withdraw(address user, uint _shares) private {
        uint r = (underlyingBalance().mul(_shares)).div(totalSupply());

        _burn(user, _shares);

        // Check balance
        uint b = token.balanceOf(address(this));
        if (b < r) {
            uint w = r.sub(b);
            IController(controller).withdraw(address(token), w);
            uint _after = token.balanceOf(address(this));
            uint _diff = _after.sub(b);
            if (_diff < w) {
                r = b.add(_diff);
            }
        }
        
        uint _fee = r.mul(withdrawalFee).div(withdrawalMax);
        token.safeTransfer(IController(controller).rewards(), _fee);
        token.safeTransfer(user, r.sub(_fee));
    }
}