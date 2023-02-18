// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;


import "IERC20.sol";
import "Ownable.sol";
import "Pausable.sol";
import "oburn.sol";
import "IUniswapV2Router02.sol";

contract BurnSwap is Pausable, Ownable {
    // Mapping to determine which addresses are exempt from the BUSD fee taken upon buys and sells in this contract.
    mapping (address => bool) private _addressesExemptFromFees;

    // Mapping to determine if an address is blacklisted from buying and selling OBURN with this contract.
    mapping (address => bool) private _blacklistedAddresses;

    // Mapping to determine the amount of BUSD collected for each address (tax taken from each address on buy).
    mapping (address => uint256) public addressToBUSDCollected;

    // Mapping to determine the amount of OBURN sent to the dead wallet for each address (tax taken from each address on sell).
    mapping (address => uint256) public addressToOBURNBurnt;    

    // Total BUSD collected from all transaction fees.
    uint256 public BUSDCollected = 0;

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

    // Token interface for BUSD.
    IERC20 private _busd;

    // Event to emit when a user is made exempt or included again in fees.
    event ExemptAddressFromFees(address indexed newAddress, bool indexed value);

    // Event to emit whenever someone is added or removed from the blacklist.
    event AddOrRemoveUserFromBlacklist(address indexed user, bool indexed blacklisted);

    // Event to emit whenever OBURN is bought with BUSD.
    event oburnBuy(address indexed user, uint256 oburnAmount, uint256 busdAmount);

    // Event to emit whenever OBURN is sold for BUSD.
    event oburnSell(address indexed user, uint256 oburnAmount, uint256 busdAmount);

    constructor(address initRouterAddress, address initOBURNPairAddress, address payable initOBURNAddress, address initBUSDAddress) {
        quickSwapRouter = IUniswapV2Router02(initRouterAddress);
        quickSwapPair = initOBURNPairAddress;
        _oburn = OnlyBurns(initOBURNAddress);
        _busd = IERC20(initBUSDAddress);

        _oburn.approve(initRouterAddress, type(uint256).max);
        _busd.approve(initRouterAddress, type(uint256).max);
        _busd.approve(msg.sender, type(uint256).max);
    }

    /**
    @dev Function to purchase OBURN with this contract - routes the transaction through QuickSwap and takes the fee out on the BUSD side.
    @param amountOBURN the amount of OBURN to purchase (slippage factored in during buy) - if 0, just get as much OBURN as possible with the BUSD amount supplied
    @param amountBUSD the amount of BUSD to sell - if 0, sell the BUSD required to get the OBURN amount specified
    @param slippage the slippage for the OBURN buy. 5% is 5, 10% is 10, etc
    */
    function purchaseOBURN(uint256 amountOBURN, uint256 amountBUSD, uint256 slippage) external whenNotPaused {
        require(slippage < 100, "Slippage must be less than 100.");
        require(amountOBURN > 0 || amountBUSD > 0, "Either the amount of OBURN to buy or the amount of BUSD to sell must be specified.");
        require(!_blacklistedAddresses[msg.sender], "You have been blacklisted from trading OBURN through this contract.");

        address[] memory path = new address[](2);
        path[0] = address(_busd);
        path[1] = address(_oburn);

        uint256 amountBUSDNeeded = amountBUSD;
        uint256 oburnBuyFee = _oburn.buyFee();
        uint[] memory amounts = new uint[](2);

        if (amountBUSD == 0) {
            amounts = quickSwapRouter.getAmountsIn(amountOBURN, path);
            amountBUSDNeeded = amounts[0] * ((100 + slippage) / 100);
        }

        uint256 amountBUSDAfterTax = amountBUSDNeeded;
        if (!_addressesExemptFromFees[msg.sender]) {
            addressToBUSDCollected[msg.sender] += amountBUSDNeeded * oburnBuyFee / 100;
            BUSDCollected += amountBUSDNeeded * oburnBuyFee / 100;
            amountBUSDAfterTax = amountBUSDNeeded * (100 - oburnBuyFee) / 100;
        }

        _busd.transferFrom(msg.sender, address(this), amountBUSDNeeded);

        if (amountBUSD > 0) {
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
                amountBUSDAfterTax,
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
                amountBUSDAfterTax,
                path,
                address(this),
                block.timestamp
            );            
        }

        _oburn.transfer(msg.sender, amounts[1]);

        if (amounts[0] < amountBUSDAfterTax) {
            _busd.transfer(msg.sender, amountBUSDAfterTax - amounts[0]);
        }

        emit oburnBuy(msg.sender, amounts[0], amounts[1]);
    }

    /**
    @dev Function to sell OBURN with this contract - routes the transaction through QuickSwap and takes the fee out on the BUSD side.
    @param amountOBURN the amount of OBURN to sell - if 0, just sell the amount of BUSD supplied
    @param amountBUSD the amount of BUSD to sell (slippage factored in during sell) - if 0, sell the BUSD necessary to get the OBURN amount specified
    @param slippage the slippage for the OBURN sell. 5% is 5, 10% is 10, etc
    */
    function sellOBURN(uint256 amountOBURN, uint256 amountBUSD, uint256 slippage) external whenNotPaused {
        require(slippage < 100, "Slippage must be less than 100.");
        require(amountOBURN > 0 || amountBUSD > 0, "Either the amount of OBURN to buy or the amount of BUSD to sell must be specified.");
        require(!_blacklistedAddresses[msg.sender], "You have been blacklisted from trading OBURN through this contract.");

        address[] memory path = new address[](2);
        path[0] = address(_oburn);
        path[1] = address(_busd);

        uint256 amountOBURNNeeded = amountOBURN;
        uint256 oburnSellFee = _oburn.sellFee();
        uint[] memory amounts = new uint[](2);

        if (amountOBURN == 0) {
            amounts = quickSwapRouter.getAmountsIn(amountBUSD, path);
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
            uint256 minimumBUSDNeeded = 0;

            if (amountBUSD > 100) {
                if (_addressesExemptFromFees[msg.sender]) {
                    minimumBUSDNeeded = amountBUSD * (100 - slippage) / 100;
                }
                else {
                    minimumBUSDNeeded = amountBUSD * (100 - slippage - oburnSellFee) / 100;
                }
            }

            amounts = quickSwapRouter.swapExactTokensForTokens(
                amountOBURNAfterTax,
                minimumBUSDNeeded,
                path,
                address(this),
                block.timestamp
            );
        }
        else {
            uint256 amountBUSDOut = amountBUSD;
            if (!_addressesExemptFromFees[msg.sender]) {
                amountBUSDOut = amountBUSD * (100 - oburnSellFee) / 100;
            }

            amounts = quickSwapRouter.swapTokensForExactTokens(
                amountBUSDOut,
                amountOBURNAfterTax,
                path,
                address(this),
                block.timestamp
            );             
        }

        _busd.transfer(msg.sender, amounts[1]);

        if (amounts[0] < amountOBURNAfterTax) {
            _oburn.transfer(msg.sender, amountOBURNAfterTax - amounts[0]);
        }        

        emit oburnSell(msg.sender, amounts[1], amounts[0]);
    }

    /**
    @dev Only owner function to extract BUSD from this address that has been collected from transaction fees.
    */
    function withdrawBUSD() external onlyOwner {
        uint256 currBUSDBalance = _busd.balanceOf(address(this));
        require(currBUSDBalance > 0, "Contract does not have any BUSD to withdraw currently.");
        _busd.transfer(owner(), currBUSDBalance);
    }

    /**
    @dev Only owner function to change the reference to the QuickSwap router.
    @param newQuickSwapRouterAddress the new QuickSwap router address
    */
    function changeQuickSwapRouter(address newQuickSwapRouterAddress) external onlyOwner {
        quickSwapRouter = IUniswapV2Router02(newQuickSwapRouterAddress);
        _oburn.approve(newQuickSwapRouterAddress, type(uint256).max);
        _busd.approve(newQuickSwapRouterAddress, type(uint256).max);
    }

    /**
    @dev Only owner function to change the reference to the QuickSwap pair.
    @param newQuickSwapPairAddress the new QuickSwap pair address
    */
    function changeQuickSwapPair(address newQuickSwapPairAddress) external onlyOwner {
        quickSwapPair = newQuickSwapPairAddress;
    }

    /**
    @dev Only owner function to change the reference to the OBURN token.
    @param newOBURNAddress the new OBURN token address
    */
    function changeOBURN(address payable newOBURNAddress) external onlyOwner {
        _oburn = OnlyBurns(newOBURNAddress);
        _oburn.approve(address(quickSwapRouter), type(uint256).max);
    }

    /**
    @dev Only owner function to change the reference to the BUSD token.
    @param newBUSDAddress the new BUSD token address
    */
    function changeBUSD(address newBUSDAddress) external onlyOwner {
        _busd = IERC20(newBUSDAddress);
        _busd.approve(address(quickSwapRouter), type(uint256).max);
        _busd.approve(msg.sender, type(uint256).max);
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