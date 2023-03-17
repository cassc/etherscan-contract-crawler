// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
contract PoolPartyTickerNameClaim is ERC20, ReentrancyGuard{
    event Mint(address indexed minter, uint amount);
    event Claim(address indexed burner, string name);
    event ConvertPoints(address indexed user, uint amount);
    event Flush(address indexed flusher, uint amount);
    address public flusher = 0x54A08edD4DD34192a654EeE22a1E3293B0522574; // this is the address that the incoming ETH belongs to. Once you send ETH into the contract it no longer belongs to you. 
    bool public IS_ACTIVE; // Defines minting period
    uint256 public MINTING_RATE  = 48000; // 48000 units per ETH
    uint256 public CLAIM_RATE = 9600 ether; // burn 9600 units to claim a name.
    uint256 CLAIMER_AIRDROP_POINTS = 960 ether;
    mapping(string=>address) public NAME_OWNERS; // lookup who the owner of the ticker name is
    mapping (address=>uint256) public NAME_CLAIMER_AIRDROP_POINTS; // tally of how many loyalty points the participant gets
    address public activator; // address that may run the activation sequence.
    constructor() ERC20("Pool Party Ticker Name Claim", "NAMECLAIM") ReentrancyGuard(){
        activator=msg.sender;
        }
    receive() external payable nonReentrant {
        require(IS_ACTIVE, "Minting is not active.");
        mint(msg.value * MINTING_RATE); // mints 48,000 NAMECLAIM points per ETH ("ether" here is shorthand for 10**18, the number of decimals in NAMECLAIM)
        emit Mint(msg.sender, msg.value);
    }
    
    /// @notice This function is for claiming the name. You can only claim unclaimed names. It requires 9,600 NAMECLAIM tokens to be burnt to reserve a name.
    function claimName(string memory ticker_name) public nonReentrant{
        require(IS_ACTIVE, "Name Claiming Phase is Over");
        require(_checkName(ticker_name), "Ticker name must be all caps and less than 10 characters.");
        require(NAME_OWNERS[ticker_name] == address(0), "This name is already taken.");
        _burn(msg.sender, CLAIM_RATE); 
        NAME_OWNERS[ticker_name] = msg.sender;
        NAME_CLAIMER_AIRDROP_POINTS[msg.sender] += CLAIMER_AIRDROP_POINTS;
        emit Claim(msg.sender, ticker_name);
        emit ConvertPoints(msg.sender, CLAIMER_AIRDROP_POINTS);
    }
    
    function convertToAirdropPoints(uint256 amount) public nonReentrant {
        _burn(msg.sender, amount);
        NAME_CLAIMER_AIRDROP_POINTS[msg.sender]+=amount;
        emit ConvertPoints(msg.sender, amount);
    }
    function _checkName(string memory _name) public pure returns(bool){
        uint allowedChars = 0;
        bytes memory byteString = bytes(_name);
        require(byteString.length>0, "Must not be blank");
        require(byteString.length<=9, "Exceeds allowed length");
        bytes memory allowed = bytes("ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890");  //here you put what character are allowed to use
        for(uint i=0; i < byteString.length ; i++){
           for(uint j=0; j<allowed.length; j++){
              if(byteString[i]==allowed[j] )
              allowedChars++;         
           }
        }
        if(allowedChars<byteString.length)
        return false;
        return true;
    }

    ///@notice Allows flusher to take possession of the ETH in the contract. flusher-only function.
    function flush() public nonReentrant {
        require(msg.sender==flusher, "Only Flusher can run this function.");
        uint256 amount = address(this).balance;
        (bool sent, bytes memory data) = payable(flusher).call{value: amount}(""); // send ETH to the flusher 
        require(sent, "Failed to send Ether");
        emit Flush(msg.sender, amount);
    }
    ///@notice Allows flusher to take possession of erc20s accidentally sent. flusher-only function.
    ///@param token_contract_address address of the erc20 token set to flush. Be careful, flusher, make sure you know what these contract addersses are. 
    function flush_erc20(address token_contract_address) public nonReentrant {
        require(msg.sender==flusher, "Only Flusher can run this function.");
        IERC20 tc = IERC20(token_contract_address);
        tc.transfer(flusher, tc.balanceOf(address(this)));
    }
    ///@notice Function should be run by the flusher before Pool Party Mainnet Launch. De-activates minting.
    function donezo() public nonReentrant {
        require(IS_ACTIVE==true, "Already called.");
        require(msg.sender==flusher, "Only Flusher can run this function.");
        IS_ACTIVE=false;
    }
    bool HAS_RUN_ACTIVATION;
    ///@notice Function should be run by the activator once the unavailable names have been registered.
    function activate() public nonReentrant {
        require(IS_ACTIVE==false, "Already called.");
        require(HAS_RUN_ACTIVATION==false, "Can only call once.");
        require(msg.sender==activator, "Only Activator can run this function.");
        IS_ACTIVE=true;
        HAS_RUN_ACTIVATION=true;
        NAME_OWNERS["TEAM"]=address(1);
        NAME_OWNERS["MAXI"]=address(1);
        NAME_OWNERS["BASE"]=address(1);
        NAME_OWNERS["TRIO"]=address(1);
        NAME_OWNERS["LUCKY"]=address(1);
        NAME_OWNERS["DECI"]=address(1);
        NAME_OWNERS["POLY"]=address(1); 
        NAME_OWNERS["WATER"]=address(1);
        NAME_OWNERS["DCA"]=address(1);
        NAME_OWNERS["PARTY"]=address(1);
        NAME_OWNERS["HEX"]=address(1);
        NAME_OWNERS["PULSE"]=address(1);
        NAME_OWNERS["PULSEX"]=address(1);
        NAME_OWNERS["HDRN"]=address(1);
        NAME_OWNERS["ICSA"]=address(1);
        NAME_OWNERS["NAMECLAIM"]=address(1);
    }
    ///@notice Function should be run by the activator to mark certain names as unavailable to anyone.
    function unavailable(string memory name) public nonReentrant {
        require(IS_ACTIVE==false, "Already called.");
        require(HAS_RUN_ACTIVATION==false, "Can only call before activation.");
        require(msg.sender==activator, "Only Activator can run this function.");
        NAME_OWNERS[name]=address(1);
    }
    function mint(uint256 amount) private {_mint(msg.sender, amount);}
}