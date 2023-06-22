/**
 *Submitted for verification at Etherscan.io on 2023-06-15
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7; 

// import "./interfaces/IZkSync.sol";
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


contract Ownable  {
    address payable public _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor ()  {
        _owner = payable(msg.sender);
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }


    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address payable newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


interface Token {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);

}


contract EthcashPresale is Ownable {
    using SafeMath for uint;

    address public tokenAddr;
    
    uint256 public tokenPriceETH = 13888880000000;  //1ETH= 72000 ETHCASH TOKEN 
    uint256 public tokenDecimal = 18;
    uint256 public maticDecimal = 18;
    uint256 public totalTransaction;
    uint256 public totalHardCap;
    uint256 public amountRaisedETH;
    

    

    event TokenTransfer(address beneficiary, uint amount);
    event amountTransfered(address indexed fromAddress,address contractAddress,address indexed toAddress, uint256 indexed amount);
    event TokenDeposited(address indexed beneficiary, uint amount);
    event BnbDeposited(address indexed beneficiary, uint amount);
    
    mapping(address => uint256) public balances;
    // mapping(address => bool) public whitelisted;
    mapping(address => uint256) public tokenExchanged;

    bool public whitelist = false;
    bool public claim = false;
 

    constructor(address _tokenAddr)  {
        tokenAddr = _tokenAddr;
    }

    

    /* This function will deposit Tokens in the smart contract (Token must be approved first) */    
    function depositTokens(uint256  _amount) public returns (bool) {
        require(_amount <= Token(tokenAddr).balanceOf(msg.sender),"Token Balance of user is less");
        require(Token(tokenAddr).transferFrom(msg.sender,address(this), _amount));
        emit TokenDeposited(msg.sender, _amount);
        return true;
    }

    /* This will deposit BNB to Contract */
    function depositCrypto() payable public returns (bool){
        uint256 amount = msg.value;
        address userAddress = msg.sender;
        emit BnbDeposited(userAddress, amount);
        return true;
    }
    
    /* This function will accept BNB directly sent to the address */
    receive() payable external {
        ExchangeBNBforToken(msg.sender, msg.value);
    }

    /* This Function will exchange BNB to Token */    
    function ExchangeBNBforToken(address _addr, uint256 _amount) private {
        uint256 amount = _amount;
        address userAdd = _addr;
        uint256 bnbAmount = 0;
         balances[msg.sender] = balances[msg.sender].add(msg.value);
    
        // require(balances[msg.sender] >= minContribution && balances[msg.sender] <= maxContribution,"Contribution should satisfy min max case");
        totalTransaction.add(1);
        totalHardCap.add(_amount);
        bnbAmount = ((amount.mul(10 ** uint256(tokenDecimal)).div(tokenPriceETH)).mul(10 ** uint256(tokenDecimal))).div(10 ** uint256(tokenDecimal));
        tokenExchanged[userAdd] += bnbAmount;
        
        emit BnbDeposited(msg.sender,msg.value);
    }


    /* This Function will exchange BNB to Token in Mannual Call */
    function buyToken() public payable {
            uint256 amount = msg.value;
            address userAdd = msg.sender;
            uint256 bnbAmount = 0;
            balances[msg.sender] = balances[msg.sender].add(msg.value);

            // require(balances[msg.sender] >= minContribution && balances[msg.sender] <= maxContribution,"Contribution should satisfy min max case");
            totalTransaction.add(1);
            totalHardCap.add(amount);
            amountRaisedETH = amountRaisedETH + (msg.value);
            bnbAmount = ((amount.mul(10 ** uint256(tokenDecimal)).div(tokenPriceETH)).mul(10 ** uint256(tokenDecimal))).div(10 ** uint256(tokenDecimal));
            
            Token(tokenAddr).transfer(userAdd, bnbAmount);
            emit TokenTransfer(userAdd, bnbAmount);
            
            emit BnbDeposited(msg.sender,msg.value);
        }


     

    
    /* ONLY OWNER FUNCTIONS */

    /* This Function will be used to turn on or off whitelisting process */
    function turnWhitelist() public onlyOwner returns (bool success)  {
        if (whitelist) {
            whitelist = false;
        } else {
            whitelist = true;
        }
        return true;
        
    }

    /* This Function will be used to turn on or off claim process */
    function claimIn() public onlyOwner returns (bool success)  {
        if (claim) {
            claim = false;
        } else {
            claim = true;
        }
        return true;
        
    }
    
    /* Update Token Price */
    function updateTokenPrice(uint256 newTokenValue) public onlyOwner {
        tokenPriceETH = newTokenValue;
    }

    /* Update Token Decimal */
    function updateTokenDecimal(uint256 newDecimal) public onlyOwner {
        tokenDecimal = newDecimal;
    }

    /* Update Token Address */
    function updateTokenAddress(address newTokenAddr) public onlyOwner {
        tokenAddr = newTokenAddr;
    }

    /* Withdraw Remaining token after sale */
      function withdrawTokens(address tokenAddress, address beneficiary) public onlyOwner {
        Token token = Token(tokenAddress);
        uint256 tokenBalancee = token.balanceOf(address(this));

        (bool success, bytes memory data) = address(token).call(abi.encodeWithSignature("transfer(address,uint256)", beneficiary, tokenBalancee));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "Token transfer failed");
    }



    /* Withdraw Crypto remaining in contract */
    function withdrawCrypto(address payable beneficiary) public onlyOwner {
        (bool success, ) = beneficiary.call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }


    /* ONLY OWNER FUNCTION ENDS HERE */


    /* VIEW FUNCTIONS */

    /* View Token Balance */
    function tokenBalance() public view returns (uint256){
        return Token(tokenAddr).balanceOf(address(this));
    }

    /* View BNB Balance */
    function bnbBalance() public view returns (uint256){
        return address(this).balance;
    }
}