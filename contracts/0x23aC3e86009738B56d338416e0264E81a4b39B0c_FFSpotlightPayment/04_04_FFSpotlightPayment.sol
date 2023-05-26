// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title Interface of ERC721Drop
 * @dev https://github.com/ourzora/zora-drops-contracts/blob/6e99143ec7b952deab7ce652fa0c45a7d950c4c3/src/interfaces/IERC721Drop.sol#L232
 */
interface IERC721Drop {
    /// @notice External purchase function (payable in eth)
    /// @param quantity to purchase
    /// @return first minted token ID
    function purchase(uint256 quantity) external payable returns (uint256);
}

/**
 * @title FFSpotlightPayment
 * @dev Handles SpotlightPayment for ForeFront
 */
contract FFSpotlightPayment is Ownable, ReentrancyGuard {
    address public immutable FF_TREASURY_ADDRESS;
    uint256 public spotlightFee = 0.00055 ether;

    constructor(address _treasuryAddress) {
        FF_TREASURY_ADDRESS = _treasuryAddress;
    }

    /**
     * @dev Pays Spotlight Fee to FF treasury, and then purchase NFT on Zora.
     * @return First minted token id
     */
    function purchase(
        address zoraDropAddress,
        uint256 quantity
    ) external payable nonReentrant returns (uint256) {
        require(msg.value >= spotlightFee, "error: SPOTLIGHT_FEE > amount");

        if (spotlightFee > 0) {
            (bool sent, bytes memory data) = FF_TREASURY_ADDRESS.call{
                value: spotlightFee
            }("");
            require(sent, "Failed to send Ether");
        }

        uint256 zoraAmount = msg.value - spotlightFee;
        return
            IERC721Drop(zoraDropAddress).purchase{value: zoraAmount}(quantity);
    }

    function setFee(uint256 _fee) external onlyOwner {
        spotlightFee = _fee;
    }
}