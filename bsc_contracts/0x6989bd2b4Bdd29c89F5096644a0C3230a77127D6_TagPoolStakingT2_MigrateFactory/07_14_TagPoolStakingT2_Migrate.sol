// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./iTagPoolT2Token.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract TagPoolStakingT2_Migrate is AccessControl,ReentrancyGuard {

    bytes32 public constant PAUSE_ROLE = keccak256("PAUSE_ROLE");

    iTagPoolT2Token public dToken;

    iTagPoolT2Token public Token;

    mapping ( address => bool ) public isClaimed;

    constructor(
        address _DFA,
        address _dToken,
        address _Token
    ) public  {
        _setupRole(DEFAULT_ADMIN_ROLE, _DFA);

        dToken = iTagPoolT2Token(_dToken);
        Token = iTagPoolT2Token(_Token);

    }

    function setDToken(address _dToken) public onlyRole(DEFAULT_ADMIN_ROLE) {
        dToken = iTagPoolT2Token(_dToken);
    }

    function setToken(address _Token) public onlyRole(DEFAULT_ADMIN_ROLE) {
        dToken = iTagPoolT2Token(_Token);
    }

    function claim( ) external nonReentrant {
        require(isClaimed[msg.sender] != true, "User already Claimed");
        uint256 balance = dToken.balanceOf(msg.sender);
        isClaimed[msg.sender ] = true;
        Token.mint(msg.sender , balance);
    }

}