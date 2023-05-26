pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LiquidityLockerWithTokenBurn {
    address public owner;
    INonfungiblePositionManager public nftContract;
    uint256[] public tokenIds;
    bool public locked;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor(INonfungiblePositionManager _nftContract) {
        owner = msg.sender;
        locked = false;
        nftContract = _nftContract;
    }
    
    function lockNFT(uint256 tokenId) external onlyOwner {
        require(IERC721(nftContract).ownerOf(tokenId) != address(this), "NFT is already locked");
        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

        tokenIds.push(tokenId);
    }
    
    function lockContract() external onlyOwner {
    	locked = true;
    }
    
    function exit() external onlyOwner {
    	require(!locked, "Contract is locked");
    	
    	for (uint256 i = 0; i < tokenIds.length; i++) {
            IERC721(nftContract).transferFrom(address(this), owner, tokenIds[i]);
        }
    }

    function withdrawAll() external onlyOwner {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            withdrawTradingFees(tokenIds[i]);
        }
    }

    function withdrawTradingFees(uint256 tokenId) public onlyOwner {
       (address token0Addr, address token1Addr) = getTokens(tokenId);

       INonfungiblePositionManager.CollectParams memory params = 
            INonfungiblePositionManager.CollectParams({
                tokenId: tokenId,
                recipient: address(this),
                amount0Max: type(uint128).max, // collect all available fees
                amount1Max: type(uint128).max
            });

        (uint256 collectedAmount0, uint256 collectedAmount1) = nftContract.collect(params);

        // Burn the MRF tokens
        IERC20Burnable token0 = IERC20Burnable(token0Addr);
        token0.burn(collectedAmount0);

        // Send the WETH to owner
        IERC20 token1 = IERC20(token1Addr);
        require(token1.transfer(msg.sender, collectedAmount1), "Transfer failed for token1");
    }

    function changeOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid new owner address");
        owner = newOwner;
    }

    function getTokens(uint256 tokenId) internal view returns (address token0, address token1) {
        (
            ,,
            address token0,
            address token1,
            ,,,,,,,
            
        ) = nftContract.positions(tokenId);

        return (token0, token1);
    }
}

interface IERC20Burnable is IERC20 {
    function burn(uint256 amount) external;
}

interface INonfungiblePositionManager is IERC721 {
    /// @notice Returns the position information associated with a given token ID.
    /// @dev Throws if the token ID is not valid.
    /// @param tokenId The ID of the token that represents the position
    /// @return nonce The nonce for permits
    /// @return operator The address that is approved for spending
    /// @return token0 The address of the token0 for a specific pool
    /// @return token1 The address of the token1 for a specific pool
    /// @return fee The fee associated with the pool
    /// @return tickLower The lower end of the tick range for the position
    /// @return tickUpper The higher end of the tick range for the position
    /// @return liquidity The liquidity of the position
    /// @return feeGrowthInside0LastX128 The fee growth of token0 as of the last action on the individual position
    /// @return feeGrowthInside1LastX128 The fee growth of token1 as of the last action on the individual position
    /// @return tokensOwed0 The uncollected amount of token0 owed to the position as of the last computation
    /// @return tokensOwed1 The uncollected amount of token1 owed to the position as of the last computation
    function positions(uint256 tokenId)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    /// @notice Collects up to a maximum amount of fees owed to a specific position to the recipient
    /// @param params tokenId The ID of the NFT for which tokens are being collected,
    /// recipient The account that should receive the tokens,
    /// amount0Max The maximum amount of token0 to collect,
    /// amount1Max The maximum amount of token1 to collect
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(CollectParams calldata params) external payable returns (uint256 amount0, uint256 amount1);
}