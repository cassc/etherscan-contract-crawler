//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract TokenMigrate is Ownable {
    using SafeMath for uint256;

    IERC20 public TOKENV1;
    IERC20 public TOKENV2;

    uint256 public numberOfV1TokensForOneV2Token;

    uint256 public createdAt;

    address public superAdmin;

    bool public isActive = false;

    event newMigrate(
        uint256 tokenAmountV1,
        uint256 tokenAmountV2,
        address toUser
    );
    event changeRation(uint256 newRatio, uint256 oldRatio);

    constructor(
        address _v1Token,
        address _v2Tokens,
        address _owner,
        uint256 _ratio,
        address admin
    ) {
        TOKENV1 = IERC20(_v1Token);
        TOKENV2 = IERC20(_v2Tokens);

        createdAt = block.timestamp;

        superAdmin = admin;
        // transfer pool ownership
        transferOwnership(_owner);
        numberOfV1TokensForOneV2Token = _ratio;
    }

    receive() external payable {}

    function v1TokenBalance() public view returns (uint256) {
        return TOKENV1.balanceOf(address(this));
    }

    function v2TokenBalance() public view returns (uint256) {
        return TOKENV2.balanceOf(address(this));
    }

    function migrateAllTokens() public {
        require(isActive, "Pool not activated yet");
        uint256 userV1TokenBalance = TOKENV1.balanceOf(msg.sender);
        uint256 totalV2TokensToReceive = userV1TokenBalance.div(
            numberOfV1TokensForOneV2Token
        );

        require(
            TOKENV2.balanceOf(address(this)) >= totalV2TokensToReceive,
            "No enough v2 tokens in the pool"
        );

        TOKENV1.transferFrom(
            address(msg.sender),
            address(this),
            userV1TokenBalance
        );

        TOKENV2.transfer(msg.sender, totalV2TokensToReceive);

        emit newMigrate(userV1TokenBalance, totalV2TokensToReceive, msg.sender);
    }

    function migratePartialTokens(uint256 _amount) public {
        require(isActive, "Pool not activated yet");

        require(
            TOKENV1.balanceOf(msg.sender) >= _amount,
            "You don't have enough token balance"
        );
        uint256 totalV2TokensToReceive = _amount.div(
            numberOfV1TokensForOneV2Token
        );

        require(
            TOKENV2.balanceOf(address(this)) >= totalV2TokensToReceive,
            "No enough v2 tokens in the pool"
        );

        TOKENV1.transferFrom(address(msg.sender), address(this), _amount);

        TOKENV2.transfer(msg.sender, totalV2TokensToReceive);

        emit newMigrate(_amount, totalV2TokensToReceive, msg.sender);
    }

    function changeRatio(uint256 _numberOfV1TokensForOneV2Token)
        external
        onlyOwner
    {
        emit changeRation(
            _numberOfV1TokensForOneV2Token,
            numberOfV1TokensForOneV2Token
        );
        numberOfV1TokensForOneV2Token = _numberOfV1TokensForOneV2Token;
    }

    function getBep20Tokens(address _tokenAddress, uint256 amount)
        external
        onlyOwner
    {
        require(
            IERC20(_tokenAddress).balanceOf(address(this)) >= amount,
            "No Enough Tokens"
        );
        IERC20(_tokenAddress).transfer(msg.sender, amount);
    }

    function changeStatus(bool status) public {
        require(
            msg.sender == superAdmin,
            "Only super admin can call this function"
        );

        isActive = status;
    }
}