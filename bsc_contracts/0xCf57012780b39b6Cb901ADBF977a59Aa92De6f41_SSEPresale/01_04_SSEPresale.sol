// SPDX-License-Identifier: MIT

// SSE Presale Contract 

// Develoaped By www.soroosh.app 

pragma solidity ^0.8.16;

import "./DataFeeds.sol";
import "./Ownable.sol";

interface IBEP20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract SSEPresale is DataFeeds, Ownable {

    bool public isActive;

    // min and max amount
    uint public immutable minTokenAmount;
    uint public immutable maxTokenAmount;
    uint public constant TOKEN_PRICE =  0.01 * 10 ** 18;
    uint public totalTokenSale;
    uint public totalBNBValue;
    
    // list of allowed wallets - this lits gets updated from www.soroosh.app
    address[] public allowedWallets;
    address public admin;
    // list of wallets that have entered the presale
    mapping (address => uint) walletTokenAllocation;
    mapping (address => uint) walletBNBAllocation;

    event AdminIsChanged(address indexed previousAdmin, address indexed newAdmin);

    
    IBEP20 private immutable _token;
    
    constructor(IBEP20 token_, uint minAmount_, uint maxAmount_) {
        _transferOwnership(msg.sender);
        changeAdmin(msg.sender);
        _token = token_;
        minTokenAmount = minAmount_ * 10 ** 18;
        maxTokenAmount = maxAmount_ * 10 ** 18;
    }

    // =============== Activation and DeActivating Presale ============== \\

    function activate() public onlyOwner() {
        isActive = true;

    }

    function deActivate() public onlyOwner() {
        isActive = false;

    }

    // =============== Functinos for Allowed Wallets ============== \\

    /// @dev returns allowedlist.
    /// @return list of allowedlist.
    function getAllowedWallets() public view returns (address[] memory) {
        return allowedWallets;
    }

    /// @dev sets presale admin.
    /// @param newAdmin Address of the wallet.
    function changeAdmin(address newAdmin) public onlyOwner {
        require(newAdmin != address(0), "SSEPrsale : admin can't be zero address");
        address oldAdmin = admin;
        admin = newAdmin;
        emit AdminIsChanged(oldAdmin, newAdmin);
    }

    /// @dev Adds wallet address to allowedlist.
    /// @param wallet Address of owner to be replaced.
    function addWalletToPresale(address wallet) public  onlyAdmin {
        require(!isAllowed(wallet), "already in allowed list");
        allowedWallets.push(wallet);
    }

    /// @dev remove wallet from allowedwallets byindex.
    /// @param index index of the wallet to be removed.
    function removeAllowedWalletByIndex(uint index) public onlyAdmin {
        require(index < allowedWallets.length, "index out of bound");
        while (index<allowedWallets.length-1) {
            allowedWallets[index] = allowedWallets[index+1];
            index++;
        }
        allowedWallets.pop();
    }
    
    /// @dev finds the index of the address in allowedwallets
    /// @param address_ address of the wallet.
    function find(address address_) private view returns(uint) {
        uint i = 0;
        while (allowedWallets[i] != address_) {
            i++;
        }
        return i;
    }
    /// @dev removes the wallet from the allowedwallets by address
    /// @param address_ address of the wallet.
    function removeAllowedWalletByAddress(address address_) public onlyAdmin {
        uint index = find(address_);
        removeAllowedWalletByIndex(index);
    }


    // =============== Functions For PreSale ============== \\

    /// @dev checks if address is allowed to enter presale.
    /// @param address_ address of the wallet.
    function isAllowed(address address_) public view returns (bool) {
        if(allowedWallets.length == 0) {
            return false;
        }

        for (uint i = 0; i < allowedWallets.length; i++) {
            if (allowedWallets[i] == address_) {
                return true;
            }
        }

        return false;
    }
    
        // =============== Functions For Calculating Amount ============== \\

    /// @dev Gets bnb last price
    function getBNBLatestPrice() public view returns (uint) {
        return uint(_getLatestPrice() / 1e8);
    }

    /// @dev converts BNB TO USD.
    /// @param value amount of BNB.
    function calulateUsd(uint value) private view returns (uint) {
        uint bnbPrice = getBNBLatestPrice();
        return value * bnbPrice;
    }

