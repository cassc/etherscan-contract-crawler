pragma solidity ^0.5.0;

import "@openzeppelin/contracts/crowdsale/Crowdsale.sol";
import "@openzeppelin/contracts/crowdsale/validation/PausableCrowdsale.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./CappedCrowdsale.sol";

contract TangentETHSale is Crowdsale, CappedCrowdsale, PausableCrowdsale, Ownable {
    constructor(
        uint256 rate,            // rate, in TKNbits
        address payable wallet,  // wallet to send Ether
        IERC20 token,            // the token
        uint256 cap,             // total cap, in wei
        uint256 minContribution, // min contribution in wei
        uint256 maxContribution  // max contribution in wei
    )
        CappedCrowdsale(cap, minContribution, maxContribution)
        Crowdsale(rate, wallet, token)
        PausableCrowdsale()
        public
    {

    }

    function withdrawToken(address token, uint256 amount) external onlyOwner {
        IERC20(token).transfer(msg.sender, amount);
    }
}