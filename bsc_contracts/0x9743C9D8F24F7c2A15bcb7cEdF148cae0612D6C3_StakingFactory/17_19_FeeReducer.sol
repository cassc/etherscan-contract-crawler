// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <=0.8.6;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/IRouterV2.sol";

import "../token/MyToken.sol";
import "../token/MyShare.sol";


/**
 * @title The magical FeeReducer contract.
 * @author int(200/0), slidingpanda
 */
contract FeeReducer is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 private tenTokenV1 = IERC20(0xAb887Edaf53570dd212E94CecdA38B7c165420b5);
    IERC20 private ten = IERC20(0x25B9d4b9535920194c359d2879dB6a1382c2ff26);
    MyShare private myShareToken;

    address public router;

    bool public isActive = true;

    uint256 public myShareHoldDivisor = 1e6;
    uint256 public myShareBurnDivisor = 1e5;
    uint256 public fixShareBurnAmount;
    uint256 public fixTENSendAmount = 1e20;

    uint256 public constant MONTH_IN_SECOND = 2629800; // 60*60*24*365.25/12
    uint256 public constant YEAR_IN_SECOND = 31557600; // 60*60*24*365.25

    mapping(address => uint256) private reducedUntil;

    /**
     * Creates the feeReducer.
	 *
     * @param owner_ owner of the myToken
     * @param myShareAddr address of the myShare Token
     * @param routerAddr address of the (UniV2 clone) router
     */
    constructor(
        address owner_,
        address myShareAddr,
        address routerAddr
    ) public {
        myShareToken = MyShare(myShareAddr);
        fixShareBurnAmount = myShareToken.totalSupply() / (2 * myShareBurnDivisor);
        transferOwnership(owner_);
        router = routerAddr;
    }

    /**
     * Activates/Deactivates the possiblity to reduce the fees (true = active, false = inactive, default = true).
     *
     * @param toSet status
     */
    function setActivity(bool toSet) external onlyOwner {
        isActive = toSet;
    }

    /**
     * Changes router (UniV2 clone) for the myXXX -> XXX swap.
	 *
     * @notice The liquidity needs to exist or else buyBackAnsBurn fails.
	 *
     * @param newRouter router address
     */
    function setRouter(address newRouter) external onlyOwner {
        router = newRouter;
    }

    /**
     * Sets the divisor of balance<->totalSupply check.
	 * Everyone except liquidity pools who has more than this trigger value gets a fee reduction.
	 *
     * @notice Default: 1e6 (trigger = totalSupply / myShareHoldDivisor)
	 *
     * @param newDivisor new divisor
     */
    function setMyShareHoldDivisor(uint256 newDivisor) external onlyOwner {
        require(newDivisor != 0, "Zero division not possible");
        require(newDivisor <= myShareToken.totalSupply(), "Not more than the totalSupply");
		
        myShareHoldDivisor = newDivisor;
    }

    /**
     * Changes the divisor of the myShare totalSupply.
	 *
     * @param newDivisor new divisor
     */
    function setMyShareBurnDivisor(uint256 newDivisor) external onlyOwner {
        require(newDivisor <= myShareToken.totalSupply(), "Not more than the totalSupply");

        myShareBurnDivisor = newDivisor;
    }

    /**
     * Changes the amount of the myShare burn amount.
	 *
     * @param newAmount new amount
     */
    function setMyShareBurnFixAmount(uint256 newAmount) external onlyOwner {
        require(newAmount <= myShareToken.totalSupply(), "Not more than the totalSupply");

        fixShareBurnAmount = newAmount;
    }

    /**
     * Changes the divisor of the teneo send amount.
	 *
     * @param newAmount new amount
     */
    function setTenBurnFixAmount(uint256 newAmount) external onlyOwner {
        require(newAmount <= tenTokenV1.totalSupply(), "Not more than the totalSupply");

        fixTENSendAmount = newAmount;
    }

    /**
     * Shows if an address has reduced fees.
	 *
     * @param user address
     * @return reduced is reduced
     */
    function isReduced(address user) public view returns (bool reduced) {
        if (reducedUntil[user] >= block.timestamp) {
            reduced = true;
        }
    }

    /**
     * Returns the possible fee multiplicators.
	 *
     * @notice The calculation: "amount * feeMultiX / 10" and feeMultiX can be resolved like this:
	 *			- Wrapper withdraw / LP zap in (base 1%):
     *				Holding     50% fees
     *				FeeReducer  10% fees
     *			- myToken transaction:
     *				Holding     90% fees
     *				FeeReducer  50% fees
	 *
     * @param user address which is checked
     * @return feeMultiToken fee multiplier for the myToken
     * @return feeMultiWrapper fee multiplier for withdrawing
     */
    function feeMultiplier(address user) external view returns (uint256 feeMultiToken, uint256 feeMultiWrapper) {
        if (myShareToken.balanceOf(user) >= myShareToken.totalSupply() / myShareHoldDivisor) {
            feeMultiToken = 9;
            feeMultiWrapper = 5;
        } else {
            feeMultiToken = 10;
            feeMultiWrapper = 10;
        }

        if (isReduced(user)) {
            feeMultiToken = 5;
            feeMultiWrapper = 1;
        }
    }

    /**
     * Burns the balance of the myShare token of this contract.
     */
    function burn() public {
        uint256 daoBalance = myShareToken.balanceOf(address(this));

        if (daoBalance > 0) {
            myShareToken.burn(daoBalance);
        }
    }

    /**
     * Gives back the myShare amount for reducing the fees for one month.
	 *
     * @return amount amount for reducing one month
     */
    function myShareAmountForOneMonth() public view returns (uint256 amount) {
        uint256 supply = myShareToken.totalSupply();

        amount = supply / myShareBurnDivisor + fixShareBurnAmount;
    }

    /**
     * Gives back the TEN/tenTEN amount for reducing the fees for one month.
	 *
     * @return amount amount for reducing one month
     */
    function tenAmountForOneMonth() public view returns (uint256 amount) {
        amount = fixTENSendAmount;
    }

    /**
     * Swaps tenTEN token to TEN token to not any gain reflows. Or other tokens if needed.
	 *
     * @param route route for buying back TEN
     */
    function buyBackBurn(address[] memory route) external {
        uint256 tenTenBalance = tenTokenV1.balanceOf(address(this));

        if (tenTenBalance > 0) {
            tenTokenV1.approve(router, tenTenBalance);

            IRouterV2(router)
                .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    tenTenBalance,
                    0,
                    route,
                    address(this),
                    block.timestamp + 20
                );
        }

        burn();
    }

    /**
     * Burns myShare tokens or sends tenTEN/TEN tokens for one month of fee reducing.
	 *
     * @notice - The burn amount for reducing depends on the relative supply amount and a fix amount because the myShare supply is changing
     *         - The TEN supply is fixed (also the max tenTEN amount), so the amount which will be send is also fixed
	 *
     * @param user user address
     * @param token token address
     * @return success 'true' - if successfully reduced
     */
    function reduceForMonth(address user, address token) external returns (bool success) {
        require(isActive, "This fee reducer is not active");
        require(token == address(tenTokenV1) || token == address(myShareToken) || token == address(ten), "Need TEN, tenTEN or MyShare to reduce");

        uint256 time = block.timestamp;

        if (time <= reducedUntil[user]) {
            time = reducedUntil[user];
        }

        if (token == address(tenTokenV1)) {
            tenTokenV1.transferFrom(msg.sender, address(this), tenAmountForOneMonth());

            reducedUntil[user] = time + MONTH_IN_SECOND;
            success = true;
        } else if (token == address(myShareToken)) {
            myShareToken.transferFrom(msg.sender, address(this), myShareAmountForOneMonth());

            reducedUntil[user] = time + MONTH_IN_SECOND;
            success = true;
        } else if (token == address(ten)) {
            ten.transferFrom(msg.sender, address(this), tenAmountForOneMonth());

            reducedUntil[user] = time + MONTH_IN_SECOND;
            success = true;
        }

        burn();
    }

    /**
     * Burns myShare tokens or sends tenTEN/TEN tokens for one year of fee reducing.
	 *
     * @notice Same as for a reduceForMonth, but 10x higher amounts (not 12).
	 *
     * @param user user address
     * @param token token address
     * @return success 'true' - if successfully reduced
     */
    function reduceForYear(address user, address token) external returns (bool success) {
        require(isActive, "This fee reducer is not active");
        require(token == address(tenTokenV1) || token == address(myShareToken) || token == address(ten), "Need TEN, tenTEN or MyShare to reduce");

        uint256 time = block.timestamp;

        if (time <= reducedUntil[user]) {
            time = reducedUntil[user];
        }

        if (token == address(tenTokenV1)) {
            tenTokenV1.transferFrom(msg.sender,address(this), 10 * tenAmountForOneMonth());

            reducedUntil[user] = time + YEAR_IN_SECOND;
            success = true;
        } else if (token == address(myShareToken)) {
            myShareToken.transferFrom(msg.sender,address(this), 10 * myShareAmountForOneMonth());

            reducedUntil[user] = time + YEAR_IN_SECOND;
            success = true;
        } else if (token == address(ten)) {
            ten.transferFrom(msg.sender,address(this), 10 * tenAmountForOneMonth());

            reducedUntil[user] = time + YEAR_IN_SECOND;
            success = true;
        }

        burn();
    }

    /**
     * Withdraws ERC20 tokens from the contract.
	 * Also TEN Tokens.
	 *
     * @param tokenAddr address of the IERC20 token
     * @param to address of the recipient
     */
    function withdrawERC(address tokenAddr, address to) external onlyOwner {
        IERC20(tokenAddr).safeTransfer(to, IERC20(tokenAddr).balanceOf(address(this)));
    }

    /**
     * Gives the owner the possibility to withdraw ETH which are airdroped or send by mistake to this contract.
	 *
     * @param to recipient of the tokens
     */
    function daoWithdrawETH(address to) external onlyOwner {
        (bool sent,) = to.call{value: address(this).balance}("");
		
        require(sent, "Failed to send ETH");
    }
}