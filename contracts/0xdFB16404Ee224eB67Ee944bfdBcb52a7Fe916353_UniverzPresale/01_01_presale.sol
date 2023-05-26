/**
 *Submitted for verification at BscScan.com on 2023-04-01
*/

/**
 *Submitted for verification at Etherscan.io on 2023-03-31
 */

//SPDX-License-Identifier: MIT Licensed
pragma solidity ^0.8.6;

interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external;

    function transfer(address to, uint256 value) external;

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external;

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(
                oldAllowance >= value,
                "SafeERC20: decreased allowance below zero"
            );
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
        }
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _transferOwnership(msg.sender);
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract UniverzPresale is Ownable {
    IERC20 public Univerz = IERC20(0x1f1c8b8CaA6d207C68F1bbf26b8f38AC83fAb086);
    IERC20 public USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);

    AggregatorV3Interface public priceFeedEth;
    AggregatorV3Interface public priceFeedBNB;

    uint256[4] salePhasesPercentages;
    uint256[4] public salePhasePrices;
    uint256[4] public minPurchaseAmount;
    uint256 public currentSalePhase;
    uint256 public soldTokens;
    uint256 public saleCounter;

    uint256 public amountRaisedEth;
    uint256 public amountRaisedUSDT;
    uint256 public percentDivider = 100_00;

    bool public presaleStatus;

    event currentSalePhaseEvent(uint256 phaseNo);

    constructor() {
        salePhasesPercentages = [500, 500, 500, 500]; //5 percent each
        minPurchaseAmount = [5, 10, 15, 25]; //5 usdt, 10 usdt , 15 usdt , 25 usdt ;

        salePhasePrices = [5000, 10000, 15000, 25000]; // 0.005 , 0.010, 0.015 , 0.025
        priceFeedEth = AggregatorV3Interface(
            0x79fEbF6B9F76853EDBcBc913e6aAE8232cFB9De9
        );
        presaleStatus = true;
    }

    receive() external payable {}

    // to get real time price of Eth
    function getLatestPriceEth() public view returns (uint256) {
        (, int256 price, , , ) = priceFeedEth.latestRoundData();
        return uint256(price);
    }

    // to get real time price of Eth
    function getLatestPriceBnb() public view returns (uint256) {
        (, int256 price, , , ) = priceFeedBNB.latestRoundData();
        return uint256(price);
    }

    // to buy token during preSale time with Eth => for web3 use
    function buyTokenEth() public payable {
        require(
            presaleStatus,
            "The buying is currently paused. Can't buy at this moment"
        ); // For disabling sale feature for temporily!.
        require(
            soldTokens < (Univerz.totalSupply() * 2000) / percentDivider ||
                currentSalePhase < 4,
            "Sale  is Over!"
        ); // To check that is sale of token is sold out or not

        uint256 payAmountInUsd = ETHtoUsd(msg.value);

        require(
            (payAmountInUsd / 1e8) >= minPurchaseAmount[currentSalePhase],
            "You cannot buy minimum token than limit of phase"
        ); //Limit buy check . For example 5 usd and 1000 token is minimum token of that phase

        uint256 _amountOfTokens = EthToToken(msg.value);
        require(
            _amountOfTokens <=
                ((Univerz.totalSupply() *
                    salePhasesPercentages[currentSalePhase]) / percentDivider) -
                    saleCounter,
            " You cannot buy that amount in current phase.Because tokens are is sold out.Try to decrease the amount"
        );

        saleCounter += _amountOfTokens;
        soldTokens += _amountOfTokens;
        if (
            (
                (currentSalePhase == 3)
                    ? saleCounter >=
                        ((Univerz.totalSupply() *
                            salePhasesPercentages[currentSalePhase]) /
                            percentDivider) -
                            1
                    : saleCounter >=
                        (Univerz.totalSupply() *
                            salePhasesPercentages[currentSalePhase]) /
                            percentDivider
            ) && currentSalePhase < 4
        ) {
            currentSalePhase++;
            saleCounter = 0;
        }

        SafeERC20.safeTransferFrom(Univerz, owner(), msg.sender, _amountOfTokens);
    }

    function buyTokenUSDT(uint256 _payAmount) public {
        require(
            presaleStatus,
            "The buying is currently paused. Can't buy at this moment"
        ); // For disabling sale feature for temporily!.
        require(
            soldTokens < (Univerz.totalSupply() * 2000) / percentDivider ||
                currentSalePhase < 4,
            "Sale  is Over!"
        ); // To check that is sale of token is sold out or not

        require(
            _payAmount >=
                minPurchaseAmount[currentSalePhase] * (10**USDT.decimals()),
            "You cannot buy minimum token than limit of phase"
        ); //Limit buy check . For example 5 usd and 1000 token is minimum token of that phase

        uint256 _amountOfTokens = getTokenAmount(_payAmount);
        require(
            _amountOfTokens <=
                ((Univerz.totalSupply() *
                    salePhasesPercentages[currentSalePhase]) / percentDivider) -
                    saleCounter,
            " You cannot buy that amount in current phase.Because tokens are is sold out.Try to decrease the amount"
        );

        saleCounter += _amountOfTokens;
        soldTokens += _amountOfTokens;
        if (
            (
                (currentSalePhase == 3)
                    ? saleCounter >=
                        ((Univerz.totalSupply() *
                            salePhasesPercentages[currentSalePhase]) /
                            percentDivider) -
                            1
                    : saleCounter >=
                        (Univerz.totalSupply() *
                            salePhasesPercentages[currentSalePhase]) /
                            percentDivider
            ) && currentSalePhase < 4
        ) {
            currentSalePhase++;
            saleCounter = 0;
        }

        SafeERC20.safeTransferFrom(USDT, msg.sender, address(this), _payAmount);
        SafeERC20.safeTransferFrom(Univerz, owner(), msg.sender, _amountOfTokens);
    }

    function stopPresale(bool _off) external onlyOwner {
        presaleStatus = _off;
    }

    // to check number of token for given Eth

    function ETHtoUsd(uint256 _amount) public view returns (uint256) {
        return (_amount * (getLatestPriceEth())) / (1 ether);
    }

    function EthToToken(uint256 _amount) public view returns (uint256) {
        uint256 EthToUsd = (_amount * (getLatestPriceEth())) / (1 ether);
        return ((EthToUsd * 1e24) / salePhasePrices[currentSalePhase]) / 1e8;
    }

     function getTokenAmount(uint256 _amount) public view returns (uint256) {
        return (_amount * 1e18) / salePhasePrices[currentSalePhase];
    }

 

    // change tokens
    function changeToken(address _token) external onlyOwner {
        Univerz = IERC20(_token);
    }

    //change USDT
    function changeUSDT(address _USDT) external onlyOwner {
        USDT = IERC20(_USDT);
    }

    function contractBalanceEth() external view returns (uint256) {
        return address(this).balance;
    }

    function currentPresaleSoldPercentage()
        external
        view
        returns (uint256 _percentage)
    {
        _percentage =
            (saleCounter * percentDivider * 100) /
            ((Univerz.totalSupply() * salePhasesPercentages[currentSalePhase]) /
                percentDivider);
    }

    function contractBalanceUSDT() external view returns (uint256) {
        return USDT.balanceOf(address(this));
    }

 

    /** 
     To increase or decrease the price and change phase according to
     situation of market. like it acts as failsafe feature 
     **/

    function changeSalePhase(uint256 _phaseNo) external onlyOwner {
        require(_phaseNo >= 4, "Cannot be greater than four phases");
        currentSalePhase = _phaseNo;
        emit currentSalePhaseEvent(currentSalePhase);
    }

 
    function pauseOrUnpauseBuying(bool _pause) external onlyOwner {
        presaleStatus = _pause;
    }

    function setSalePhasesPercentages(
        uint256[4] memory _percentages,
        uint256 _percentDivider
    ) external onlyOwner {
        salePhasesPercentages = _percentages;
    }

    function setMinAmountofPurchase(uint256[4] memory _minPurchaseAmount)
        external
        onlyOwner
    {
        minPurchaseAmount = _minPurchaseAmount;
    }



    function changeExchangeToken(IERC20 _token) external onlyOwner {
        USDT = _token;
    }

    function changeSalePhasePrices(uint256[4] memory _prices)
        external
        onlyOwner
    {
        salePhasePrices = _prices;
    }

    function transferFundsEth(uint256 _value) external onlyOwner {
        payable(owner()).transfer(_value);
    }

   function changeAggreagtor (address _wallet) external onlyOwner{
     priceFeedEth = AggregatorV3Interface(
           _wallet
        );
   }


    // to draw out tokens
    function transferTokens(IERC20 token, uint256 _value) external onlyOwner {
        token.transfer(msg.sender, _value);
    }
}