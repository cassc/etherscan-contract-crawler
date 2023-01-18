// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "openzeppelin/access/Ownable.sol";
import "openzeppelin/token/ERC20/IERC20.sol";

interface IMasterChefV1 {
    function withdraw(uint256 _pid, uint256 _amount) external;

    function deposit(uint256 _pid, uint256 _amount) external;
}

interface IBridgeAdapter {
    function bridge() external;
    function bridgeWithData(bytes calldata data) external;
}

abstract contract BaseServer is Ownable {
    IMasterChefV1 public constant masterchefV1 =
        IMasterChefV1(0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd);
    IERC20 public constant sushi =
        IERC20(0x6B3595068778DD592e39A122f4f5a5cF09C90fE2);

    uint256 public immutable pid;

    address public immutable minichef;

    address public bridgeAdapter;

    event Harvested(uint256 indexed pid);
    event Withdrawn(uint256 indexed pid, uint256 indexed amount);
    event Deposited(uint256 indexed pid, uint256 indexed amount);
    event WithdrawnSushi(uint256 indexed pid, uint256 indexed amount);
    event WithdrawnDummyToken(uint256 indexed pid);
    event BridgeUpdated(address indexed newBridgeAdapter);

    constructor(uint256 _pid, address _minichef) {
        pid = _pid;
        minichef = _minichef;
        bridgeAdapter = address(this);
    }

    function harvestAndBridge() public {
        masterchefV1.withdraw(pid, 0);
        bridge();
        emit Harvested(pid);
    }

    function withdraw() public onlyOwner {
        masterchefV1.withdraw(pid, 1);
        emit Withdrawn(pid, 1);
    }

    function deposit(address token) public onlyOwner {
        IERC20(token).approve(address(masterchefV1), 1);
        masterchefV1.deposit(pid, 1);
        emit Deposited(pid, 1);
    }

    function withdrawSushiToken(address recipient) public onlyOwner {
        uint256 sushiBalance = sushi.balanceOf(address(this));
        sushi.transfer(recipient, sushiBalance);
        emit WithdrawnSushi(pid, sushiBalance);
    }

    function withdrawDummyToken(address token, address recipient)
        public
        onlyOwner
    {
        IERC20(token).transfer(recipient, 1);
        emit WithdrawnDummyToken(pid);
    }

    function updateBridgeAdapter(address newBridgeAdapter) public onlyOwner {
        require(newBridgeAdapter != address(0), "zero address");
        bridgeAdapter = newBridgeAdapter;
        emit BridgeUpdated(newBridgeAdapter);
    }

    function bridge() public {
        if (bridgeAdapter == address(this)) {
            _bridge();
        } else {
            uint256 sushiBalance = sushi.balanceOf(address(this));
            sushi.transfer(bridgeAdapter, sushiBalance);
            IBridgeAdapter(bridgeAdapter).bridge();
        }
    }

    function bridgeWithData(bytes calldata data) public {
        if (bridgeAdapter == address(this)) {
            _bridgeWithData(data);
        } else {
            uint256 sushiBalance = sushi.balanceOf(address(this));
            sushi.transfer(bridgeAdapter, sushiBalance);
            IBridgeAdapter(bridgeAdapter).bridgeWithData(data);
        }
    }

    function _bridge() internal virtual;
    function _bridgeWithData(bytes calldata data) internal virtual;
}