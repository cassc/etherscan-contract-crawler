/**
 *Submitted for verification at Etherscan.io on 2023-05-15
*/

// Sources flattened with hardhat v2.12.7 https://hardhat.org

// File contracts/interface/ILSDStorage.sol

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface ILSDStorage {
    // Depoly status
    function getDeployedStatus() external view returns (bool);

    // Guardian
    function getGuardian() external view returns (address);

    function setGuardian(address _newAddress) external;

    function confirmGuardian() external;

    // Getters
    function getAddress(bytes32 _key) external view returns (address);

    function getUint(bytes32 _key) external view returns (uint256);

    function getString(bytes32 _key) external view returns (string memory);

    function getBytes(bytes32 _key) external view returns (bytes memory);

    function getBool(bytes32 _key) external view returns (bool);

    function getInt(bytes32 _key) external view returns (int256);

    function getBytes32(bytes32 _key) external view returns (bytes32);

    // Setters
    function setAddress(bytes32 _key, address _value) external;

    function setUint(bytes32 _key, uint256 _value) external;

    function setString(bytes32 _key, string calldata _value) external;

    function setBytes(bytes32 _key, bytes calldata _value) external;

    function setBool(bytes32 _key, bool _value) external;

    function setInt(bytes32 _key, int256 _value) external;

    function setBytes32(bytes32 _key, bytes32 _value) external;

    // Deleters
    function deleteAddress(bytes32 _key) external;

    function deleteUint(bytes32 _key) external;

    function deleteString(bytes32 _key) external;

    function deleteBytes(bytes32 _key) external;

    function deleteBool(bytes32 _key) external;

    function deleteInt(bytes32 _key) external;

    function deleteBytes32(bytes32 _key) external;

    // Arithmetic
    function addUint(bytes32 _key, uint256 _amount) external;

    function subUint(bytes32 _key, uint256 _amount) external;
}


// File contracts/contract/LSDBase.sol

pragma solidity ^0.8.9;
/// @title Base settings / modifiers for each contract in LSD

