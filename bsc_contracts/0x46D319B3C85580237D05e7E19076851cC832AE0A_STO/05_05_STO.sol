// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract STO is Context, Ownable {
    using SafeMath for uint256;

    uint256 public rate; // token rate against of stable coin
    IERC20 private token; // token address
    address private wallet; // company wallet address to withdraw after STO is finished

    uint256 public softCap; // softCap for STO
    uint256 public hardCap; // hardCap for STO

    uint256 private weiRaised; // total raised funds in Stable Coins
    uint256 public endSTODate; // end date for STO
    uint256 public startSTODate; // start date for STO

    uint256 public minPurchase; // minimum investment amount in Stable Coin
    uint256 public maxPurchase; // maximum investment amount in Stable Coin

    string[] acceptedCoins; // array of Stable Coin names accepted to invest
    mapping(string => address) acceptedCoin; // address of accepted Stable Coin

    mapping(address => bool) isClaimed; // status to represent if a specfic user claimed
    mapping(address => uint256) totalInvestedOf; // total investment for a specific user
    mapping(address => uint256) purchasedTokensOf; // total bought token amount for a specific user
    mapping(address => mapping(string => uint256)) investedCoinsOf; // investment by Stable Coins for a specfic user

    /**
     * @param purchaser user who invests to buy tokens
     * @param beneficiary user who get tokens in practice
     * @param coins Stable Coin amount invested
     * @param coinName Stable Coin Name invested
     * @param tokens Token amount bought
     * @dev event which occurs when token was purchased successfully.
     */
    event TokensPurchased(
        address indexed purchaser,
        address indexed beneficiary,
        uint256 coins,
        string coinName,
        uint256 tokens
    );

    /**
     * @dev event which occurs when STO was started.
     */
    event STOStarted(
        uint256 startSTO,
        uint256 endSTO,
        uint256 minPurchase,
        uint256 maxPurchase,
        uint256 softCap,
        uint256 hardCap
    );

    /**
     * @dev event which occurs when raised fund for a specific user was refunded.
     */
    event Refunded(address indexed beneficiary);

    /**
     * @dev event which occurs when whole raised funds were withdrawn into company's account.
     */
    event Withdrawn(address indexed wallet);

    event StableCoinAdded(address indexed coin, string coinName);
    event StableCoinRemoved(string coinName);

    /**
     * @dev constructor
     */
    constructor(
        uint256 _rate,
        address _wallet,
        address _token,
        uint256 _startSTO,
        uint256 _endSTO,
        uint256 _minPurchase,
        uint256 _maxPurchase,
        uint256 _softCap,
        uint256 _hardCap,
        uint256 _weiRaised
    ) {
        require(
            _endSTO > _startSTO,
            "STO: The ending date must be after the starting date"
        );
        require(
            _softCap > 0 && _hardCap > _softCap,
            "STO: softCap and hardCap must be larger than 0"
        );
        require(_rate > 0, "STO: rate must be larger than 0");
        require(_wallet != address(0), "STO: wallet is the zero address");
        require(_token != address(0), "STO: token is the zero address");
        rate = _rate;
        wallet = _wallet;
        token = IERC20(_token);
        startSTODate = _startSTO;
        endSTODate = _endSTO;
        minPurchase = _minPurchase;
        maxPurchase = _maxPurchase;
        softCap = _softCap;
        hardCap = _hardCap;
        weiRaised = _weiRaised;
        acceptedCoins = ["USDT", "USDC", "BUSD"];
        acceptedCoin["USDT"] = 0xAAccE7485CFeBFcaD048a2280bc2Fc75E75907Cb;
        acceptedCoin["USDC"] = 0x936Eb66361300b8926De11ABd4495949dc541800;
        acceptedCoin["BUSD"] = 0xE8D29CB745e6eAfa6080457FB744c9f3D4273A72;
    }

    /**
     * @dev stoActive modifier possible all actions when STO is processed.
     */
    modifier stoActive() {
        require(
            block.timestamp < endSTODate &&
                block.timestamp > startSTODate &&
                hardCap >= weiRaised + minPurchase,
            "STO: STO must be active"
        );
        _;
    }

    /**
     * @dev stoFailed modifier possible all actions when STO isn't active.
     */
    modifier stoFailed() {
        require(
            endSTODate < block.timestamp && softCap > weiRaised,
            "STO: STO must not be active"
        );
        _;
    }

    /**
     * @notice STO must be active to call this function.
     * @param _beneficiary the address whose get token.
     * @param _weiAmount the wei amount of Stable Coin to send
     * @param _coinName the stable coin name like (USDT, USDC or nay other Token that you accepting)
     * @dev Purchase Tokens
     */
    function buyTokens(
        address _beneficiary,
        uint256 _weiAmount,
        string memory _coinName
    ) public stoActive {
        require(acceptedCoin[_coinName] != address(0), "Invalid Coin Name");
        require(
            IERC20(acceptedCoin[_coinName]).balanceOf(_msgSender()) >=
                _weiAmount,
            "Not Enough Coin Amount"
        );

        require(
            IERC20(acceptedCoin[_coinName]).allowance(
                _msgSender(),
                address(this)
            ) >= _weiAmount,
            "NOT Enough Coin Amount Approved"
        );
        _preValidatePurchase(_beneficiary, _weiAmount);
        uint256 tokens = _getTokenAmount(_weiAmount);
        IERC20(acceptedCoin[_coinName]).transferFrom(
            _msgSender(),
            address(this),
            _weiAmount
        );
        weiRaised = weiRaised.add(_weiAmount);
        isClaimed[_beneficiary] = false;
        totalInvestedOf[_beneficiary] = totalInvestedOf[_beneficiary].add(
            _weiAmount
        );
        purchasedTokensOf[_beneficiary] = purchasedTokensOf[_beneficiary].add(
            tokens
        );
        investedCoinsOf[_beneficiary][_coinName] = investedCoinsOf[
            _beneficiary
        ][_coinName].add(_weiAmount);
        _deliverTokens(_beneficiary, tokens);
        emit TokensPurchased(
            _msgSender(),
            _beneficiary,
            _weiAmount,
            _coinName,
            tokens
        );
    }

    /**
     * @param _beneficiary the User address to refund
     * @dev If STO goal is not reached softCap, then Investors Claim their funds that they spend for Purchse token.
     */
    function claimRefund(address _beneficiary) public stoFailed {
        require(
            isClaimed[_beneficiary] == false,
            "STO: Only STO member can refund coins!"
        );
        isClaimed[_beneficiary] = true;
        for (uint256 i = 0; i < acceptedCoins.length; i++) {
            if (investedCoinsOf[_beneficiary][acceptedCoins[i]] > 0) {
                IERC20(acceptedCoin[acceptedCoins[i]]).transfer(
                    _beneficiary,
                    investedCoinsOf[_beneficiary][acceptedCoins[i]]
                );
                totalInvestedOf[_beneficiary].sub(
                    investedCoinsOf[_beneficiary][acceptedCoins[i]]
                );
            }
        }
        emit Refunded(_beneficiary);
    }

    /**
     * @dev Withdraw Whole Raised Funds into Company's account when STO is finished successfully.
     */
    function withdraw() external onlyOwner {
        for (uint256 i = 0; i < acceptedCoins.length; i++) {
            IERC20(acceptedCoin[acceptedCoins[i]]).transfer(
                wallet,
                IERC20(acceptedCoin[acceptedCoins[i]]).balanceOf(address(this))
            );
        }
        emit Withdrawn(wallet);
    }

    /**
     * @dev Internal function checking all rules and regulation before purchase token This is internal function no one could call from outside
     * @param _beneficiary Its beneficary address
     * @param _weiAmount wei amount
     * @notice Until and unless owner also couldn't call
     */
    function _preValidatePurchase(
        address _beneficiary,
        uint256 _weiAmount
    ) internal view {
        require(
            _beneficiary != address(0),
            "STO: beneficiary is the zero address"
        );
        require(_weiAmount != 0, "STO: weiAmount is 0");
        require(_weiAmount >= minPurchase, "have to send at least minPurchase");
        require(_weiAmount <= maxPurchase, "have to send at most maxPurchase");
        this;
    }

    /**
     * @dev internal function which deliver Token to User
     */
    function _deliverTokens(
        address _beneficiary,
        uint256 _tokenAmount
    ) internal {
        token.transfer(_beneficiary, _tokenAmount);
    }

    /**
     * @param _weiAmount amount in wei of USD from investor
     * @dev Internally Get Token Amount
     */
    function _getTokenAmount(
        uint256 _weiAmount
    ) internal view returns (uint256) {
        return _weiAmount.mul(10 ** 18).div(rate);
    }

    /**
     * @notice Only Owner can set Token that accepting for purchase Token that on sell.
     * @param _coin Stable Coin Address to add
     * @param _coinName Stable Coin Name to add
     */
    function acceptCoin(
        address _coin,
        string memory _coinName
    ) external onlyOwner {
        require(acceptedCoin[_coinName] == address(0), "Already Exist");
        acceptedCoin[_coinName] = _coin;
        acceptedCoins.push(_coinName);
        emit StableCoinAdded(_coin, _coinName);
    }

    /**
     * @notice Owner Remove Token Accept Token to purchase token.
     * @param _coinName Stable Coin Name to remove
     */
    function removeAcceptedCoin(string memory _coinName) external onlyOwner {
        require(acceptedCoin[_coinName] != address(0), "Token Not Exist");
        acceptedCoin[_coinName] = address(0);
        for (uint256 i = 0; i < acceptedCoins.length; i++) {
            if (
                keccak256(abi.encodePacked(acceptedCoins[i])) ==
                keccak256(abi.encodePacked(_coinName))
            ) {
                acceptedCoins[i] = acceptedCoins[acceptedCoins.length - 1];
                acceptedCoins.pop();
            }
        }
        emit StableCoinRemoved(_coinName);
    }

    /**
     * @notice Only owner can set rate
     * @dev Set Rate
     * @param _rate New Rate
     */
    function setRate(uint256 _rate) external onlyOwner {
        require(_rate > 0, "STO: rate must be larger than 0");
        rate = _rate;
    }

    /**
     * @notice Only owner can set wallet address
     * @dev Set wallet address
     * @param _wallet new wallet address
     */
    function setWallet(address _wallet) external onlyOwner {
        require(_wallet != address(0), "STO: wallet is the zero address");
        wallet = _wallet;
    }

    /**
     * @notice Only owner can set softCap
     * @dev Set softCap
     * @param _softCap new softCap in wei
     */
    function setSoftCap(uint256 _softCap) external onlyOwner {
        require(_softCap > 0, "STO: softCap must be larger than 0");
        softCap = _softCap;
    }

    /**
     * @notice Only owner can set hardCap
     * @dev Set hardCap
     * @param _hardCap new hardCap in wei
     */
    function setHardCap(uint256 _hardCap) external onlyOwner {
        require(_hardCap > 0, "STO: hardCap must be larger than 0");
        hardCap = _hardCap;
    }

    /**
     * @notice Only owner can set startSTODate
     * @dev Set startSTODate
     * @param _startSTODate new start STO date
     */
    function setStartSTODate(uint256 _startSTODate) external onlyOwner {
        require(_startSTODate > 0, "STO: start STO Date must be larger than 0");
        startSTODate = _startSTODate;
    }

    /**
     * @notice Only owner can set endSTODate
     * @dev Set endSTODate
     * @param _endSTODate new end STO date
     */
    function setEndSTODate(uint256 _endSTODate) external onlyOwner {
        require(_endSTODate > 0, "STO: end STO Date must be larger than 0");
        endSTODate = _endSTODate;
    }

    /**
     * @notice Only owner can set minPurchase
     * @dev Set minPurchase
     * @param _minPurchase new minPurchase
     */
    function setMinPurchase(uint256 _minPurchase) external onlyOwner {
        require(_minPurchase > 0, "STO: minPurchase must be larger than 0");
        minPurchase = _minPurchase;
    }

    /**
     * @notice Only owner can set maxPurchase
     * @dev Set maxPurchase
     * @param _maxPurchase new maxPurchase
     */
    function setMaxPurchase(uint256 _maxPurchase) external onlyOwner {
        require(_maxPurchase > 0, "STO: maxPurchase must be larger than 0");
        maxPurchase = _maxPurchase;
    }

    /**
     * @dev Get rate
     */
    function getRate() external view returns (uint256) {
        return rate;
    }

    /**
     * @dev Its function just getting current block time from blockchain.
     */
    function getCurrentTimestamp() external view returns (uint256) {
        return block.timestamp;
    }

    /**
     * @dev Get STO End Time.
     */
    function getEndSTOTimestamp() external view returns (uint256) {
        return endSTODate;
    }

    /**
     * @dev Get STO Start Time.
     */
    function getStartSTOTimestamp() external view returns (uint256) {
        return startSTODate;
    }

    /**
     * @dev Get total raised Stable Coin in wei.
     */
    function getWeiRaised() external view returns (uint256) {
        return weiRaised;
    }

    /**
     * @dev Get hardcap in wei.
     */
    function getHardCap() external view returns (uint256) {
        return hardCap;
    }

    /**
     * @dev Get softCap in wei.
     */
    function getSoftCap() external view returns (uint256) {
        return softCap;
    }

    /**
     * @dev Get minPurchase in wei
     */
    function getMinPurchase() external view returns (uint256) {
        return minPurchase;
    }

    /**
     * @dev Get maxPurchase in wei
     */
    function getMaxPurchase() external view returns (uint256) {
        return maxPurchase;
    }

    /**
     * @dev Get total invested Stable Coin for a specific user.
     */
    function getTotalInvestedOf() external view returns (uint256) {
        return totalInvestedOf[_msgSender()];
    }

    /**
     * @dev Get total purchased tokens amount for a specific user.
     */
    function getPurchasedTokensOf() external view returns (uint256) {
        return purchasedTokensOf[_msgSender()];
    }
}