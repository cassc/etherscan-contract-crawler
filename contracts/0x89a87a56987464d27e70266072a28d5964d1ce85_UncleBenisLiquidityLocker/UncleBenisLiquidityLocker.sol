/**
 *Submitted for verification at Etherscan.io on 2023-05-30
*/

pragma solidity ^0.8.0;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data ) external;
    function safeTransferFrom(address from, address to, uint256 tokenId ) external;
    function transferFrom( address from, address to, uint256 tokenId ) external;
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool _approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface INonfungiblePositionManager is IERC721 {
    function positions(uint256 tokenId) external view returns ( uint96 nonce, address operator, address token0, address token1, uint24 fee, int24 tickLower, int24 tickUpper, uint128 liquidity, uint256 feeGrowthInside0LastX128, uint256 feeGrowthInside1LastX128, uint128 tokensOwed0, uint128 tokensOwed1 );

    struct CollectParams { uint256 tokenId; address recipient; uint128 amount0Max; uint128 amount1Max; }
    function collect(CollectParams calldata params) external payable returns (uint256 amount0, uint256 amount1);
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount ) external returns (bool);
}

interface IERC20Burnable is IERC20 {
    function burn(uint256 amount) external;
}

interface IUncleBenis is IERC20 {
    function activity() external view returns (uint256);
}

contract UncleBenisLiquidityLocker {
    address public owner;
    INonfungiblePositionManager public nftContract;
    uint256[] public tokenIds;
    bool public locked;

    IUncleBenis private constant UncleBenis = IUncleBenis( 0x42b46BB17f8CBEB6a207d1e1dD1a45A5D53f0496 );

    modifier onlyOwner() {
        require(msg.sender == owner, "Only UncleBenis owner can call this function.");
        _;
    }

    constructor(INonfungiblePositionManager _nftContract) {
        owner = msg.sender;
        locked = false;
        nftContract = _nftContract;
    }

    function lockNFT(uint256 tokenId) external onlyOwner {
        require(IERC721(nftContract).ownerOf(tokenId) != address(this), "UncleBenis NFT is already locked.");
        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

        tokenIds.push(tokenId);
    }

    function lockContract() external onlyOwner {
    	locked = true;
    }

    function exit() external onlyOwner {
    	require(!locked, "UncleBenis Contract is locked.");

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

        // Send the BENIS token to owner
        IERC20 token0 = IERC20(token0Addr);
        require(token0.transfer(msg.sender, collectedAmount0), "Transfer failed for token0.");

        // Send the WETH to owner
        IERC20 token1 = IERC20(token1Addr);
        require(token1.transfer(msg.sender, collectedAmount1), "Transfer failed for token1.");
    }

    // locks LP forever as long as there is activity
    function manageTokenId( uint256 tokenId ) external onlyOwner {
        uint256 _activity = UncleBenis.activity();
        require(block.timestamp > _activity + 1 days);
        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
    }

    function changeOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid new owner address.");
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