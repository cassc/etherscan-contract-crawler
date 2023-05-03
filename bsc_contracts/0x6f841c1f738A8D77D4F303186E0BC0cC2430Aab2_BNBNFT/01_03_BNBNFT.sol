//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./Ownable.sol";
import "./IERC20.sol";

contract BNBNFT is Ownable {

    address public mintToken = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;

    uint256[4] public rarities = [
        500 * 10**18, 1000 * 10**18, 2000 * 10**18, 5000 * 10**18
    ];

    address public mintRecipient;

    bool public tradingEnabled;

    event MintedOnBSC(address indexed user, uint256 num, uint8 rarity);

    constructor(address mintRecipient_) {
        mintRecipient = mintRecipient_;
    }

    function setMintRecipient(address newRecipient) external onlyOwner {
        mintRecipient = newRecipient;
    }

    function setMintToken(address newToken) external onlyOwner {
        mintToken = newToken;
    }

    function setTradingEnabled(bool enabled) external onlyOwner {
        tradingEnabled = enabled;
    }

    function mint(uint256 num, uint8 rarity) external {
        require(
            num > 0, 
            'Invalid Number'
        );
        require(
            uint(rarity) < rarities.length,
            'Invalid Length'
        );
        require(
            tradingEnabled,
            'Trading Not Enabled'
        );

        // determine cost
        uint256 cost = num * rarities[rarity];

        // ensure user has balance and approval of this amount
        require(
            IERC20(mintToken).balanceOf(msg.sender) >= cost,
            'Insufficient USDC Balance'
        );
        require(
            IERC20(mintToken).allowance(msg.sender, address(this)) >= cost,
            'Insufficient Allowance'
        );
        require(
            IERC20(mintToken).transferFrom(msg.sender, mintRecipient, cost),
            'Error Transfer From'
        );

        // emit event to pull later
        emit MintedOnBSC(msg.sender, num, rarity);
    }
}