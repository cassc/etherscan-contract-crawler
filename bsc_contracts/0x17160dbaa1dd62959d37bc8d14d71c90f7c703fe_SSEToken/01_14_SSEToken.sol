// SPDX-License-Identifier: MIT

// Develoaped By www.soroosh.app 

pragma solidity ^0.8.0;

import "./VotingToken.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./SafeMath.sol";


contract SSEToken is VotingToken, Ownable, Pausable {
    using SafeMath for uint256;
    mapping(address => uint256) private frosted;

    address[] public whiteListWallets;
    
    event Frost(address indexed from, address indexed to, uint256 value);
    
    event Defrost(address indexed from, address indexed to, uint256 value);

    // =========== WhiteList Functions =========== \\

    /// @dev Adds new address to whitelist.

   function addWhiteListWallet(address newAddress) public onlyOwner {
        if(!isWhiteListWallet(newAddress)){
            whiteListWallets.push(newAddress);
        }
   }

    /// @dev removes whitelist wallet by index.
    /// @param index_ index of the wallet.

   function removeWhiteListWalletByIndex(uint index_) public onlyOwner {
        require(index_ < whiteListWallets.length, "index out of bound");
        while (index_ < whiteListWallets.length - 1) {
            whiteListWallets[index_] = whiteListWallets[index_ + 1];
            index_++;
        }
        whiteListWallets.pop();
    }

    /// @dev finds the index of the address in whiteList
    /// @param address_ address of the wallet.
    
    function findWhiteListIndex(address address_) private view returns (uint) {
        uint i = 0;
        while (whiteListWallets[i] != address_) {
            i++;
        }
        return i;
    }

    /// @dev removes whitelist wallet by address
    /// @param address_ address of the wallet.

    function removeWhiteListWalletByAddress(address address_) public onlyOwner {
        uint index = findWhiteListIndex(address_);
        removeWhiteListWalletByIndex(index);
    }

    /// @dev Returns list of whiteList.
    /// @return List of whiteList addresses.

    function getWhiteListWallets() public view returns (address[] memory) {
        return whiteListWallets;
    }
    
    /// @dev Checks if address is in whitelist.
    /// @param address_ address of the wallet.
    /// @return true if address is in white list.
    
    function isWhiteListWallet(address address_) public view returns (bool) {
    if(whiteListWallets.length == 0) {
        return false;
    }

    for (uint i = 0; i < whiteListWallets.length; i++) {
        if (whiteListWallets[i] == address_) {
            return true;
        }
    }
        return false;
    }

    // =========== End Of WhiteList Functions =========== \\

    /**
     * @dev Gets the frosted balance of a specified address.
     * @param _owner is the address to query the frosted balance of. 
     * @return uint256 representing the amount owned by the address which is frosted.
     */

    function frostedOf(address _owner) public view returns (uint256) {
        return frosted[_owner];
    }

    /**
     * @dev Gets the available balance of a specified address which is not frosted.
     * @param _owner is the address to query the available balance of. 
     * @return uint256 representing the amount owned by the address which is not frosted.
     */

    function availableBalance(address _owner) public view returns (uint256) {
        return _balances[_owner].sub(frosted[_owner]);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        super._beforeTokenTransfer(from, to, amount);
        require(!paused() || isWhiteListWallet(from) , "BEP20Pausable: token transfer while paused");
        require(_balances[from].sub(frosted[from]) >= amount, "SSE: not avaiable balance");
    }

    /**
     * @dev Sets the values for {name}, {symbol}, {totalsupply} and {deciamls}.
     *
     * {name}, {symbol} and {decimals} are immutable: they can only be set once during
     * construction. {totalsupply} may be changed by using mint and burn functions. 
     */
    constructor(uint256 totalSupply_) {
        _name = "SOROOSH SMART ECOSYSTEM";
        _symbol = "SSE";
        _decimals = 18;
        _transferOwnership(_msgSender());
        _mint(_msgSender(), totalSupply_);
    }

    function mint(address account, uint256 amount) public onlyOwner returns (bool) {
        _mint(account, amount);
        return true;
    }

    function burn(uint256 amount) public returns (bool) {
        _burn(_msgSender(), amount);
        return true;
    }
    
    function pause() public onlyOwner returns (bool) {
        _pause();
        return true;
    }
    
    function unpause() public onlyOwner returns (bool) {
        _unpause();
        return true;
    }

    /**
     * @dev transfer frosted tokens to a specified address
     * @param to is the address to which frosted tokens are transferred.
     * @param amount is the frosted amount which is transferred.
     */
    function frost(address to, uint256 amount) public onlyOwner returns (bool) {
        _frost(_msgSender(), to, amount);
        return true;
    }

    /**
     * @dev defrost frosted tokens of specified address
     * @param to is the address from which frosted tokens are defrosted.
     * @param amount is the frosted amount which is defrosted.
     */
    
    function defrost(address to, uint256 amount) public onlyOwner returns (bool) {
        _defrost(_msgSender(), to, amount);
        return true;
    }

    function _frost(address from, address to, uint256 amount) private {
        frosted[to] = frosted[to].add(amount);
        _transfer(from, to, amount);
        emit Frost(from ,to, amount);
    }

    function _defrost(address onBehalfOf, address to, uint256 amount) private {
        require(frosted[to] >= amount);
        frosted[to] = frosted[to].sub(amount);
        emit Defrost(onBehalfOf, to, amount);
    }

    function transferAnyBEP20(address _tokenAddress, address _to, uint256 _amount) public onlyOwner returns (bool) {
        IBEP20(_tokenAddress).transfer(_to, _amount);
        return true;
    }
}