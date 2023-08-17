// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./MotionToken.sol";
import "./AggregatorV3Interface.sol";


contract MotionCrowdsale is
    Initializable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable
{

    MotionToken private _token;

    // Address where funds are collected
    address payable private _wallet;
    AggregatorV3Interface internal _aggregatorInterface;

    uint256 private _rate;
    uint256 private baseMultiplier;
    // Amount of wei raised
    uint256 private _qtySold;

    uint256 private _openingTime;
    uint256 private _closingTime;
    mapping(address => bool) private _whitelist;
    mapping(address => uint256) private _contributions;

    bool private _finalized;
    // minimum amount of funds to be raised in weis
    uint256 private _goal;
    // Token Distribution

    // Caps
    uint256 private _investorMinCap;

    // Token reserve funds
    address private _partnersFund;
    address private _partnersTimelock;
    address[] private _supportedStableTokens;
    mapping(address => uint16) private _nftHolders;
    IERC20Upgradeable public USDTInterface;


    uint256 private _releaseTime;

    event WhitelistAdded(address);
    event WhitelistRemoved(address);
    event CrowdsaleFinalized();

    event TimedCrowdsaleExtended(
        uint256 prevClosingTime,
        uint256 newClosingTime
    );

    event TokensPurchased(
        address indexed purchaser,
        uint256 value,
        uint256 amount
    );

    modifier onlyWhileOpen() {
        require(isOpen(), "TimedCrowdsale: not open");
        _;
    }

    modifier checkGoal(uint256 qty) {
        require(qty > 0 && (qty + _qtySold) <= _goal, "Goal Reached");
        _;
    }

    /**
     * @dev Reverts if beneficiary is not whitelisted. Can be used when extending this contract.
     */
    modifier isWhitelisted(address _beneficiary) {
        require(_whitelist[_beneficiary], "Only Whitelist function");
        _;
    }



    function initialize(
        uint256 crowdSalerate,
        address payable walletAddress,
        MotionToken tokenContract,
        uint256 saleOpeningTime,
        uint256 saleClosingTime,
        uint256 saleGoal,
        uint256 releaseTime,
        address priceFeed,
        address usdtAddress
    ) external initializer {
        require(crowdSalerate > 0, "Crowdsale: rate is 0");
        require( walletAddress != address(0), "Crowdsale: wallet is the zero address");
        require(address(tokenContract) != address(0),"Crowdsale: token is the zero address");
        require(saleOpeningTime >= block.timestamp,"TimedCrowdsale: opening time is before current time");
        require(saleClosingTime > saleOpeningTime,"TimedCrowdsale: opening time is not before closing time");
        require(saleGoal > 0, "Crowdsale: goal is 0");

        _rate = crowdSalerate;
        _wallet = walletAddress;
        _token = tokenContract;
        _openingTime = saleOpeningTime;
        _closingTime = saleClosingTime;
        _finalized = false;
        _goal = saleGoal;
        _releaseTime = releaseTime;
        _investorMinCap = 1;
        baseMultiplier = 10 ** 18;
        OwnableUpgradeable.__Ownable_init();
        PausableUpgradeable.__Pausable_init();
        _aggregatorInterface = AggregatorV3Interface(priceFeed);
        USDTInterface = IERC20Upgradeable(usdtAddress);
    }

    //
    function intializeAnotherVersion(
        uint256 crowdSalerate,
        address payable walletAddress,
        MotionToken tokenContract,
        uint256 saleOpeningTime,
        uint256 saleClosingTime,
        uint256 saleGoal,
        uint256 releaseTime,
        address priceFeed,
        address usdtAddress,
        uint8 version
    ) external onlyOwner reinitializer(version) {
        require(crowdSalerate > 0, "Crowdsale: rate is 0");
        require(walletAddress != address(0),"Crowdsale: wallet is the zero address");
        require(address(tokenContract) != address(0),"Crowdsale: token is the zero address");
        // solhint-disable-next-line not-rely-on-time
        require(saleOpeningTime >= block.timestamp,"TimedCrowdsale: opening time is before current time");
        // solhint-disable-next-line max-line-length
        require(saleClosingTime > saleOpeningTime,"TimedCrowdsale: opening time is not before closing time");
        require(saleGoal > 0, "Crowdsale: goal is 0");

        _rate = crowdSalerate;
        _wallet = walletAddress;
        _token = tokenContract;
        _openingTime = saleOpeningTime;
        _closingTime = saleClosingTime;
        _finalized = false;
        _goal = saleGoal;
        _releaseTime = releaseTime;
        _investorMinCap = 1;
        _aggregatorInterface = AggregatorV3Interface(priceFeed);
        USDTInterface = IERC20Upgradeable(usdtAddress);
    }


    function getUserContribution(
        address _beneficiary
    ) public view returns (uint256) {
        return _contributions[_beneficiary];
    }

    /**
     * @return the token being sold.
     */
    function token() public view returns (address) {
        return address(_token);
    }

    /**
     * @return the address where funds are collected.
     */
    function wallet() public view returns (address payable) {
        return _wallet;
    }

    /**
     * @return the number of token units a buyer gets per wei.
     */
    function rate() public view virtual returns (uint256) {
        return _rate;
    }

    /**
     * @return the amount of wei raised.
     */
    function qtySold() public view returns (uint256) {
        return _qtySold;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Low balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "ETH Payment failed");
    }

    receive() external payable {}

    function buyTokensEthInternal(
        uint256 qty,
        address beneficiary
    )
        internal
        virtual
        nonReentrant
        onlyWhileOpen
        checkGoal(qty)
        returns (bool)
    {
        require(qty != 0, "Crowdsale: Qty sent is 0");
        require(msg.value > 0, "Value can not be Zero");
        require(beneficiary != address(0), "Benificiary can't be address 0");
        uint256 _existingContribution = _contributions[beneficiary];
        uint256 _newContribution = _existingContribution + qty;
        require(
            _newContribution >= _investorMinCap,
            "Your Qty is less than minimum cap or contributions are above hard cap"
        );
        uint256 usdPrice = qty * _rate;
        uint256 price = getLatestPrice();
        uint256 ethAmount = ((usdPrice * baseMultiplier) / (price / 10 ** 4)) *
            10 ** 4;

        require(msg.value >= ethAmount, "Less payment");

        uint256 excess = msg.value - ethAmount;
        if (_nftHolders[beneficiary] != 0) {
            qty = qty + ((qty * _nftHolders[beneficiary]) / 100);
        }
        _contributions[beneficiary] = _newContribution;
        _qtySold = _qtySold + qty;
        sendValue(_wallet, ethAmount);
        if (excess > 0) sendValue(payable(beneficiary), excess);
        IERC20(_token).transfer(beneficiary, qty * baseMultiplier);
        emit TokensPurchased(beneficiary, ethAmount, qty);
        return true;
    }

    function buyTokensEth(uint256 qty) public payable returns (bool) {
        require(
            _msgSender() != address(0),
            "Crowdsale: beneficiary is the zero address"
        );
        return buyTokensEthInternal(qty, _msgSender());
    }

    function addNftTokenHolders(
        address[] memory holders,
        uint16[] memory typeOfTokens
    ) external onlyOwner onlyWhileOpen returns (bool) {
        require(
            holders.length == typeOfTokens.length,
            "Please provide equal arrays"
        );
        for (uint i = 0; i < holders.length; i++) {
            _nftHolders[holders[i]] = typeOfTokens[i];
        }
        return true;
    }

    function removeNftTokenHolders(
        address[] memory holders
    ) external onlyOwner onlyWhileOpen returns (bool) {
        for (uint i = 0; i < holders.length; i++) {
            _nftHolders[holders[i]] = 0;
        }
        return true;
    }

    function getNftTokenType(address holder) public view returns (uint16) {
        return _nftHolders[holder];
    }

    function buyTokensUsdt(
        uint256 qty
    )
        public
        payable
        virtual
        nonReentrant
        onlyWhileOpen
        checkGoal(qty)
        returns (bool)
    {
        require(
            _msgSender() != address(0),
            "Crowdsale: beneficiary is the zero address"
        );
        require(qty != 0, "Crowdsale: Qty sent is 0");
        uint256 _existingContribution = _contributions[_msgSender()];
        uint256 _newContribution = _existingContribution + qty;
        require(
            _newContribution >= _investorMinCap,
            "Your Qty is less than minimum cap or contributions are above hard cap"
        );

        uint256 usdPrice = qty * _rate;
        usdPrice = usdPrice / (10 ** 22);
        uint256 ourAllowance = USDTInterface.allowance(
            _msgSender(),
            address(this)
        );
        require(ourAllowance >= usdPrice, "Make sure to add enough allowance");
        (bool success, ) = address(USDTInterface).call(
            abi.encodeWithSignature(
                "transferFrom(address,address,uint256)",
                _msgSender(),
                _wallet,
                usdPrice
            )
        );
        require(success, "Token payment failed");
        if (_nftHolders[_msgSender()] != 0) {
            qty = qty + ((qty * _nftHolders[_msgSender()]) / 100);
        }
        IERC20(_token).transfer(_msgSender(), qty * baseMultiplier);
        _contributions[_msgSender()] = _newContribution;
        _qtySold = _qtySold + qty;
        emit TokensPurchased(_msgSender(), usdPrice, qty);

        return true;
    }

    function getLatestPrice() public view returns (uint256) {
        (, int256 price, , , ) = _aggregatorInterface.latestRoundData();
        price = (price * (10 ** 10));
        return uint256(price);
    }

    function setRate(uint256 rateToSet) external virtual onlyOwner {
        _rate = rateToSet;
    }

    /**
     * @return _openingTime the crowdsale opening time.
     */
    function openingTime() public view returns (uint256) {
        return _openingTime;
    }

    /**
     * @return the crowdsale closing time.
     */
    function closingTime() public view returns (uint256) {
        return _closingTime;
    }

    function changePreSalesValues(uint256 _closeTime, uint256 salesGoal) external onlyOwner {
        _extendTime(_closeTime);
        _goal = salesGoal;

    }

    /**
     * @return true if the crowdsale is open, false otherwise.
     */
    function isOpen() public view returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        return
            block.timestamp >= _openingTime && block.timestamp <= _closingTime;
    }

    /**
     * @dev Checks whether the period in which the crowdsale is open has already elapsed.
     * @return Whether crowdsale period has elapsed
     */
    function hasClosed() public view returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp > _closingTime;
    }

    /**
     * @dev Extend crowdsale.
     * @param newClosingTime Crowdsale closing time
     */
    function _extendTime(uint256 newClosingTime) internal {
        require(!hasClosed(), "TimedCrowdsale: already closed");
        // solhint-disable-next-line max-line-length
        require(
            newClosingTime > _closingTime,
            "TimedCrowdsale: new closing time is before current closing time"
        );

        emit TimedCrowdsaleExtended(_closingTime, newClosingTime);
        _closingTime = newClosingTime;
    }

    /**
     * @dev Adds single address to whitelist.
     * @param beneficiary Address to be added to the whitelist
     */
    function addToWhitelist(address beneficiary) external onlyOwner {
        if (_whitelist[beneficiary] == false) {
            _whitelist[beneficiary] = true;
            emit WhitelistAdded(beneficiary);
        }
        _whitelist[beneficiary] = true;
    }

    /**
     * @dev removes single address to whitelist.
     * @param beneficiary Address to be added to the whitelist
     */
    function removeFromWhitelist(address beneficiary) external onlyOwner {
        if (_whitelist[beneficiary] == true) {
            _whitelist[beneficiary] = false;
            emit WhitelistRemoved(beneficiary);
        }
    }

    /**
     * @return true if the crowdsale is finalized, false otherwise.
     */
    function finalized() public view virtual returns (bool) {
        return _finalized;
    }

    /**
     * @dev Must be called after crowdsale ends, to do some extra finalization
     * work. Calls the contract's finalization function.
     */
    function finalize() public onlyOwner {
        require(!_finalized, "FinalizableCrowdsale: already finalized");
        _finalized = true;

        _finalization();
        emit CrowdsaleFinalized();
    }

    /**
     * @return minimum amount of funds to be raised in wei.
     */
    function goal() public view returns (uint256) {
        return _goal;
    }

    /**
     * @dev Escrow finalization task, called when finalize() is called.
     */
    function _finalization() internal onlyOwner {
        _token.transfer(_wallet, _token.balanceOf(address(this)));
        _closingTime = block.timestamp;
    }

    function pause() public onlyOwner {
        super._pause();
    }

    /**
     * @dev Airdrop function of motion token
     */
    function airdropToken(
        uint256 qty,
        address recipient
    ) external onlyOwner returns (bool) {
        return buyTokensEthInternal(qty, recipient);
    }

    function rescueETH(uint256 weiAmount) external onlyOwner {
        require(address(this).balance >= weiAmount, "insufficient ETH balance");
        payable(owner()).transfer(weiAmount);
    }

    function rescueAnyERC20Tokens(
        address _tokenAddr,
        address _to,
        uint _amount
    ) public onlyOwner {
        IERC20(_tokenAddr).transfer(_to, _amount);
    } 

    fallback() external payable {}
}