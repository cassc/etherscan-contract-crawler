// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract FakeWBTC is ERC20("FakeWBTC", "FAKE") {
    constructor() public {
        _setupDecimals(8);
    }

    function mintTo(address account, uint256 amount) public {
        _mint(account, amount);
    }

    function mint(uint256 amount) public {
        _mint(msg.sender, amount);
    }
}

contract FakeWHITE is ERC20("FakeWHITE", "FAKEWHITE") {

    function mintTo(address account, uint256 amount) public {
        _mint(account, amount);
    }

    function mint(uint256 amount) public {
        _mint(msg.sender, amount);
    }
}

contract FakeWETH is ERC20("FakeWETH", "FAKETH") {
    receive() external payable {}
    function mintTo(address account, uint256 amount) public {
        _mint(account, amount);
    }

    function mint(uint256 amount) public {
        _mint(msg.sender, amount);
    }

    function deposit() external payable {
        _mint(msg.sender, msg.value);
    }

    function withdraw(uint wad) external {
        payable(msg.sender).transfer(wad);
        _burn(msg.sender, wad);
    }
}

contract FakeUSDC is ERC20("FakeUSDC", "FAKEU") {
    using SafeERC20 for ERC20;
    constructor() public {
        _setupDecimals(6);
    }
    function mintTo(address account, uint256 amount) public {
        _mint(account, amount);
    }

    function mint(uint256 amount) public {
        _mint(msg.sender, amount);
    }
}