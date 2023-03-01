// SPDX-License-Identifier: MIT

// SSE Sponser Presale Contract 

// Developed By www.soroosh.app 

pragma solidity ^0.8.16;

import "./DataFeeds.sol";
import "./Ownable.sol";
import "./SSEPresaleTimeLock.sol";


contract SSESponserPresale is DataFeeds, Ownable {
    
    // presale status 
    bool public isActive;

    // min and max amount
    uint public immutable minTokenAmount;
    uint public immutable maxTokenAmount;
    
    // token price
    uint public constant TOKEN_PRICE =  1e16;
 
    // presale financial report 
    uint public totalTokenSold;
    uint public totalBNBValue;
    
    // list of allowed wallets - this lits gets updated by Soroosh Team.
    address[] public allowedWallets;

    // presale admin
    address public admin;

    // Sponser
    struct Sponser {
        uint tokenAmount;
        uint BNBAmount;
        SSEPreSaleTimeLock timeLockWallet;
    }

    mapping(address => Sponser) sponsers;

    address[] public sponsersList;

    //events 
    event AdminIsChanged(address indexed previousAdmin, address indexed newAdmin);

    // Contracts 
    IBEP20 private immutable _token;
    
    constructor(IBEP20 token_, uint minAmount_, uint maxAmount_) {
        _transferOwnership(msg.sender);
        changeAdmin(msg.sender);
        _token = token_;
        minTokenAmount = minAmount_ * 1e18;
        maxTokenAmount = maxAmount_ * 1e18;
    }

    // =============== Activation and DeActivating Presale ============== \\

    function activate() public onlyOwner() {
        isActive = true;

    }

    function deActivate() public onlyOwner() {
        isActive = false;

    }

    // =============== Functinos for Allowed Wallets ============== \\

    /// @dev sets presale admin.
    /// @param newAdmin Address of the wallet.

    function changeAdmin(address newAdmin) public onlyOwner {
        require(newAdmin != address(0), "SSESponserPrsale : admin can't be zero address");
        address oldAdmin = admin;
        admin = newAdmin;
        emit AdminIsChanged(oldAdmin, newAdmin);
    }

    /// @dev returns allowedlist.
    /// @return list of allowedlist.

    function getAllowedWallets() public view returns (address[] memory) {
        return allowedWallets;
    }

    /// @dev Adds wallet address to allowedlist.
    /// @param wallet Address of owner to be replaced.

    function addWalletToPresale(address wallet) public  onlyAdmin {
        require(!isAllowed(wallet), "SSESponserPrsale : wallet already in allowed list");
        allowedWallets.push(wallet);
    }

    /// @dev remove wallet from allowedwallets byindex.
    /// @param index index of the wallet to be removed.

    function removeAllowedWalletByIndex(uint index) public onlyAdmin {
        require(index < allowedWallets.length, "SSESponserPrsale : index out of bound");
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

    /// @dev returns the Sponser Object.
    /// @param address_ address of the Sponser.

    function getSponser(address address_) public view returns (Sponser memory) {
        return sponsers[address_];
    }
    

    /// @dev returns the Sponsers Wallet List.

    function getSponsersList() public view returns (address[] memory) {
        return sponsersList;
    }

        // =============== Functions For Calculating Amount ============== \\

    /// @dev Gets bnb latest price from @chainlink
    
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
        uint _toUsdt = calulateUsd(value) * 1e18;
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
    /// @param amount amount of Token.

    function checkTokenAmount(uint amount) private view returns (bool) {
        if (amount >= minTokenAmount && amount <= maxTokenAmount ) {
            return true;
        }
        return false;
    }

    /// @dev returns the amount of tokens which user has already bought.
    /// @param address_ address of the wallet.

    function getWalletTokenParticipation (address address_) public view returns (uint) {
        Sponser storage sponser = sponsers[address_];
        return sponser.tokenAmount;
    }

    /// @dev returns the amount of bnb which user has already entered with.
    /// @param address_ address of the wallet.

    function getWalletBNBParticipation (address address_) public view returns (uint) {
        Sponser storage sponser = sponsers[address_];
        return sponser.BNBAmount;
    }

    /// @dev will calculate the priodic release amount of tokens in PreSaleTimeLock Walelt
    /// @param amount_ amount of total tokens.
    
    function getPeriodicRelease (uint amount_ ) private pure returns (uint) {
        return amount_ / 12;
    } 


    /// @dev main function to enter presalse as sponser.

    function enterPresaleAsSponser() public payable {
        require(isActive, "SSESponserPresale : Presale is currently not active.");
        require(isAllowed(msg.sender), "SSESponserPresale : Access Denied, Your Wallet Should be in AllowedList");
        require(getWalletTokenParticipation(msg.sender) == 0, "SSESponserPresale : A Wallet can only participate in sponser presale only once!");

        uint amount = getTokenAmountFromBNB(msg.value);

        require(checkTokenAmount(amount), "SSESponserPresale : Amount should be in boundries");

        totalTokenSold += amount;
        totalBNBValue += msg.value;

        SSEPreSaleTimeLock _ssePreSaleTimeLock = new SSEPreSaleTimeLock(token(), getPeriodicRelease(amount), msg.sender);

        Sponser memory newSponser = Sponser({
        tokenAmount: amount,
        BNBAmount: msg.value,
        timeLockWallet: _ssePreSaleTimeLock
        });

        sponsers[msg.sender] = newSponser;
        sponsersList.push(msg.sender);

        sendTokenToWallet(amount, address(_ssePreSaleTimeLock));
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
    /// @param amount amount of token.

    function withdrawBNB(address payable to, uint amount) public payable onlyOwner {
        require(to != address(0), "SSEPrsale : destination is zero address");
        uint Balance = address(this).balance;
        require(Balance > 0 wei, "SSESponserPresale : Error! No Balance to withdraw");
        require(Balance >= amount, "SSESponserPresale : Balance insufficient"); 

        to.transfer(amount);
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