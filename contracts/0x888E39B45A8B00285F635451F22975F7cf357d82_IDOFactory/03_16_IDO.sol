pragma solidity ^0.8.0;
 
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IERC20Decimals.sol";
 
contract IDO is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private ids;

    struct Initialize {
        bool hasWhitelisting;
        uint256 tradeValue;
        uint256 startDate;
        uint256 endDate;
        uint256 individualMinimumAmount;
        uint256 individualMaximumAmount;
        uint256 minimumRaise;
        uint256 tokensForSale;
        bool isTokenSwapAtomic;
    }
 
    struct Purchase {
        address purchaser;
        uint256 amount;
        uint256 pamount;
        uint256 timestamp;
    }

    bool public unsoldTokensReedemed;
    Initialize public initialize;
    string public idoURI;
    IERC20 public erc20;
    uint8 public decimals;
    IERC20 public tokenPayment;
    bool public hastokenPayment;
    bool public isSaleFunded;
    bytes32 public merkleRootWhitelist;
    uint256 public tokensAllocated;
    address payable public FEE_ADDRESS;
    uint256 public feePercentage;
 
    mapping(uint256 => Purchase) public purchases;
    mapping(address => uint256) public redeemAmount;
    mapping(address => bool) public redeemStatus;
 
    event Fund(address indexed funder, uint256 indexed amount, uint256 indexed timestamp);
    event PurchaseEvent(address indexed purchaser, uint256 indexed purchaseId, uint256 indexed amount, uint256 timestamp);
    event Redeem(address indexed who, uint256 indexed amount, uint256 indexed timestamp);
    event Refund(address indexed who, uint256 indexed amount, uint256 indexed timestamp);
 
    constructor(Initialize memory _initialize, string memory  _uri, address _tokenPaymentAddress, bool _hasTokenPayment, address _tokenAddress, uint256 _feePercentage, address _FEE_ADDRESS) {
        uint256 timestamp = block.timestamp;
 
        require(timestamp < _initialize.startDate, "Start Date Date should be further than current date");
        require(timestamp < _initialize.endDate, "End Date should be further than current date");
        require(_initialize.startDate < _initialize.endDate, "End Date higher than Start Date");
        require(_initialize.tokensForSale > 0, "Tokens for Sale should be > 0");
        require(_initialize.tokensForSale > _initialize.individualMinimumAmount, "Tokens for Sale should be > Individual Minimum Amount");
        require(_initialize.individualMaximumAmount >= _initialize.individualMinimumAmount, "Individual Maximim AMount should be > Individual Minimum Amount");
        require(_initialize.minimumRaise <= _initialize.tokensForSale, "Minimum Raise should be < Tokens For Sale");
        require(_initialize.tradeValue > 0, "Trade value has to be > 0");
        require(_feePercentage > 0, "Fee Percentage has to be > 0");
        require(_feePercentage <= 10000, "Fee Percentage has to be < 10000");
 
        initialize = _initialize;
        tokenPayment = IERC20(_tokenPaymentAddress);
        hastokenPayment = _hasTokenPayment;
        FEE_ADDRESS = payable(_FEE_ADDRESS);
        idoURI = _uri;
 
        initialize.minimumRaise = !_initialize.isTokenSwapAtomic  ? _initialize.minimumRaise : 0;

        erc20 = IERC20(_tokenAddress);
        decimals = IERC20Decimals(_tokenAddress).decimals();
        feePercentage = _feePercentage;
        unsoldTokensReedemed = false;
        isSaleFunded = false;
        ids.increment();
    }
 
    modifier isNotAtomicSwap() {
        require(!initialize.isTokenSwapAtomic, "Has to be non Atomic swap");
        _;
    }
 
    modifier isSaleFinalized() {
        require(block.timestamp > initialize.endDate, "Has to be finalized");
        _;
    }
 
    function setMerkleRoot(bytes32 _merkleRootWhitelist) external onlyOwner {
        merkleRootWhitelist = _merkleRootWhitelist;
    }
 
    function setTokenURI(string memory _idoURI) public onlyOwner {
        idoURI = _idoURI;
    }

    function lastId() external view returns(uint256) {
        return ids.current();
    }
 
    function fund(uint256 _amount) external nonReentrant {
        uint256 timestamp = block.timestamp;
        require(timestamp < initialize.startDate, "Has to be pre-started");
 
        uint256 availableTokens = erc20.balanceOf(address(this)) + _amount;
        require(availableTokens <= initialize.tokensForSale, "Transfered tokens have to be equal or less than proposed");
 
        address who = _msgSender();
        SafeERC20.safeTransferFrom(erc20, who, address(this), _amount);
 
        if(availableTokens == initialize.tokensForSale){
            isSaleFunded = true;
        }
        emit Fund(who, _amount, timestamp);
    }
 
    function swap(uint256 _amount) external payable {
        require(!initialize.hasWhitelisting, "IDO has whitelisting");
        swapint(_msgSender(), _amount);
    }
 
    function swap(bytes32[] calldata _merkleProof, uint256 _amount) external payable {
        require(initialize.hasWhitelisting, "IDO not has whitelisting");
        address who = _msgSender();
        require(MerkleProof.verify(_merkleProof, merkleRootWhitelist, keccak256(abi.encodePacked(who))), "Address not whitelist");
        swapint(who, _amount);
    }

    function swapint(address _who, uint256 _amount) internal nonReentrant {
        require(isSaleFunded, "Has to be funded");
        uint256 timestamp = block.timestamp;
        require(timestamp >= initialize.startDate && timestamp <= initialize.endDate, "Has to be open");
        require(_amount > 0, "Amount must be more than zero");
        require(_amount <= (initialize.tokensForSale - tokensAllocated), "Amount is less than tokens available");
        uint256 costAmount = _amount * initialize.tradeValue / (10 ** decimals);
        require(hastokenPayment || (!hastokenPayment && msg.value >= costAmount), "User has to cover the cost of the swap in BNB, use the cost function to determine");
        require(_amount >= initialize.individualMinimumAmount, "Amount is smaller than minimum amount");
        require((redeemAmount[_who] + _amount) <= initialize.individualMaximumAmount, "Total amount is bigger than maximum amount");

        if (hastokenPayment) {
            SafeERC20.safeTransferFrom(tokenPayment, _who, address(this), costAmount);
        }
        if (initialize.isTokenSwapAtomic) {
            SafeERC20.safeTransfer(erc20, _who, _amount);
        }
        if (msg.value > costAmount) {
            Address.sendValue(payable(_who), msg.value - costAmount);
        }
        uint256 purchaseId = ids.current();
        purchases[purchaseId] = Purchase(_who, _amount, costAmount, timestamp);
        tokensAllocated += _amount;
        redeemAmount[_who] += _amount;
        ids.increment();
        emit PurchaseEvent(_who, purchaseId, _amount, timestamp);
    }
 
    function redeemTokens() external isNotAtomicSwap isSaleFinalized nonReentrant {
        require(tokensAllocated >= initialize.minimumRaise, "Minimum raise has not been achieved");
        address who = _msgSender();
        require(!redeemStatus[who], "Already redeemed");
        uint256 amount = redeemAmount[who];
        require(amount > 0, "Purchase cannot be zero");
        redeemStatus[who] = true;
        SafeERC20.safeTransfer(erc20, who, amount);
        emit Redeem(who, amount, block.timestamp);
    }
 
    function redeemGivenMinimumGoalNotAchieved() external isNotAtomicSwap isSaleFinalized nonReentrant {
        require(tokensAllocated < initialize.minimumRaise, "Minimum raise has to be reached");
        address who = _msgSender();
        require(!redeemStatus[who], "Already redeemed");
        uint256 amount = redeemAmount[who] * initialize.tradeValue / (10 ** decimals);
        require(amount > 0, "Purchase cannot be zero");
        redeemStatus[who] = true;
        if (hastokenPayment) {
            SafeERC20.safeTransfer(tokenPayment, who, amount);
        } else {
            Address.sendValue(payable(who), amount);
        }
        emit Refund(who, amount, block.timestamp);
    }
 
    function withdrawFunds() external onlyOwner isSaleFinalized {
        require(tokensAllocated >= initialize.minimumRaise, "Minimum raise has to be reached");
        address who = _msgSender();
        uint256 amount = hastokenPayment ? tokenPayment.balanceOf(address(this)) : address(this).balance;
        uint256 amountFee = amount * feePercentage / 10000;
        uint256 amountOwner = amount - amountFee;
        if (hastokenPayment) {
            SafeERC20.safeTransfer(tokenPayment, FEE_ADDRESS, amountFee);
            if (amountOwner > 0) {
                SafeERC20.safeTransfer(tokenPayment, who, amountOwner);
            }
        } else {
            Address.sendValue(FEE_ADDRESS, amountFee);
            if (amountOwner > 0) {
                Address.sendValue(payable(who), amountOwner);
            }
        }
    }  
 
    function withdrawUnsoldTokens() external onlyOwner isSaleFinalized {
        require(!unsoldTokensReedemed, "Token already taken");
        uint256 unsoldTokens = tokensAllocated >= initialize.minimumRaise ? initialize.tokensForSale - tokensAllocated : initialize.tokensForSale;
        require(unsoldTokens > 0, "Unsold token cannot be zero");
        unsoldTokensReedemed = true;
        SafeERC20.safeTransfer(erc20, _msgSender(), unsoldTokens);
    }   
 
    function removeOtherbep20Tokens(address _tokenAddress, address _to) external onlyOwner isSaleFinalized {
        require(_tokenAddress != address(erc20) && _tokenAddress != address(tokenPayment), "Token Address has to be diff than the bep20 subject to sale and payment");
        IERC20 bep20Token = IERC20(_tokenAddress);
        SafeERC20.safeTransfer(bep20Token, _to, bep20Token.balanceOf(address(this)));
    }
}