// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "hardhat/console.sol";

contract Presale is ReentrancyGuard, Ownable {
    uint256 public constant DECIMALS = 18;
    uint256 public constant DENOMINATOR = 10**DECIMALS;
    uint256 public constant INITIAL_PRICE = (DENOMINATOR) / 7402; //Initial price  1 ETH == 7402 tokens

    /**
     * @dev price must be set with `DENOMINATOR` decimals
     */
    uint256 public price = INITIAL_PRICE;

    address payable public receiverOfEarnings;

    IERC20Metadata public presaleToken;
    uint8 internal tokenDecimals;

    bool public paused;

    event PriceChange(uint256 oldPrice, uint256 newPrice);
    event BoughtWithBNB(uint256 amount);

    /**
     * @dev Throws is the presale is paused
     */
    modifier notPaused() {
        require(!paused, "Presale is paused");
        _;
    }

    /**
     * @dev Throws is presale is NOT paused
     */
    modifier isPaused() {
        require(paused, "Presale is not paused");
        _;
    }

    /**
     * @param _presaleToken adress of the token to be purchased through preslae
     * @param _receiverOfEarnings address of the wallet to be allowed to withdraw the proceeds
     */
    constructor(
        address _presaleToken,
        address payable _receiverOfEarnings
    ) {
        require(
            _receiverOfEarnings != address(0),
            "Receiver wallet cannot be 0"
        );
        receiverOfEarnings = _receiverOfEarnings;
        presaleToken = IERC20Metadata(_presaleToken);
        tokenDecimals = presaleToken.decimals();

        paused = true; //@dev start as paused
    }

    /**
     * @notice Sets the address allowed to withdraw the proceeds from presale
     * @param _receiverOfEarnings address of the reveiver
     */
    function setReceiverOfEarnings(address payable _receiverOfEarnings)
        external
        onlyOwner
    {
        require(
            _receiverOfEarnings != receiverOfEarnings,
            "Receiver already configured"
        );
        require(_receiverOfEarnings != address(0), "Receiver cannot be 0");
        receiverOfEarnings = _receiverOfEarnings;
    }

    /**
     * @notice Sets new price for the presale token
     * @param _price new price of the presale token - uses `DECIMALS` for precision
     */
    function setPrice(uint256 _price) external onlyOwner {
        require(_price != price, "New price cannot be same");
        uint256 _oldPrice = price;
        price = _price;
        emit PriceChange(_oldPrice, _price);
    }

    /**
     * @notice Releases presale tokens to the recipient
     * @param _recipient recipient of the presale tokens
     * @param _paidAmount amount paid by recipient
     */
    function _releasePresaleTokens(
        address _recipient,
        uint256 _paidAmount
    ) internal {
        uint256 tokensToReceive = calculateTokensToReceive(_paidAmount);
 
        require(
            tokensToReceive <= presaleToken.balanceOf(address(this)),
            "Contract balance too low"
        );

        require(
            presaleToken.transfer(_recipient, tokensToReceive),
            "Token transfer failed"
        );
    }

    receive() external payable {
        buyTokensWithBNB();
    }

    /**
     * @notice Allows purchase of presale tokens using BNB
     */
    function buyTokensWithBNB()
        public
        payable
        notPaused
        nonReentrant
    {
        require(msg.value > 0, "No BNB sent");
        _releasePresaleTokens(msg.sender, msg.value);
        emit BoughtWithBNB(msg.value);
    }

    /**
     * @notice Transfers collected funds to `receiverOfEarnings` address
     */
    function withdraw() external {
        require(
            msg.sender == receiverOfEarnings,
            "Sender not allowed to withdraw"
        );

        uint256 bnbBalance = address(this).balance;

        if (bnbBalance > 0) {
            payable(receiverOfEarnings).transfer(bnbBalance);
        }
    }

    /**
     * @notice Transfers all remaining `presaleToken` balance to owner when presale is over
     */
    function rescuePresaleTokens() external onlyOwner isPaused {
        uint256 balance = presaleToken.balanceOf(address(this));
        require(balance > 0, "No tokens to rescue");

        require(
            presaleToken.transfer(owner(), balance),
            "Token transfer failed"
        );
    }

    /**
     * @notice Calculates the amount of `presaleToken` based on the amount of `paidWithToken`
     * @param _amount amount of `paidWithToken` used in purchase
     */
    function calculateTokensToReceive(uint256 _amount)
        public
        view
        returns (uint256)
    {
        uint256 amountToTransfer = (_amount * 10**tokenDecimals) / price;
        return amountToTransfer;
    }

    /**
     * @notice Pauses the presale
     */
    function pause() external onlyOwner notPaused {
        paused = true;
    }

    /**
     * @notice Unpauses the presale
     */
    function unpause() external onlyOwner isPaused {
        paused = false;
    }
}