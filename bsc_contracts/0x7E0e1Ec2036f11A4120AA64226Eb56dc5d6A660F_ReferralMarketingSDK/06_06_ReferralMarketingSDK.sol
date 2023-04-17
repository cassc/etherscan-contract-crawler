// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ISwapGetAmounts.sol";
import "./INetworkSDK.sol";

contract ReferralMarketingSDK is Ownable, INetworkSDK {
    address private clientAdmin;
    mapping (bytes32 => address) public referrers;
    uint256 public networkFee; // platform fee in 1/1000 of % of coins
    uint256 public networkFeeDiscounted; // platform fee in 1/1000 of % of coins after discount cap
    uint256 public discountThreshold; // threshold in coins after which networkFeeDiscounted is applied
    uint256 public referrerFee; // referrer fee in 1/1000 of % of coins
    uint256 public pricePerToken; // price of each token in coins (multiplied by 10^18)
    IERC20 tokenContract;
    IERC20 coinContract;
    ISwapGetAmounts swapContract;
    IERC20 swapTokenContract;

    event ClientTransferred(address indexed previousClientAdmin, address indexed newClientAdmin);
    event ReferrerFeeSet(uint256 newFee);
    event NetworkFeeSet(uint256 newFee);
    event ReferrerSet(address indexed newRecipient, bytes32 indexed referrerCode);

    constructor(
        uint256 _referrerFee,
        uint256 _networkFee,
        uint256 _networkFeeDiscounted,
        uint256 _discountThreshold,
        uint256 _pricePerToken,
        address _tokenContract,
        address _coinContract,
        address _swapContract,
        address _swapTokenContract
    ) {
        referrerFee = _referrerFee;
        networkFee = _networkFee;
        networkFeeDiscounted = _networkFeeDiscounted;
        discountThreshold = _discountThreshold;
        pricePerToken = _pricePerToken;
        clientAdmin = address(0);
        tokenContract = IERC20(_tokenContract);
        coinContract = IERC20(_coinContract);
        swapContract = ISwapGetAmounts(_swapContract);
        swapTokenContract = IERC20(_swapTokenContract);
    }

    function calcRefSplit(
        uint256 _numTokens,
        bytes32 _referrerCode,
        uint256 _receivedTotal
    ) external view returns (
        uint256 sellPrice,
        uint256 _pricePerToken,
        uint256 networkAmount,
        uint256 referrerAmount,
        address referrerAddress,
        uint256 sellerAmount
    ) {
        if (_referrerCode != bytes32(0)) {
            referrerAddress = referrers[_referrerCode];
//            require(referrerAddress != address(0), "Referrer not found");
        } else {
            referrerAddress = address(0);
        }

        _pricePerToken = _getPricePerToken();
        sellPrice = _numTokens * _pricePerToken / 10**9;

        if (_referrerCode != bytes32(0)) {
            // calculate network amount
            if (discountThreshold > _receivedTotal) {
                networkAmount = sellPrice * networkFee / 100_000;
            } else {
                networkAmount = sellPrice * networkFeeDiscounted / 100_000;
            }

            // calculate referral amount
            referrerAmount = sellPrice * referrerFee / 100_000;

            sellerAmount = sellPrice - networkAmount - referrerAmount;
        } else {
            networkAmount = 0;
            referrerAmount = 0;
            sellerAmount = sellPrice;
        }
    }

    function setReferrerFee(uint256 _newFee) public onlyAdmins {
        require(_newFee <= 100_000 - networkFee, "Fee must be between 0 and 100'000");
        referrerFee = _newFee;
        emit ReferrerFeeSet(referrerFee);
    }

    function setNetworkFee(uint256 _newFee) public onlyOwner {
        require(_newFee <= 100_000, "Fee must be between 0 and 100'000");
        networkFee = _newFee;
        emit NetworkFeeSet(networkFee);
    }

    function setReferrer(bytes32 _referrerCode, address _newRecipient) public onlyAdmins {
        referrers[_referrerCode] = _newRecipient;
        emit ReferrerSet(_newRecipient, _referrerCode);
    }

    function getReferrer(bytes32 referrerCode) public view returns (address) {
        return referrers[referrerCode];
    }

    function setTokenPrice(uint256 _newPrice) public onlyAdmins {
        pricePerToken = _newPrice;
    }

    function _getPricePerToken() public view returns (uint256) {
        if (pricePerToken != 0) return pricePerToken;
        address[] memory addressChain = new address[](3);
        addressChain[0] = address(coinContract);
        addressChain[1] = address(swapTokenContract);
        addressChain[2] = address(tokenContract);
        uint[] memory amounts = swapContract.getAmountsIn(1_000_000_000, addressChain);
        return amounts[0];
    }

    function getPricePerToken() external view returns (uint256) {
        return _getPricePerToken();
    }

    function transferClientAdmin(address newAddress) public virtual onlyAdmins {
        require(newAddress != address(0), "new address is zero");
        address oldAddress = clientAdmin;
        clientAdmin = newAddress;
        emit ClientTransferred(oldAddress, newAddress);
    }

    modifier onlyAdmins() {
        require(msg.sender == owner() || msg.sender == clientAdmin, "caller is not admin");
        _;
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

    event SwapContractChanged(address indexed previousContract, address indexed newContract);
    function setSwapContract(address newAddress) public onlyOwner {
        address oldAddress = address(swapContract);
        swapContract = ISwapGetAmounts(newAddress);
        emit SwapContractChanged(oldAddress, newAddress);
    }

    event SwapTokenContractChanged(address indexed previousContract, address indexed newContract);
    function setTokenSwapContract(address newAddress) public onlyOwner {
        address oldAddress = address(swapTokenContract);
        swapTokenContract = IERC20(newAddress);
        emit SwapTokenContractChanged(oldAddress, newAddress);
    }

    event TokenContractChanged(address indexed previousContract, address indexed newContract);
    function setTokenContract(address newAddress) public onlyOwner {
        address oldAddress = address(tokenContract);
        tokenContract = IERC20(newAddress);
        emit TokenContractChanged(oldAddress, newAddress);
    }

    event CoinContractChanged(address indexed previousContract, address indexed newContract);
    function setCoinContract(address newAddress) public onlyOwner {
        address oldAddress = address(coinContract);
        coinContract = IERC20(newAddress);
        emit CoinContractChanged(oldAddress, newAddress);
    }

    function getClientAdmin() public view returns (address) {
        return clientAdmin;
    }

    function getTokenContract() public view returns (address) {
        return address(tokenContract);
    }

    function getCoinContract() public view returns (address) {
        return address(coinContract);
    }

    function getSwapContract() public view returns (address) {
        return address(swapContract);
    }

    function getSwapTokenContract() public view returns (address) {
        return address(swapTokenContract);
    }
}