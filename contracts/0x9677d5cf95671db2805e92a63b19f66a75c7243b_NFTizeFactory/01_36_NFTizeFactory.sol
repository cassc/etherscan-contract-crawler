// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./NftPoolToken.sol";
import "./NftizePool.sol";

/// @title NFTize pool creator/factory contract
contract NFTizeFactory is Initializable, IERC721Receiver, OwnableUpgradeable, UUPSUpgradeable {
    address public constant SUSHISWAP_ROUTER_ADDRESS = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
    IUniswapV2Router02 public constant sushiswapRouter = IUniswapV2Router02(SUSHISWAP_ROUTER_ADDRESS);

    // index of created contracts
    address[] public poolsContracts;

    IERC20 public theosToken;
    address public testPoolCreator;
    address public poolCreator;
    address public lpManagerAddress;
    address public poolImplementation;
    bool public permissionlessPoolCreation;
    uint256 internal _theosAmount;
    uint256 internal _poolTokenAmount;

    event NftizePoolCreated(
        address indexed poolContract,
        address indexed token,
        uint256 maxPoolValueI,
        uint256 firstNftValueI,
        uint256 tokenId,
        address nftContractAddress,
        address socialCauseFeeAddress,
        uint256 socialCauseFeePercentage,
        address senderAddress
    );

    event LiquidityAdded(
        address indexed poolContract,
        uint256 theosTokenAmount,
        uint256 poolTokenAmount,
        address sushiLP
    );

    event TokenAmountsChanged(uint256 newTheosAmount, uint256 newTokenAmount);

    error InsufficientTheosLiquidity(uint256 available, uint256 required);
    error InvalidPoolCreator();

    function initialize(
        address theosAddress,
        address _testPoolCreator,
        address _poolCreator,
        address _lpManagerAddress,
        address _poolImplementation
    ) external virtual initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        theosToken = IERC20(theosAddress);
        testPoolCreator = _testPoolCreator;
        poolCreator = _poolCreator;
        lpManagerAddress = _lpManagerAddress;
        poolImplementation = _poolImplementation;
        permissionlessPoolCreation = true;
        _changeAmounts(1_300_000 ether, 15000 ether);
    }

    function changeAmounts(uint256 newTheosAmount, uint256 newPoolTokenAmount) external onlyOwner {
        _changeAmounts(newTheosAmount, newPoolTokenAmount);
    }

    /// @notice Returns the new pool token contract address
    function createPool(
        string memory tokenName,
        string memory symbol,
        uint256 poolSlots,
        uint256 basePrice,
        address whitelister,
        address nftContractAddress,
        uint256 tokenId,
        uint256 firstNftValueI,
        uint256 maxPoolValueI,
        address socialCauseFeeAddress,
        uint256 socialCauseFeePercentage
    ) external {
        uint256 theosAmount =_theosAmount;
        uint256 poolTokenAmount = _poolTokenAmount;

        // Check that the calling account has the permission for creating a pool
        if (permissionlessPoolCreation == false && poolCreator != msg.sender && testPoolCreator != msg.sender) {
            revert InvalidPoolCreator();
        }

        if (theosAmount > (theosToken.balanceOf(msg.sender))) {
            revert InsufficientTheosLiquidity({ available: theosToken.balanceOf(msg.sender), required: theosAmount });
        }

        theosToken.transferFrom(msg.sender, address(this), theosAmount);
        IERC721(nftContractAddress).safeTransferFrom(msg.sender, address(this), tokenId);

        NftizePool nftizePoolContract = NftizePool(Clones.clone(poolImplementation));

        nftizePoolContract.initialize(
            TokenData(tokenName, symbol, poolTokenAmount),
            basePrice,
            poolSlots,
            whitelister,
            nftContractAddress,
            tokenId,
            socialCauseFeeAddress,
            socialCauseFeePercentage,
            maxPoolValueI,
            address(theosToken)
        );

        poolsContracts.push(address(nftizePoolContract));

        IERC20B(nftizePoolContract.poolToken()).approve(SUSHISWAP_ROUTER_ADDRESS, poolTokenAmount);
        theosToken.approve(SUSHISWAP_ROUTER_ADDRESS, theosAmount);

        sushiswapRouter.addLiquidity(
            address(theosToken), // tokenA
            address(nftizePoolContract.poolToken()), // tokenB
            theosAmount, // desiredATokenAmount
            poolTokenAmount, // desiredBTokenAmount
            theosAmount, // amountAMin
            poolTokenAmount, // amountBMin
            msg.sender, // to address for LP tokens
            block.timestamp
        );

        IERC721(nftContractAddress).approve(address(nftizePoolContract), tokenId);
        nftizePoolContract.depositNFT(nftContractAddress, tokenId, firstNftValueI);

        address sushiLp = nftizePoolContract.addLpProvider(msg.sender, theosAmount, poolTokenAmount, lpManagerAddress);

        emit NftizePoolCreated(
            address(nftizePoolContract),
            address(nftizePoolContract.poolToken()),
            maxPoolValueI,
            firstNftValueI,
            tokenId,
            nftContractAddress,
            socialCauseFeeAddress,
            socialCauseFeePercentage,
            msg.sender
        );

        emit LiquidityAdded(address(nftizePoolContract), theosAmount, poolTokenAmount, sushiLp);
    }

    function togglePermissionlessPoolCreation() external {
        if (owner() == msg.sender || poolCreator == msg.sender) {
            permissionlessPoolCreation = !permissionlessPoolCreation;
        } else revert InvalidPoolCreator();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function _changeAmounts(uint256 newTheosAmount, uint256 newPoolTokenAmount) internal {
        _theosAmount = newTheosAmount;
        _poolTokenAmount = newPoolTokenAmount;
        emit TokenAmountsChanged(newTheosAmount, newPoolTokenAmount);
    }

    uint256[50] private ______gap;
}