abstract contract LSDBase {
    // Calculate using this as the base
    uint256 constant calcBase = 1 ether;

    // Version of the contract
    uint8 public version;

    // The main storage contact where primary persistant storage is maintained
    ILSDStorage lsdStorage;

    /*** Modifiers ***********************************************************/

    /**
     * @dev Throws if called by any sender that doesn't match a LSD network contract
     */
    modifier onlyLSDNetworkContract() {
        require(
            getBool(
                keccak256(abi.encodePacked("contract.exists", msg.sender))
            ),
            "Invalid contract"
        );
        _;
    }

    /**
     * @dev Throws if called by any sender that doesn't match one of the supplied contract
     */
    modifier onlyLSDContract(
        string memory _contractName,
        address _contractAddress
    ) {
        require(
            _contractAddress ==
                getAddress(
                    keccak256(
                        abi.encodePacked("contract.address", _contractName)
                    )
                ),
            "Invalid contract"
        );
        _;
    }

    /*** Methods **********************************************************************/

    /// @dev Set the main LSD storage address
    constructor(ILSDStorage _lsdStorageAddress) {
        // Update the contract address
        lsdStorage = ILSDStorage(_lsdStorageAddress);
    }

    /// @dev Get the address of a network contract by name
    function getContractAddress(string memory _contractName)
        internal
        view
        returns (address)
    {
        // Get the current contract address
        address contractAddress = getAddress(
            keccak256(abi.encodePacked("contract.address", _contractName))
        );
        // Check it
        require(contractAddress != address(0x0), "Contract not found");
        return contractAddress;
    }

    /// @dev Get the name of a network contract by address
    function getContractName(address _contractAddress)
        internal
        view
        returns (string memory)
    {
        // Get the contract name
        string memory contractName = getString(
            keccak256(abi.encodePacked("contract.name", _contractAddress))
        );
        // Check it
        require(bytes(contractName).length > 0, "Contract not found");
        // Return
        return contractName;
    }

    /// @dev Get revert error message from a .call method
    function getRevertMsg(bytes memory _returnData)
        internal
        pure
        returns (string memory)
    {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";
        assembly {
            // Slice the sighash
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }

    /*** LSD Storage Methods ********************************************************/

    // Note: Uused helpers have been removed to keep contract sizes down

    /// @dev Storage get methods
    function getAddress(bytes32 _key) internal view returns (address) {
        return lsdStorage.getAddress(_key);
    }

    function getUint(bytes32 _key) internal view returns (uint256) {
        return lsdStorage.getUint(_key);
    }

    function getString(bytes32 _key) internal view returns (string memory) {
        return lsdStorage.getString(_key);
    }

    function getBytes(bytes32 _key) internal view returns (bytes memory) {
        return lsdStorage.getBytes(_key);
    }

    function getBool(bytes32 _key) internal view returns (bool) {
        return lsdStorage.getBool(_key);
    }

    function getInt(bytes32 _key) internal view returns (int256) {
        return lsdStorage.getInt(_key);
    }

    function getBytes32(bytes32 _key) internal view returns (bytes32) {
        return lsdStorage.getBytes32(_key);
    }

    /// @dev Storage set methods
    function setAddress(bytes32 _key, address _value) internal {
        lsdStorage.setAddress(_key, _value);
    }

    function setUint(bytes32 _key, uint256 _value) internal {
        lsdStorage.setUint(_key, _value);
    }

    function setString(bytes32 _key, string memory _value) internal {
        lsdStorage.setString(_key, _value);
    }

    function setBytes(bytes32 _key, bytes memory _value) internal {
        lsdStorage.setBytes(_key, _value);
    }

    function setBool(bytes32 _key, bool _value) internal {
        lsdStorage.setBool(_key, _value);
    }

    function setInt(bytes32 _key, int256 _value) internal {
        lsdStorage.setInt(_key, _value);
    }

    function setBytes32(bytes32 _key, bytes32 _value) internal {
        lsdStorage.setBytes32(_key, _value);
    }

    /// @dev Storage delete methods
    function deleteAddress(bytes32 _key) internal {
        lsdStorage.deleteAddress(_key);
    }

    function deleteUint(bytes32 _key) internal {
        lsdStorage.deleteUint(_key);
    }

    function deleteString(bytes32 _key) internal {
        lsdStorage.deleteString(_key);
    }

    function deleteBytes(bytes32 _key) internal {
        lsdStorage.deleteBytes(_key);
    }

    function deleteBool(bytes32 _key) internal {
        lsdStorage.deleteBool(_key);
    }

    function deleteInt(bytes32 _key) internal {
        lsdStorage.deleteInt(_key);
    }

    function deleteBytes32(bytes32 _key) internal {
        lsdStorage.deleteBytes32(_key);
    }

    /// @dev Storage arithmetic methods
    function addUint(bytes32 _key, uint256 _amount) internal {
        lsdStorage.addUint(_key, _amount);
    }

    function subUint(bytes32 _key, uint256 _amount) internal {
        lsdStorage.subUint(_key, _amount);
    }
}


// File contracts/interface/deposit/ILSDLpTokenStaking.sol

pragma solidity ^0.8.9;

interface ILSDLpTokenStaking {
    function stakeLP(uint256 _amount) external;

    function addLiquidity(uint256 _lsdTokenAmount) external payable;

    function unstakeLP(uint256 _amount) external;

    function getTotalLPTokenBalance() external view returns (uint256);

    function getClaimAmount(address _address) external view returns (uint256);

    function claim() external;

    function getTotalRewards() external view returns (uint256);

    function getStakedLP(address _address) external view returns (uint256);

    function getEarnedByLP(address _address) external view returns (uint256);

    function getBonusApr() external view returns (uint256);

    function getBonusPeriod() external view returns (uint256);

    function getMainApr() external view returns (uint256);

    function getIsBonusPeriod() external view returns (uint256);

    function getStakers() external view returns (uint256);

    function setBonusApr(uint256 _bonusApr) external;

    function setBonusPeriod(uint256 _bonusPerios) external;

    function setMainApr(uint256 _mainApr) external;

    function setBonusCampaign() external;
}


// File contracts/interface/owner/ILSDOwner.sol

pragma solidity ^0.8.9;

interface ILSDOwner {
    function getApy() external view returns (uint256);

    function getStakeApr() external view returns (uint256);

    function getBonusApr() external view returns (uint256);

    function getBonusEnabled() external view returns (bool);

    function getBonusPeriod() external view returns (uint256);

    function getMultiplier() external view returns (uint256);

    function getLIDOApy() external view returns (uint256);

    function getRPApy() external view returns (uint256);

    function getSWISEApy() external view returns (uint256);

    function getProtocolFee() external view returns (uint256);

    function getMinimumDepositAmount() external view returns (uint256);

    function setApy(uint256 _apy) external;

    function setStakeApr(uint256 _stakeApr) external;

    function setBonusApr(uint256 _bonusApr) external;

    function setBonusPeriod(uint256 _bonusPeriod) external;

    function setBonusEnabled(bool _bonusEnabled) external;

    function setMultiplier(uint256 _multiplier) external;

    function setRPApy(uint256 _rpApy) external;

    function setLIDOApy(uint256 _lidoApy) external;

    function setSWISEApy(uint256 _swiseApy) external;

    function setProtocolFee(uint256 _protocalFee) external;

    function setMinimumDepositAmount(uint256 _minimumDepositAmount) external;

    function upgrade(
        string memory _type,
        string memory _name,
        string memory _contractAbi,
        address _contractAddress
    ) external;
}


// File contracts/interface/token/ILSDToken.sol

pragma solidity ^0.8.9;

interface ILSDToken {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}


// File @openzeppelin/contracts/token/ERC20/[email protected]

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}


