// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorInterface.sol";
import "./BLBIOAdministration.sol";

/**
 * @title BLB Initial Offering
 *
 * @dev BLB Token is offered in BNB and BUSD(USDT).
 * @dev the prices are set in USD and calculated to corresponding BNB in 
 *   every purchase transaction via chainlink price feed aggregator.
 * @dev the purchased blbs are locked in the contract until the Initial offering
 *   ends. then the owner can unlock proper fraction to be claimed. 
 * @dev there are two sale plan; public sale price for small amounts and private sale
 *  price for large amounts of blb.
 * @dev since solidity does not support floating variables, all prices are
 *   multiplied by 10^18 to embrace decimals.
 */
contract BLBIO is BLBIOAdministration {

    //price feed aggregator
    AggregatorInterface immutable AGGREGATOR_BNB_USD;

    bool public soldOut; //false means users can purchase, true means blb sold out
    
    struct UserClaim {
        uint256 total;
        uint256 claimed;
        bool freeToClaim;
    }
    mapping(address => UserClaim) userClaims;


    constructor(
        address _BLBAddr,
        address _BUSDAddr,
        address _AGGREGATORAddr,
        uint256 _publicBLBsPerUSD,
        uint256 _privateBLBsPerUSD,
        uint256 _retailLimitUSD,
        uint256 _minUSDLimit
    ) {
        BLB = IERC20(_BLBAddr); 
        BUSD = IERC20(_BUSDAddr);
        AGGREGATOR_BNB_USD = AggregatorInterface(_AGGREGATORAddr);

        setBLBsPerUSD(_publicBLBsPerUSD, _privateBLBsPerUSD); 
        setRetailLimit(_retailLimitUSD); 
        setMinUSDLimit(_minUSDLimit); 
    }

    /**
     * @dev emits when a user purchases BLB.
     */
    event Purchase(
        address indexed purchaser,
        string indexed tokenPaid,
        uint256 amountPaid,
        uint256 amountBLB 
    );

    /**
     * @dev emits when a user claims their unlocked BLB.
     */
    event Claim(
        address indexed claimant,
        uint256 amountBLB
    );

    /**
     * @dev emits when SoldOut situation switches.
     */
    event SoldOut(bool situation);


// get -------------------------------------------------------------------------

    /**
     * @return price BNB/USD. (8 digits decimals)
     */
    function priceBNB() public view returns(uint256) {
        return uint256(AGGREGATOR_BNB_USD.latestAnswer());
    }

    /**
     * @return amount BLBs is earned for USD.
     *
     * @notice the private and public amount are calculated automatically.
     */
    function BLBsForUSD(uint256 amountBUSD) public view returns(uint256) {
        require(!soldOut, "BLBIO: sold out!");
        uint256 amountPerUSD = amountBUSD >= retailLimit ? privateBLBsPerUSD : publicBLBsPerUSD;
        return amountPerUSD * amountBUSD / 10 ** 18;
    }

    /**
     * @return amount BLBs is earned for BNB.
     *
     * @notice the private and public amount are calculated automatically.
     */
    function BLBsForBNB(uint256 amountBNB) public view returns(uint256) {
        require(!soldOut, "BLBIO: sold out!");
        return BLBsForUSD(amountBNB * priceBNB() / 10 ** 8);
    }

    /**
     * @return amount of the BLB token the user can claim.
     */
    function totalClaimable(address claimant) public view returns(uint256) {
        UserClaim storage uc = userClaims[claimant];
        return uc.total - uc.claimed;
    }

    /**
     * @return amount of the BLB token the user can claim just now.
     */
    function claimable(address claimant) public view returns(uint256) {
        UserClaim storage uc = userClaims[claimant];
        
        if(uc.freeToClaim) {
            return totalClaimable(claimant);
        } else {
            return uc.total * claimableFraction/1000000  - uc.claimed;
        }
    }


// set -------------------------------------------------------------------------

    /**
     * @dev purchase BLB Token paying in BNB.
     *
     * @notice requirement:
     *   - required amount must be paid in BNB.
     *
     * @notice emits a Purchase event
     */
    function purchaseInBNB() public payable {
        address purchaser = msg.sender;
        uint256 amountBNB = msg.value;
        uint256 amountBLB = BLBsForBNB(amountBNB);
        require(
            amountBNB * priceBNB() / 10 ** 8 >= minUSDLimit, 
            "BLBIO: less than minimum amount BNB"
        );
        userClaims[purchaser].total += amountBLB;
        TotalClaimable += amountBLB;
        emit Purchase(purchaser, "BNB", amountBNB, amountBLB);
    }

    /**
     * @dev purchase BLB Token paying in BUSD.
     *
     * @notice requirement:
     *   - Purchaser must approve the ICO to spend required BUSD.
     *
     * @notice emits a Purchase event
     */
    function purchaseInBUSD(uint256 amountBUSD) public {
        require(
            amountBUSD >= minUSDLimit, 
            "BLBIO: less than minimum amount BUSD"
        );
        address purchaser = msg.sender;
        uint256 amountBLB = BLBsForUSD(amountBUSD);
        BUSD.transferFrom(purchaser, address(this), amountBUSD); 
        userClaims[purchaser].total += amountBLB;       
        TotalClaimable += amountBLB;
        emit Purchase(purchaser, "BUSD", amountBUSD, amountBLB);
    }

    /**
     * @dev transfer unlocked BLBs to the claimant.
     *
     * @notice requirement:
     *   - claimable amount should not be zero.
     *   - there must be sufficient BLB token in this contract.
     *
     * @notice emits a Claim event
     */
    function claim() public {
        address claimant = msg.sender; 
        UserClaim storage uc = userClaims[claimant];
        uint256 _claimable = claimable(claimant);

        require(_claimable != 0, "BLBIO: there is no BLB to claim");
        require(BLB.balanceOf(address(this)) >= _claimable, "BLBIO: insufficient BLB in the contract");

        uc.claimed += _claimable;

        BLB.transfer(claimant, _claimable); 

        emit Claim(claimant, _claimable);      
    }

    /**
     * @dev turns the contract's offering on or off.
     *
     * @notice requirement:
     *   - only owner of the contract can call this function.
     * 
     * @notice emits a SoldOut event
     */
    function setSoldOut() public onlyOwner {
        soldOut = soldOut ? false : true;

        emit SoldOut(soldOut);
    }
    
    /**
     * @dev gift some BLBs to desired user.
     *
     * @notice requirement:
     *   - only owner of the contract can call this function.
     * 
     * @notice the user who earned BLB may be able to claim or may has to wait just 
     *   like other users. 
     * 
     * @notice emits a Purchase event
     */
    function giftBLB(
        address addr, 
        uint256 amount, 
        bool freeToClaim
    ) public onlyOwner {
        userClaims[addr].total += amount; 
        userClaims[addr].freeToClaim = freeToClaim; 
        TotalClaimable += amount;
        emit Purchase(addr, "gift", 0, amount);
    }
}