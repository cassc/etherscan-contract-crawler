/**
 *Submitted for verification at BscScan.com on 2023-05-13
*/

/**
 *Submitted for verification at BscScan.com on 2023-04-12
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

interface IERC20 {
    function transfer(address _to, uint256 _value) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
     function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    // don't need to define other functions, only using `transfer()` in this case
}

contract FTSWAP {

    // Old Token

       IERC20 ft_old = IERC20(address(0xBF8544b07Dc7dfAcD71232E2a8fDF2c23e592393));
       IERC20 btc_token = IERC20(address(0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c));
       IERC20 ft_token = IERC20(address(0x624ABE953139B26c934fdF4748ffEbed5287f2d1));
       IERC20 usdt = IERC20(address(0x55d398326f99059fF775485246999027B3197955));



     uint public bnbRatio = 120;
     uint public usdtRatio = 120;
     uint public btcRatio = 120;
     address public _owner;
    

    constructor()
    {
       _owner = msg.sender;
    }
     


        receive() external payable
        {
            
        uint calculatedAmount = msg.value * bnbRatio;
        uint256 amount = calculatedAmount - (calculatedAmount * 2/10000);
        ft_token.transfer(msg.sender, amount);
   
        }




     function BuyToken(uint amount,string memory paymentType) public
     {


         string memory btcVar = "BTC";
        

    
          require(amount > 0, "Amount must be greater than 0");


          if(keccak256(abi.encodePacked((paymentType))) == keccak256(abi.encodePacked((btcVar))))
          {
                require(btc_token.balanceOf(msg.sender) >= amount, "Insufficient balance");
                // Transfer tokens from sender to contract
                btc_token.transferFrom(msg.sender, address(this), amount);
                 uint sendToken = amount * btcRatio;
                uint calculatedSell = sendToken - (sendToken * 2/10000);
                // Send Ether to sender
                 ft_token.transfer(msg.sender,calculatedSell);

          }
          else 
          {
                 require(usdt.balanceOf(msg.sender) >= amount, "Insufficient balance");
                  // Transfer tokens from sender to contract
                 usdt.transferFrom(msg.sender, address(this), amount);

                 uint sendToken = amount * usdtRatio;
                 uint calculatedSell = sendToken - (sendToken * 2/10000);
                  // Send Ether to sender
                 ft_token.transfer(msg.sender,calculatedSell);
          }
         
        
         
     }  




     function SellToken(uint amount,string memory paymentType) public
     {


         string memory btcVar = "BTC";
          string memory usdtVar = "USDT";
        

    
          require(amount > 0, "Amount must be greater than 0");


          if(keccak256(abi.encodePacked((paymentType))) == keccak256(abi.encodePacked((btcVar))))
          {
               
         require(ft_token.balanceOf(msg.sender) >= amount, "Insufficient balance");
         // Transfer tokens from sender to contract
         ft_token.transferFrom(msg.sender, address(this), amount);

         uint sendToken = amount / btcRatio;
         uint calculatedSell = sendToken - (sendToken * 3/10000);
        // Send Ether to sender
          btc_token.transfer(msg.sender,calculatedSell);

          }
          else if(keccak256(abi.encodePacked((paymentType))) == keccak256(abi.encodePacked((usdtVar))))
          {
            require(ft_token.balanceOf(msg.sender) >= amount, "Insufficient balance");
         // Transfer tokens from sender to contract
         ft_token.transferFrom(msg.sender, address(this), amount);

         uint sendToken = amount / usdtRatio;
         uint calculatedSell = sendToken - (sendToken * 3/10000);
        // Send Ether to sender
          usdt.transfer(msg.sender,calculatedSell);    

          }
          else{

               require(ft_token.balanceOf(msg.sender) >= amount, "Insufficient balance");
        // Transfer tokens from sender to contract
        ft_token.transferFrom(msg.sender, address(this), amount);
        uint sendBNB = amount / bnbRatio;
        uint calculatedSell = sendBNB - (sendBNB * 3/10000);
        // Send Ether to sender
        payable(msg.sender).transfer(calculatedSell);

          }
         
        
         
     }  




     function convert(uint amount) public{

        require(amount > 0, "Amount must be greater than 0");
        require(ft_old.balanceOf(msg.sender) >= amount, "Insufficient balance");
        // Transfer tokens from sender to contract
         ft_old.transferFrom(msg.sender, address(this), amount);

        // Send Ether to sender
        ft_token.transfer(msg.sender,amount);

     }





      function checkBalance(address account,string memory coinType) view external returns (uint256) {
           string memory btcVar = "BTC";
          string memory usdtVar = "USDT";
           string memory ftVar = "FT";

            if(keccak256(abi.encodePacked((coinType))) == keccak256(abi.encodePacked((btcVar))))
          {
             return btc_token.balanceOf(account);
          }
          else  if(keccak256(abi.encodePacked((coinType))) == keccak256(abi.encodePacked((usdtVar))))
          {
              return usdt.balanceOf(account);
          }

           else  if(keccak256(abi.encodePacked((coinType))) == keccak256(abi.encodePacked((ftVar))))
          {
               return ft_token.balanceOf(account);
          }
          else{
              return ft_old.balanceOf(account);
          }

       
      }




      function sendBNBOwner() public payable  onlyOwner
      {
      require(msg.sender == _owner, "BEP20: only owner can call this function");
      uint balance = address(this).balance;
      payable(_owner).transfer(balance); 
      }

       function sendUSDTOwner() public payable  onlyOwner
      {
      require(msg.sender == _owner, "BEP20: only owner can call this function");
      uint balance = usdt.balanceOf(address(this));
      usdt.transfer(_owner,balance); 
      }


       function sendBTCOwner() public payable  onlyOwner
      {
      require(msg.sender == _owner, "BEP20: only owner can call this function");
      uint balance = btc_token.balanceOf(address(this));
      btc_token.transfer(_owner,balance); 
      }



       function sendOLDOwner() public payable  onlyOwner
      {
      require(msg.sender == _owner, "BEP20: only owner can call this function");
      uint balance = ft_old.balanceOf(address(this));
      ft_old.transfer(_owner,balance); 
      }


         function sendTokenOwner() public onlyOwner
         {
          require(msg.sender == _owner, "BEP20: only owner can call this function");
          uint tokenBalance = ft_token.balanceOf(address(this));
          ft_token.transfer(_owner, tokenBalance);
         }




        modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
        }

         

         function transferOwnership(address newOwner) public onlyOwner 
          {
             _owner = newOwner;
          }


             function changeCoinRatio(uint _btcRatio,uint _usdtRatio,uint _bnbRatio) public onlyOwner
            {
                bnbRatio = _bnbRatio;
                usdtRatio = _usdtRatio;
                btcRatio = _btcRatio;   
            }
          

}