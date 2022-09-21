// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
* @notice IFireCatTreasury
*/
interface IFireCatTreasury {

    /**
    * @notice All treasury of contract.
    * @dev Fetch data from _totalTreasury.
    * @return totalTreasury.
    */
    function totalTreasury() external view returns (uint256);

    /**
    * @notice check treasury by address.
    * @dev Fetch treasury from _treasurys.
    * @param tokenId uint256.
    * @return treasury.
    */
    function treasuryOf(uint256 tokenId) external view returns (uint256);

    /**
    * @notice The treasury token of contract.
    * @dev Fetch data from _treasuryToken.
    * @return treasuryToken.
    */
    function treasuryToken() external view returns (address);

    /**
    * @notice The interface of treasury adding.
    * @dev add liquidity pool token to contract.
    * @param user address.
    * @param tokenId uint256.
    * @param addAmount uint256.
    * @return actualAddAmount.
    */
    function addTreasury(address user, uint256 tokenId, uint256 addAmount) external returns (uint);
    /**
    * @notice The interface of treasury exchange.
    * @dev Exchange LP token from NFT.
    * @param tokenId uint256.
    * @return actualSubAmount.
    */
    function swapTreasury(uint256 tokenId) external returns (uint);

    /**
    * @notice The interface of treasury withdrawn.
    * @dev Trasfer LP Token to owner.
    * @param amount uint256.
    * @return actualSubAmount.
    */
    function withdrawTreasury(uint256 amount) external returns (uint);

    /**
    * @notice The interface of IERC20 withdrawn, not include treausury token.
    * @dev Trasfer token to owner.
    * @param amount uint256.
    * @return actualSubAmount.
    */
    function withdrawRemaining(address token, uint256 amount) external returns (uint);

    /**
    * @notice The exchange switch of the treasury.
    * @dev set bool to swapOn.
    * @param swapOn_ bool.
    */
    function setSwapOn(bool swapOn_) external;
    
    /**
    * @notice set the fireCat proxy contract.
    * @dev set to fireCatProxy.
    * @param fireCatProxy_ address.
    */
    function setFireCatProxy(address fireCatProxy_) external;

    /**
    * @notice set the fireCat NFT contract.
    * @dev set to fireCatNFT.
    * @param fireCatNFT_ address.
    */
    function setFireCatNFT(address fireCatNFT_) external;
}