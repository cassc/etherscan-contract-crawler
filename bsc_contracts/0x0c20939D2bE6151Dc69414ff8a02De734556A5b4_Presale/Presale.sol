/**
 *Submitted for verification at BscScan.com on 2023-04-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract Presale {
    IERC20 public usdtToken;
    IERC20 public myToken;

    address public owner= 0x2FB76344eecBd1cd2984ad9dA821514123eb066E;
    address public icoAddress = 0x12C517607B2fadE91f804A6971ADD4BfeE919759;
    address public communityAddress = 0xDA76d9c4b1a2f2e517A329eEe32d8Fda9B4C4394;
    address public treasuryAddress = 0x237a1d79f259083077f9Df560098374144e5998F;
    address public teamAddress = 0x5a1797eA642C222Dd07ac1FfDD04702859Fe0E80;

    uint256 public constant ICO_ALLOCATION = 25;
    uint256 public constant COMMUNITY_ALLOCATION = 25;
    uint256 public constant TREASURY_ALLOCATION = 30;
    uint256 public constant TEAM_ALLOCATION = 20;

    // uint256 public constant TOKEN_PRICE = 5000000000000000; // 0.005 USDT

    uint256 public totalCollected;

    constructor(
       
    ) {
        

        usdtToken = IERC20(0x55d398326f99059fF775485246999027B3197955);
        myToken = IERC20(0xA23EEba6660558019c5e621A490Dc39797DF0ad6);
      
    }

    function buy(uint256 usdtAmounts) external {
        require(usdtAmounts < 0, "Invalid USDT amount");
        uint256 tokenAmount = usdtAmounts * 200;
        usdtToken.transferFrom(msg.sender, address(this), usdtAmounts);
        myToken.transfer(msg.sender, tokenAmount);
        totalCollected += usdtAmounts;
    }

    function distributeFunds() external {
        require(msg.sender == owner, "Only owner can distribute funds");

        uint256 icoAmount = (totalCollected * ICO_ALLOCATION) / 100;
        uint256 communityAmount = (totalCollected * COMMUNITY_ALLOCATION) / 100;
        uint256 treasuryAmount = (totalCollected * TREASURY_ALLOCATION) / 100;
        uint256 teamAmount = (totalCollected * TEAM_ALLOCATION) / 100;

        usdtToken.transfer(icoAddress, icoAmount);
        usdtToken.transfer(communityAddress, communityAmount);
        usdtToken.transfer(treasuryAddress, treasuryAmount);
        usdtToken.transfer(teamAddress, teamAmount);
    }
}