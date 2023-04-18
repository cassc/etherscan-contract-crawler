// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

/** 
    @title Presale this is the version for a single funding IDO, no launch
    @notice This is a Natspec commented contract by Self Development Team

    - - -    

    @notice Version v1.2.1 date: apr 12, 2023 - SELF presale#4 : BSC edition
    This version specifically handles for this sale;
        - describes rate --> number of wantToken per invesToken 
        - sets hardcap
        - sets starttime and endtime (duration)
        - sets tokens addresses
        - starts the sale
        - swaps the investTokens by particants to presale contract
        - forwards the investTokens to/ by owner by calling 'forwardInvesToken'
        - emits events on variable state changes
        - no claiming / distribution of tokens (removed from contract)
        - no vesting (removed from contract)

    - - -

    @notice comment on rate
        - rate include rateDecimals = 3
            this means --> quantity(wantToken) = quantity(invesToken).mul(rate).div(1e3)
            - example1:  rate : 100_000 , participant receives 100 wantToken for 1 investToken
            - example2:  rate : 10_000 , participant receives 10 wantToken for 1 investToken
            - example3:  rate : 1_000 , participant receives 1 wantToken for 1 investToken
            - example4:  rate : 100 , participant receives 0.1 wantToken for 1 investToken

    - - -

    @notice comment on supply
        supply of wantToken is calculated by 
        (hardCap * rate) / 1_000... or hardCap.mul(rate).div(1e3);

    - - -

    @dev control buttons for admin
        bool public swapOn = false;   // set by owner, turns off/on swap process
        // bool public claimOn = false;  //  (not used)
    
        required overwrite routines for this contract; 

*/

/** notes JaWsome
     
    1. uint is alias of uint.. use only 1 notation. Lets use uint for readability
    2. use NatSpec Comments for test version. remove comments with live deployments
    3. swapOn / claimOn deafults changed to false
    4. make deployment parameters explicit; 
    5. explicit calculate rate before deployment 
        --> price is 0.02  .. this means 1 iToken -> 50 wToken
        --> 50.mul(1e3) .. this means rate is 50_000  
    6. deployment settings: 

        for the sake of simplicity, input variable by call or lazy hardcoded
        input parameters in Presale.sol
         presaleStorage.sol common

        rate = 50_000; 50 wantToken for 1 investToken.  
        hardCap = 52_000; max 52 000 investToken

        startTime = 1681754400 //https://www.epochconverter.com start 17.04.23 18:00 
        endTime= 1682359200   //https://www.epochconverter.com start 24.04.23 18:00 1682359200 (86400*7)

        investToken = 0x55d398326f99059ff775485246999027b3197955 = (USDT-BEP20) decimals:18
        wantToken = 0xab11DFD9CDFC51053415a505C97937Df1881b3d1 = (SELF-BEP20) decimals:18

        bsc testnet:
        investToken = 0x7ef95a0FEE0Dd31b22626fA2e10Ee6A223F8a684 = (SELF-BEP20) decimals:18

        maxSwap = 5_000;
        swapOn = false;
     
    - - -
    
    7. Note on versioning  v1.2.3  Environment / Project / Detail
        1 = Environment (stage : harhat, truffle, etc. use 1 for now)
        2 = Project (ATPAD, SELF, SWAPPY)
        3 = Detailed version 3 is 3rd update of SELF presale.
     

    8. Not using TokenSupply

    9. Withdraw Claims, no mapping of participants, use transactions.


    @notice Version v1.2.2 date: apr 17, 2023 - SELF presale#4 : BSC edition

    1-require((_amount + swapTotal) < hardCap, "hardCap exceeded");
        Changed to 
        require((_amount + swapTotal) <= hardCap, "hardCap exceeded");

       - Initial check will never let contract reach the hardcap 

  

      Notes Rufi: 
      Use a dynamic routine to counter the decimal issue in future, I have hardcoded it for now.

     */

/** @dev Contract
/// @notice PresaleStorage to be inherited by Presale
 *  State variables
 *  Events
 *  Modifiers
 *  Basic setup to be configured by child contract
 */
contract PresaleSwapStorage {
    /// @dev constants
    string public constant nameStorage = "PresaleStorage V1.2.1";

    /// @dev variables
    uint public rate;
    uint public hardCap;
    uint public startTime;
    uint public endTime;
    uint public minSwap;
    uint public maxSwap;
    bool public swapOn;
    uint public tokenSupply;
    uint public swapTotal;

    /// @dev maps to support the process
    mapping(address => uint) public swaps;
    mapping(address => uint) public claims;

    /// @dev events
    event Swapped(address indexed owner, uint amount);
    event InvestTokensForwarded(uint amount);
    event timeUpdated(uint end);
    event SwapEnabledUpdated(bool flag);
    event hardCapFilled(address indexed _from);

    /// @dev modifiers
    modifier swapEnabled() {
        require(swapOn == true, "Presale: Swapping is disabled");
        _;
    }
    modifier onProgress() {
        require(
            block.timestamp < endTime && block.timestamp >= startTime,
            "Presale: Not in progress"
        );
        _;
    }
}