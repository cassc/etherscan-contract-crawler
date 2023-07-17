// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);
    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);
    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);
    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract Market is Ownable {
    struct OfferDetails {
        uint256 _id;        // index of offer
        address _tokenA;    // base token address
        uint256 _amountA;   // base token amount
        address _tokenB;    // quote token address
        uint256 _amountB;   // quote token amount
        uint256 _endTime;   // offer live time
        address _creator;   // creator address 
        address _claimer;   // claimer address
        uint8   _active;    // active: 0, claimed: 1, cancelled: 2
        bool    _type;      // 0: buy, 1: sell
        bool    _public;    // 0: private, 1: public
    }

    mapping(uint256 => mapping(address => bool)) public claimWallets;

    // Uniswap router for token swap
    address private constant UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    // Dead address for burn of PEAR token
    address private burnAddress = 0x000000000000000000000000000000000000dEaD;

    // Pear token amount of burn for each offer creation
    uint256 public pearBurnAmount;

    // Pear token address (Goerli)
    address public pearTokenContract;
    
    // Flag for whitelist function
    bool public whiteListRequired = false;
    
    // Whitelisted token address 
    mapping(address => bool) public whiteListedToken;

    // Total count of created offers
    uint256 public totalOffers;

    // Created offer list
    mapping(uint256 => OfferDetails) public OfferId;

    // Fee values
    uint256 public txFee;
    uint256 public ptFee;

    // Reward pool size in ETH
    uint256 public rewardCollected;

    // Platform pool size in ETH
    uint256 public platformCollected;

    // Reward threshold
    uint256 public rewardThreshold;

    // Reward distribution
    bool public isRewardEnabled;
    
    // Reward list
    mapping(address => uint256) public rewardBalance;

    // Top holder count for reward distribution
    uint256 public topHolderForReward;

    event PearBurnAmountUpdated (uint256 _amount);
    event TotalFeeUpdated (uint256 _amount);
    event PlatformFeeUpdated (uint256 _amount);
    event RewardThresholdUpdated (uint256 _amount);
    event TopHolderForRewardUpdated (uint256 _amount);

    event OfferCreated (address _creator, uint256 _offerId);
    event OfferClaimed (address _claimer, uint256 _offerId);
    event OfferCancelled (address _creator, uint256 _offerId);
    event WithdrawCompleted (address _caller, address _receiver, uint256 _amount);
    event DistributionCompleted (address _caller, uint256 _count, uint256 _amount);

    constructor() {
        whiteListedToken[address(0x0)] = true;

        pearTokenContract = 0x5dCD6272C3cbb250823F0b7e6C618bce11B21f90; // ETH

        pearBurnAmount = 50 * 1000000000000000000;

        rewardThreshold = 1000; // $1000
        topHolderForReward = 50;

        txFee = 1; // 1%
        ptFee = 50; // 50% of collected fee

        isRewardEnabled = true;
    }

    fallback() external payable {}

    receive() external payable {}

    function whiteListToken(address _token) public onlyOwner {
        whiteListedToken[_token] = true;
    }

    function flipRewardEnabled() public onlyOwner {
        isRewardEnabled = !isRewardEnabled;
    }

    function flipWhiteList() public onlyOwner {
        whiteListRequired = !whiteListRequired;
    }

    function setPearBurnAmount(uint256 _value) public onlyOwner {
        require(_value > 0, "value is not valid");
        pearBurnAmount = _value;
        emit PearBurnAmountUpdated(_value);
    }

    function setTotalFee(uint256 _value) public onlyOwner {
        require(_value > 0 && _value < 100, "value is not valid");
        txFee = _value;
        emit TotalFeeUpdated(_value);
    }

    function setptFee(uint256 _value) public onlyOwner {
        require(_value > 0 && _value < 100, "value is not valid");
        ptFee = _value;
        emit PlatformFeeUpdated(_value);
    }

    function setRewardThreshold(uint256 _value) public onlyOwner {
        require(_value > 0, "value is not valid");
        rewardThreshold = _value;
        emit RewardThresholdUpdated(_value);
    }

    function setTopHolderForReward(uint256 _value) public onlyOwner {
        require(_value > 0, "value is not valid");
        topHolderForReward = _value;
        emit TopHolderForRewardUpdated(_value);
    }

    function makeOffer (
        address _tokenA,
        uint256 _amountA,
        address _tokenB,
        uint256 _amountB,
        uint256 _endTime,
        bool    _type,
        bool    _public,
        address[] memory _claim
    ) public payable {
        require(msg.sender == tx.origin, "Only EOA");

        if (whiteListRequired) {
            require(whiteListedToken[_tokenA] == true, "Token not allowed for sales yet");
        }

        if (_public == false) {
            if (_claim.length > 0) {
                for (uint i=0; i<_claim.length; i++) {
                    require(_claim[i] != address(0x0) && 
                        _claim[i] != 0x000000000000000000000000000000000000dEaD && 
                        _claim[i] != address(this), 
                        "Claim address is not valid");
                }
            }
        }

        // check pear token allowance and balance
        checkPearTokenBalance(msg.sender);

        // transfer pear token from caller to this contract
        IERC20(pearTokenContract).transferFrom(msg.sender, address(this), pearBurnAmount);

        if (_tokenA == address(0x0)) {
            require(msg.value == _amountA, "You must send ETH equal to amount");            
            require(isContract(_tokenB), "Quote token must be a contract");
        } else {
            require(isContract(_tokenA), "Your offered token must be a contract");
            checkBaseTokenBalance(msg.sender, _tokenA, _amountA);
            IERC20(_tokenA).transferFrom(msg.sender, address(this), _amountA);
        }

        OfferId[totalOffers]._id = totalOffers;
        OfferId[totalOffers]._tokenA = _tokenA;
        OfferId[totalOffers]._amountA = _amountA;
        OfferId[totalOffers]._tokenB = _tokenB;
        OfferId[totalOffers]._amountB = _amountB;
        OfferId[totalOffers]._endTime = _endTime;
        OfferId[totalOffers]._creator = msg.sender;
        OfferId[totalOffers]._claimer = address(0x0);
        OfferId[totalOffers]._active = 0;
        OfferId[totalOffers]._type = _type;
        OfferId[totalOffers]._public = _public;

        if (_public == false) {
            if (_claim.length > 0) {
                for (uint i=0; i<_claim.length; i++) {
                    claimWallets[totalOffers][_claim[i]] = true;
                }
                OfferId[totalOffers]._claimer = 0x000000000000000000000000000000000000dEaD;
            }
        }

        emit OfferCreated(
            msg.sender,
            totalOffers
        );

        totalOffers += 1;
    }

    function acceptOffer(uint256 _id) public payable {
        require(msg.sender == tx.origin, "Only EOA");

        require(OfferId[_id]._active == 0, "Offer already closed");
        require(block.timestamp <= OfferId[_id]._endTime, "The time is up.");
        
        if (OfferId[_id]._public == false) {
            if (OfferId[_id]._claimer == 0x000000000000000000000000000000000000dEaD) {
                require(claimWallets[_id][msg.sender] == true, "Permission denied");
            }
        }
        
        uint256 feeCollected = 0;
        uint256 curBalance;

        address tokenA = OfferId[_id]._tokenA;
        address tokenB = OfferId[_id]._tokenB;
        uint256 amountA = OfferId[_id]._amountA;
        uint256 amountB = OfferId[_id]._amountB;
        address creator = OfferId[_id]._creator;

        uint256 feeA = (amountA * txFee) / 100;
        uint256 rawAmountA = amountA - feeA;
        uint256 feeB = (amountB * txFee) / 100;
        uint256 rawAmountB = amountB - feeB;        

        if (tokenA == address(0x0)) {
            payable(msg.sender).transfer(rawAmountA);
            feeCollected += feeA;
        } else {
            IERC20(tokenA).transfer(msg.sender, rawAmountA);
            
            curBalance = address(this).balance;
            _swapTokensForEth(tokenA, feeA);
            feeCollected += (address(this).balance - curBalance);
        }

        if (tokenB == address(0x0)) {
            require(msg.value == amountB, "Not enough ETH to proceed this offer");
            payable(creator).transfer(rawAmountB);
            feeCollected += feeB;
        } else {
            checkBaseTokenBalance(msg.sender, tokenB, amountB);

            IERC20(tokenB).transferFrom(msg.sender, address(this), amountB);
            IERC20(tokenB).transfer(creator, rawAmountB);

            curBalance = address(this).balance;
            _swapTokensForEth(tokenB, feeB);
            feeCollected += (address(this).balance - curBalance);
        }

        uint256 ptFeeCollected = (feeCollected * ptFee) / 100;
        uint256 reFeeCollected = feeCollected - ptFeeCollected;

        platformCollected += ptFeeCollected;
        rewardCollected += reFeeCollected;

        // Burn PEAR token on this contract
        uint256 pearBalance = IERC20(pearTokenContract).balanceOf(address(this));        
        require(pearBalance >= pearBurnAmount, "Contract internal issue, don't have enough PEAR balance");
        IERC20(pearTokenContract).transfer(burnAddress, pearBurnAmount);

        OfferId[_id]._claimer = msg.sender;
        OfferId[_id]._active = 1;

        emit OfferClaimed(
            msg.sender,
            _id
        );
    }

    function cancelOffer(uint256 _id) public payable {
        require(msg.sender == tx.origin, "Only EOA");

        require(OfferId[_id]._active == 0, "Offer already closed");

        address tokenA = OfferId[_id]._tokenA;
        uint256 amountA = OfferId[_id]._amountA;
        address creator = OfferId[_id]._creator;

        require(msg.sender == creator, "You are not the owner of this offer");

        // return PEAR token from this contract
        uint256 pearBalance = IERC20(pearTokenContract).balanceOf(address(this));        
        require(pearBalance >= pearBurnAmount, "Contract internal issue, don't have enough PEAR balance");
        IERC20(pearTokenContract).transfer(creator, pearBurnAmount);

        OfferId[_id]._active = 2;
        emit OfferCancelled(creator, _id);

        if (tokenA == address(0x0)) {
            payable(creator).transfer(amountA);
        } else {
            IERC20(tokenA).transfer(creator, amountA);
        }
    }

    function checkPearTokenBalance(address _account) internal view {
        uint256 pearApproved = IERC20(pearTokenContract).allowance(_account, address(this));
        require(pearApproved >= pearBurnAmount, "Insufficient allowance, Approve PEAR first");

        uint256 pearBalance = IERC20(pearTokenContract).balanceOf(_account);        
        require(pearBalance >= pearBurnAmount, "You don't have enough PEAR balance");
    }

    function checkBaseTokenBalance(address _account, address _token, uint256 _amount) internal view {
        uint256 approved = IERC20(_token).allowance(_account, address(this));
        require(approved >= _amount, "Insufficient allowance, Approve token first");

        uint256 userBalance = IERC20(_token).balanceOf(_account);
        require(userBalance >= _amount, "You don't have enough balance");
    }

    function isContract(address _account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return _account.code.length > 0;
    }

    function getCounts() external view returns (uint256) {
        return totalOffers;
    }

    function getOfferDetail(
        uint256 _id
    ) external view returns (OfferDetails memory) {
        return OfferId[_id];
    }

    function getUserOffers(
        address _account
    ) external view returns (OfferDetails[] memory) {
        uint256 count = 0;
        uint256 i = 0;
        for (i = 0; i < totalOffers; i++) {
            if (OfferId[i]._creator == _account) {
                count++;
            }
        }

        OfferDetails[] memory result = new OfferDetails[](count);
        uint256 index = 0;
        for (i = 0; i < totalOffers; i++) {
            if (OfferId[i]._creator == _account) {
                result[index] = OfferId[i];
                index++;
            }
        }
        return result;
    }

    function isWhitelistedToken(address _token) external view returns (bool) {
        return whiteListedToken[_token];
    }

    function isOfferCompleted(uint256 _id) external view returns (bool) {
        return OfferId[_id]._active != 0;
    }

    function _swapTokensForEth(address _token, uint256 _amount) internal {
        require(_amount > 0, "Swap amount cannot be zero");

        address[] memory path = new address[](2);            
        path[0] = _token;
        path[1] = IUniswapV2Router02(UNISWAP_V2_ROUTER).WETH();

        IERC20(_token).approve(UNISWAP_V2_ROUTER, _amount);

        IUniswapV2Router02(UNISWAP_V2_ROUTER).swapExactTokensForETHSupportingFeeOnTransferTokens(
            _amount, 
            0,
            path, 
            address(this),
            block.timestamp
        );
    }

    /** Admin functions */
    function getPlatformFeeCollected() external view returns (uint256) {
        return platformCollected;
    }

    function withdrawAdmin(address _to, uint256 _amount) public onlyOwner {
        require(msg.sender == tx.origin, "Only EOA");

        require(platformCollected > 0, "no platform earning");

        require(_to != address(0x0) && _to != burnAddress && _to != address(this), 
            "withdraw address is not valid");

        require(_amount <= platformCollected, "amount is not valid");

        payable(_to).transfer(_amount);

        platformCollected -= _amount;

        emit WithdrawCompleted(msg.sender, _to, _amount);
    }

    /** Reward functions for users */
    function distributeReward(address[] memory _addresses, uint256[] memory _rate) public onlyOwner {
        require(msg.sender == tx.origin, "Only EOA");

        require(isRewardEnabled == true, "reward distribution is disabled");
        
        require(rewardCollected > 0, "reward pool is empty");

        require(_addresses.length == _rate.length && _addresses.length <= topHolderForReward, 
            "invalid parameter");

        uint256 totalRate = 0;
        for (uint i=0; i<_addresses.length; i++) {
            totalRate += _rate[i];
        }

        uint256 distributeValue = 0;
        uint256 totalAmount = 0;
        uint256 originRewardSize = rewardCollected;

        for (uint i=0; i<_addresses.length; i++) {
            distributeValue = (originRewardSize * _rate[i]) / totalRate;
            
            rewardBalance[_addresses[i]] += distributeValue;
            rewardCollected -= distributeValue;
            totalAmount += distributeValue;
        }

        emit DistributionCompleted(
            msg.sender,
            _addresses.length,
            totalAmount
        );
    }

    function getRewardDistributed() external view returns (uint256) {
        return rewardBalance[msg.sender];
    }

    function withdrawReward(address _to, uint256 _amount) public {
        require(msg.sender == tx.origin, "Only EOA");
        
        require(rewardBalance[msg.sender] > 0, "no reward");

        require(_to != address(0x0) && _to != burnAddress && _to != address(this), 
            "withdraw address is not valid");

        require(_amount <= rewardBalance[msg.sender], "amount is not valid");

        payable(_to).transfer(_amount);

        rewardBalance[msg.sender] -= _amount;

        emit WithdrawCompleted(msg.sender, _to, _amount);
    }
}