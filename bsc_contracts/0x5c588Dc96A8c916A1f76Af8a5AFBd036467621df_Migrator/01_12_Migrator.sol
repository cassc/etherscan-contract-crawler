// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./utils/IBabyDogeRouter.sol";
import "./utils/IBabyDogeFactory.sol";
import "./utils/IBabyDogePair.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

// Move liquitidy from DEX-A to DEX-B.
contract Migrator is ReentrancyGuard, AccessControl {
    bytes32 internal constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");

    address public treatsToken;

    IBabyDogeRouter public router;

    event Migrated(
        address _oldPair,
        address token0,
        address token1,
        uint256 _amount0,
        uint256 _amount1,
        uint256 _amountOfLpReceived
    );

    constructor(IBabyDogeRouter _router, address _treatsToken) {
        router = _router;
        treatsToken = _treatsToken;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(GOVERNANCE_ROLE, _msgSender());
    }

    /*
     * Params
     * address referral  - Address to the referral contract
     *
     * Function points the contract to the Treat Token contract
     * In case token will be deployed later.
     */

    function setTreatToken(address _address) public onlyRole(GOVERNANCE_ROLE) {
        treatsToken = _address;
    }

    /*
     * Params
     * address oldPair - Address of the lp token from which you would like to remove the liquidity from
     * address oldRouterAddress - Address of exchange router the liquidity is moved from
     *
     * Migrates liquidity from any other exchange to BabyDoge Exchange
     * Sends new LP token to whoever calls the function.
     */

    function migrate(IBabyDogePair _oldPair, address _oldRouterAddress)
        external
        nonReentrant
    {
        address token0 = _oldPair.token0();
        address token1 = _oldPair.token1();
        require(
            token0 != treatsToken && token1 != treatsToken,
            "Can't migrate Treats Token"
        );
        uint256 liquidity = _oldPair.balanceOf(msg.sender);
        _oldPair.transferFrom(msg.sender, address(this), liquidity);

        IBabyDogePair(_oldPair).approve(
            _oldRouterAddress,
            liquidity
        );
        IBabyDogeRouter(
            _oldRouterAddress
        ).removeLiquidity(
                token0,
                token1,
                liquidity,
                0,
                0,
                address(this),
                block.timestamp + 1200
            );

        uint256 amountA = IERC20(token0).balanceOf(address(this));
        uint256 amountB = IERC20(token1).balanceOf(address(this));
        IERC20(token0).approve(address(router), amountA);
        IERC20(token1).approve(address(router), amountB);
        (
            uint256 amountASent,
            uint256 amountBSent,
            uint256 liquidityReceived
        ) = router.addLiquidity(
                token0,
                token1,
                amountA,
                amountB,
                0,
                0,
                msg.sender,
                block.timestamp + 1200
            );

        uint256 leftOverAmountToken0 = IERC20(token0).balanceOf(address(this));
        uint256 leftOverAmountToken1 = IERC20(token1).balanceOf(address(this));

        if (leftOverAmountToken0 > 0)
            IERC20(token0).transfer(msg.sender, leftOverAmountToken0);
        if (leftOverAmountToken1 > 0)
            IERC20(token1).transfer(msg.sender, leftOverAmountToken1);

        emit Migrated(
            address(_oldPair),
            token0,
            token1,
            amountASent,
            amountBSent,
            liquidityReceived
        );
    }
}