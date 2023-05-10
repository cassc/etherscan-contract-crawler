// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./@openzeppelin/contracts/access/AccessControl.sol";

interface IBotProtect {
    function protect(address from, address to, uint amount) external;
}

contract NonFunMachine is ERC20, AccessControl {
    bytes32 public constant DEPLOYER = keccak256("DEPLOYER");

    uint public TGE;
    mapping(address => bool) private whiteLists;
    //BotProtect
    IBotProtect public BotProtect;

    event LogAddWhiteList(address user, bool wl);
    event LogMint(address user, uint amount);

    constructor() ERC20("Non-Fungible Machine", "NFM"){
        _setRoleAdmin(DEPLOYER, DEPLOYER);
        _setupRole(DEPLOYER, msg.sender);
    }

    function mint(address user, uint amount) external onlyRole(DEPLOYER) {
        _mint(user, amount);
        emit LogMint(user, amount);
    }

    function _transfer(address from, address to, uint amount) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (TGE == 0) {
            require(whiteLists[from] || whiteLists[to], "Trading is not active until TGE.");
        }

        if (address(BotProtect) != address(0)) {
            BotProtect.protect(from, to, amount);
        }
        super._transfer(from, to, amount);
    }

    function startTGE() external onlyRole(DEPLOYER) {
        TGE = block.timestamp;
    }

    function addWhiteLists(address user, bool _wl) external onlyRole(DEPLOYER) {
        whiteLists[user] = _wl;
        emit LogAddWhiteList(user, _wl);
    }

    function updateBotProtectSystem(IBotProtect _bp) external onlyRole(DEPLOYER) {
        BotProtect = _bp;
    }

    function withdrawToken(
        address token,
        uint amount,
        address sendTo
    ) external onlyRole(DEPLOYER)  {
        ERC20(token).transfer(sendTo, amount);
    }

    function withdraw() external onlyRole(DEPLOYER) {
        (bool success,) = msg.sender.call{value : address(this).balance}("");
        require(success, "withdraw failed");
    }

    receive() payable external {}
}