// File contracts/interface/token/ILSDTokenVELSD.sol

pragma solidity ^0.8.9;
interface ILSDTokenVELSD is IERC20 {
    function mint(address _address, uint256 _amount) external;

    function burn(address _address, uint256 _amount) external;
}


// File contracts/interface/utils/uniswap/IUniswapV2Pair.sol

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
  event Approval(address indexed owner, address indexed spender, uint value);
  event Transfer(address indexed from, address indexed to, uint value);

  function name() external pure returns (string memory);
  function symbol() external pure returns (string memory);
  function decimals() external pure returns (uint8);
  function totalSupply() external view returns (uint);
  function balanceOf(address owner) external view returns (uint);
  function allowance(address owner, address spender) external view returns (uint);

  function approve(address spender, uint value) external returns (bool);
  function transfer(address to, uint value) external returns (bool);
  function transferFrom(address from, address to, uint value) external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);
  function PERMIT_TYPEHASH() external pure returns (bytes32);
  function nonces(address owner) external view returns (uint);

  function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

  event Mint(address indexed sender, uint amount0, uint amount1);
  event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
  event Swap(
      address indexed sender,
      uint amount0In,
      uint amount1In,
      uint amount0Out,
      uint amount1Out,
      address indexed to
  );
  event Sync(uint112 reserve0, uint112 reserve1);

  function MINIMUM_LIQUIDITY() external pure returns (uint);
  function factory() external view returns (address);
  function token0() external view returns (address);
  function token1() external view returns (address);
  function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
  function price0CumulativeLast() external view returns (uint);
  function price1CumulativeLast() external view returns (uint);
  function kLast() external view returns (uint);

  function mint(address to) external returns (uint liquidity);
  function burn(address to) external returns (uint amount0, uint amount1);
  function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
  function skim(address to) external;
  function sync() external;
}


