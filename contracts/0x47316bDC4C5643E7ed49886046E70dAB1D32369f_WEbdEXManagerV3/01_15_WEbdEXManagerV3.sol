//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../utils/NFT.sol";

interface IWEbdEXPassV3 {
    struct User {
        bool passExpired;
        bool haveFreeTrial;
        uint256 expirationTime;
    }

    function getUserInfoByWallet(
        address to
    ) external view returns (User memory);
}

contract WEbdEXManagerV3 is Ownable {
    Bot public bot;
    IWEbdEXPassV3 public webDexPassV3;
    Register[] internal registers;
    address public webDexStrategiesV3;

    mapping(address => User) internal users;

    struct User {
        address manager;
        bool status;
    }

    struct Bot {
        string name;
        address token;
        address wallet;
        address seller;
    }

    struct Register {
        address wallet;
        address manager;
    }

    struct Display {
        address wallet;
        address manager;
        bool status;
        bool passExpired;
        bool haveFreeTrial;
        uint256 expirationTime;
    }

    event Transaction(
        address indexed from,
        string method,
        uint256 timeStamp,
        address to,
        uint256 value
    );

    constructor(
        string memory name_,
        string memory symbol_,
        address wallet_,
        IWEbdEXPassV3 webDexPassV3_,
        address seller_
    ) {
        bot = Bot(
            name_,
            address(
                new NFT(string(abi.encodePacked(name_, " Affiliated")), symbol_)
            ),
            wallet_,
            seller_
        );
        webDexPassV3 = webDexPassV3_;
    }

    modifier onlyWebDexStrategiesOrOwner() {
        require(
            msg.sender == webDexStrategiesV3 ||
                (msg.sender == owner() && webDexStrategiesV3 != address(0)),
            "You must own the contract or the WebDexStrategies"
        );

        _;
    }

    function changeWEbdEXStrategiesV3(
        address newWebDexStrategiesV3
    ) public onlyOwner {
        webDexStrategiesV3 = newWebDexStrategiesV3;
    }

    function registerInBot(address manager) public {
        if (manager != address(0)) {
            require(users[manager].status, "Unregistered manager");
        }

        require(!users[msg.sender].status, "User already registered");

        users[msg.sender].manager = manager;
        users[msg.sender].status = true;
        NFT(bot.token).safeMint(msg.sender);

        registers.push(Register(msg.sender, manager));

        emit Transaction(
            msg.sender,
            manager == address(0)
                ? "Register In Bot With Manager"
                : "Register In Bot",
            block.timestamp,
            address(this),
            0
        );
    }

    function getUserInfo() public view returns (Display memory) {
        return _getUser(msg.sender);
    }

    function getUserInfoByWallet(
        address to
    ) public view onlyWebDexStrategiesOrOwner returns (Display memory) {
        return _getUser(to);
    }

    function getBot() public view returns (Bot memory) {
        return bot;
    }

    function getRegisters() public view returns (Register[] memory) {
        return registers;
    }

    function _getUser(address to) internal view returns (Display memory) {
        IWEbdEXPassV3.User memory userInfo = webDexPassV3.getUserInfoByWallet(
            to
        );

        return
            Display(
                to,
                users[to].manager,
                users[to].status,
                userInfo.passExpired,
                userInfo.haveFreeTrial,
                userInfo.expirationTime
            );
    }
}