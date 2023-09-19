/**
 *Submitted for verification at Etherscan.io on 2023-09-10
*/

// SPDX-License-Identifier: MIT

/*

##       #      ##      # #     #            ##     ###      #      ##  
# #     # #     # #     # #     #           #        #      # #     # # 
# #     # #     ##      ##      #            #       #      ###     ##  
# #     # #     # #     # #     #             #      #      # #     # # 
##       #      # #     # #     ###         ##       #      # #     # # 

The Dorkl Star serves a unique purpose in the cryptoverse. It is designed to burn Dorkl tokens, ensuring scarcity 
of remaining tokens. This innovative integration of pop culture with blockchain mechanics showcases the limitless 
possibilities in the ever-evolving world of cryptocurrency.

*/


pragma solidity 0.8.19;

interface INonFungiblePositionManager {
    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }
    function collect(CollectParams calldata params) external returns (uint256 amount0, uint256 amount1);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
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
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}


contract DORKL_STAR  {
    
    address public owner;
    address public constant DORKLRecipient = 0x000000000000000000000000000000000000dEaD;
    address public constant WETHRecipient = 0xb330d1b36Ea0bE40071E33938ed5C6b7cBFFBa7b;
    address public constant DORKL = 0x94Be6962be41377d5BedA8dFe1b100F3BF0eaCf3;
    address public constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    mapping(uint256 => Position) public positions;


    INonFungiblePositionManager public positionManager;

    uint256 public DORKLWithdrawn;
    uint256 public WETHWithdrawn;
    uint256 public currentNFTId;
    uint256 public lastCalled = 0;
    uint256 public constant TIME_PERIOD = 15 minutes;


    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    constructor(address _positionManager) {
        owner = msg.sender;
        positionManager = INonFungiblePositionManager(_positionManager);
        
    }

    struct Position {
    address owner;
    uint128 liquidity;
    address token0;
    address token1;
    }  



    function EnterDORKL_Star(uint256 tokenId) external onlyOwner {
    
    positionManager.transferFrom(msg.sender, address(this), tokenId);
    
    currentNFTId = tokenId; 
    
    
    (, , , , , , , uint128 liquidity, , , , ) =
            positionManager.positions(tokenId);
    positions[tokenId] = Position({
        owner: msg.sender,
        liquidity: liquidity,
        token0: DORKL,
        token1: weth
    });
    }


    function HoiiYaa() external  {
         require(block.timestamp - lastCalled >= TIME_PERIOD, "Function can only be called once every hour");

        INonFungiblePositionManager.CollectParams memory params = INonFungiblePositionManager.CollectParams({
            tokenId: currentNFTId,
            recipient: address(this),
            amount0Max: type(uint128).max,
            amount1Max: type(uint128).max
        });

        (uint256 amount0, uint256 amount1) = positionManager.collect(params);

        
        DORKLWithdrawn += amount0;
        WETHWithdrawn += amount1;

        
        IERC20(DORKL).transfer(DORKLRecipient, amount0);
        IERC20(weth).transfer(WETHRecipient, amount1);

        lastCalled = block.timestamp;
    }

    function ShitCoins(address _token) external onlyOwner {
        if (_token == address(0x0)) {
            payable(msg.sender).transfer(address(this).balance);
            return;
        }
        IERC20 ERC20token = IERC20(_token);
        uint256 balance = ERC20token.balanceOf(address(this));
        ERC20token.transfer(msg.sender, balance);
    }

    function Star(address _contract, address _to, uint256 _tokenId) external onlyOwner {
        IERC721(_contract).transferFrom(address(this), _to, _tokenId);

        currentNFTId = 0;
    }

    
}