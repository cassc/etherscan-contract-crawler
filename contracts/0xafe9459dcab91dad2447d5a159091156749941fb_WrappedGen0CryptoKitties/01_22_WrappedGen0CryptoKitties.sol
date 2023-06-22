// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./WrappedCryptoKitties.sol";
import "./IWG0.sol";

/**
 * @title Wrapped Gen0 CryptoKitties
 * @author FIRST 721 CLUB
 * @dev Wrapped Gen0 CryptoKitties(721WG0) NFT is 1:1 backed by orignal Gen0 CryptoKitties NFT. Stake 
 * one orignal Gen0 NFT to Wrapped Gen0 contract, you will get one 721WG0 NFT with the same ID. Burn 
 * one 721WG0 NFT, you will get back your original Gen0 NFT with the same ID.
 */
contract WrappedGen0CryptoKitties is  WrappedCryptoKitties {
    // The ERC-20 WG0 contract address
    address public WG0Contract;

    // The ERC-20 WVG0 contract address
    address public WVG0Contract;

    /**
     * @dev Initializes the contract params.
     */
    constructor(address kittyCore_, address WG0Contract_, address WVG0Contract_) 
      WrappedCryptoKitties(kittyCore_, "Wrapped Gen0 CryptoKitties", "721WG0")
    {
        WG0Contract = WG0Contract_;
        WVG0Contract = WVG0Contract_;
    }

    /**
     * @dev check the kitty is Gen0
     */
    function _checkBeforeMint(uint256 kittyId) internal view override {
         (,,,,,,,,uint256 generation,) = kittyCore.getKitty(kittyId);
         require(generation == 0, 'kitty must be Gen0');
    }

    /**
     * @dev Swap 721WG0 NFTs by ERC-20 WG0 tokens
     *
     * Requirements:
     *
     * - `kittyIds` must be owned by the WG0 contract
     * - WG0.balanceOf(msg.sender) >= kittyIds.length * 1e18
     * - WG0.allowance(msg.sender, address(this)) >= kittyIds.length * 1e18
     */
    function swapFromWG0(uint256[] calldata kittyIds, address receiver) external nonReentrant {
        _swapFromWG0OrWVG0(WG0Contract, kittyIds, receiver);
    }

    /**
     * @dev Swap ERC-20 WG0 tokens by 721WG0 NFTs
     *
     * Requirements:
     *
     * - `kittyIds` must be owned by the caller.
     */
    function swapToWG0(uint256[] calldata kittyIds, address receiver) external nonReentrant {
        _swapToWG0OrWVG0(WG0Contract, kittyIds, receiver);
    }

    /**
     * @dev Swap 721WG0 NFTs by ERC-20 WVG0 tokens
     *
     * Requirements:
     *
     * - `kittyIds` must be owned by the WVG0 contract
     * - WVG0.balanceOf(msg.sender) >= kittyIds.length * 1e18
     * - WVG0.allowance(msg.sender, address(this)) >= kittyIds.length * 1e18
     */
    function swapFromWVG0(uint256[] calldata kittyIds, address receiver) external nonReentrant {
        _swapFromWG0OrWVG0(WVG0Contract, kittyIds, receiver);
    }

    /**
     * @dev Swap ERC-20 WVG0 tokens by 721WG0 NFTs
     *
     * Requirements:
     *
     * - `kittyIds` must be virgin and owned by the caller.
     */
    function swapToWVG0(uint256[] calldata kittyIds, address receiver) external nonReentrant {
        _swapToWG0OrWVG0(WVG0Contract, kittyIds, receiver);
    }

    /**
     * @dev Swap From ERC-20(WG0,WVG0) tokens to 721WG0 NFTs
     *
     * Requirements:
     *
     * - `kittyIds` must be owned by contractAddress.
     */
    function _swapFromWG0OrWVG0(address contractAddress,uint256[] calldata kittyIds, address receiver) internal  {
        uint256 count = kittyIds.length;
        require(count > 0,"invalid count");
        SafeERC20.safeTransferFrom(IERC20(contractAddress), msg.sender, address(this), count * 1e18);
        address[] memory addressArray = new  address[](count);

        for(uint256 i = 0; i < kittyIds.length; i++){
            addressArray[i] = address(this);
        }
        
        IWG0(contractAddress).burnTokensAndWithdrawKitties(kittyIds,addressArray);

        for(uint256 i = 0; i < kittyIds.length; i++){
            uint256 kittyId = kittyIds[i];
            require(address(this) == kittyCore.ownerOf(kittyId), "invalid kittyId");
            _checkBeforeMint(kittyId);
            _mint(receiver, kittyId);
        }
    }

    /**
     * @dev Swap From 721WG0 NFTs to ERC-20(WG0,WVG0) tokens
     *
     * Requirements:
     *
     * - `kittyIds` must be owned by the caller.
     */
    function _swapToWG0OrWVG0(address contractAddress, uint256[] calldata kittyIds, address receiver) internal {
        uint256 count = kittyIds.length;
        require(count > 0,"invalid count");

        for(uint256 i = 0; i < kittyIds.length; i++){
            uint256 kittyId = kittyIds[i];
            require(msg.sender == ownerOf(kittyId), "not owner");
            _burn(kittyId);
            kittyCore.approve(contractAddress, kittyId);
        }
        
        IWG0(contractAddress).depositKittiesAndMintTokens(kittyIds);
        SafeERC20.safeTransfer(IERC20(contractAddress), receiver, count * 1e18);
    }
}