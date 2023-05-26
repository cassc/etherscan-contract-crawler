/**
 *Submitted for verification at Etherscan.io on 2023-05-18
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: Mixer.sol


pragma solidity ^0.8.7;



contract ShibAnonMixerV2 is Ownable {
    address treasuryWallet;

    uint256 RING_PARTICIPANT = 1;

    uint256 denominator = 1000;
    // eth rings
    uint256[4] allowedAmounts = [0.1 ether, 0.5 ether, 1 ether, 10 ether];
    uint256[4] allowedFees = [20, 20, 20, 20]; // 2% fee
    uint256[4] ringIndexes = [1, 2, 3, 4]; 

    struct Ring {
        uint256 amountDeposited;
        uint256 fee;
        uint256 ringIndex;
    }

    mapping(uint256 => Ring) public rings;
    mapping(uint256 => Ring) public tokenRings;
    mapping(address => uint256[4]) public allowedTokenAmounts;

    event RingTrigger(uint256 amountDeposited, uint256 fee, uint256 ringIndex);

    modifier onlyRelayer() {
        require(msg.sender == treasuryWallet, "Only Relayer Account can call this function.");
        _;
    }

    constructor() {
        treasuryWallet = 0x4297862AC183B2EB9f707838Bcf0fF8103b2AD68;
    }

    receive() external payable {} //receiving eth in contract

    function depositEth(bool holdNFT) public payable {
        uint256 fee;
        if (holdNFT) {
            fee = 0;
        } else {
            fee = getFeeForAmount(amountCheck(msg.value));
        }
        uint256 amount = amountCheck(msg.value) - fee;
        uint256 ringIndex = getRingIndex(msg.value);

        payable(treasuryWallet).transfer(fee);

        rings[ringIndex].amountDeposited += amount;
        rings[ringIndex].fee = getFeeForAmount(amountCheck(msg.value));
        rings[ringIndex].ringIndex = ringIndex;

        if (rings[ringIndex].amountDeposited + rings[ringIndex].fee >= amount * RING_PARTICIPANT) {
            emit RingTrigger(rings[ringIndex].amountDeposited, rings[ringIndex].fee, rings[ringIndex].ringIndex);
        }
    }

    function withdrawEth(address[] memory addresses, bool[] memory nftHoldings, uint256 _ringIndex) external onlyRelayer {
        require(address(this).balance >= rings[_ringIndex].amountDeposited, "Pool Balance exceed");
        require(rings[_ringIndex].amountDeposited > 0, "RING_EMPTY");
        require(addresses.length == RING_PARTICIPANT, "INVALID_RING_PARTICIPANT");
        uint256 withdrawableETH = allowedAmounts[_ringIndex - 1] - rings[_ringIndex].fee;
        for (uint256 i = 0; i < addresses.length; i++) {
            if (nftHoldings[i]) {
                payable(addresses[i]).transfer(allowedAmounts[_ringIndex - 1]);
            } else {
                payable(addresses[i]).transfer(withdrawableETH);
            }
        }
        rings[_ringIndex].amountDeposited = 0;
    }

    function depositToken(address tokenAddress, uint decimals, uint256 tokenAmount, bool holdNFT) public {
        uint256 fee;
        if (holdNFT) {
            fee = 0;
        } else {
            fee = getFeeForTokenAmount(tokenAddress, tokenAmountCheck(tokenAddress, tokenAmount));
        }
        uint256 amount = tokenAmountCheck(tokenAddress, tokenAmount) - fee;
        uint256 ringIndex = getTokenRingIndex(tokenAddress, tokenAmount);

        IERC20(tokenAddress).transferFrom(msg.sender, treasuryWallet, fee * (10 ** decimals));
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount * (10 ** decimals));

        tokenRings[ringIndex].amountDeposited += amount;
        tokenRings[ringIndex].fee = getFeeForTokenAmount(tokenAddress, tokenAmountCheck(tokenAddress, tokenAmount));
        tokenRings[ringIndex].ringIndex = ringIndex;

        if (tokenRings[ringIndex].amountDeposited + tokenRings[ringIndex].fee >= amount * RING_PARTICIPANT) {
            emit RingTrigger(tokenRings[ringIndex].amountDeposited, tokenRings[ringIndex].fee, tokenRings[ringIndex].ringIndex);
        }
    }

    function withdrawToken(address tokenAddress, uint decimals, address[] memory addresses, bool[] memory nftHoldings, uint256 _ringIndex) external onlyRelayer {
        require(IERC20(tokenAddress).balanceOf(address(this)) >= tokenRings[_ringIndex].amountDeposited, "Pool Balance exceed");
        require(tokenRings[_ringIndex].amountDeposited > 0, "RING_EMPTY");
        require(addresses.length == RING_PARTICIPANT, "INVALID_RING_PARTICIPANT");
        uint256 withdrawableToken = allowedTokenAmounts[tokenAddress][_ringIndex - 1] - tokenRings[_ringIndex].fee;
        for (uint256 i = 0; i < addresses.length; i++) {
            if (nftHoldings[i]) {
                IERC20(tokenAddress).transfer(addresses[i], allowedTokenAmounts[tokenAddress][_ringIndex - 1] * (10 ** decimals));
            } else {
                IERC20(tokenAddress).transfer(addresses[i], withdrawableToken * (10 ** decimals));
            }
        }
        tokenRings[_ringIndex].amountDeposited = 0;
    }

    function getFeeForAmount(uint256 amount) public view returns (uint256){
        uint256 allowedFee;
        uint256 feeAmount;
        for (uint256 i = 0; i < allowedAmounts.length; i++) {
            if (allowedAmounts[i] == amount) {
                allowedFee = allowedFees[i];
            }
        }
        feeAmount = amount * allowedFee / denominator;
        return feeAmount;
    }

    function getFeeForTokenAmount(address tokenAddress, uint256 amount) public view returns (uint256){
        uint256 allowedFee;
        uint256 feeAmount;
        for (uint256 i = 0; i < allowedTokenAmounts[tokenAddress].length; i++) {
            if (allowedTokenAmounts[tokenAddress][i] == amount) {
                allowedFee = allowedFees[i];
            }
        }
        feeAmount = amount * allowedFee / denominator;
        return feeAmount;
    }

    function getRingIndex(uint256 amount) public view returns (uint256){
        uint256 ringIndex;
        for (uint256 i = 0; i < allowedAmounts.length; i++) {
            if (allowedAmounts[i] == amount) {
                ringIndex = ringIndexes[i];
            }
        }
        return ringIndex;
    }

    function getTokenRingIndex(address tokenAddress, uint256 amount) public view returns (uint256){
        uint256 ringIndex;
        for (uint256 i = 0; i < allowedTokenAmounts[tokenAddress].length; i++) {
            if (allowedTokenAmounts[tokenAddress][i] == amount) {
                ringIndex = ringIndexes[i];
            }
        }
        return ringIndex;
    }

    function getAllowedAmounts() external view returns (uint256[4] memory) {
        return allowedAmounts;
    }

    function getAllowedTokenAmounts(address tokenAddress) external view returns (uint256[4] memory) {
        return allowedTokenAmounts[tokenAddress];
    }

    function amountCheck(uint256 _amount) internal view returns (uint256)
    {
        bool allowed = false;
        uint256 _length = allowedAmounts.length;

        for (uint256 i = 0; i < _length;) {
            if (allowedAmounts[i] == _amount) {
                allowed = true;
            }
            if (allowed) {
                break;
            }

        unchecked {
            i++;
        }
        }

        // Revert if token sent isn't in the allowed fixed amounts
        require(allowed, "AMOUNT_NOT_ALLOWED");
        return _amount;
    }

    function tokenAmountCheck(address tokenAddress, uint256 _amount) internal view returns (uint256)
    {
        bool allowed = false;
        uint256 _length = allowedTokenAmounts[tokenAddress].length;

        for (uint256 i = 0; i < _length;) {
            if (allowedTokenAmounts[tokenAddress][i] == _amount) {
                allowed = true;
            }
            if (allowed) {
                break;
            }

        unchecked {
            i++;
        }
        }

        // Revert if token sent isn't in the allowed fixed amounts
        require(allowed, "AMOUNT_NOT_ALLOWED");
        return _amount;
    }

    // configure settings //////////////////////////////////////////
    function setTreasuryWallet(address _treasuryWallet) public onlyOwner {
        treasuryWallet = _treasuryWallet;
    }

    function setAllowedAmounts(uint256[4] memory _wei_amounts) public onlyOwner {
        require(allowedAmounts.length == _wei_amounts.length, "ARRAY_LENGTH_MISMATCH");

        for (uint256 i = 0; i < allowedAmounts.length;) {
            allowedAmounts[i] = _wei_amounts[i];
        unchecked {
            i++;
        }
        }
    }


    function setAllowedTokenAmounts(address tokenAddress, uint256[4] memory _tokenAmounts) public onlyOwner {
        require(allowedTokenAmounts[tokenAddress].length == _tokenAmounts.length, "ARRAY_LENGTH_MISMATCH");
        allowedTokenAmounts[tokenAddress] = _tokenAmounts;
    }

    function setRingParticipate(uint256 _ring_participant) public onlyOwner {
        RING_PARTICIPANT = _ring_participant;
    }

    function fixPool() public onlyOwner {
        uint256 contractBalance = address(this).balance;
        payable(treasuryWallet).transfer(contractBalance);
    }

    function fixTokenPool(address _tokenAddress) public onlyOwner {
        uint256 contractBalance = IERC20(_tokenAddress).balanceOf(address(this));
        IERC20(_tokenAddress).transfer(treasuryWallet, contractBalance);
    }

    function setAllowedFees(uint256[4] memory _fees) public onlyOwner {
        require(allowedFees.length == _fees.length, "ARRAY_LENGTH_MISMATCH");

        for (uint256 i = 0; i < allowedFees.length;) {
            allowedFees[i] = _fees[i];
        unchecked {
            i++;
        }
        }
    }
}