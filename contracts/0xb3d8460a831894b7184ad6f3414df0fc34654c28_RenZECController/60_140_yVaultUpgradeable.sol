// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;

import "oz410/token/ERC20/IERC20.sol";
import "oz410/math/SafeMath.sol";
import "oz410/utils/Address.sol";
import "oz410/token/ERC20/SafeERC20.sol";
import "oz410/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "oz410/access/Ownable.sol";

import "../interfaces/yearn/IController.sol";

contract yVaultUpgradeable is ERC20Upgradeable {
  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint256;

  IERC20 public token;

  uint256 public min = 25;
  uint256 public constant max = 30;

  address public governance;
  address public controller;

  mapping(address => bool) public whitelist;

  modifier isWhitelisted() {
    require(whitelist[msg.sender], "!whitelist");
    _;
  }

  modifier onlyGovernance() {
    require(msg.sender == governance);
    _;
  }

  function addToWhitelist(address[] calldata entries) external onlyGovernance {
    for (uint256 i = 0; i < entries.length; i++) {
      address entry = entries[i];
      require(entry != address(0));

      whitelist[entry] = true;
    }
  }

  function removeFromWhitelist(address[] calldata entries) external onlyGovernance {
    for (uint256 i = 0; i < entries.length; i++) {
      address entry = entries[i];
      whitelist[entry] = false;
    }
  }

  function __yVault_init_unchained(
    address _token,
    address _controller,
    string memory _name,
    string memory _symbol
  ) public initializer {
    __ERC20_init_unchained(_name, _symbol);
    token = IERC20(_token);
    governance = msg.sender;
    controller = _controller;
  }

  function decimals() public view override returns (uint8) {
    return ERC20(address(token)).decimals();
  }

  function balance() public view returns (uint256) {
    return token.balanceOf(address(this)).add(IController(controller).balanceOf(address(token)));
  }

  function setMin(uint256 _min) external {
    require(msg.sender == governance, "!governance");
    min = _min;
  }

  function setGovernance(address _governance) public {
    require(msg.sender == governance, "!governance");
    governance = _governance;
  }

  function setController(address _controller) public {
    require(msg.sender == governance, "!governance");
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

  function depositAll() external {
    deposit(token.balanceOf(msg.sender));
  }

  function deposit(uint256 _amount) public {
    uint256 _pool = balance();
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
    _mint(msg.sender, shares);
  }

  function withdrawAll() external {
    withdraw(balanceOf(msg.sender));
  }

  // Used to swap any borrowed reserve over the debt limit to liquidate to 'token'
  function harvest(address reserve, uint256 amount) external {
    require(msg.sender == controller, "!controller");
    require(reserve != address(token), "token");
    IERC20(reserve).safeTransfer(controller, amount);
  }

  // No rebalance implementation for lower fees and faster swaps
  function withdraw(uint256 _shares) public {
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
  }

  function getPricePerFullShare() public view returns (uint256) {
    return balance().mul(1e18).div(totalSupply());
  }
}