/**
 *Submitted for verification at Etherscan.io on 2022-08-16
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    
    function symbol() external view returns(string memory);
    
    function name() external view returns(string memory);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
    
    /**
     * @dev Returns the number of decimal places
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IValidator {
    function getLoyalKeyRank(address user) external view returns (uint256);
    function getMarketplaceFee(address user) external view returns (uint256);
}

interface IKeyCard {
    function balanceOf(address user) external view returns (uint256);
}

contract LoyalKEYValidator {

    // public addresses
    IERC20 private constant KEYS = IERC20(0xe0a189C975e4928222978A74517442239a0b86ff);
    IERC20 private constant MAXI = IERC20(0x73940d8E53b3cF00D92e3EBFfa33b4d54626306D);
    IKeyCard private constant KeyCard = IKeyCard(0xddF4BbB14918402Be10BcfF8c3a45DD99d40D648);
    uint256 private constant DECI = 10**9;

    // rank system
    uint256[] public ranks;
    uint256[] public discounts;

    // market place fee structure
    uint256 public constant BASE_ROYALTY = 1800;

    // max rank
    uint256 public constant MAX = 7;

    constructor() {
        ranks = new uint256[](MAX+1);
        ranks[0] = 99999999999;         // Key Seeker 0-100 (exclusive)
        ranks[1] = 9_999999999999;      // Holder 100-10,000 (exclusive)
        ranks[2] = 99_999999999999;     // Collector 10,000-100,000 (exclusive)
        ranks[3] = 499_999999999999;    // Stacker 100,000 - 500,000 (exclusive)
        ranks[4] = 999_999999999999;    // Whale 500,000 - 1,000,000 (exclusive)
        ranks[5] = 3_999_999999999999;  // Mamba 1,000,000 - 4,000,000 (exclusive)
        ranks[6] = 7_999_999999999999;  // Mega Mamba 4,000,000 - 8,000,000 (exclusive)
        ranks[7] = 8_000_000000000000;  // Maxi Mamba 8,000,000+

        discounts = new uint256[](MAX+1);
        discounts[0] = 0;               // Key Seeker 0% discount
        discounts[1] = 5;               // Holder 5% discount
        discounts[2] = 10;              // Collector 10% discount
        discounts[3] = 20;              // Stacker 20% discount
        discounts[4] = 40;              // Whale 40% discount
        discounts[5] = 60;              // Mamba 60% discount
        discounts[6] = 70;              // Mega Mamba 70% discount
        discounts[7] = 100;             // Maxi Mamba 100% discount
    }

    function keysBalance(address user) public view returns (uint256) {
        return KEYS.balanceOf(user) + MAXI.balanceOf(user);
    }

    function hasKeyCard(address user) public view returns (bool) {
        return KeyCard.balanceOf(user) > 0;
    }

    function keyCardBalance(address user) public view returns (uint256) {
        return KeyCard.balanceOf(user);
    }

    function getLoyalKeyRank(address user) public view returns (uint256) {

        // max rank for key card users
        if (hasKeyCard(user)) {
            return MAX;
        }

        // keys balance across contracts
        uint balance = keysBalance(user);

        // if lower end return 0
        if (balance <= ranks[0]) {
            return 0;
        }

        // if upper end return max
        if (balance >= ranks[MAX]) {
            return MAX;
        }

        // loop through middle ranks and return rank user fits in
        for (uint i = 1; i < MAX; i++) {
            if (
                balance > ranks[i - 1] &&
                balance <= ranks[i]
            ) {
                return i;
            }
        }

        // something went wrong
        return 0;
    }

    function getMarketplaceFee(address user) external view returns (uint256) {
        uint rank = getLoyalKeyRank(user);
        if (rank >= discounts.length) {
            return BASE_ROYALTY;
        }
        uint discountPercent = discounts[rank];
        uint discount = ( BASE_ROYALTY * discountPercent ) / 100;
        return BASE_ROYALTY - discount;
    }
}