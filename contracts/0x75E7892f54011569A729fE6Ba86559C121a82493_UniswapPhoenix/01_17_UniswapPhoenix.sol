// SPDX-License-Identifier: MIT
// UniswapPhoenix: Innovatively Bridging the Gap Between Liquidity and Returns
// UniswapPhoenix: Burn your LP position NFTs but keep your fees
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

// Interface for collecting fees from Uniswap V3 non-custodial position
interface ISwapNonfungiblePositionManager {
    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }
    function collect(CollectParams calldata params) external payable returns (uint256 amount0, uint256 amount1);
}

contract UniswapPhoenix is ERC721, ERC721URIStorage, Ownable, IERC721Receiver {
    uint256 private _nextTokenId;

    // Mapping from Phoenix NFT ID to Uniswap V3 Position NFT ID
    mapping(uint256 => uint256) public phoenixToUniswapPosition;

    address public constant uniswapV3PositionsNFT = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;
    uint128 constant UINT128_MAX = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    event ReBord(uint256 indexed tokenId, uint256 indexed uniswapV3PositionsTokenId, address owner);
    event Collect(uint256 indexed tokenId, uint256 indexed uniswapV3PositionsTokenId, address recipient);

    constructor()
        ERC721("UniswapPhoenix", "UPX")
        Ownable(msg.sender)
    {}

    // Function for users to deposit Uniswap V3 Position NFT and mint Phoenix NFT
    function regenerates(uint256 uniswapV3PositionsTokenId) public { // rebord
        require(IERC721(uniswapV3PositionsNFT).ownerOf(uniswapV3PositionsTokenId) == msg.sender, "Not the owner of the Uniswap V3 Position NFT");
        // Transfer the Uniswap V3 Position NFT to this contract
        IERC721(uniswapV3PositionsNFT).safeTransferFrom(msg.sender, address(this), uniswapV3PositionsTokenId);

        // Mint a new Phoenix NFT for the user
        uint256 tokenId = _nextTokenId++;
        _safeMint(msg.sender, tokenId);

        // Record the mapping
        phoenixToUniswapPosition[tokenId] = uniswapV3PositionsTokenId;
        emit ReBord(tokenId, uniswapV3PositionsTokenId, msg.sender);
    }

    // Function for Phoenix NFT holders to collect fees from their Uniswap V3 Position
    function collect(uint256 tokenId) public  {
        address phoenixOwner = ownerOf(tokenId);
        uint256 uniswapV3PositionsTokenId = phoenixToUniswapPosition[tokenId];

        // Collect fees from Uniswap V3 non-custodial position
        ISwapNonfungiblePositionManager(uniswapV3PositionsNFT).collect(
            ISwapNonfungiblePositionManager.CollectParams(
                uniswapV3PositionsTokenId, phoenixOwner, UINT128_MAX, UINT128_MAX));
        emit Collect(tokenId, uniswapV3PositionsTokenId, phoenixOwner);
    }

    // The following functions are overrides required by Solidity.

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        uint256 uniswapV3PositionsTokenId = phoenixToUniswapPosition[tokenId];
        return IERC721Metadata(uniswapV3PositionsNFT).tokenURI(uniswapV3PositionsTokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }
}