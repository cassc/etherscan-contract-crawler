// Referral Marketing contract

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ReferralMarketingSDK.sol";

abstract contract NetworkSDK {
    address private _network;
    ReferralMarketingSDK public sdk;

    event NetworkTransferred(address indexed previousNetwork, address indexed newNetwork);
    event SDKChanged(address indexed previousSDK, address indexed newSDK);

    constructor(address __network, address __sdk) {
        _network = __network;
        sdk = ReferralMarketingSDK(__sdk);
    }

    function network() public view virtual returns (address) {
        return _network;
    }

    modifier onlyNetwork() {
        _checkNetwork();
        _;
    }

    function _checkNetwork() internal view virtual {
        require(network() == msg.sender, "caller is not Network");
    }

    function transferNetwork(address newAddress) public virtual onlyNetwork {
        require(newAddress != address(0), "new address is zero");
        address oldAddress = _network;
        _network = newAddress;
        emit NetworkTransferred(oldAddress, newAddress);
    }

    function setSDK(address newAddress) public virtual onlyNetwork {
        address oldAddress = address(sdk);
        sdk = ReferralMarketingSDK(newAddress);
        emit SDKChanged(oldAddress, newAddress);
    }
}

contract ReferralMarketingClient is Ownable, NetworkSDK {
    address public seller;
    mapping (bytes32 => address) public referrers;
    uint256 public receivedTotal; // total amount of tokens sold (in coins)
    IERC20 public tokenContract; // tokens to sell
    IERC20 public coinContract; // coins to buy with

    event TokensBought(
        uint256 sellPrice,
        uint256 pricePerToken,
        uint256 networkAmount,
        uint256 referrerAmount,
        address indexed referrerAddress,
        bytes32 indexed _referrerCode,
        uint256 sellerAmount
    );

    event SellerChanged(address indexed previousSeller, address indexed newSeller);
    event TokenContractChanged(address indexed previousTokenContract, address indexed newTokenContract);
    event CoinContractChanged(address indexed previousCoinContract, address indexed newCoinContract);

    constructor(
        address _seller, address _network,
        address _tokenContract, address _coinContract,
        address _sdk
    ) NetworkSDK(_network, _sdk) {
        seller = _seller;
        tokenContract = IERC20(_tokenContract);
        coinContract = IERC20(_coinContract);
        receivedTotal = 0;
    }

    function buyTokens(uint256 _numTokens, bytes32 _referrerCode) public {
        uint256 sellPrice; // tokens to sell
        uint256 pricePerToken;
        uint256 networkAmount;
        uint256 referrerAmount;
        address referrerAddress;
        uint256 sellerAmount;
        (sellPrice, pricePerToken, networkAmount, referrerAmount, referrerAddress, sellerAmount) = sdk.calcRefSplit(_numTokens, _referrerCode, receivedTotal);

        // transfer coins to contract
        require(coinContract.transferFrom(msg.sender, address(this), _numTokens * pricePerToken / 10**9), "Transfer failed");

        receivedTotal += sellPrice;

        // transfer tokens to buyer
        require(tokenContract.transfer(msg.sender, _numTokens), "Token transfer failed");

        // transfer tokens to network
        if (networkAmount > 0) {
            require(coinContract.transfer(network(), networkAmount), "Network transfer failed");
        }

        // transfer tokens to seller
        if (sellerAmount > 0) {
            require(coinContract.transfer(seller, sellerAmount), "Seller transfer failed");
        }

        // transfer tokens to referrer
        if (referrerAddress != address(0) && referrerAmount > 0) {
            require(coinContract.transfer(referrerAddress, referrerAmount), "Referrer transfer failed");
        }

        emit TokensBought(sellPrice, pricePerToken, networkAmount, referrerAmount, referrerAddress, _referrerCode, sellerAmount);
    }

    function withdrawCoins() public onlyOwner {
        require(coinContract.transfer(msg.sender, coinContract.balanceOf(address(this))), "Withdrawal failed");
    }

    function withdrawTokens() public onlyOwner {
        require(tokenContract.transfer(msg.sender, tokenContract.balanceOf(address(this))), "Withdrawal failed");
    }

    function setSeller(address newAddress) public onlyOwner {
        address oldAddress = address(seller);
        seller = newAddress;
        emit SellerChanged(oldAddress, newAddress);
    }

    function setTokenContract(address newAddress) public onlyNetwork {
        address oldAddress = address(tokenContract);
        tokenContract = IERC20(newAddress);
        emit TokenContractChanged(oldAddress, newAddress);
    }

    function setCoinContract(address newAddress) public onlyNetwork {
        address oldAddress = address(coinContract);
        coinContract = IERC20(newAddress);
        emit CoinContractChanged(oldAddress, newAddress);
    }

    function withdrawTokensCustom(address tokenAddress, uint256 amount) public onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(address(this)) >= amount, "Insufficient balance");
        token.transfer(msg.sender, amount);
    }

    function withdraw(uint256 amount) public onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }
}