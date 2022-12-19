// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IRouterV2.sol";
import "./interfaces/IFactoryV2.sol";
import "./interfaces/IShibaWorldCupManager.sol";

/**
 * @title ShibaWorldCupTeam
 * @notice ERC20 representing a team participating in the world cup, the sell tax of each team will be distributed to the holders of the token of the winning team.
 */
contract ShibaWorldCupTeam is ERC20, ERC20Burnable, Ownable {
    //---------- Contracts ----------//
    IRouterV2 public dexRouter; // DEX router contract.
    IShibaWorldCupManager public immutable manager; // ShibaWorldCupManager contract.

    //---------- Variables ----------//
    address public lpPair; // Pair that contains the liquidity for the taxSwap.
    bool public hasLiquidity; // Flag to check if you already have liquidity.
    bool private onSwap; // Flag to check if on swap tax tokens.

    //---------- Storage -----------//
    mapping(address => bool) private _lpPairs; // Contains the liquidity pairs of the token.

    //---------- Events -----------//
    event ModifiedPair(address pair, bool enabled);
    event NewRouter(address newRouter, address lpPair);

    //---------- Constructor ----------//
    constructor(
        IRouterV2 _dexRouter,
        IShibaWorldCupManager _manager,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {
        _mint(msg.sender, 1_000_000 * 10**decimals());
        dexRouter = _dexRouter;
        manager = _manager;
        lpPair = IFactoryV2(dexRouter.factory()).createPair(
            manager.SWC(),
            address(this)
        );
        _lpPairs[lpPair] = true;
        hasLiquidity = false;
    }

    //---------- Modifiers ----------//
    /**
     * @dev Modify the status of the boolean onSwap for checks in the transfer.
     */
    modifier swapLocker() {
        onSwap = true;
        _;
        onSwap = false;
    }

    //----------- Internal Functions -----------//
    /**
     * @dev Swap the sell tax and send it to the treasury.
     * @param amount of tokens to swap.
     */
    function _taxSwap(uint256 amount) internal swapLocker {
        if (allowance(address(this), address(dexRouter)) < amount) {
            _approve(address(this), address(dexRouter), type(uint256).max);
        }

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = manager.SWC();

        try
            dexRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amount,
                0,
                path,
                address(manager),
                block.timestamp
            )
        {} catch {
            return;
        }
    }

    /**
     * @dev Check if the pair has liquidity.
     */
    function _checkLiquidity() internal {
        require(!hasLiquidity, "Already have liquidity");
        if (balanceOf(lpPair) > 0) {
            hasLiquidity = true;
        }
    }

    /**
     * @dev Override the internal transfer function to apply the sell tax and distribute it.
     * @param sender address of origin.
     * @param recipient destination address.
     * @param amount tokens to transfer.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        require(
            sender != address(0x0),
            "ERC20: transfer from the zero address"
        );
        require(
            recipient != address(0x0),
            "ERC20: transfer to the zero address"
        );
        require(amount > 0, "Transfer amount must be greater than zero");

        if (!hasLiquidity) {
            _checkLiquidity();
        }

        if (!onSwap) {
            if (hasLiquidity) {
                uint256 balance = balanceOf(address(this));
                if (balance > 0) {
                    _taxSwap(balance);
                }
            }
        }

        // check whitelist
        bool excluded = isExcluded(sender) || isExcluded(recipient);
        bool buy = _lpPairs[sender];
        bool sell = _lpPairs[recipient];

        if (excluded) {
            super._transfer(sender, recipient, amount);
        } else {
            if (buy) {
                require(manager.isTradingEnabled(), "Trading disabled");
                super._transfer(sender, recipient, amount);
            } else if (sell) {
                require(manager.isTradingEnabled(), "Trading disabled");
                uint256 sellTax = manager.sellFee();
                // sell tax amount
                uint256 taxAmount = (amount * sellTax) / 100;

                // tax transfer sent to this contract
                super._transfer(sender, address(this), taxAmount);
                // default transfer sent to recipient
                super._transfer(sender, recipient, amount - taxAmount);
            } else {
                super._transfer(sender, recipient, amount);
            }
        }
    }

    //----------- External Functions -----------//
    /**
     * @notice Forward the ETH to the treasury wallet.
     */
    receive() external payable {
        uint256 amount = msg.value;
        (bool success, ) = payable(address(manager)).call{
            value: amount,
            gas: 35000
        }("");
        require(success);
    }

    /**
     * @notice Check if a address is excluded from tax.
     * @param account address to check.
     * @return Boolean if excluded or not.
     */
    function isExcluded(address account) public view returns (bool) {
        if (account == address(this)) {
            return true;
        }
        return manager.isExcluded(account);
    }

    /**
     * @notice Check if a pair address is on list.
     * @param pair address to check.
     * @return Boolean if on list or not.
     */
    function isLpPair(address pair) external view returns (bool) {
        return _lpPairs[pair];
    }

    //----------- Owner Functions -----------//
    /**
     * @notice Set address in pairs list.
     * @param pair address to set.
     * @param enabled boolean to enable or disable.
     */
    function setLpPair(address pair, bool enabled) external onlyOwner {
        require(pair != address(0x0), "Invalid pair");
        _lpPairs[pair] = enabled;
        emit ModifiedPair(pair, enabled);
    }

    /**
     * @notice Change the dex router address before having liquidity.
     * @param newRouter address to set.
     */
    function setRouter(address newRouter) external onlyOwner {
        require(newRouter != address(0x0), "Invalid router");
        require(!hasLiquidity, "Already have liquidity");
        IRouterV2 router = IRouterV2(newRouter);
        address newPair = IFactoryV2(router.factory()).getPair(
            address(this),
            router.WETH()
        );
        if (newPair == address(0x0)) {
            lpPair = IFactoryV2(router.factory()).createPair(
                address(this),
                router.WETH()
            );
        } else {
            lpPair = newPair;
        }
        dexRouter = router;
        _approve(address(this), address(dexRouter), type(uint256).max);
        emit NewRouter(newRouter, lpPair);
    }

    /**
     * @notice Burn tokens of sell tax.
     * @param amount to burn.
     */
    function burnTax(uint256 amount) external onlyOwner {
        uint256 balance = balanceOf(address(this));
        require(amount > 0 && balance > 0, "Zero amount");
        uint256 toBurn = amount > balance ? balance : amount;
        _burn(address(this), toBurn);
    }

    /**
     * @notice Swap tokens of sell tax.
     * @param amount to swap.
     */
    function swapTax(uint256 amount) external onlyOwner {
        uint256 balance = balanceOf(address(this));
        require(amount > 0 && balance > 0, "Zero amount");
        uint256 toSwap = amount > balance ? balance : amount;
        _taxSwap(toSwap);
    }
}