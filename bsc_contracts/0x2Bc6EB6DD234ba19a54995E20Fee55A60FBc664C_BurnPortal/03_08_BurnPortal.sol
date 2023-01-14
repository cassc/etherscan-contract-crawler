// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IBabyDogeRouter.sol";
import "./interfaces/IBabyDogeFactory.sol";
import "./interfaces/IBabyDogePair.sol";
import "./interfaces/IWETH.sol";
import "./SafeOwnable.sol";

/*
 * @title Provides buy BabyDoge Token discount for BabyDoge burning
 * Leftover fees are converted to `treasuryToken`
 */
contract BurnPortal is SafeOwnable {
    struct Discount {
        // Discount amount in basis points, where 10_000 is 100% discount, which means purchase without fees
        uint16 discount;
        // Amount of BabyDoge tokens to burn to reach this discount
        uint112 burnAmount;
    }

    IBabyDogeRouter public immutable router;
    IWETH private immutable WETH;
    IERC20 public immutable bbdToken;
    address private constant DEAD_WALLET = 0x000000000000000000000000000000000000dEaD;

    address public treasuryToken;
    address public feeReceiver;
    bool public freePurchaseForEveryone = false;
    uint8 public babyDogeTokenTax = 10; //  10% BabyDoge tax
    uint256 public totalBurned = 0;

    Discount[] public discounts;
    mapping(address => uint256) public burnedAmount;

    event BabyDogePurchase(
        address account,
        uint256 babyDogeAmount,
        address tokenIn,
        uint256 treasuryTokensAmount
    );
    event NewDiscounts(Discount[]);
    event NewTreasuryToken(address);
    event NewFeeReceiver(address);
    event NewBabyDogeTokenTax(uint256);
    event FreePurchaseForEveryoneEnabled();
    event FreePurchaseForEveryoneDisabled();
    event BabyDogeBurn(address account, uint256 amount);
    event TokensWithdrawal(address token, address account, uint256 amount);

    error InvalidDiscount(uint256);


    /*
     * @param _router BabyDoge router address
     * @param _bbdToken BabyDoge token address
     * @param _treasuryToken IERC20 token address which will be bought for leftover BabyDoge Token after swap
     * @param _discounts Array of Discount structs, containing discount amount and burn amount to receive that discount
     */
    constructor(
        IBabyDogeRouter _router,
        IERC20 _bbdToken,
        address _treasuryToken,
        address _feeReceiver,
        Discount[] memory _discounts
    ){
        require(address(_bbdToken) != address(0) && _treasuryToken != address(0));
        feeReceiver = _feeReceiver == address(0) ? address(this) : _feeReceiver;
        router = _router;
        WETH = IWETH(_router.WETH());
        _bbdToken.approve(address(_router), type(uint256).max);

        bbdToken = _bbdToken;
        treasuryToken = _treasuryToken;

        _checkDiscounts(_discounts);
        for(uint i = 0; i < _discounts.length; i++) {
            discounts.push(_discounts[i]);
        }
    }


    /*
     * @notice Swaps BNB for BabyDoge token and sends them to msg.sender
     * @param amountOutMin Minimum amount of BabyDoge tokens to receive
     * @param README.md Minimum amount of treasury tokens to receive
     * @param path Swap path
     * @param deadline Deadline of swap transaction
     * @return amountOut Amount of BabyDoge tokens user has received
     * @return amountTreasuryOut Amount of treasury tokens were collected
     */
    function buyBabyDogeWithBNB(
        uint256 amountOutMin,
        uint256 amountToTreasuryMin,
        address[] calldata path,
        uint256 deadline
    ) external payable returns(uint256 amountOut, uint256 amountTreasuryOut){
        require(path[0] == address(WETH), "Invalid tokenIn");
        require(msg.value > 0, "0 amountIn");
        WETH.deposit{value : msg.value}();

        (amountOut, amountTreasuryOut) = _buyBabyDogeWithERC20(
            msg.value,
            amountOutMin,
            amountToTreasuryMin,
            path,
            deadline
        );
    }


    /*
     * @notice Swaps ERC20 for BabyDoge token and sends them to msg.sender
     * @param amountIn Amount tokens to spend
     * @param amountOutMin Minimum amount of BabyDoge tokens to receive
     * @param amountToTreasuryMin Minimum amount of treasury tokens to receive
     * @param path Swap path
     * @param deadline Deadline of swap transaction
     * @return amountOut Amount of BabyDoge tokens user has received
     * @return amountTreasuryOut Amount of treasury tokens were collected
     */
    function buyBabyDogeWithERC20(
        uint256 amountIn,
        uint256 amountOutMin,
        uint256 amountToTreasuryMin,
        address[] calldata path,
        uint256 deadline
    ) external returns(uint256 amountOut, uint256 amountTreasuryOut){
        IERC20(path[0]).transferFrom(msg.sender, address(this), amountIn);

        (amountOut, amountTreasuryOut) = _buyBabyDogeWithERC20(
            amountIn,
            amountOutMin,
            amountToTreasuryMin,
            path,
            deadline
        );
    }


    /*
     * @notice Burns BabyDoge tokens by sending them to dead wallet
     * @param amount Amount of BabyDoge tokens to burn
     */
    function burnBabyDoge(uint256 amount) external {
        bbdToken.transferFrom(msg.sender, DEAD_WALLET, amount);
        burnedAmount[msg.sender] += amount;
        totalBurned += amount;

        emit BabyDogeBurn(msg.sender, amount);
    }


    /*
     * @notice Sets new discounts values
     * @param _discounts Array of Discount structs, containing discount amount and burn amount to receive that discount
     */
    function setDiscounts(Discount[] calldata _discounts) external onlyOwner {
        _checkDiscounts(_discounts);
        delete discounts;
        for(uint i = 0; i < _discounts.length; i++) {
            discounts.push(_discounts[i]);
        }

        emit NewDiscounts(_discounts);
    }


    /*
     * @notice Updates BabyDogeToken tax
     */
    function updateBabyDogeTokenTax() external {
        require(msg.sender == tx.origin || msg.sender == owner());
        IBabyDogeToken babyDoge = IBabyDogeToken(address(bbdToken));
        uint256 _babyDogeTokenTax = babyDoge._taxFee() + babyDoge._liquidityFee();
        require(babyDogeTokenTax != _babyDogeTokenTax, "Already set");
        require(_babyDogeTokenTax < 100, "Invalid tax");

        babyDogeTokenTax = uint8(_babyDogeTokenTax);

        emit NewBabyDogeTokenTax(_babyDogeTokenTax);
    }


    /*
     * @notice Allows everyone to purchase without fees
     */
    function enableFreePurchaseForEveryone() external onlyOwner {
        require(freePurchaseForEveryone != true, "Already set");
        freePurchaseForEveryone = true;

        emit FreePurchaseForEveryoneEnabled();
    }


    /*
     * @notice Disable free BabyDoge purchase for everyone. Now individual fees will work
     */
    function disableFreePurchaseForEveryone() external onlyOwner {
        require(freePurchaseForEveryone != false, "Already set");
        freePurchaseForEveryone = false;

        emit FreePurchaseForEveryoneDisabled();
    }


    /*
     * @notice Sets new treasury token
     * @param _treasuryToken IERC20 token address which will be bought for leftover BabyDoge Token after swap
     * @dev Must either be WBNB or have pair with WBNB with non-zero liquidity
     */
    function setTreasuryToken(address _treasuryToken) external onlyOwner {
        require(_treasuryToken != address(0));

        if(_treasuryToken != address(WETH)) {
            address pair = IBabyDogeFactory(router.factory()).getPair(address(WETH), _treasuryToken);

            (uint112 reserve0, uint112 reserve1,) = IBabyDogePair(pair).getReserves();
            require(reserve0 > 0 && reserve1 > 0, "No reserves with WBNB");
        }

        treasuryToken = _treasuryToken;

        emit NewTreasuryToken(_treasuryToken);
    }


    /*
     * @notice Sets new fee receiver
     * @param _feeReceiver Address which will receive the fees
     */
    function setFeeReceiver(address _feeReceiver) external onlyOwner {
        require(_feeReceiver != address(0) && feeReceiver != _feeReceiver);

        feeReceiver = _feeReceiver;

        emit NewFeeReceiver(_feeReceiver);
    }


    /*
     * @notice Withdraws ERC20 token. Should be used with treasury tokens on in case of accident
     * @param token IERC20 token address
     * @param account Address of receiver
     * @param amount Amount of tokens to withdraw
     */
    function withdrawERC20(
        IERC20 token,
        address account,
        uint256 amount
    ) external onlyOwner {
        token.transfer(account, amount);

        emit TokensWithdrawal(address(token), account, amount);
    }


    /*
     * @notice View function go get discounts list
     * @return List or discounts
     */
    function getDiscounts() external view returns(Discount[] memory) {
        return discounts;
    }


    /*
     * @notice View function go get personal discount
     * @return Discount in basis points where 10_000 is 100% discount = purchase without fee
     */
    function getPersonalDiscount(address account) public view returns(uint256) {
        if (freePurchaseForEveryone) {
            return 10_000;
        }
        uint256 numberOfDiscounts = discounts.length;

        int256 min = 0;
        int256 max = int256(numberOfDiscounts - 1);

        uint256 burnedTokens = burnedAmount[account];

        while (min <= max) {
            uint256 mid = uint256(max + min) / 2;

            if (
                burnedTokens == discounts[mid].burnAmount
                ||
                (burnedTokens > discounts[mid].burnAmount && (mid == numberOfDiscounts - 1))
                ||
                (burnedTokens > discounts[mid].burnAmount && (mid == 0 || burnedTokens < discounts[mid + 1].burnAmount))
            ) {
                return discounts[mid].discount;
            }

            if (discounts[mid].burnAmount > burnedTokens) {
                max = int256(mid) - 1;
            } else {
                min = int256(mid) + 1;
            }
        }

        return 0;
    }


    /*
     * @notice Swaps ERC20 for BabyDoge token
     * @param amountIn Amount tokens to spend
     * @param amountOutMin Minimum amount of BabyDoge tokens to receive
     * @param amountToTreasuryMin Minimum amount of treasury tokens to receive
     * @param path Swap path
     * @param deadline Deadline of swap transaction
     * @return amountOut Amount of BabyDoge tokens user has received
     * @return amountTreasuryOut Amount of treasury tokens were collected
     */
    function _buyBabyDogeWithERC20(
        uint256 amountIn,
        uint256 amountOutMin,
        uint256 amountToTreasuryMin,
        address[] calldata path,
        uint256 deadline
    ) private returns(uint256 amountOut, uint256 amountTreasuryOut){
        amountTreasuryOut = 0;
        require(path[path.length - 1] == address(bbdToken), "Invalid path");
        if (IERC20(path[0]).allowance(address(this), address(router)) < amountIn) {
            IERC20(path[0]).approve(address(router), type(uint256).max);
        }

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn,
            0,
            path,
            address(this),
            deadline
        );

        amountOut = bbdToken.balanceOf(address(this));
        uint256 personalDiscount = getPersonalDiscount(msg.sender);
        require(personalDiscount > 0, "No discount");
        uint256 amountToTreasury = amountOut * babyDogeTokenTax / 100 * (10_000 - personalDiscount) / 10_000;
        // swap BabyDoge to treasury bbdToken
        address[] memory treasuryPath;
        address _treasuryToken = treasuryToken;
        if (_treasuryToken == address(WETH)) {
            treasuryPath = new address[](2);
            treasuryPath[0] = address(bbdToken);
            treasuryPath[1] = _treasuryToken;
        } else {
            treasuryPath = new address[](3);
            treasuryPath[0] = address(bbdToken);
            treasuryPath[1] = address(WETH);
            treasuryPath[2] = _treasuryToken;
        }

        if (amountToTreasury > 0) {
            (uint256[] memory amounts) = router.swapExactTokensForTokens(
                amountToTreasury,
                amountToTreasuryMin,
                treasuryPath,
                feeReceiver,
                block.timestamp + 1200
            );

            amountOut -= amountToTreasury;
            amountTreasuryOut = amounts[amounts.length - 1];
        }

        bbdToken.transfer(msg.sender, amountOut);

        require(amountOut > amountOutMin, "Below amountOutMin");

        emit BabyDogePurchase(msg.sender, amountOut, path[0], amountTreasuryOut);
    }


    /*
     * @notice Checks discounts array for validity
     */
    function _checkDiscounts(Discount[] memory _discounts) private pure {
        require(_discounts.length > 0, "No discount data");
        Discount memory prevDiscount = _discounts[0];
        if (_discounts[0].discount == 0 || _discounts[0].burnAmount == 0) {
            revert InvalidDiscount(0);
        }
        for(uint i = 1; i < _discounts.length; i++) {
            if (
                _discounts[i].discount == 0
                || prevDiscount.discount >= _discounts[i].discount
                || prevDiscount.burnAmount >= _discounts[i].burnAmount
            ) {
                revert InvalidDiscount(i);
            }
        }
    }
}


interface IBabyDogeToken {
    function _taxFee() external returns(uint256);
    function _liquidityFee() external returns(uint256);
}