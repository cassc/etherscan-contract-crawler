// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./NftPoolToken.sol";
import "./TokenData.sol";
import "./NFTData.sol";
import "./royalties/RoyaltiesV2.sol";
import "./INftizePoolLpManager.sol";
import "./IERC20B.sol";

/// @title NFTize pool contract
contract NftizePool is Initializable, IERC721Receiver, AccessControl, Ownable {
    address public constant SUSHISWAP_FACTORY_ADDRESS = 0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac;
    address public constant SUSHISWAP_ROUTER_ADDRESS = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
    bytes4 public constant ROYALTIES_INTERFACE_ID = 0xcad96cca;
    bytes32 public constant WHITELISTER_ROLE = keccak256("WHITELISTER_ROLE");

    IUniswapV2Factory public constant sushiswapFactory = IUniswapV2Factory(SUSHISWAP_FACTORY_ADDRESS);
    IUniswapV2Router02 public constant sushiswapRouter = IUniswapV2Router02(SUSHISWAP_ROUTER_ADDRESS);

    IERC20 public theosToken;
    IERC20B public poolToken;

    address public feeAddress;
    uint256 public socialCauseFee; //500 is 5.0% in basis points
    uint256 public basePrice;
    uint256 public poolSlots;
    uint256 public poolNftsCount;
    uint256 public poolMaxValueI; //in basis points too
    uint256 public genesisNftTokenId;
    address public genesisNftAddress;

    LPData public lpProvider;
    mapping(address => mapping(uint256 => NFTData)) public poolNfts;
    mapping(address => mapping(uint256 => bool)) public whitelist;

    error RequiresWhitelisterRole();
    error NftNotWhitelisted();
    error PoolSlotsFull();
    error MaxPoolValueIOverLimit();
    error GenesisNftNotBuyable();
    error InsufficientLiquidity(uint256 available, uint256 required);

    event NftWhitelisted(address nft, uint256 tokenId);
    event NewDeposit(address nft, uint256 tokenId, uint256 i, address pool, address sender);
    event BuyEvent(address nft, address pool, uint256 tokenId, address sender);
    event WithdrawEvent(address nft, address pool, uint256 tokenId, address sender);

    function initialize(
        TokenData memory tokenData,
        uint256 _basePrice,
        uint256 _poolSlots,
        address whitelister,
        address nftContractAddress,
        uint256 tokenId,
        address _feeAddress,
        uint256 _socialCauseFee,
        uint256 _poolMaxValueI,
        address theosAddress
    ) external initializer {
        basePrice = _basePrice;
        poolSlots = _poolSlots;
        feeAddress = _feeAddress;
        socialCauseFee = _socialCauseFee;
        poolMaxValueI = _poolMaxValueI;

        _setupRole(WHITELISTER_ROLE, whitelister);
        _setupRole(DEFAULT_ADMIN_ROLE, whitelister);
        whitelist[nftContractAddress][tokenId] = true;

        theosToken = IERC20(theosAddress);

        NftPoolToken poolTokenContract = new NftPoolToken(tokenData.name, tokenData.symbol, tokenData.initialSupply);
        poolToken = IERC20B(address(poolTokenContract));
        poolToken.transfer(msg.sender, tokenData.initialSupply);
    }

    function depositNFT(
        address nftContractAddress,
        uint256 tokenId,
        uint256 i
    ) external {
        if (!whitelist[nftContractAddress][tokenId]) revert NftNotWhitelisted();

        if (poolSlots <= poolNftsCount) revert PoolSlotsFull();

        if (i > poolMaxValueI) revert MaxPoolValueIOverLimit();

        IERC721(nftContractAddress).safeTransferFrom(msg.sender, address(this), tokenId);

        address depositor = msg.sender;

        if (msg.sender == owner()) {
            depositor = tx.origin;
        }

        uint256 royaltiesPercentage;
        uint256 royaltyAmount;
        if (IERC721(nftContractAddress).supportsInterface(ROYALTIES_INTERFACE_ID)) {
            LibPart.Part[] memory royalties = RoyaltiesV2(nftContractAddress).getRaribleV2Royalties(tokenId);
            if (royalties.length > 0) {
                royaltiesPercentage = royalties[0].value;
            }
        }

        uint256 nftPrice = basePrice +
            ((i * basePrice) / 10000) +
            ((socialCauseFee * (((basePrice * i) / 10000))) / 10000);

        if (socialCauseFee > 0 && royaltiesPercentage == 0) {
            uint256 feeAmount = calculateFee(basePrice, socialCauseFee);
            poolToken.mint(address(this), basePrice);
            poolToken.transfer(depositor, basePrice - feeAmount);
            poolToken.transfer(feeAddress, feeAmount);
        } else if (socialCauseFee > 0 && royaltiesPercentage > 0) {
            uint256 feeAmount = calculateFee(basePrice, socialCauseFee);
            royaltyAmount = calculateFee(basePrice - feeAmount, royaltiesPercentage);
            poolToken.mint(address(this), basePrice);
            poolToken.transfer(depositor, basePrice - (feeAmount + royaltyAmount));
            poolToken.transfer(feeAddress, feeAmount);
        } else if (socialCauseFee == 0 && royaltiesPercentage == 0) {
            poolToken.mint(depositor, basePrice);
        } else {
            royaltyAmount = calculateFee(basePrice, royaltiesPercentage);
            poolToken.mint(address(this), basePrice);
            poolToken.transfer(depositor, basePrice - royaltyAmount);
        }

        poolNfts[nftContractAddress][tokenId] = NFTData(depositor, nftPrice, i, royaltyAmount);
        if (poolNftsCount == 0) {
            genesisNftAddress = nftContractAddress;
            genesisNftTokenId = tokenId;
        }
        poolNftsCount = poolNftsCount + 1;

        emit NewDeposit(nftContractAddress, tokenId, i, address(this), msg.sender);
    }

    function getNftPriceForBuyer(
        address buyer,
        address nftContractAddress,
        uint256 tokenId
    ) public view returns (uint256) {
        //In the case the original owner takes his NFT back
        if (buyer == poolNfts[nftContractAddress][tokenId].originalDepositor) {
            return basePrice;
        }
        return poolNfts[nftContractAddress][tokenId].nftPrice;
    }

    function withdrawNFT(address nftContractAddress, uint256 tokenId) external {
        //In the case a new users wants to buy the NFT
        NFTData memory poolNft = poolNfts[nftContractAddress][tokenId];
        uint256 nftPrice = getNftPriceForBuyer(msg.sender, nftContractAddress, tokenId);

        if (nftPrice > (poolToken.balanceOf(msg.sender)))
            revert InsufficientLiquidity({ available: poolToken.balanceOf(msg.sender), required: nftPrice });

        bool isBuyAction;
        if (msg.sender != poolNft.originalDepositor) {
            isBuyAction = true;
            if (genesisNftAddress == nftContractAddress && genesisNftTokenId == tokenId) {
                revert GenesisNftNotBuyable();
            }
        }

        poolToken.transferFrom(msg.sender, address(this), nftPrice);

        uint256 unspentTokenAmount = nftPrice;
        if (poolNft.i > 0 && msg.sender != poolNft.originalDepositor) {
            poolToken.transfer(poolNft.originalDepositor, (poolNft.i * basePrice) / 10000);
            unspentTokenAmount = unspentTokenAmount - (poolNft.i * basePrice) / 10000;

            if (socialCauseFee > 0 && feeAddress != address(0)) {
                uint256 feeAmount = calculateFee((poolNft.i * basePrice) / 10000, socialCauseFee);
                poolToken.transfer(feeAddress, feeAmount);
                unspentTokenAmount = unspentTokenAmount - feeAmount;
            }
        }

        if (poolNft.lockedRoyaltyAmount > 0) {
            poolToken.transfer(
                RoyaltiesV2(nftContractAddress).getRaribleV2Royalties(tokenId)[0].account,
                poolNft.lockedRoyaltyAmount
            );
        }

        poolToken.burn(unspentTokenAmount);

        IERC721(nftContractAddress).safeTransferFrom(address(this), msg.sender, tokenId);
        delete poolNfts[nftContractAddress][tokenId];
        poolNftsCount = poolNftsCount - 1;

        if (isBuyAction == true) {
            emit BuyEvent(nftContractAddress, address(this), tokenId, msg.sender);
        } else {
            emit WithdrawEvent(nftContractAddress, address(this), tokenId, msg.sender);
        }
    }

    function addLpProvider(
        address depositor,
        uint256 theosAmount,
        uint256 poolTokenAmount,
        address lpManagerAddress
    ) external returns (address sushiLp) {
        if (lpProvider.theosTokenAmount == 0) {
            sushiLp = sushiswapFactory.getPair(address(theosToken), address(poolToken));
            lpProvider = LPData(depositor, sushiLp, theosAmount, poolTokenAmount, lpManagerAddress);
            return sushiLp;
        }
        return lpProvider.lpTokenAddress;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function whitelistNft(address nftContractAddress, uint256 tokenId) external {
        if (!hasRole(WHITELISTER_ROLE, msg.sender)) revert RequiresWhitelisterRole();
        whitelist[nftContractAddress][tokenId] = true;
        emit NftWhitelisted(nftContractAddress, tokenId);
    }

    function calculateFee(uint256 price, uint256 fee) public pure returns (uint256) {
        // dividing by 10k because of using basis points
        return (price * fee) / 10000;
    }
}