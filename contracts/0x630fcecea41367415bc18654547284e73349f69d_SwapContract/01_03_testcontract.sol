// SPDX-License-Identifier: MIT

// ==========================================================================================================================
//    ____     _   _    _  __  U _____ u U  ___ u  _____                  _       ____     ____              _   _     ____   
//   |  _"\ U |"|u| |  |"|/ /  \| ___"|/  \/"_ \/ |" ___|__        __ U  /"\  u U|  _"\ uU|  _"\ u  ___     | \ |"| U /"___|u 
//  /| | | | \| |\| |  | ' /    |  _|"    | | | |U| |_  u\"\      /"/  \/ _ \/  \| |_) |/\| |_) |/ |_"_|   <|  \| |>\| |  _ / 
//  U| |_| |\ | |_| |U/| . \\u  | |___.-,_| |_| |\|  _|/ /\ \ /\ / /\  / ___ \   |  __/   |  __/    | |    U| |\  |u | |_| |  
//   |____/ u<<\___/   |_|\_\   |_____|\_)-\___/  |_|   U  \ V  V /  U/_/   \_\  |_|      |_|     U/| |\u   |_| \_|   \____|  
//    |||_  (__) )(  ,-,>> \\,-.<<   >>     \\    )(\\,-.-,_\ /\ /_,-. \\    >>  ||>>_    ||>>_.-,_|___|_,-.||   \\,-._)(|_   
//   (__)_)     (__)  \.)   (_/(__) (__)   (__)  (__)(_/ \_)-'  '-(_/ (__)  (__)(__)__)  (__)__)\_)-' '-(_/ (_")  (_/(__)__)  
// ==========================================================================================================================

pragma solidity >=0.8.0;

// Imports

import "@openzeppelin/contracts/access/Ownable.sol";

contract SwapContract is Ownable {
    bool allowCalls = false;

    constructor() {}

    //======================================================================
    // Contract Activation Functions
    //======================================================================

    function disableCalls() public onlyOwner {
        allowCalls = false;
    }

    function enableCalls() public onlyOwner {
        allowCalls = true;
    }

    function getCallStatus() public view returns(bool) {
        return allowCalls;
    }

    //======================================================================
    // Test Call Function
    //======================================================================

    function testCall() external payable {
        require(allowCalls, "Contract Inactive");
        payable(msg.sender).transfer(msg.value);
    }

    //=======================================================================
    // Token Withdrawal Functions, in case anything ends up stuck in contract
    //=======================================================================

    function withdrawETH() external onlyOwner {
        require(address(this).balance > 0, "No ETH balance");
        payable(msg.sender).transfer(address(this).balance);
    }

    //=======================================================================
    // Functions to receive ETH
    //=======================================================================

    receive() external payable {}
    fallback() external payable {}

    
}