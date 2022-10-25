// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "hardhat/console.sol";
import "./ITaxToken.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

interface IOwnable {
    function owner() external view returns (address);
}

abstract contract TaxableRouter is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    // Wallets authorized to set fees for contracts.
    mapping(address => address) public feeOwners;

    /// @notice Modifier which only allows fee owners to change fees at all.
    /// @param token: Token of which `msg.sender` has to be the fee owner of.
    modifier byFeeOwner(address token) {
        require(msg.sender == feeOwners[token]);
        _;
    }

    // The taxes WE take from our clients.
    struct TokenBaseTax {
        bool isActive;
        uint16 tax;
    }
    // Remembers if a token has been registered by its owner to activate taxing.
    mapping(address => TokenBaseTax) public tokenBaseTax;
    /// @notice Makes sure only to take taxes on tax-activated tokens.
    /// @param token: Token to check if activated.
    modifier taxActive(address token) {
        if(tokenBaseTax[token].isActive){
            _;
        }
    }

    // Behaves like a constructor, but for upgradeables.
    function initialize() initializer internal {
        __ReentrancyGuard_init();
        __Ownable_init();
    }

    event SetTaxTierLevel(address, uint16);
    /// @notice Allows us to set a tax tier level for a certain token.
    /// @notice HOWEVER we can only make it "better".
    /// @notice So for tokens being unitialized we can set a max fee of 1%.
    /// @notice For tokens that are already initialized we can only set a lower fee than exists.
    /// @notice This is a safety measure for our clients.
    /// @param token: Token to set tax tier for.
    /// @param tax: Taxes users have to pay (send to this router). Max 1% (but you can get less ;)).
    function setTaxTierLevel(address token, uint16 tax)
        external onlyOwner {
            // Max tax is 1%.
            require(tax <= 100, "CCM: SET_TAX_TIER_LEVEL_INVALID_TAX");
            TokenBaseTax memory taxEntry = tokenBaseTax[token];
            // If there is an entry the new tax has to be BETTER.
            require(!taxEntry.isActive || tax < taxEntry.tax, "CCM: SET_TAX_TIER_LEVEL_INVALID_TAX_UPDATE");
            tokenBaseTax[token] = TokenBaseTax(true, tax);
            emit SetTaxTierLevel(token, tax);
        }
    
    event ChoseTaxTierLevel(address, address);
    /// @notice Let's a fee owner choose a tier level by sending in the amount of BNB.
    /// @param token: Token to define a tax tier for.
    function chooseTaxTierLevel(address token)
     external payable byFeeOwner(token) {
        // We have a tier system here:
        // ----------------------------------------------
        // | Level      | Cost (in BNB) | Tax per trade |
        // ---------------------------------------------|
        // | Beginner   | 0             | 1%            |
        // | Apprentice | 5             | 0.5%          |
        // | Expert     | 10            | 0.3%          |
        // | Master     | Ask us!       | 0%            |
        // ----------------------------------------------
        // The tier you get solely depends on the BNB you send in.
        // Your tier level CAN be changed later. Just call the method again.
        // We'll make sure that you can only upgrade e.g. not pay higher taxes than before, so no downgrade for you.
        uint apprenticeFee = 5 ether;
        uint expertFee = 10 ether;
        // The BNB sent in has to be one of the levels, otherwise we reject.
        // We also only want to have that exact amount, not more, not less.
        if(msg.value == expertFee){
            // Token must not be on expert level already
            TokenBaseTax memory existing = tokenBaseTax[token];
            require(!existing.isActive || existing.tax > 30);
            tokenBaseTax[token] = TokenBaseTax(true, 30);
        } else if(msg.value == apprenticeFee){
            // Token must not be on apprentice level or better already.
            TokenBaseTax memory existing = tokenBaseTax[token];
            require(!existing.isActive || existing.tax > 50);
            tokenBaseTax[token] = TokenBaseTax(true, 50);
        } else if(msg.value == 0) {
            // Token must not be initialized.
            TokenBaseTax memory existing = tokenBaseTax[token];
            require(!existing.isActive);
            tokenBaseTax[token] = TokenBaseTax(true, 100);
        } else {
            // No tier level selected. Reject.
            require(false, "CCM: NO_TIER_LEVEL_SELECTED");
        }
        emit ChoseTaxTierLevel(msg.sender, token);
    }

    event ClaimedInitialFeeOwnership(address, address);
    /// @notice Let's a token owner claim the initial fee ownership.
    /// @dev In order to make this working your token has to implement an owner() method 
    /// @dev that returns the address of the token owner.
    /// @dev After claim you can transfer the fee ownership if you like.
    /// @param token: Fee ownership to claim for token. You have to be the token owner.
    function claimInitialFeeOwnership(address token) external {
        require(feeOwners[token] == address(0x0), "CCM: FEE_OWNER_ALREADY_INITIALIZED");
        // The token owner shall have the power to claim the initial fee ownership.
        require(msg.sender == IOwnable(token).owner(), "CCM: FEE_OWNER_IS_NOT_TOKEN_OWNER");
        feeOwners[token] = msg.sender;
        emit ClaimedInitialFeeOwnership(msg.sender, token);
    }
    event TransferedFeeOwnership(address, address, address);
    /// @notice Transfers fee ownership to target owner.
    /// @notice This does not transfer the receiving of fees! It only allows `newOwner` to set new fees.
    /// @notice Obviously `newOwner` can now set itself to the fee receiver, but it's not happening automatically.
    /// @param token: The token to set fees for.
    /// @param newOwner: The new fee ownership holder.
    function transferFeeOwnership(
        address token, address newOwner
    ) external byFeeOwner(token) {
        feeOwners[token] = newOwner;
        emit TransferedFeeOwnership(msg.sender, token, newOwner);
    }
    /// @notice Allows the router owner to get the ETH given by for example tax tier level setup.
    function withdrawETH() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success);
    }
    /// @notice Transfers any ERC20 token balance to the owner.
    function withdrawAnyERC20Token(address token) external onlyOwner {
        IERC20(token).transfer(owner(), IERC20(token).balanceOf(address(this)));
    }
    /// @notice Helper method to calculate the takes to take.
    /// @dev Actually we want to first multiply and then divide.
    /// @dev Reason is that division is potentially lossy when working on whole numbers.
    /// @dev For example 7 / 5 is 1.
    /// @dev Therefore first multiplying does not multiply with such a loss, hence increases accuracy.
    /// @dev But the multiplication could overflow which we don't want so we first check if that would happen
    /// @dev and if it is safe then we first multiply and then divide. Otherwise we just switch the ordering.
    function calculateTax(uint16 taxPercent, uint amount) private pure returns (uint tax) {
        if(taxPercent == 0) return 0;

        if(amount >= ~uint(0) / taxPercent)
            tax = amount / 10000 * taxPercent;
        else
            tax = amount * taxPercent / 10000;
    }
    /// @notice Takes the router tax defined by your token's tax level.
    /// @param token Your token to get your token's specific router tax.
    /// @param amount The total amount to take taxes from
    /// @return taxTaken The tax taken by us (the router)
    function takeRouterTax(address token, uint amount) private view returns (uint taxTaken){
        taxTaken = calculateTax(tokenBaseTax[token].tax, amount);
    }
    
    /// @notice Takes buy taxes when someone buys YOUR token.
    /// @notice For us for example it would be the path: WETH => CCMT.
    /// @param token The token being bought (you).
    /// @param taxableToken The token to take taxes from (WETH e.g.)
    /// @param sender The sender of the swap transaction. Probably msg.sender most of the time.
    /// @param amount The amount they put IN (WETH e.g.).
    /// @return amountLeft The amount of the given IN asset (WETH e.g.) that will actually used to buy.
    function takeBuyTax(
        address token, address taxableToken, 
        address sender, uint amount
    ) internal taxActive(token) returns(uint amountLeft, uint tokenTax) {
        // First ask the token how many taxes it wants to take.
        (uint tokenTaxToTake) = ITaxToken(token).takeTax(
            taxableToken, sender, true, amount
        );
        require(tokenTaxToTake <= amount, "CCM: TAX_TOO_HIGH");
        
        // We take fees based upon your tax tier level,
        uint routerTaxToTake = takeRouterTax(token, amount);
        amountLeft = amount - tokenTaxToTake - routerTaxToTake;
        tokenTax = tokenTaxToTake;
    }
    /// @notice Takes sell taxes when someone sells YOUR token.
    /// @notice For us for example it would be the path: CCMT => WETH.
    /// @param token The token being sold (you).
    /// @param taxableToken The token to take taxes from (WETH e.g.)
    /// @param sender The sender of the swap transaction. Probably msg.sender most of the time.
    /// @param amount The amount they want to take OUT (WETH e.g.).
    /// @return amountLeft The amount of the OUT asset (WETH e.g.) that will actually sent to the seller.
    function takeSellTax(
        address token, address taxableToken, 
        address sender, uint amount
    ) internal taxActive(token) returns(uint amountLeft, uint tokenTax)  {
        // First ask the token how many taxes it wants to take.
        (uint tokenTaxToTake) = ITaxToken(token).takeTax(
            taxableToken, sender, false, amount
        );
        require(tokenTaxToTake <= amount, "CCM: TAX_TOO_HIGH");
        
        uint routerTaxToTake = takeRouterTax(token, amount);
        amountLeft = amount - tokenTaxToTake - routerTaxToTake;
        tokenTax = tokenTaxToTake;
    }
}