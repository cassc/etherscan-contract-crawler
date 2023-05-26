// SPDX-License-Identifier: UNLICENSED
/*
 * https://cannappscorp.com/ -- Global Cannabis Applications Corporation (GCAC)
 *
 * Address: Suite 830, 1100 Melville Street, Vancouver, British Columbia, V6E 4A6 Canada
 * Email: [email protected]
 *
 * As at 31-March-2021, GCAC is a publicly traded company on the Canadian Stock Exchange.
 *
 * Official GCAC Listing
 * https://www.thecse.com/en/listings/technology/global-cannabis-applications-corp
 *
 * Official GCAC Regulatory Filings 
 * https://www.sedar.com/DisplayCompanyDocuments.do?lang=EN&issuerNo=00036309
 *
 * This is an ERC-20 smart contract for the GCAC token that will be used as one side
 * of a Uniswap liquidity pool trading pair. This GCAC token has the following properties:
 *
 * 1. The number of GCAC tokens from this contract that will be initially added to the 
 *    Uniswap liquidity pool shall be 100,000. The amount of WETH added to the other side of
 *    the initial Uniswap liquidity pool shall be 5.
 * 2. GCAC hereby commits to swap an amount of WETH currency with the Uniswap GCAC<>WETH 
 *    trading pair every 3 months for no fewer than 8 quarters, i.e., 2 years, commencing 
 *    for the quarterly report as filed by GCAC for the quarter ending 31-March-2021.
 * 3. The value of the WETH currency swapped by GCAC shall be equal to 1% of GCAC's official
 *    'revenue', as disclosed in each of its quarterly regulatory filings. Each WETH
 *    swap shall be performed no later than 10 working days after the regulatory filing is
 *    available on the System for Electronic Document Analysis and Retrieval (SEDAR). SEDAR 
 *    is a mandatory document filing system for Canadian public companies.
 * 4. GCAC tokens returned by Uniswap from the quarterly swap of WETH shall be burned 
 *    by this smart contract, thereby reducing GCAC token circulating supply over time.
 * 5. This contract shall not be allowed mint any new GCAC tokens, i.e., no dilution.
 * 6. GCAC, the company, shall initially hold 100,000 GCAC tokens on its corporate
 *    balance sheet, i.e., the GCAC treasury tokens.
 * 7. GCAC's treasury tokens may only ever be swapped for WETH in Uniswap and are prevented
 *    from being transferred out of this contract to another exchange or wallet, i.e., no rug-pull.
 * 8. GCAC hereby commits to notify the DeFi community of its intent to withdraw liquidity from 
 *    Uniswap at least 3 months in advance. This contact enforces the liquidity-time-lock.
 * 9. GCAC hereby commits to notify the DeFi community of its intent to swap GCAC treasury tokens 
 *    on Uniswap at least 3 months in advance. This contact enforces the treasury-time-lock.
 *
 *
 * https://abbey.ch/         -- Abbey Technology GmbH, Zug, Switzerland
 * 
 * ABBEY DEFI
 * ========== 
 * 1. Decentralized Finance 'DeFi' is designed to be globally inclusive. 
 * 2. Centralized finance is based around national stock markets that have high barriers to entry. 
 * 3. The Abbey DeFi methodology offers companies listed on national stock exchanges exposure to DeFi.
 *
 * Abbey is a Uniswap-based DeFi service provider that allows public companies to offer people a novel 
 * way to speculate on the success of their business in a decentralized manner.
 * 
 * The premise is both elegant and simple, the public company commits to a marketing spend equal to 1% 
 * of its quarterly sales revenue. And, since it’s a public company, the exact value of this 1% is 
 * published in their public accounts, as filed quarterly with a national securities regulator.
 * 
 * Using Abbey as a Uniswap DeFi marketing agency, the public company spends 1% of its quarterly cash 
 * sales revenue on one side of a bespoke Uniswap trading contract. The other side of the Uniswap trade 
 * is the public company’s proprietary token that’s representing 1% of its future sales revenue.
 * 
 * DeFi traders wishing to speculate on the revenue growth of the public company deposit crypto-USD 
 * in return for “PUBCO-1%” Uniswap tokens. The Uniswap Automated Market Maker ensures DeFi market 
 * liquidity and legitimate price discovery. The more USD that the company deposits over time, the 
 * higher the value of the PUBCO-1% token, as held by DeFi speculators.
 *
*/
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title Global Cannabis Applications Corporation (GCAC) contract for Uniswap.
 * @author Abbey Technology GmbH
 * @notice Token contract for use with Uniswap.  Enforces restrictions outlined in the prospectus.
 */
