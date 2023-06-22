//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract f9launch is ERC20 {
  uint256 public startTimestamp; // same timestamp as the end of the IDO (claim time)

  address public f9launchTeam;
  address public liquidityPoolCreator;
  address public launchpad;

  bool private _lock;

  constructor(
    address _liquidityPoolCreator,
    address _operationsActive,
    address _f9launchTeam,
    address _rewards,
    address _f9,
    uint256 _startTimestamp
  ) ERC20("Metatron IX", "METAIX") {
    f9launchTeam = _f9launchTeam;
    startTimestamp = _startTimestamp;
    liquidityPoolCreator = _liquidityPoolCreator;

    // totalSupply: 555555555 * 1e18

    _mint(liquidityPoolCreator, 222222222 * 1e18); // 40%
    _mint(_operationsActive, 49999999 * 1e18); // 9%
    _mint(f9launchTeam, 33333333 * 1e18); // 6%
    _mint(_rewards, 16666666 * 1e18); // 3%
    _mint(_f9, 16666666 * 1e18); // 3%

    // _mint(_launchpad, 233333333 * 1e18); // 42% -> check setLaunchpad
  }

  modifier onlyf9launchTeam() {
    require(_msgSender() == f9launchTeam, "Not Authorized");
    _;
  }

  function transfer(address to, uint256 amount) public virtual override returns (bool) {
    require(
      block.timestamp >= startTimestamp ||
        _msgSender() == liquidityPoolCreator ||
        _msgSender() == launchpad,
      "Wait for IDO to finish"
    );
    return super.transfer(to, amount);
  }

  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) public virtual override returns (bool) {
    require(
      block.timestamp >= startTimestamp ||
        from == liquidityPoolCreator ||
        _msgSender() == launchpad,
      "Wait for IDO to finish"
    );
    return super.transferFrom(from, to, amount);
  }

  function setStartTimestamp(uint256 _newStart) external {
    require(_msgSender() == address(launchpad), "Only IDO");
    require(_newStart >= block.timestamp, "New time is in the past");
    startTimestamp = _newStart;
  }

  function setLaunchpad(address _launchpadAddress) external onlyf9launchTeam {
    launchpad = _launchpadAddress;
    if (!_lock) {
      _mint(_launchpadAddress, 233333333 * 1e18); // 42%
      _lock = true;
    }
  }

  function setf9launchTeam(address newf9launchTeam) external onlyf9launchTeam {
    f9launchTeam = newf9launchTeam;
  }
}