    /// @dev converts BNB TO SSE Amount.
    /// @param value amount of BNB.
    function getTokenAmountFromBNB(uint value) private view returns (uint){
        uint _toUsdt = calulateUsd(value) * 10 ** 18;
        return _toUsdt / TOKEN_PRICE;
    }

    /// @dev converts SSE to BNB amount.
    /// @param amount amount of token.
    function getBNBAmountFromToken(uint amount) public view returns (uint) {
        uint _BNBPrice = getBNBLatestPrice();
        uint _toUSDT = amount * TOKEN_PRICE;
        return _toUSDT  / _BNBPrice;
    }
 
        // =============== Functions For Checking Boundaries ============== \\

    /// @dev checks if amount of BNB is in presale boundry.
    /// @param value amount of BNB.
    function checkBNBAmount(uint value) private view returns (bool) {
        uint _toUsdt = calulateUsd(value) * 10 ** 18;
        uint totalAmount = _toUsdt / TOKEN_PRICE;
        if (totalAmount >= minTokenAmount && totalAmount <= maxTokenAmount ) {
            return true;
        }
        return false;
    }

    /// @dev returns the amount of tokens which user has already bought.
    /// @param address_ address of the wallet.
    function getWalletTokenParticipation (address address_) public view returns (uint) {
        return walletTokenAllocation[address_];
    }

    /// @dev returns the amount of bnb which user has already entered with.
    /// @param address_ address of the wallet.
    function getWalletBNBParticipation (address address_) public view returns (uint) {
        return walletBNBAllocation[address_];
    }

    /// @dev checks if user can buy more token.
    /// @param amount amount token.
    function checkParticipationUpdate(uint amount) private view returns (bool) {
        uint entered = getWalletTokenParticipation(msg.sender);
        if (maxTokenAmount > entered) {
            uint left = maxTokenAmount - entered;
            return uint(left) >= amount;
        }
        return false;


    }


    /// @dev main function to enter presalse -- will check if already participated and will update the amount.

    function enterPresale() public payable {
        require(isActive, "SSEPresale : Presale is currently not active.");
        require(isAllowed(msg.sender), "SSEPresale : Access Denied, Your Wallet Should be in AllowedList");

        if (getWalletTokenParticipation(msg.sender) == 0) {
            require(checkBNBAmount(msg.value),"SSEPresale : Amount is not valid");
            uint amount = getTokenAmountFromBNB(msg.value);
            walletTokenAllocation[msg.sender] = amount;
            walletBNBAllocation[msg.sender] = msg.value;
            totalTokenSale += amount;
            totalBNBValue += msg.value;
            sendTokenToWallet(amount, msg.sender);
        

        } else {
            // we need to know how much left and will calculate the amount needed for the transaction !
            uint amount = getTokenAmountFromBNB(msg.value);
            require(checkParticipationUpdate(amount) ,"SSEPresale: Amount Provided is not acceptable.");
            walletTokenAllocation[msg.sender] += amount;
            walletBNBAllocation[msg.sender] += msg.value;
            totalTokenSale += amount;
            totalBNBValue += msg.value;
            sendTokenToWallet(amount, msg.sender);
            
        }
    }


    // =============== Transfering And Withdraw Methods ============== \\
    
    /// @dev withdraws token from contract.
    /// @param amount amount token.
    /// @param beneficiary_ destination address.
    function withdrawToken(uint256 amount, address beneficiary_) public onlyOwner {
        require(token().transfer(beneficiary_, amount));
    }

    /// @dev withdraws BNB from contract.
    /// @param to destination address.
    function withdrawBNB(address payable to) public payable onlyOwner {
        require(to != address(0), "SSEPrsale : destinatino is zero address");
        uint Balance = address(this).balance;
        require(Balance > 0 wei, "Error! No Balance to withdraw"); 
        to.transfer(Balance);
    }


    /// @dev sent token to wallet.
    /// @param amount amount of token.
    /// @param destinatino_ destination address.
    function sendTokenToWallet(uint amount, address destinatino_) private returns (bool) {
        require(token().transfer(destinatino_, amount), "SSEPresale : withdraw error.");
        return true;
    }
    
    function token() public view returns (IBEP20) {
        return _token;
    }
    
    // =============== Modifiers ============== \\

    modifier onlyAdmin() {
        require(msg.sender == admin || msg.sender == owner(), "caller is neither admin or owner");
        _;
    }
}