// File contracts/interface/utils/uniswap/IUniswapV2Router01.sol

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}


// File contracts/interface/utils/uniswap/IUniswapV2Router02.sol

pragma solidity >=0.6.2;
interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


// File contracts/interface/vault/ILSDRewardsVault.sol

pragma solidity ^0.8.9;

interface ILSDRewardsVault {
    function claimByLsd(address _address, uint256 amount) external;

    function claimByLp(address _address, uint256 amount) external;
}


// File contracts/interface/vault/ILSDTokenVault.sol

pragma solidity ^0.8.9;

interface ILSDTokenVault {
    function unstakeLsd(address _address, uint256 amount) external;

    function unstakeLp(address _address, uint256 amount) external;
}


// File contracts/contract/deposit/LSDLpTokenStaking.sol

pragma solidity ^0.8.9;
contract LSDLpTokenStaking is LSDBase, ILSDLpTokenStaking {
    //events
    event AddLiquidity(
        address indexed userAddress,
        uint256 amount,
        uint256 addTime
    );

    event Staked(
        address indexed userAddress,
        uint256 amount,
        uint256 stakeTime
    );

    struct User {
        uint256 balance;
        uint256 claimAmount;
        uint256 lastTime;
        uint256 earnedAmount;
    }

    struct History {
        uint256 startTime;
        uint256 endTime;
        uint256 apr;
    }

    uint256 private totalRewards;
    uint256 private bonusPeriod = 15;
    uint256 private bonusApr = 50;
    uint256 private mainApr = 20;
    uint256 private stakers = 0;

    mapping(address => User) private users;
    mapping(uint256 => History) private histories;
    uint private historyCount;

    uint256 private ONE_DAY_IN_SECS = 24 * 60 * 60;
    uint constant MAX_UINT = 2 ** 256 - 1;
    address uniLPAddress = 0xB92FE026Bd8F5539079c06F4e44f88515E7304C9;
    address uniswapRouterAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    // Construct
    constructor(ILSDStorage _lsdStorageAddress) LSDBase(_lsdStorageAddress) {
        version = 1;
        historyCount = 1;
        histories[0] = History(block.timestamp, 0, 20);

        ILSDToken lsdToken = ILSDToken(getContractAddress("lsdToken"));
        lsdToken.approve(uniswapRouterAddress, MAX_UINT);
    }

    receive() external payable {}

    function stakeLP(uint256 _amount) public override {
        IUniswapV2Pair pair = IUniswapV2Pair(uniLPAddress);
        // check balance
        require(pair.balanceOf(msg.sender) >= _amount, "Invalid amount");
        // check allowance
        require(
            pair.allowance(msg.sender, address(this)) >= _amount,
            "Invalid allowance"
        );

        // transfer LSD Tokens
        pair.transferFrom(
            msg.sender,
            getContractAddress("lsdTokenVault"),
            _amount
        );

        // check if already staked user
        User storage user = users[msg.sender];
        if (user.lastTime == 0) {
            user.balance = _amount;
            user.claimAmount = 0;
            user.earnedAmount = 0;
            user.lastTime = block.timestamp;
            stakers++;
        } else {
            uint256 excessAmount = getClaimAmount(msg.sender);
            user.balance += _amount;
            user.claimAmount = excessAmount;
            user.lastTime = block.timestamp;
        }

        // submit event
        emit Staked(msg.sender, _amount, block.timestamp);
    }

    function addLiquidity(uint256 _lsdTokenAmount) public payable override {
        ILSDToken lsdToken = ILSDToken(getContractAddress("lsdToken"));
        // check the balance
        require(lsdToken.balanceOf(msg.sender) >= _lsdTokenAmount);

        // check allowance
        require(
            lsdToken.allowance(msg.sender, address(this)) >= _lsdTokenAmount,
            "Invalid allowance"
        );

        // transfer tokens to this contract.
        lsdToken.transferFrom(msg.sender, address(this), _lsdTokenAmount);

        // if (
        //     lsdToken.allowance(address(this), uniswapRouterAddress) <
        //     _lsdTokenAmount
        // ) {
        //     lsdToken.approve(uniswapRouterAddress, MAX_UINT);
        // }

        IUniswapV2Router02 uniswapRouter = IUniswapV2Router02(
            uniswapRouterAddress
        );

        (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        ) = uniswapRouter.addLiquidityETH{value: msg.value}(
                getContractAddress("lsdToken"),
                _lsdTokenAmount,
                0,
                0,
                getContractAddress("lsdTokenVault"),
                block.timestamp + 15
            );

        if (msg.value > amountETH) {
            payable(msg.sender).transfer(msg.value - amountETH);
        }

        if (_lsdTokenAmount > amountToken) {
            lsdToken.transfer(msg.sender, _lsdTokenAmount - amountToken);
        }

        // check if already staked user
        User storage user = users[msg.sender];
        if (user.lastTime == 0) {
            user.balance = liquidity;
            user.claimAmount = 0;
            user.earnedAmount = 0;
            user.lastTime = block.timestamp;
            stakers++;
        } else {
            uint256 excessAmount = getClaimAmount(msg.sender);
            user.balance += liquidity;
            user.claimAmount = excessAmount;
            user.lastTime = block.timestamp;
        }

        // submit event
        emit AddLiquidity(msg.sender, liquidity, block.timestamp);
    }

    // Remove LP
    function unstakeLP(uint256 _amount) public override {
        User storage user = users[msg.sender];
        require(user.balance >= _amount, "Invalid amount");

        uint256 excessAmount = getClaimAmount(msg.sender);
        user.balance -= _amount;
        user.claimAmount = excessAmount;
        user.lastTime = block.timestamp;

        if (user.balance == 0) stakers--;

        ILSDTokenVault lsdTokenVault = ILSDTokenVault(
            getContractAddress("lsdTokenVault")
        );
        lsdTokenVault.unstakeLp(msg.sender, _amount);
    }

    function getIsBonusPeriod() public view override returns (uint256) {
        History memory history = histories[historyCount - 1];
        if (block.timestamp < history.startTime) {
            History memory bonusHistory = histories[historyCount - 2];
            return bonusHistory.startTime;
        } else return 0;
    }

    // Get Claim Amount By LP Staking
    function getClaimAmount(
        address _address
    ) public view override returns (uint256) {
        User memory user = users[_address];

        if (block.timestamp >= user.lastTime + ONE_DAY_IN_SECS) {
            IUniswapV2Pair pair = IUniswapV2Pair(uniLPAddress);
            (
                uint112 _reserve0,
                uint112 _reserve1,
                uint32 _blockTimestampLast
            ) = pair.getReserves();
            uint256 totalSupply = pair.totalSupply();

            uint256 balance = (user.balance * _reserve0 * 2) / totalSupply;

            uint256 i;
            uint256 j = 0;
            uint256 sum = 0;
            if (getIsBonusPeriod() == 0) i = historyCount;
            else i = historyCount - 1;
            while (i >= 1) {
                if (user.lastTime < histories[i - 1].startTime) {
                    if (j == 0) {
                        sum +=
                            (block.timestamp - histories[i - 1].startTime) *
                            histories[i - 1].apr;
                    } else {
                        sum +=
                            (histories[i - 1].endTime -
                                histories[i - 1].startTime) *
                            histories[i - 1].apr;
                    }
                } else {
                    if (j == 0) {
                        sum +=
                            (block.timestamp - user.lastTime) *
                            histories[i - 1].apr;
                    } else {
                        sum +=
                            (histories[i - 1].endTime - user.lastTime) *
                            histories[i - 1].apr;
                    }
                }
                if (
                    ((user.lastTime > histories[i - 1].startTime) &&
                        (user.lastTime <= histories[i - 1].endTime)) ||
                    ((user.lastTime > histories[i - 1].startTime) &&
                        (histories[i - 1].endTime == 0))
                ) break;
                i--;
                j++;
            }
            return
                user.claimAmount +
                (balance * sum) /
                (365 * 100 * ONE_DAY_IN_SECS);
        } else {
            return user.claimAmount;
        }
    }

    function getTotalLPTokenBalance() public view override returns (uint256) {
        IUniswapV2Pair pair = IUniswapV2Pair(uniLPAddress);
        return pair.balanceOf(getContractAddress("lsdTokenVault"));
    }

    // Claim bonus by LP
    function claim() public override {
        uint256 excessAmount = getClaimAmount(msg.sender);
        require(excessAmount > 0, "Invalid call");

        ILSDRewardsVault lsdRewardsVault = ILSDRewardsVault(
            getContractAddress("lsdRewardsVault")
        );
        lsdRewardsVault.claimByLp(msg.sender, excessAmount);

        User storage user = users[msg.sender];
        user.lastTime = block.timestamp;
        user.claimAmount = 0;
        user.earnedAmount += excessAmount;
        totalRewards += excessAmount;
    }

    // Get total rewards by LP
    function getTotalRewards() public view override returns (uint256) {
        return totalRewards;
    }

    // Get Staked LP
    function getStakedLP(
        address _address
    ) public view override returns (uint256) {
        User memory user = users[_address];
        return user.balance;
    }

    function getEarnedByLP(
        address _address
    ) public view override returns (uint256) {
        User memory user = users[_address];
        return user.earnedAmount;
    }

    function getBonusPeriod() public view override returns (uint256) {
        return bonusPeriod;
    }

    function getBonusApr() public view override returns (uint256) {
        return bonusApr;
    }

    function getMainApr() public view override returns (uint256) {
        return mainApr;
    }

    function getStakers() public view override returns (uint256) {
        return stakers;
    }

    /**@dev 
        DAO contract functions
    */
    function setBonusPeriod(
        uint256 _days
    ) public override onlyLSDContract("lsdDaoContract", msg.sender) {
        bonusPeriod = _days;
    }

    // set bonus apr
    function setBonusApr(
        uint256 _bonusApr
    ) public override onlyLSDContract("lsdDaoContract", msg.sender) {
        if (getIsBonusPeriod() == 0) {
            bonusApr = _bonusApr;
        } else {
            bonusApr = _bonusApr;
            History storage history = histories[historyCount - 2];
            history.apr = bonusApr;
        }
    }

    // set main apr
    function setMainApr(
        uint256 _mainApr
    ) public override onlyLSDContract("lsdDaoContract", msg.sender) {
        if (getIsBonusPeriod() == 0) {
            mainApr = _mainApr;
            History storage history = histories[historyCount - 1];
            history.endTime = block.timestamp;
            histories[historyCount] = History(block.timestamp, 0, mainApr);
            historyCount++;
        } else {
            mainApr = _mainApr;
            History storage history = histories[historyCount - 1];
            history.apr = mainApr;
        }
    }

    // set bonus on
    function setBonusCampaign()
        public
        override
        onlyLSDContract("lsdDaoContract", msg.sender)
    {
        require(getIsBonusPeriod() == 0, "already setted.");
        History storage history = histories[historyCount - 1];
        // end of main apr
        history.endTime = block.timestamp;

        // begin of bonus apr
        histories[historyCount] = History(
            block.timestamp,
            block.timestamp + bonusPeriod * ONE_DAY_IN_SECS,
            bonusApr
        );
        historyCount++;
        // begin of next main apr
        histories[historyCount] = History(
            block.timestamp + bonusPeriod * ONE_DAY_IN_SECS,
            0,
            mainApr
        );
        historyCount++;
    }

}