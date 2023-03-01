/**
 *Submitted for verification at BscScan.com on 2023-02-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}


interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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

contract CryptoCubes is Ownable { 
    
    IERC20 public USDT;
    
    modifier onlyServer() {
        require(msg.sender == serverAddress, "Ownable: caller is not the server");
        _;
    }

    uint public currentGame = 1;
    address public serverAddress;
    mapping(address => uint) public balancePlayer;
    mapping(address => bool) public lockWithdraw;
    
    struct Game { 
        bool playing;
        uint endTime;
        uint[3] result;
        uint[5] settings;
    }
    mapping(uint => Game) public games;
    
    event Bet(uint indexed _game, address _player, uint _color);
    event StartGame(uint indexed _game, uint _endTime);
    event Withdraw(address indexed _player, uint _amount);
    event Deposit(address indexed _player, uint _amount);
    event Win(uint indexed _game, address _player, uint _amount);
    event Lose(uint indexed _game, address _player, uint _amount);
    event Refund(uint indexed _game, address _player);
    event EndGame(uint indexed _game, uint[3] _result);
    event Settings(uint indexed _game, uint[4] _result);
    
    function currentTime() public view returns (uint) {
        return block.timestamp;
    }
    
    function getResult(uint _gameId) public view returns (uint[3] memory) {
        return games[_gameId].result;
    }
    
    function bet(uint _game, uint _color) public {
        require(games[_game].playing == true);
        require(block.timestamp < games[_game].endTime);
        
        if (lockWithdraw[msg.sender] != true) {
            lockWithdraw[msg.sender] = true;
        }
        
        emit Bet(_game, msg.sender, _color);
    }
    
    function withdraw(uint _amount) public {
        require(lockWithdraw[msg.sender] != true);
        require(balancePlayer[msg.sender] >= _amount);
        USDT.transfer(msg.sender, _amount);
        balancePlayer[msg.sender] -= _amount;
        
        emit Withdraw(msg.sender, _amount);
    }
    
    function deposit(uint _amount) public {
        USDT.transferFrom(msg.sender, address(this), _amount);
        balancePlayer[msg.sender] +=_amount;
        
        emit Deposit(msg.sender, _amount);
    }
    
    //Functions for server
    function startGame(uint _time, uint[4] memory _settings) public  onlyServer  {
        uint _previewGame = currentGame - 1;
        require(games[_previewGame].playing == false);
        
        games[currentGame].playing = true;
        uint _endTime = block.timestamp + _time;
        games[currentGame].endTime = _endTime;
        
        emit StartGame(currentGame, _endTime);
        emit Settings(currentGame, _settings);
    }
    
    function endGame(uint[3] memory _result) public onlyServer {
        games[currentGame].playing = false; 
        games[currentGame].result = _result;
        
        emit EndGame(currentGame, _result);
        
        currentGame++;
    }
    
    function setWinners(uint _game, address[] memory _addresses, uint[] memory _amount) public onlyServer {
        for (uint i = 0; i < _addresses.length; i++) {
            balancePlayer[_addresses[i]] += _amount[i];
            lockWithdraw[_addresses[i]] = false;
            
            emit Win(_game, _addresses[i], _amount[i]);
        }
    }
    
    function setLossers(uint _game, address[] memory _addresses, uint[] memory _amount) public onlyServer {
        for (uint i = 0; i < _addresses.length; i++) {
            balancePlayer[_addresses[i]] -= _amount[i];
            lockWithdraw[_addresses[i]] = false;
            
            emit Lose(_game, _addresses[i], _amount[i]);
        }
    } 
    
    function setRefund(uint _game, address[] memory _addresses) public onlyServer {
        for (uint i = 0; i < _addresses.length; i++) {
            lockWithdraw[_addresses[i]] = false;
            
            emit Refund(_game, _addresses[i]);
        }
    } 
    

    //Functions for admin
    function setBalancePlayer(address _playerAddress, uint _newBalance) public onlyOwner {
        balancePlayer[_playerAddress] = _newBalance;
    }
    
    function managerAddress(address _serverAddress) public onlyOwner {
        serverAddress = _serverAddress;
    }
    
    function setAddressContractUSDT(IERC20 _contractUSDT) public onlyOwner {
        USDT = _contractUSDT;
    }
    
    function withdrawProfitForAdmin(address _address, uint _amount) public onlyOwner {
        USDT.transfer(_address, _amount);
    }
}