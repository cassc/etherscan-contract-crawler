// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./libraries/Formula.sol";
import "./libraries/Config.sol";
import "./libraries/TransferHelper.sol";


interface IUSDT{
    function balanceOf(address who) external view returns (uint256);
}

contract Sale is Ownable, ReentrancyGuard {

    address public token;
    uint256 public totalTokenSale;
    uint256 public maxContribute;

    /// Boolean variable to provide the status of sale finalization.
    bool public isSaleFinalized;

    uint256 public soldTokenAmount;
    uint256 public privateSaleStartTime;
    uint256 public privateSaleEndTime;
    uint256 public withdrawStartTime;

    mapping(address => bool) public stableCoins;
    mapping(address => uint256) public lockedTimeWithdraw;
    mapping(address => uint256) public withdrawnAmount;
    mapping(address => uint256) public boughtCashes;
    mapping(address => uint256) public tokensByUser;


    event SetSaleTimes(uint256 privateSaleStartTime, uint256 privateSaleEndTime, uint256 withdrawStartTime);
    event WithdrawBoughtTokens(address indexed acc, uint256 amount, uint256 withdrawedAt);
    event PrivateSaleTokens(address indexed buyer, address indexed stableCoins, uint256 usdt, uint256 token, uint256 boughtAt);
    event SaleFinalized(uint256 burnedAmount, uint256 finalizedSaleAt);

    /// @dev Constructor to set initial values for the contract.
    ///
    /// @param _token Address of the token that gets distributed.
    constructor( address _token, address _USDT) {
        token = _token;
        setStableCoins(_USDT);
        // Set finalize status to false.
        isSaleFinalized = false;
    }

    modifier hasSaleRunning() {
        uint256 currentTime = block.timestamp;
        require(!isSaleFinalized, "IDO: Sale has ended");
        require(privateSaleStartTime > 0, "IDO: Sale has yet to be started");
        require(
            (privateSaleStartTime <= currentTime && currentTime <= privateSaleEndTime) ,
            "IDO: Now is not sale time"
        );
        _;
    }

    function setStableCoins(address _stableCoin) public onlyOwner {
        stableCoins[_stableCoin] = true;
    }

    function setSaleTimes(
        uint256 _privateSaleStartTime,
        uint256 _privateSaleEndTime,
        uint256 _withdrawStartTime
    ) external onlyOwner {
        require(
            _privateSaleStartTime > block.timestamp &&
            _withdrawStartTime > _privateSaleEndTime &&
            _privateSaleStartTime < _privateSaleEndTime ,
            "IDO: Invalid sale time"
        );
        privateSaleStartTime = _privateSaleStartTime;
        privateSaleEndTime = _privateSaleEndTime;
        withdrawStartTime = _withdrawStartTime;
        emit SetSaleTimes(_privateSaleStartTime, _privateSaleEndTime, _withdrawStartTime);
    }

    /// @dev Used to withdraw MSG tokens after IDO. It is only allowed to call when sale is end.
    function withdrawTokens() external {
        uint256 amount = tokensByUser[_msgSender()];
        uint256 withdrawn = Formula.mulDiv(amount, Constant.WITHDRAWABLE_RATE, Formula.SCALE);

        require(block.timestamp >= lockedTimeWithdraw[_msgSender()], "IDO: It is not withdraw time yet!");
        require(amount > 0, "IDO: Nothing to withdraw now!");
        require(withdrawnAmount[_msgSender()] < amount, "IDO: Exceeded the amount allowed to withdraw!");

        // Transfering MSG to sender
        TransferHelper.safeTransfer(token, _msgSender(), withdrawn);

         // Storing remaining amount and time to withdraw
        withdrawnAmount[_msgSender()] += withdrawn;
        lockedTimeWithdraw[_msgSender()] += Constant.ONE_DAY;

        emit WithdrawBoughtTokens(_msgSender(), amount, block.timestamp);
    }

    /// @dev Used to buy tokens using USDT. It is only allowed to call when sale is running.
    function buyTokens(uint256 _amount, address _stableCoin) external nonReentrant hasSaleRunning {
        require(stableCoins[_stableCoin], "IDO: Invalid currency!");
        if(maxContribute > 0){
            require((boughtCashes[msg.sender] + _amount) <= maxContribute, "IDO: Total contribute is greater than max allowed contribute");
        }

        boughtCashes[_msgSender()] += _amount;

        // Calculate amount of token user has bought
        uint256 tokensToSale = _calculateTokenToSale(_amount);
        tokensByUser[_msgSender()] += tokensToSale;
        totalTokenSale += tokensToSale;
        lockedTimeWithdraw[_msgSender()] = withdrawStartTime;

        TransferHelper.safeTransferFrom(_stableCoin, _msgSender(), owner(), _amount);

        emit PrivateSaleTokens(_msgSender(), _stableCoin, _amount, tokensToSale, block.timestamp);
    }

    function _calculateTokenToSale(uint256 _amount) private returns (uint256) {
        // Fetch the current rate as per the phases.
        uint256 rate = getCurrentRate();

        // Calculate the amount of tokens to sale.
        uint256 tokensToSale = Formula.mulDiv(_amount, Formula.SCALE, rate);
        _checkSoldOut(tokensToSale);
        soldTokenAmount += tokensToSale;

        return tokensToSale;
    }


    /// @dev Finalize the sale. Only be called by the owner of the contract.
    function finalizeSale() external onlyOwner {
        // Should not already be finalized.
        require(!isSaleFinalized, "IDO: Already finalized");

        // Set finalized status to be true as it not repeatatedly called.
        isSaleFinalized = true;

        // Burn remain tokens
        uint256 remainTokens = Constant.SALE_MINT_TOKEN_AMOUNT - soldTokenAmount;
        TransferHelper.safeTransfer(token, Constant.DEAD_ADDRESS, remainTokens);

        // Emit event.
        emit SaleFinalized(remainTokens, block.timestamp);
    }

    /// @dev Public getter to fetch the current rate as per the running phase.
    function getCurrentRate() public view returns (uint256) {
        uint256 currentTime = block.timestamp;
        // Private sale
        if (currentTime >= privateSaleStartTime && currentTime <= privateSaleEndTime) {
            return Constant.PRIVATE_SALE_RATE;
        }

        // Return 0 when there is no phase running.
        return 0;
    }

    function _checkSoldOut(uint256 _tokenAmount) private view {
        uint256 expectedSoldAmount = soldTokenAmount + _tokenAmount;
        if (block.timestamp <= privateSaleEndTime) {
            require(expectedSoldAmount <= Constant.SALE_MINT_TOKEN_AMOUNT, "IDO: Private sale is sold out");
        }
    }

    function setTokenSale(address _tokenSale) external onlyOwner{
        require(_tokenSale != address(0), "IDO: Invalid token!");
        token = _tokenSale;
    }

    function getWithdrawableAmount(address _acc) external view returns (uint256) {
        return tokensByUser[_acc];
    }

    function setMaxContribute(uint256 _maxContribute) external onlyOwner{
        maxContribute = _maxContribute;
    }

}