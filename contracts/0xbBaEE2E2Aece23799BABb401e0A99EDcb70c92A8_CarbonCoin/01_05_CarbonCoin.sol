// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CarbonCoin is ERC20 {
    address private owner;
    address private admin;
    IERC20 public usdtToken;
    IERC20 public usdcToken;
    uint public certIndex;
    uint public exchangeRate;
    bool public allowUSDT;
    bool public allowUSDC;
    uint public supply;
    uint256 public totalSupply_;

    struct Cert{
        uint256 name;
        address recipient;
        uint datetime;
        uint quantity; 
        uint256 email;
    }

    Cert[] public cert;
    
    constructor() ERC20("Green Carbon Coin", "GCX") {
        usdtToken = IERC20(0x3B00Ef435fA4FcFF5C209a37d1f3dcff37c705aD);
        usdcToken = IERC20(0xeb8f08a975Ab53E34D8a0330E0D34de942C95926);
        allowUSDT = true;
        allowUSDC = true;
        exchangeRate = 1000000;
        certIndex = 0;
        owner = msg.sender;
        admin = msg.sender;
        supply = 1000000;
        totalSupply_ += 1000000;
    }

    function decimals() public view virtual override returns (uint8) {
        return 0;
    }
    
    function totalSupply() public view virtual override returns (uint256) {
        return totalSupply_;
    }
    
    function exchangeUSDT (uint amount) external {
        require(allowUSDT);
        require(amount <= usdtToken.balanceOf(msg.sender));
        require(1 <= amount / 1000000);
        uint token = amount * exchangeRate / 1000000 / 1000000;
        require(supply >= token);
        usdtToken.transferFrom(msg.sender, address(this), amount);
        usdtToken.transfer(owner, amount);
        _mint(msg.sender, token);
        supply -= token;
        totalSupply_ += 1000000;
    }

    function exchangeUSDC (uint amount) external {
        require(allowUSDC);
        require(amount <= usdcToken.balanceOf(msg.sender));
        require(1 <= amount / 1000000);
        uint token = amount * exchangeRate / 1000000 / 1000000;
        require(supply >= token);
        usdcToken.transferFrom(msg.sender, address(this), amount);
        usdcToken.transfer(owner, amount);
        _mint(msg.sender, token);
        supply -= token;
    }

    function redeem (uint256 name, uint quantity, uint256 email) external {
        require(balanceOf(msg.sender) >= quantity);
        _burn(msg.sender, quantity);
        Cert memory userCert = Cert(name, msg.sender, block.timestamp, quantity, email);
        cert.push(userCert);
        certIndex += 1;
    }

    function listCert (uint index) public view returns(uint256, address, uint, uint, uint256) {
        require(index < certIndex);
        return (cert[index].name, cert[index].recipient, cert[index].datetime ,cert[index].quantity, cert[index].email);
    }

    function updateExchangeRate (uint rate) external {
        require(msg.sender == admin);
        require(rate > 0);
        exchangeRate = rate;
    }

    function addSupply (uint amount) external {
        require(msg.sender == owner);
        require(amount > 0);
        supply += amount;
        totalSupply_ += amount;
    }
    
    function updateOwner (address newOwner) external {
        require(msg.sender == owner);
        owner = newOwner;
    }
    
    function updateAdmin (address newAdmin) external {
        admin = newAdmin;
    }
}