// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';


interface WETH {
    function deposit() external payable;

    function withdraw(uint256 amount) external;

    function transfer(address to, uint256 amount) external returns (bool);
}

contract BRCEVMVault {
    address public admin;

    address public wethAddress;
    mapping(address => bool) public whitelistToken;
    mapping(bytes32 => bool) public usedTxids;

    // Deposit token
    event Deposit(
        address indexed from,
        address indexed to,
        address indexed tokenAddress,
        uint256 amount
    );

    // Withdraw token
    event Withdraw(
        address indexed to,
        address indexed tokenAddress,
        uint256 amount,
        bytes32 txid
    );

    // Withdraw token
    event AdminChanged(address indexed admin, address indexed newAdmin);

    constructor(address _wethAddress) {
        admin = msg.sender;
        wethAddress = _wethAddress;
        whitelistToken[_wethAddress] = true;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    receive() external payable {}

    function changeAdmin(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0), "Invalid address");
        emit AdminChanged(admin, newAdmin);
        admin = newAdmin;
    }

    function setWETHAddress(address _wethAddress) public onlyAdmin {
        wethAddress = _wethAddress;
        whitelistToken[_wethAddress] = true;
    }

    function setWhitelistToken(
        address[] memory tokenAddresses
    ) public onlyAdmin {
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            whitelistToken[tokenAddresses[i]] = true;
        }
    }

    function removeWhitelistToken(
        address[] memory tokenAddresses
    ) public onlyAdmin {
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            whitelistToken[tokenAddresses[i]] = false;
        }
    }

    function deposit(
        address tokenAddress,
        address to,
        uint256 amount
    ) public payable {
        if (tokenAddress == address(0)) {
            WETH weth = WETH(wethAddress);
            weth.deposit{value: msg.value}();

            emit Deposit(msg.sender, to, wethAddress, msg.value);
        } else {
            require(
                whitelistToken[tokenAddress],
                "Token address is not whitelisted"
            );

            IERC20 token = IERC20(tokenAddress);
            token.transferFrom(msg.sender, address(this), amount);

            emit Deposit(msg.sender, to, tokenAddress, amount);
        }
    }

    function withdraw(
        address tokenAddress,
        address to,
        uint256 amount,
        bytes32 txid
    ) public onlyAdmin {
        require(
            whitelistToken[tokenAddress],
            "Token address is not whitelisted"
        );

        require(!usedTxids[txid], "Txid used");

        if (wethAddress == tokenAddress) {
            WETH weth = WETH(tokenAddress);
            weth.withdraw(amount);
            (bool success, ) = to.call{value: amount}("");
            require(success, "Token transfer failed");
        } else {
            IERC20 token = IERC20(tokenAddress);
            require(token.transfer(to, amount), "Token transfer failed");
        }

        usedTxids[txid] = true;

        emit Withdraw(to, tokenAddress, amount, txid);
    }
}