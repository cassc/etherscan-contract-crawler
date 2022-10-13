// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

interface IElTxuletNFT {
    function mint(
        address,
        uint256,
        uint256,
        bytes memory
    ) external;
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function decimals() external view returns (uint8);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
}

contract ElTxuletNFTShop is Pausable, Ownable {
    IElTxuletNFT public elTxuletNFT;
    address public fundsRecipient;
    AggregatorV3Interface private ethToUsdFeed; //ChainLink Feed
    mapping(uint256 => uint256) public USDPrice;
    mapping(IERC20 => bool) public allowedStable;

    constructor(
        IElTxuletNFT _elTxuletNFT,
        IERC20[] memory _stablecoins,
        address _fundsRecipient,
        address _ethToUsdFeed
    ) {
        elTxuletNFT = _elTxuletNFT;
        for (uint256 i; i < _stablecoins.length; i++) {
            allowedStable[_stablecoins[i]] = true;
        }
        fundsRecipient = _fundsRecipient;
        ethToUsdFeed = AggregatorV3Interface(_ethToUsdFeed);

        // Prices
        USDPrice[1] = 750; // Gold
        USDPrice[2] = 300; // Silver
        USDPrice[3] = 150; // Bronze
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function addStable(IERC20 _address) public onlyOwner {
        require(!allowedStable[_address], "already allowed");
        allowedStable[_address] = true;
    }

    function removeStable(IERC20 _address) public onlyOwner {
        require(allowedStable[_address], "already removed");
        allowedStable[_address] = false;
    }

    /**
     * @dev Buy NFT with ETH with a 0.8% slippage
     * @param _tokenId Id of the token to be minted
     */
    function buyInETH(
        uint256 _tokenId,
        address _to,
        uint256 _amount
    ) public payable whenNotPaused {
        uint256 ethPrice = getNFTPriceInETH(_tokenId);
        require(
            msg.value > (_amount * (992 * ethPrice)) / 1000 &&
                msg.value < (_amount * (1008 * ethPrice)) / 1000,
            "bad ETH amount"
        );

        // Proceed to mint the token
        _mint(_to, _tokenId, _amount, "");
        // The value is immediately transfered to the funds recipient
        (bool sent, ) = payable(fundsRecipient).call{
            value: msg.value
        }("");
        require(sent, "Failed to send Ether");
    }

    /**
     * @dev Buy NFT with the specified token.
     * will revert if allowance is not set.
     * Please check for token alowance before calling this function.
     * You may need to call the "approve" function before.
     * @param _tokenId Id of the token to be minted
     */
    function buyInUSD(
        uint256 _tokenId,
        address _to,
        uint256 _amount,
        IERC20 _stableAddress
    ) public whenNotPaused {
        require(allowedStable[_stableAddress], "token not allowed");
        _stableAddress.transferFrom(
            msg.sender,
            fundsRecipient,
            _amount * USDPrice[_tokenId] * 10**_stableAddress.decimals()
        );
        _mint(_to, _tokenId, _amount, "");
    }

    /**
     * @dev Mint a specific amount of a given token
     * @param _to Address that will receive the token
     * @param _tokenId Id of the token to mint
     * @param _amount Amount to mint
     */
    function _mint(
        address _to,
        uint256 _tokenId,
        uint256 _amount,
        bytes memory _data
    ) internal {
        elTxuletNFT.mint(_to, _tokenId, _amount, _data);
    }

    /**
     * @dev Get current rate of ETH to US Dollar
     */
    function _getETHtoUSDPrice() private view returns (uint256) {
        (, int256 price, , , ) = ethToUsdFeed.latestRoundData();
        return uint256(price);
    }

    /**
     * @dev Return the price in ETH of the specified Id
     * decimals of Chainlink feeds are NOT with 18 decimals.
     * @param _tokenId Id of the token need price
     */
    function getNFTPriceInETH(uint256 _tokenId)
        public
        view
        returns (uint256 priceInETH)
    {
        uint256 priceInUsd = USDPrice[_tokenId];
        uint256 ethToUsd = _getETHtoUSDPrice();
        // Convert price in ETH for US Dollar price
        priceInETH =
            (priceInUsd * 10**ethToUsdFeed.decimals() * 10**18) /
            ethToUsd;
    }

    /**
     * @dev Set the price in USD (no decimals) of a given token
     * @param _tokenId Id of the token to change the price of
     * @param _price New price in USD (no decimals) for the token
     */
    function setPrice(uint256 _tokenId, uint256 _price) external onlyOwner {
        USDPrice[_tokenId] = _price;
    }
}