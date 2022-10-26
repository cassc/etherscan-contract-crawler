// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorInterface.sol";


/**
 * @title BLB Initial Offering
 *
 * @dev BLB Token is offered in BNB, BUSD and USDT.
 * @dev the prices are set in USD and calculated to corresponding BNB in 
 *   every buy transaction via chainlink price feed aggregator.
 * @dev since solidity does not support floating variables, all prices are
 *   multiplied by 10^18 to embrace decimals.
 */
contract BLBIO is Ownable {

    //price feed aggregator
    AggregatorInterface immutable AGGREGATOR_BUSD_BNB;

    IERC20 public BLB;
    IERC20 public BUSD;

    /**
     * @return price of the token in USD.
     *
     * @notice multiplied by 10^18.
     */
    uint256 public priceInUSD;


    /**
     * @dev emits when a user buys BLB, paying in BNB.
     */
    event BuyInBNB(uint256 indexed amountBLB, uint256 indexed amountBNB);

    /**
     * @dev emits when a user buys BLB, paying in BUSD.
     */
    event BuyInBUSD(uint256 indexed amountBLB, uint256 indexed amountBUSD);

    /**
     * @dev emits when the owner sets a new price for the BLB token (in USD).
     */
    event SetPriceInUSD(uint256 indexed newPrice);

    /**
     * @dev emits when the owner withdraws any amount of BNB or ERC20 token.
     *  
     * @notice if the withdrawing token is BNB, tokenAddr equals address zero.
     */
    event Withdraw(address indexed tokenAddr, uint256 indexed amount);


    constructor() {
        BLB = IERC20(0x3034e7400F7DE5559475a6f0398d26991f965ca3); 
        BUSD = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
        AGGREGATOR_BUSD_BNB = AggregatorInterface(0x87Ea38c9F24264Ec1Fff41B04ec94a97Caf99941);
        
        setPriceInUSD(10 ** 18); //equals 1 USD
    }


    /**
     * @return price of the token in BNB corresponding to the USD price.
     *
     * @notice multiplied by 10^18.
     */
    function priceInBNB() public view returns(uint256) {
        return uint256(AGGREGATOR_BUSD_BNB.latestAnswer())
            * priceInUSD
            / 10 ** 18;
    }


    /**
     * @dev buy BLB Token paying in BNB.
     *
     * @notice multiplied by 10^18.
     * @notice maximum tolerance 2%.
     *
     * @notice requirement:
     *   - there must be sufficient BLB token in ICO.
     *   - required amount must be paid in BNB.
     *
     * @notice emits a BuyInBNB event
     */
    function buyInBNB(uint256 amount) public payable {
        require(msg.value >= amount * priceInBNB() * 98 / 10**20, "insufficient fee");
        require(BLB.balanceOf(address(this)) >= amount, "insufficient BLB in the contract");
        BLB.transfer(msg.sender, amount);
        emit BuyInBNB(amount, msg.value);
    }

    /**
     * @dev buy BLB Token paying in BUSD.
     *
     * @notice multiplied by 10^18.
     *
     * @notice requirement:
     *   - there must be sufficient BLB token in ICO.
     *   - Buyer must approve the ICO to spend required BUSD.
     *
     * @notice emits a BuyInBUSD event
     */
    function buyInBUSD(uint256 amount) public {
        require(BLB.balanceOf(address(this)) >= amount, "insufficient BLB in the contract");
        uint256 payableBUSD = priceInUSD * amount / 10 ** 18;
        BUSD.transferFrom(msg.sender, address(this), payableBUSD); 
        BLB.transfer(msg.sender, amount);       
        emit BuyInBUSD(amount, payableBUSD);
    }

    /**
     * @dev set ticket price in USD;
     *
     * @notice multiplied by 10^18.
     *
     * @notice requirement:
     *   - only owner of the contract can call this function.
     *
     * @notice emits a SetPriceInUSD event
     */
    function setPriceInUSD(uint256 _priceInUSD) public onlyOwner {
        priceInUSD = _priceInUSD;
        emit SetPriceInUSD(_priceInUSD);
    }

    /**
     * @dev withdraw ERC20 tokens from the contract.
     *
     * @notice requirement:
     *   - only owner of the contract can call this function.
     *
     * @notice emits a Withdraw event
     */
    function withdrawERC20(address tokenAddr, uint256 amount) public onlyOwner {
        IERC20(tokenAddr).transfer(msg.sender, amount);
        emit Withdraw(tokenAddr, amount);
    }


    /**
     * @dev withdraw BNB from the contract.
     *
     * @notice requirement:
     *   - only owner of the contract can call this function.
     *
     * @notice emits a Withdraw event(address zero as the BNB token)
     */
    function withdraw(uint256 amount) public onlyOwner {
        payable(msg.sender).transfer(amount);
        emit Withdraw(address(0), amount);
    }
}