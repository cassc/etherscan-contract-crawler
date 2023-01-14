// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Whitelist {
  
    enum whitelistingStatus{ NOTAPPROVED,APPROVED,APPLIED }

    mapping(address => whitelistingStatus) public whitelisted;

    function isWhitelisted(address _address) public view returns (bool){           
        if ( whitelisted[_address] == whitelistingStatus.APPROVED){
        return true;
        }
        else {
        return false;
        }
    }


    modifier onlyWhitelisted()
    {
        require(isWhitelisted(msg.sender), "Caller must be on the whitelist");
        _;
    }

    function applyForWhitelist() public 
    {
        whitelisted[msg.sender] = whitelistingStatus.APPLIED;
    }    
}

contract polarToken is ERC20,Ownable,Whitelist {
  //main 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
  //goerli 0x07865c6E87B9F70255377e024ace6630C1Eaa37F

    address public usdcAddress = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    uint256 public priceInUSDC;

    uint256 public supplyCap = 5000;
    uint256 public basisPointsMint = 0;


    constructor(string memory _name, string memory _symbol, uint256 _price) ERC20(_name, _symbol) {
        //  _mint(msg.sender, 5);
        priceInUSDC = _price;
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
      require(isWhitelisted(to), "Recipient must be on the whitelist");

      address sender = _msgSender();
      _transfer(sender, to, amount);
      return true;
    }

    function mint(uint256 _amount) public onlyWhitelisted {
      require(_amount + totalSupply() <= supplyCap, "Token supply may not exceed cap");  

      uint256 fee = (basisPointsMint * (_amount*priceInUSDC)) / 10000;

      require (IERC20(usdcAddress).balanceOf(msg.sender) >= (_amount*priceInUSDC + fee), "Insufficient balance of USDC");
      require(IERC20(usdcAddress).allowance(msg.sender, address(this)) >= (_amount*priceInUSDC + fee), "The smart contract requires your approval to transfer your USDC on your behalf");

      IERC20(usdcAddress).transferFrom(msg.sender,address(this),_amount*priceInUSDC + fee);
      _mint(msg.sender, _amount);
      increaseAllowance(address(this),_amount);
    }

    
    function burn(uint256 _amount) public {          
      require (balanceOf(msg.sender) >= _amount, "Insufficient balance");
      require (IERC20(usdcAddress).balanceOf(address(this)) >= _amount*priceInUSDC , "Insufficient USDC in smart contract");

      IERC20(usdcAddress).transfer(msg.sender,_amount*priceInUSDC);

      _burn(msg.sender, _amount);
    }


    
    function updateUSDCAddress(address _address) public onlyOwner {          
      usdcAddress = _address;
    }

      
    function updatePrice(uint256 _price) public onlyOwner {
      priceInUSDC = _price;
    }

    function updateSupplyCap(uint256 _newCap) public onlyOwner {
      require(_newCap >=  totalSupply(),"Supply cap cannot be less than the current total supply");
      supplyCap = _newCap;
    }

    function setMintFee(uint256 _newFee) external onlyOwner {
        basisPointsMint = _newFee;
    }

    function approveWhitelist(address _address) public onlyOwner {
        require(whitelisted[_address] != whitelistingStatus.APPROVED, "This address has already been whitelisted");
        whitelisted[_address] = whitelistingStatus.APPROVED;
    }

    function revokeWhitelist(address _address) public onlyOwner {

    require(whitelisted[_address] == whitelistingStatus.APPROVED, "This address is not whitelisted");

    whitelisted[_address] = whitelistingStatus.NOTAPPROVED;
        
    }

    function withdrawUSDC() public onlyOwner {
      IERC20(usdcAddress).transfer(msg.sender,IERC20(usdcAddress).balanceOf(address(this)));
    }

    function withdrawUSDC(uint256 _amount) public onlyOwner {
      IERC20(usdcAddress).transfer(msg.sender, _amount);
    }
}