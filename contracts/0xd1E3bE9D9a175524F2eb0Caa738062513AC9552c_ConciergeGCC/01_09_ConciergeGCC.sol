// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ConciergeGCC is Ownable, ReentrancyGuard {
    
    address erc20Contract = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // USDC ethereum mainnet
        IERC20 tokenContract = IERC20(erc20Contract);

    uint256 public PRICE = 2950 * 10 ** 6; // 2950 USDC (mainnet value)

    constructor() {
        gccNftAddress = 0x9D6a7159E5AccfC6520932f0f81a47E2Ffd349A3;

        if (gccNftAddress != address(0)) {
            gccNft = IERC721(gccNftAddress);
        }
    }

    /// @notice GCC NFT Contract Address
    address public gccNftAddress;

    /// @notice GCC NFT Contract
    IERC721 public gccNft;

    /// @notice Set GCC NFT Contract Address
    /// @param _gccNftAddress  The new GCC NFT Contract Address
    function setGccNftAddress(address _gccNftAddress) public onlyOwner {
        gccNftAddress = _gccNftAddress;
        gccNft = IERC721(_gccNftAddress);
    }

    /// @notice Set Concierge token purchase price in USDC
    /// @param newPrice New purchase price
    function setPurchasePrice(uint256 newPrice) public onlyOwner {
        PRICE = newPrice;
    }

    struct StakingInfo {
        uint tokenId;
        bool purchased;
        address staker;
        uint stakedOn;
        uint stakedUntil;
    }

    /// @notice Staking info mapping based on user address
    mapping(address => StakingInfo) public stakingInfo;

    /// @notice This event is emitted when a Concierge token is purchased and minted
    /// @param buyer The address of the buyer
    /// @param tokenId The token ID of the purchased token (same as GCC NFT ID staked)
    /// @param transferred The price paid for the token
    event ConciergeTokenPurchased(
        address indexed buyer,
        uint256 indexed tokenId,
        bool transferred
    );

    /// @notice Function to stake GCC token. one address can stake only once
    /// @param tokenId GCC NFT ID to stake. Holders may have multiple token Id's so this var must be specified
    function stakeAndPurchase(uint256 tokenId) public nonReentrant {
        require(
            stakingInfo[msg.sender].staker == address(0),
            "ConciergeGCC: Already staked once from this address"
        );
        require(
            gccNftAddress != address(0),
            "ConciergeGCC: GCC NFT Address not set"
        );

        // checks token allowance from USDC contract
        uint256 allowance = tokenContract.allowance(msg.sender, address(this));
        require(allowance >= PRICE, "Not enough USDC tokens to purchase Concierge");

        // transferr's USDC payment
        bool transferred = tokenContract.transferFrom(msg.sender, address(this), PRICE);
        require(transferred, "Failed to transfer over USDC");

        // transferrs GCC Token to contract
        gccNft.transferFrom(msg.sender, address(this), tokenId);

        // creating the struct based on users address
        stakingInfo[msg.sender] = StakingInfo({
            tokenId: tokenId,
            purchased: true,
            staker: msg.sender,
            stakedOn: uint64(block.timestamp),
            stakedUntil: uint64(block.timestamp + 365 days)
        });

        // emit purchase transfer
        emit ConciergeTokenPurchased(msg.sender, tokenId, transferred);
    }

    /// @notice Unstake GCC NFT
    /// @dev This has been changed so that the current concierge token owner can unstake and receive the GCC token
    function unstake() public nonReentrant {
        require(
            stakingInfo[msg.sender].staker == msg.sender,
            "ConciergeGCC: You havent staked your GCC pass"
        );

        require(
            stakingInfo[msg.sender].stakedUntil < block.timestamp,
            "ConciergeGCC: Staking period not over"
        );

        // transfer GCC NFT to current concierge token owner
        gccNft.transferFrom(address(this), stakingInfo[msg.sender].staker, stakingInfo[msg.sender].tokenId);

        // delete structInfo from the stakingInfo mapping
        delete stakingInfo[msg.sender];
    }

    /// @notice onlyOwner manual unstake override (GCC team unstakes token on behalf of staker)
    /// @param stakedUser holders GCC token that was staked
    function unstakeOverride(address stakedUser) public onlyOwner {
        gccNft.transferFrom(address(this), stakingInfo[stakedUser].staker, stakingInfo[stakedUser].tokenId);

        delete stakingInfo[stakedUser];
    }

    /// @notice Withdraw ether from contract to owner address
    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /// @notice Withdraw ERC20 USDC tokens by token address to owner address
    function withdrawUSDC()
        external
        onlyOwner
        nonReentrant
    {

        uint256 totalBalance = tokenContract.balanceOf(address(this));
        bool success = tokenContract.transfer(msg.sender, totalBalance);
        require(success, "ConciergeGCC: ERC20 transfer failed");
    }
    
}