contract GCACToken is ERC20 {

    enum TokenType { Unknown, GCAC, LiquidityPool }

    /**
     * @notice The details of a future company cashout.
     */
    struct Notice {
        // The maximum number of tokens proposed for sale.
        uint256 amount;

        // The date after which company tokens can be swapped.
        uint256 releaseDate;

        // Whether the notice given is for this contract's tokens (GCAC) or the
        // liquidity pool tokens created by Uniswap where fees are periodically
        // cashed in.
        TokenType tokenType;
    }

    // Event fired when a restricted wallet gives notice of a potential future trade.
    event NoticeGiven(address indexed who, uint256 amount, uint256 releaseDate, TokenType tokenType);

    /**
     * @notice Notice must be given to the public before treasury tokens can be swapped.
     */
    Notice public noticeTreasury;

    /**
     * @notice Notice must be given to the public before Liquidity Tokens can be removed from the pool.
     */
    Notice public noticeLiquidity;

    /**
    * @notice The account that created this contract, also functions as the liquidity provider.
    */
    address public owner;

    /**
     * @notice Holder of the company's 50% share of all Uniswap tokens.  Can only interact with the
     * Uniswap pair/router, is forbidden from trading tokens elsewhere.
     */
    address public treasury;

    /**
     * @notice The account that performs the 1% of sales buyback of tokens, all bought tokens are burned.
     * @dev They cannot be autoburned during transfer as the Uniswap client prevents the transaction.
     */
    address public buyback;

    /**
     * @notice The address of the Uniswap router, the liquidity provider and treasury can only interact with this
     * address.  This prevents trading outside of Uniswap for these accounts.
     */
    address public router;

    /**
     * @notice The address of the Uniswap Pair/ERC20 contract holding the Liquidity Pool tokens.
     */
    address public pairAddress;

    /**
     * @notice Restrict functionaly to the contract owner.
     */
    modifier onlyOwner {
        require(_msgSender() == owner, "You are not Owner.");
        _;
    }

    /**
     * @notice Restrict functionaly to the buyback account.
     */
    modifier onlyBuyback {
        require(_msgSender() == buyback, "You are not Buyback.");
        _;
    }

    constructor(uint256 initialSupply, string memory name, string memory symbol) ERC20(name, symbol) {
        owner = _msgSender();
        _mint(_msgSender(), initialSupply);
    }

    /**
     * Set the account that burns GCAC tokens periodically.
     */
    function setBuyback(address who) public onlyOwner {
        require(buyback == address(0), "The Buyback address can only be set once.");
        buyback = who;
    }

    /**
     * Set the address of the account holding GCAC tokens on behalf of the company.
     */
    function setTreasury(address who) public onlyOwner {
        require(treasury == address(0), "The Treasury address can only be set once.");
        treasury = who;
    }

    /**
     * Set the address of the Uniswap router, only this address is allowed to move Treasury tokens.
     */
    function setRouter(address who) public onlyOwner {
        require(router == address(0), "The Router address can only be set once.");
        router = who;
    }

    /**
     * Set the address of the Uniswap Pair/Pool contract.
     */
    function setPairAddress(address who) public onlyOwner {
        require(pairAddress == address(0), "The Pair address can only be set once.");
        pairAddress = who;
    }

    /**
     * @notice Treasury and Liquidity tokens must give advanced notice to the public before they can
     * be used.  The token type is determined by the address giving notice.
     *
     * @param who The address giving notice of a sale in the future.
     * @param amount The maximum number of tokens (in wei).
     * @param numSeconds The number of seconds the tokens cannot be sold for.
     */
    function giveNotice(address who, uint256 amount, uint256 numSeconds) public onlyOwner {
        require(pairAddress != address(0), "The Uniswap Pair contract address must be set.");
        require(who == treasury || who == address(this), "Only Treasury and Liquidity must give notice.");

        uint256 when = block.timestamp + (numSeconds * 1 seconds);

        TokenType tokenType;

        if(who == treasury) {
            require(noticeTreasury.releaseDate == 0 || block.timestamp >= noticeTreasury.releaseDate, "Cannot overwrite an active existing notice.");
            require(amount <= balanceOf(who), "Can't give notice for more GCAC tokens than owned.");
            tokenType = TokenType.GCAC;
            noticeTreasury = Notice(amount, when, tokenType);
        }
        else {
            require(noticeLiquidity.releaseDate == 0 || block.timestamp >= noticeLiquidity.releaseDate, "Cannot overwrite an active existing notice.");
            ERC20 pair = ERC20(pairAddress);
            require(amount <= pair.balanceOf(who), "Can't give notice for more Liquidity Tokens than owned.");
            tokenType = TokenType.LiquidityPool;
            noticeLiquidity = Notice(amount, when, tokenType);
        }

        emit NoticeGiven(who, amount, when, tokenType);
    }

    /**
     * @notice Enforce rules around the company accounts:
     * - Liquidity Pool Creator (owner) can never receive tokens back from Uniswap.
     * - Treasury can only send tokens to Uniswap.
     * - Tokens bought back by the company are immediateley burned.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal override {
        require(recipient != owner, "Liquidity Pool Creator cannot receive tokens.");
        require(sender != buyback, "Buyback cannot transfer tokens, it can only burn.");
        if(sender == treasury) {
            require(_msgSender() == router, "Treasury account tokens can only be moved by the Uniswap Router.");
            require(noticeTreasury.releaseDate != 0 && block.timestamp >= noticeTreasury.releaseDate, "Notice period has not been set or has not expired.");
            require(amount <= noticeTreasury.amount, "Treasury can't transfer more tokens than given notice for.");
            require(noticeTreasury.tokenType == TokenType.GCAC, "The notice given for this user is the wrong token type.");

            // Clear the remaining notice balance, this prevents giving notice on all tokens and
            // trickling them out.
            noticeTreasury = Notice(0, 0, TokenType.Unknown);
        }

        super._transfer(sender, recipient, amount);
    }

    /**
     * @notice Periodically draw down any fee entitlement from the Liquidity Pool after giving notice.
     * @param to The account to send the tokens to.
     * @param amount The number of tokens, in wei.
     */
    function transferLiquidityTokens(address to, uint256 amount) public onlyOwner {
        require(pairAddress != address(0), "The Uniswap Pair contract address must be set.");

        require(noticeLiquidity.releaseDate != 0 && block.timestamp >= noticeLiquidity.releaseDate, "Notice period has not been set or has not expired.");
        require(amount <= noticeLiquidity.amount, "Insufficient Liquidity Token balance.");
        require(noticeLiquidity.tokenType == TokenType.LiquidityPool, "The notice given for this user is the wrong token type.");

        ERC20 pair = ERC20(pairAddress);
        pair.transfer(to, amount);

        // Clear the notice even if only partially used.
        noticeLiquidity = Notice(0, 0, TokenType.Unknown);
    }

    /**
     * @notice The buyback account periodically buys tokens and then burns them to reduce the
     * total supply pushing up the price of the remaining tokens.
     */
    function burn() public onlyBuyback {
        _burn(buyback, balanceOf(buyback));
    }
}