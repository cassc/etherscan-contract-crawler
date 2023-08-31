// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

// https://defigarage.dev/
/*
                                             /%(                                
                                      (%%%%%%&&&&&%%&*                          
                                 #%%%%%%%&&&&&&&%%%%%%%%%%                      
                            .%%%%%%%%&&&&&&&&&&%%%%%%%%%%%%%%/                  
                        .#%%%%%%%%&&&&&&&&&&%%%%%%%%%%%%%%%%%%%%%               
                     ,%%%%%%%%%&&&&&&&&&&%%%%%%%%%%%%%%%%%%%%%%%%%%%            
                   %%%%%%%%%&&&&&&&&&&&%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%/         
                .%%%%%%%%%&&&&&&&&&&&&&&%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%       
               #%%%%%%%%&&&&&&&&&&&&&&&&%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#     
              %%%%%%%%&&&&&&&&&&&&&&&&&&%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
            #%%%%%%%%&&&&&&&&&&&&&&&&&&%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
           %%%%%%%%%%%&&&&&&&&&&&&&&&%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%&%%#    
         (%%%%%%%%%%%&&&&&&&%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%&&&%#    
        %%%%%%%%%%&&&&&&&&&&&%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%&&&&%#    
      .%%%%%%%%&&&&&&&&&&&&&&&&&&%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%&&&&&%(    
     (%%%%%%&&&&&&&&&&&&&&&&&&&&&&%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%&&&&&&&%.    
    #%%%%%&&&&&&&&&&&&&&&&&&&&&&&&&%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%&&&&&&&&%     
   %%%%&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%%%%%%%%%%%%%%%%%%&&&&&&&&&&%     
  (%%%&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@%#########&%%%%%%%%%%%%%%&&&&&&&&&&&&%     
 *%%%&&@@@@@@@@@@@@@@#####(##(#######(//**(###(####&&%%%%%%%%&&&&&&&&&&&&&%     
 %%%%&@@@@@@@@###@@@@@@@@@@@@(,,##@*//*(%@@@@@@@@@###@&&&&%&&&&&&&&&&&&&%*    
.%%%%%@@@@@@@@######@@@@@@@@#,,,(@@@@@@@@@@@@@@@@@@@@####@@&&&&&&&&&&&&&&&&%    
 #%%%%&@@@@@@###(#@@@@&%####*,,,/##@@@@@@@@@%#(#(##((####@@@&&&&&&&&&&&&&&&&    
  %%%%%@@@@@@#...,##%##@(###,,,,(#####%&&@@@&#/**@#((###%@@&&&&&&&&&&&&&&&&&&   
   %%%%@@@@@@#(..........#(,,,,,*##( .####%&./**&(((###@@@&&&&&&&&&&&&&&&&&&,  
   .%%%%@@@@@(,,(#(#(##(((,,,,,,,,(((..        /(((####@@@&&&&&&&&&&&&&&&&&&%&  
     %%%%@@@@#/,,,,,,,*#*,,****,,,,,((((((###(((((####@@@@&&&@@&&&&&&&&&&&&&&&# 
      %%%%@@@@@(,,,,*#(******(##,,,,,,,,/((((((((((###@@@&&@@@&&&&&&&&&&&&&&%##/
       /%%%@@@@@(,,,,,######(,,,,,,,,/(((((((((((((##@@@&@@@@@&&&&&&&&&&&&&%####
         %%%@@@@@&/,,,,,*((((((((((((((((((((((((###@@@&@@@@@&&&&&&&&&&&&&###%% 
          %%%&@@@@@%,,,,,,,,,,,,,,,(((((((((((###@@@@&&@@@@@@&&&&&&&&&&&##&&    
           (%%&@@@@@@&,,,,,,,,,,,((((((((((#@@@@@@@&&@@@@@@@@@@@@@@@&%%&#       
             %%&&@@@@@@@/,,,,,*(((((((#@@@@@@@@@&&&&@@@@@@@@@@@@@&&&&           
              %%#&&&@@@@@@@@@&%&@@@@@@@@@@@@@&&&&@@@@@@@@@@@@@&&%               
                 %%&&&@@@@@@@@@@@@@@@@@@@@&&&&@@@@@@@@@@@@@@@@                  
                   %%&&&@@@@@@@@@@@@@&&&&@@@@@@@@@@@@@@@@&&&&&@&                
                   (%%%&&&&&@@&&&&&&@@@@@@@@@@@@&&&&&&&&&&&&&&&&#               
                   (%&&&@@@@@@@@@@@@@@@@@&&&&&&&&&&@&&&&&&&&&&&&#.              
                    %&&&%&&&&&@@&&&&&&&&&&&&&&&&&@@@@@&&&&&&&&&&#               
                    %&&&%&&&&@&&&&&&&&&&&&&&&&&@@@@@@@&&&&&&&&&&#.              
                    %&&&%&&&@&&&&&&&&&&&&&&&&&@@@@@@@@&&&&&&&&&&%#              
                    %&&&%&&&&&&&&&&&&&&&&&&&&&@@@@@@@@@&&&&&&&&&&#/             
                   .%&&&&&&&&&&&&&&&&&&&&&&&&&@@@@@@@@@@&&&&&&&&&&#             
                   %%@@&&&&&&&&&&&&&&&&&&&&&&@@@@@@@@@@@@&&&&&&&&&%#            
                  %%%@&&&&&&&&&&&&&&&&&&&&&@@@@@@@@&@@@@@@@@&&&&&&&##.          
                 &%%@&&&&&&&&&&&&&&&&&&&&@@@@@@@@@&@@@@@@@@@@@@@@&&&#.          
                &&&@&&&&&&&&&&&&&&&&&&&&@@@@@@@@@@&@@@@@@@@@@@@@@@&             
               /&&&&&&&&&&&&&&&&&&&&&&@@@@@@@@@@@@&@@@@@@@@@@@@#                
                @@&&&&&&&&&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@&&                    
                 %@@&&&&&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@                        
                  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                             
                  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                             
                  @#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@&/                             
                 /%%&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@&/                            
                 @%%&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@&(                           
                 &%&&&&&&&&&&@@     &@@@@@@@@@@@@@@&&(                          
                /#%&&&&&&&&&&         ,@@@@@@@@@@&&&&&(                         
                %#&&&&&&&&&&            /&&&&&&&&&&&&&&(                        
                #%&&&&&&&&&               &&&&&&&&&&&&&&#                       
               #%%&&&&&&&&                  &&&&&&&&&&&&&/                      
               ##%&&&&&&&                    &&&&&&&&&&&&&/                     
              %%#&&&&&&&&/                     &&&&&&&&&&&&%                    
              (%#&&&&&&&&&                      &&&&&&&&&&&&&.                  
               &%&&&&&&&&&#                      /&&&&&&&&&&&&&                 
                %&&&&&&&&&                        &&&&&&&&&&&&                  
                 &&&&&&&&                        @@@@@@@@&&&@#                  
                 &&&&&&&                          @@@@@@@&@%%/                  
                 &&&&&&&                            @@@@@@&%%.                  
                 #&&&&&                              %@@@@@%%.                  
                %&&&&&&                               &@@@@@&#                  
        /######&&&&&&&&&,                             @@@@&&@@@#                
     (####&&&&&&&&&&&&&&                              #@&&&&&&&&&               
     &&&&&&&&&&&&&&&&&&&                               &@&&&&&&&&&              
                                                         @@&&&&&&&/             
                                                            &@@@@                
*/

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract rugpool is ERC20, AccessControl {

    using SafeERC20 for ERC20;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");
    uint256 minted;             // amount minted
    uint256 public price;       // starting price
    address public devs;        // dev fee receiver
    address public ciab;        // cat in a box cdp address
    address public boxETH;      // cat in a box boxETH address
    uint256 public lastOpenTimeStamp; // last time someone opened a box
    uint256 public deployTimeStamp; // last time someone opened a box
    uint256 public totalTime; // max length of the auction
    uint256 public smalltime; // small time 1 use
    address public lido; // lido steth
    uint256 public index; // history pointer
    uint256 public ltvOnDeposits; // ltv ciab in 100 points
    mapping(uint256 => uint256) public lastRugSize;
    mapping(uint256 => address) public lastRugAddress;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _setupRole(ADMIN_ROLE, _msgSender());
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE); 
        price = 1 ether/10;
        ciab = address(0x6ffD098E92B606b2947b89A08911C00ca06890FA);
        boxETH = address(0x7690202e2C2297bcD03664e31116d1dFfE7e3B73);
        devs = address(0xb52f8b5E8684dbD2B2A4956305F3aBd936c51621);
        lastOpenTimeStamp = block.timestamp;
        lido = address(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);
        totalTime = 2 days; 
        smalltime = 24 hours;
        index = 10; 
        deployTimeStamp = block.timestamp;
        ltvOnDeposits = 80;
    }

    function mint(address recipient, uint256 amount) external payable {
        uint256 paymentSize = currentMintingPrice(amount);
        require(msg.value >= paymentSize,"payment not big enough");
        // return excess
        if(msg.value> paymentSize){
            uint256 excess = msg.value - paymentSize;
            payable(msg.sender).transfer(excess);
        }
        minted += amount;
        _mint(recipient, amount);
        _mint(devs, amount/20);
        // auto convert by submitting
        convert();
    }
    function setDevs(address _devs) external onlyRole(ADMIN_ROLE) {
        devs = _devs;
    }

    function burn(uint256 amount) external {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) external {
        require(allowance(account, _msgSender()) - amount >= 0, "burn amount exceeds allowance");
        uint256 newAllowance = allowance(account, _msgSender()) - amount;
        _approve(account, _msgSender(), newAllowance);
        _burn(account, amount);
    }

    function convert() public {
        uint256 amount = address(this).balance;
        // submit, convert eth to steth
        ILIDO(lido).submit{value: amount}(address(0x0));        
        // approve steth
        uint256 _size = ERC20(lido).balanceOf(address(this));
        ERC20(lido).approve(ciab,_size);
        // deposit into CIAB
        Iciab(ciab).deposit(_size);
        // get info
        uint256 _deposit = Iciab(ciab).deposited(address(this));
        uint256 _debt = Iciab(ciab).debt(address(this));
        uint256 _outstanding = Iciab(ciab).Owing(address(this));
        uint256 _desiredDebt = (_deposit + _outstanding)*ltvOnDeposits/100;
        uint256 _delta;
        if(_desiredDebt > _debt){
            // take some debt
            _delta = _desiredDebt - _debt;
            Iciab(ciab).mint(_delta);
        }
        
    }

    function openBox(uint256 _minimumOut) public {
        _burn(_msgSender(), 1 ether);
        // calculate starting size
        uint256 _size = currentOpenReturn();
        // set timestamp to current
        lastOpenTimeStamp = block.timestamp;
        // require minimumout
        require(_size >= _minimumOut,"minimumOut not met");
        // mint synth if reserve not enough
        
        if(ERC20(boxETH).balanceOf(address(this)) < _size){
            uint256 _needed = _size - ERC20(boxETH).balanceOf(address(this));
            Iciab(ciab).mint(_needed);
        }
        // send funds
        ERC20(boxETH).transfer(msg.sender, _size);

        lastRugSize[index] = _size;
        lastRugAddress[index] = msg.sender;
        index++;        
        emit _OpenedBox(msg.sender ,_size);
    }

    function currentMintingPrice(uint256 amount)
        public
        view
        returns (uint256 _price)
    {
        if(block.timestamp < deployTimeStamp + smalltime)  {return price*amount/1 ether;}
        
        // price modifier
        uint256 _priceMultiplier = (minted - (minted % 100 ))/100 ether;
        // calculate price        
        uint256 _mintingPrice = price + price*_priceMultiplier/100;

        // price modifier
        uint256 _priceMultiplier2 = (minted + amount - (minted + amount % 100 ))/100 ether ;
        // calculate price        
        uint256 _mintingPrice2 = price + price*_priceMultiplier2/100;

        uint256 _averagePrice = (_mintingPrice2 + _mintingPrice)/2;

        uint256 _totalCost = _averagePrice * amount / 1 ether;

        return _totalCost;
    }
    function history()
        public
        view
        returns (address[] memory _who, uint[] memory _size)
    {
        address[] memory who = new address[](10);
        uint[] memory size = new uint[](10); 
        for(uint i = 0; i < 10;i +=1){
                who[i] = lastRugAddress[index-1 - i];
                size[i] = lastRugSize[index-1 - i];
            }        
        return (who,size);
    }

    function totalForGrabs()
        public
        view
        returns (uint256 _total)
    {
        uint256 _deposit = Iciab(ciab).deposited(address(this));
        uint256 _debt = Iciab(ciab).debt(address(this));
        uint256 _outstanding = Iciab(ciab).Owing(address(this));   
        uint256 _buffered =  ERC20(boxETH).balanceOf(address(this)); 
        _total = _buffered + (_deposit*98/100 + _outstanding - _debt);
    }
    function currentOpenReturn()
        public
        view
        returns (uint256 _Return)
    {
        // get CIAB info
        uint256 _deposit = Iciab(ciab).deposited(address(this));
        uint256 _debt = Iciab(ciab).debt(address(this));
        uint256 _outstanding = Iciab(ciab).Owing(address(this));
        uint256 _buffered =  ERC20(boxETH).balanceOf(address(this));    
        uint256 _maxSize = _buffered + (_deposit*98/100 + _outstanding - _debt);  
        
        uint256 _adjustedTime = 30 hours;
        if(_buffered > 20 ether){
            _adjustedTime = 30 hours *20 /(_buffered/ 1 ether); 
        }
        if(_buffered > 600 ether){
            _adjustedTime = 60 minutes;
        }
        
        uint256 _delta = block.timestamp -  lastOpenTimeStamp;
        uint256 _costOfOne = price;

        if(_maxSize > _costOfOne){
            if(_delta > totalTime){_Return = _maxSize;}
            if(_delta <= totalTime){_Return = _costOfOne+(_maxSize-_costOfOne)*_delta/totalTime;}
            if(_delta <= _adjustedTime){_Return = _costOfOne*_delta/_adjustedTime;}
        }
        if(_maxSize <= _costOfOne){

            if(_delta > totalTime){_Return = _maxSize;}
            if(_delta <= totalTime){_Return = _maxSize*_delta/totalTime;}
        }
        
        return _Return;
    }

    function changeLTV(uint256 ratio) onlyRole(ADMIN_ROLE) public {
        ltvOnDeposits = ratio;
        // get CIAB info
        uint256 _deposit = Iciab(ciab).deposited(address(this));
        uint256 _debt = Iciab(ciab).debt(address(this));
        uint256 _outstanding = Iciab(ciab).Owing(address(this));
        uint256 _desiredDebt = (_deposit + _outstanding)*ratio/100;
        uint256 _delta;
        if(_desiredDebt < _debt){
            // repay some debt
            _delta = _debt - _desiredDebt;
            ERC20(boxETH).approve(ciab, _delta);
            Iciab(ciab).repay(_delta);
        }
        if(_desiredDebt > _debt){
            // take some debt
            _delta = _desiredDebt - _debt;
            Iciab(ciab).mint(_delta);
        }
    }
    event _OpenedBox(address indexed _participant,uint256 amountOut);
}
interface Iciab {
    function deposit(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function mint(uint256 amount) external;
    function repay(uint256 amount) external;
    function Owing(address _depositor) external view returns(uint256 _allocation);
    function deposited(address _depositor) external pure returns(uint256 _deposit);
    function debt(address _depositor) external pure returns(uint256 _debt);
}
interface ILIDO {
    function submit(address _referral) external payable;
}//