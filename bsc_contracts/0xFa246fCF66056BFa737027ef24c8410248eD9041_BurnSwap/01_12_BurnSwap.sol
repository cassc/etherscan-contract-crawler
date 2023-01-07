// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;


import "IERC20.sol";
import "Ownable.sol";
import "Pausable.sol";
import "oburn.sol";
import "IUniswapV2Router02.sol";

contract BurnSwap is Pausable, Ownable {
    // Mapping to determine which addresses are exempt from the USDC fee taken upon buys and sells in this contract.
    mapping (address => bool) private _addressesExemptFromFees;

    // Mapping to determine if an address is blacklisted from buying and selling OBURN with this contract.
    mapping (address => bool) private _blacklistedAddresses;

    // Mapping to determine the amount of USDC collected for each address (tax taken from each address on buy).
    mapping (address => uint256) public addressToUSDCCollected;

    // Mapping to determine the amount of OBURN sent to the dead wallet for each address (tax taken from each address on sell).
    mapping (address => uint256) public addressToOBURNBurnt;    

    // Total USDC collected from all transaction fees.
    uint256 public USDCCollected = 0;

    // Total OBURN burnt from all transaction fees.
    uint256 public OBURNBurnt = 0;

    // References the QuickSwap router for buying and selling OBURN.
    IUniswapV2Router02 public quickSwapRouter;

    // Address of the OBURN pair.
    address public quickSwapPair;

    // Address of the dead wallet to send OBURN on sells for burning.
    address public deadWallet = 0x000000000000000000000000000000000000dEaD;

    // Token interface for OBURN.
    OnlyBurns private _oburn;

    // Token interface for USDC.
    IERC20 private _usdc;

    // Event to emit when a user is made exempt or included again in fees.
    event ExemptAddressFromFees(address indexed newAddress, bool indexed value);

    // Event to emit whenever someone is added or removed from the blacklist.
    event AddOrRemoveUserFromBlacklist(address indexed user, bool indexed blacklisted);

    // Event to emit whenever OBURN is bought with USDC.
    event oburnBuy(address indexed user, uint256 oburnAmount, uint256 usdcAmount);

    // Event to emit whenever OBURN is sold for USDC.
    event oburnSell(address indexed user, uint256 oburnAmount, uint256 usdcAmount);

    constructor(address initRouterAddress, address initOBURNPairAddress, address payable initOBURNAddress, address initUSDCAddress) {
        quickSwapRouter = IUniswapV2Router02(initRouterAddress);
        quickSwapPair = initOBURNPairAddress;
        _oburn = OnlyBurns(initOBURNAddress);
        _usdc = IERC20(initUSDCAddress);

        _oburn.approve(initRouterAddress, type(uint256).max);
        _usdc.approve(initRouterAddress, type(uint256).max);
        _usdc.approve(msg.sender, type(uint256).max);
    }

    /**
    @dev Function to purchase OBURN with this contract - routes the transaction through QuickSwap and takes the fee out on the USDC side.
    @param amountOBURN the amount of OBURN to purchase (slippage factored in during buy) - if 0, just get as much OBURN as possible with the USDC amount supplied
    @param amountUSDC the amount of USDC to sell - if 0, sell the USDC required to get the OBURN amount specified
    @param slippage the slippage for the OBURN buy. 5% is 5, 10% is 10, etc
    */
    function purchaseOBURN(uint256 amountOBURN, uint256 amountUSDC, uint256 slippage) external whenNotPaused {
        require(slippage < 100, "Slippage must be less than 100.");
        require(amountOBURN > 0 || amountUSDC > 0, "Either the amount of OBURN to buy or the amount of USDC to sell must be specified.");
        require(!_blacklistedAddresses[msg.sender], "You have been blacklisted from trading OBURN through this contract.");

        address[] memory path = new address[](2);
        path[0] = address(_usdc);
        path[1] = address(_oburn);

        uint256 amountUSDCNeeded = amountUSDC;
        uint256 oburnBuyFee = _oburn.buyFee();
        uint[] memory amounts = new uint[](2);

        if (amountUSDC == 0) {
            amounts = quickSwapRouter.getAmountsIn(amountOBURN, path);
            amountUSDCNeeded = amounts[0] * ((100 + slippage) / 100);
        }

        uint256 amountUSDCAfterTax = amountUSDCNeeded;
        if (!_addressesExemptFromFees[msg.sender]) {
            addressToUSDCCollected[msg.sender] += amountUSDCNeeded * oburnBuyFee / 100;
            USDCCollected += amountUSDCNeeded * oburnBuyFee / 100;
            amountUSDCAfterTax = amountUSDCNeeded * (100 - oburnBuyFee) / 100;
        }

        _usdc.transferFrom(msg.sender, address(this), amountUSDCNeeded);

        if (amountUSDC > 0) {
            uint256 minimumOBURNNeeded = 0;

            if (amountOBURN > 100) {
                if (_addressesExemptFromFees[msg.sender]) {
                    minimumOBURNNeeded = amountOBURN * (100 - slippage) / 100;                    
                }
                else {
                    minimumOBURNNeeded = amountOBURN * (100 - slippage - oburnBuyFee) / 100;
                }
            }

            amounts = quickSwapRouter.swapExactTokensForTokens(
                amountUSDCAfterTax,
                minimumOBURNNeeded,
                path,
                address(this),
                block.timestamp
            );
        }
        else {
            uint256 amountOBURNOut = amountOBURN;
            if (!_addressesExemptFromFees[msg.sender]) {
                amountOBURNOut = amountOBURN * (100 - oburnBuyFee) / 100;
            }

            amounts = quickSwapRouter.swapTokensForExactTokens(
                amountOBURNOut,
                amountUSDCAfterTax,
                path,
                address(this),
                block.timestamp
            );            
        }

        _oburn.transfer(msg.sender, amounts[1]);

        if (amounts[0] < amountUSDCAfterTax) {
            _usdc.transfer(msg.sender, amountUSDCAfterTax - amounts[0]);
        }

        emit oburnBuy(msg.sender, amounts[0], amounts[1]);
    }

    /**
    @dev Function to sell OBURN with this contract - routes the transaction through QuickSwap and takes the fee out on the USDC side.
    @param amountOBURN the amount of OBURN to sell - if 0, just sell the amount of USDC supplied
    @param amountUSDC the amount of USDC to sell (slippage factored in during sell) - if 0, sell the USDC necessary to get the OBURN amount specified
    @param slippage the slippage for the OBURN sell. 5% is 5, 10% is 10, etc
    */
    function sellOBURN(uint256 amountOBURN, uint256 amountUSDC, uint256 slippage) external whenNotPaused {
        require(slippage < 100, "Slippage must be less than 100.");
        require(amountOBURN > 0 || amountUSDC > 0, "Either the amount of OBURN to buy or the amount of USDC to sell must be specified.");
        require(!_blacklistedAddresses[msg.sender], "You have been blacklisted from trading OBURN through this contract.");

        address[] memory path = new address[](2);
        path[0] = address(_oburn);
        path[1] = address(_usdc);

        uint256 amountOBURNNeeded = amountOBURN;
        uint256 oburnSellFee = _oburn.sellFee();
        uint[] memory amounts = new uint[](2);

        if (amountOBURN == 0) {
            amounts = quickSwapRouter.getAmountsIn(amountUSDC, path);
            amountOBURNNeeded = amounts[0] * ((100 + slippage) / 100);
        }

        _oburn.transferFrom(msg.sender, address(this), amountOBURNNeeded);

        uint256 amountOBURNAfterTax = amountOBURNNeeded;
        if (!_addressesExemptFromFees[msg.sender]) {
            amountOBURNAfterTax = amountOBURNNeeded * (100 - oburnSellFee) / 100;
            addressToOBURNBurnt[msg.sender] += amountOBURNNeeded * oburnSellFee / 100;
            OBURNBurnt += amountOBURNNeeded * oburnSellFee / 100;
            _oburn.transfer(deadWallet, amountOBURNNeeded * oburnSellFee / 100);
        }

        if (amountOBURN > 0) {
            uint256 minimumUSDCNeeded = 0;

            if (amountUSDC > 100) {
                if (_addressesExemptFromFees[msg.sender]) {
                    minimumUSDCNeeded = amountUSDC * (100 - slippage) / 100;
                }
                else {
                    minimumUSDCNeeded = amountUSDC * (100 - slippage - oburnSellFee) / 100;
                }
            }

            amounts = quickSwapRouter.swapExactTokensForTokens(
                amountOBURNAfterTax,
                minimumUSDCNeeded,
                path,
                address(this),
                block.timestamp
            );
        }
        else {
            uint256 amountUSDCOut = amountUSDC;
            if (!_addressesExemptFromFees[msg.sender]) {
                amountUSDCOut = amountUSDC * (100 - oburnSellFee) / 100;
            }

            amounts = quickSwapRouter.swapTokensForExactTokens(
                amountUSDCOut,
                amountOBURNAfterTax,
                path,
                address(this),
                block.timestamp
            );             
        }

        _usdc.transfer(msg.sender, amounts[1]);

        if (amounts[0] < amountOBURNAfterTax) {
            _oburn.transfer(msg.sender, amountOBURNAfterTax - amounts[0]);
        }        

        emit oburnSell(msg.sender, amounts[1], amounts[0]);
    }

    /**
    @dev Only owner function to extract USDC from this address that has been collected from transaction fees.
    */
    function withdrawUSDC() external onlyOwner {
        uint256 currUSDCBalance = _usdc.balanceOf(address(this));
        require(currUSDCBalance > 0, "Contract does not have any USDC to withdraw currently.");
        _usdc.transfer(owner(), currUSDCBalance);
    }

    /**
    @dev Only owner function to change the reference to the QuickSwap router.
    @param newQuickSwapRouterAddress the new QuickSwap router address
    */
    function changeQuickSwapRouter(address newQuickSwapRouterAddress) external onlyOwner {
        quickSwapRouter = IUniswapV2Router02(newQuickSwapRouterAddress);
    }

    /**
    @dev Only owner function to pause the exchange.
    */
    function pauseExchange() external onlyOwner {
        _pause();
    }

    /**
    @dev Only owner function to unpause the exchange.
    */
    function unpauseExchange() external onlyOwner {
        _unpause();
    }    

    /**
    @dev Only owner function to exempt or unexempt a user from trading fees.
    @param user the address that will be exempt or unexempt from fees
    @param exempt boolean to determine if the transaction is to remove or add a user to fees
    */
    function exemptAddressFromFees(address user, bool exempt) public onlyOwner {
        require(user != address(0), "Exempt user cannot be the zero address.");
        require(_addressesExemptFromFees[user] != exempt, "Already set to this value.");

        _addressesExemptFromFees[user] = exempt;

        emit ExemptAddressFromFees(user, exempt);
    }

    /**
    @dev Only owner function to blacklist or unblacklist a user from trading OBURN with this contract.
    @param user the address of the user being blacklisted or unblacklisted
    @param blacklist boolean to determine if the user is going to be blacklisted or unblacklisted
    */
    function blacklistOrUnblacklistUser(address user, bool blacklist) public onlyOwner {
        require(user != address(0), "Blacklist user cannot be the zero address.");
        require(_blacklistedAddresses[user] != blacklist, "Already set to this value.");
        _blacklistedAddresses[user] = blacklist;
        emit AddOrRemoveUserFromBlacklist(user, blacklist);
    }

    /**
    @dev Getter function to return if a specified address is exempt from fees when trading OBURN with this contract.
    @param excludedAddress the address being looked up to determine if they are exempt from fees
    @return boolean which represents whether or not the specified address is exempt from fees
    */
    function getAddressExemptFromFees(address excludedAddress) public view returns (bool) {
        return _addressesExemptFromFees[excludedAddress];
    }

    /**
    @dev Getter function to return if a specified address is blacklisted from trading OBURN with this contract.
    @param blacklistedAddress the address being looked up to determine if they are blacklisted
    @return boolean which represents whether or not the specified address is blacklisted
    */
    function getAddressBlacklisted(address blacklistedAddress) public view returns (bool) {
        return _blacklistedAddresses[blacklistedAddress];
    }
}