// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/IHYPCSwap.sol";
import "../interfaces/ICHYPC.sol";
import "../interfaces/IHYPC.sol";

/**
    @title  HyperCycle Swap contract.
    @author Barry Rowe, David Liendo
    @notice This contract allows a user to swap 2^19 (524288) HyPC for a c_HyPC token. All c_HyPC that get minted
            by the c_HyPC contract are deposited into this contract, and can only be received via the swap
            function.
*/
contract HyperCycleSwap is ERC721Holder, IHYPCSwap, ReentrancyGuard {
    using SafeERC20 for IHYPC;
    IHYPC private immutable HYPCToken;
    ICHYPC private immutable HYPCNFT;

    /// @notice The total amount of locked HyPC in the contract.
    uint256 public totalLocked;

    /// @notice The c_HyPC tokens inside this contract.
    uint256[] public nfts;

    /// @notice A lookup table to tell if a given c_HyPC token is in the contract.
    mapping(uint256 => bool) public nftsReceived;

    /// @notice The total number of nfts inside the contract.
    uint256 public nftTotal;

    /// @notice Decimals used inside the HyPC contract
    uint256 public constant SIX_DECIMALS = 10**6;

    /// @notice The amount of HyPC tokens to swap for 1 c_HyPC token.
    uint256 public constant HYPC_PER_TOKEN = 2**19;//524288

    //Events
    /**
        @notice An event for when a swap occurs.
        @param  owner: The address providing the HyPC for the swap.
        @param  tokenId: The c_HyPC being swapped for.
        @param  amount: The amount of HyPC used in the swap.
    **/
    event Swap(address indexed owner, uint256 indexed tokenId, uint256 amount);

    /**
        @notice An event for when a redeem occurs.
        @param  owner: The address providing the c_HyPC to be redeemed for HyPC.
        @param  tokenId: The c_HyPC being redeemed for HyPC.
        @param  amount: The amount of HyPC given back for the redeem.
    */
    event Redeem(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 amount
    );

    //Modifiers
    /// @dev Checks that the assignment of this c_HyPC is empty.
    modifier emptyAssignment(uint256 nftID) {
        require(bytes(HYPCNFT.getAssignment(nftID)).length == 0, 
                "c_HyPC assignment must be clear.");
        _;
    }

    /**
        @dev   After the c_HyPC contract is deployed, we can deploy the Swap contract in full.
        @param hypcTokenAddress: the address of the HyPC ERC20 contract.
        @param hypcNFTAddress: the address of the c_HyPC ERC721 contract.
    */
    constructor(address hypcTokenAddress, address hypcNFTAddress) {
        require(hypcTokenAddress != address(0), "Invalid Token.");
        require(hypcNFTAddress != address(0), "Invalid NFT.");

        HYPCToken = IHYPC(hypcTokenAddress);
        HYPCNFT = ICHYPC(hypcNFTAddress);
        totalLocked = 0;
    }

    /**
        @dev   This function can only be called by the c_HyPC contract when it mints a new token.
               It adds it to the list of tokens inside the Swap contract.
        @param nftID: the c_HyPC being added to the swap contract.
    */
    function addNFT(uint256 nftID) emptyAssignment(nftID) external {
        require(msg.sender == address(HYPCNFT), "Must be CHYPC address.");

        nfts.push(nftID);
        nftsReceived[nftID] = true;
        nftTotal += 1;
    }

    /**
        @notice Swaps out 524288 HyPC for 1 c_HyPC. 
        @dev    This sends the first token in the nft list to the sender, and then swaps the last element to
                to front of the list to avoid having to iterate through the array.
    */
    function swap() nonReentrant external {
        require(nfts.length > 0, "No HYPCNFTs remaining.");

        uint256 tokenId = nfts[0];
        HYPCToken.safeTransferFrom(msg.sender, address(this), HYPC_PER_TOKEN*SIX_DECIMALS);
        HYPCNFT.safeTransferFrom(address(this), msg.sender, tokenId);
        totalLocked += HYPC_PER_TOKEN*SIX_DECIMALS;

        //pop first element
        delete nfts[0];
        nfts[0] = nfts[nfts.length - 1];
        nfts.pop();
        emit Swap(msg.sender, tokenId, HYPC_PER_TOKEN*SIX_DECIMALS);
    }

    /**
        @notice Redeems a c_HyPC for 524288 locked HyPC. This is the inverse operation of a swap. As a
                requirement, the assignment string must be empty so the c_HyPC is no longer backing a
                license when it's redeemed back for HyPC.
        @param  nftID: the c_HyPC to redeem for HyPC.
    */
    function redeem(uint256 nftID) emptyAssignment(nftID) external nonReentrant {
        HYPCToken.safeTransfer(msg.sender, HYPC_PER_TOKEN*SIX_DECIMALS);
        HYPCNFT.safeTransferFrom(msg.sender, address(this), nftID);
        totalLocked -= HYPC_PER_TOKEN*SIX_DECIMALS;

        //add the nft to nftArray again;
        nfts.push(nftID);
        emit Redeem(msg.sender, nftID, HYPC_PER_TOKEN*SIX_DECIMALS);
    }
}