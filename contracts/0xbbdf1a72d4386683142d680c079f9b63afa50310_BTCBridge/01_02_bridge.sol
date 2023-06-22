//                                                                          .                         
//                                                                       .JB#BPJ~.                    
//                                                                       ^[email protected]@@@@@&GY!:                
//                           .:~!?JJ?:                                     ~?5B&@@@@@&BY!:            
//                     .~7YPB#&@@@@@@#.                                        :~JP#@@@@@&GJ^         
//                  ^?P&@@@@@@@@@&#B5!                                             .^?5B&@@@@5:       
//               :[email protected]@@@@&#BPJ7~^:.                                                     :!5#@@&?      
//             ^Y&@@@#57~:.                                                                .?#@@P.    
//           ^5&@@#Y~.                                                                       [email protected]@5    
//         ^[email protected]@@#J.                                                            :75GB##BBGG5J!. ~PG.   
//       ^[email protected]@@#J.                                                           :?G#BP5JJYYYYY5PGG~       
//     [email protected]@@G7.                                                            !#P7?PB&[email protected]&&&&#GPJ:       
//    ^[email protected]@G~                ..:^^^^^:.                                     ..^[email protected]@#P:[email protected]@@@@@@@@B~      
//   ^&@G!           :~?YPGBB####&&&&&P                                    [email protected]@@#.  [email protected]@@@@@&[email protected]@~     
//   ^5?         :?PB#BGP5JJ7!~^:..:^~^                                   :[email protected]@@@B    [email protected]@@@@@&:#@&~    
//             7G&B55PGB#&&&@@&#BPJ~                                      [email protected]@@@@@7. :[email protected]@@@@@#:&@@&:   
//             ?Y7 [email protected]@@@@@@@@@@#J:                                  :@@&@@@@@#B&@@@@@@@[email protected]~&Y   
//           [email protected]      [email protected]@@@@@@@@@@@&?                                 [email protected]@[email protected]@@@@@@@@@@@@@7.B7 ..   
//         :J#@@@@@G?:.  [email protected]@@@@@@@@@@@@@P.                               ~!! [email protected]@@@@@@@@@@@@&:^!.      
//        J&@@@[email protected]@@@&#B#@@@@@@@@@@@@@@@@5                               [email protected]#. [email protected]@@@@@@@@@@@J B#       
//       [email protected]@@P!..#@@@@@@@@@@@@@@@@@@@@@@@&:                              [email protected]#. [email protected]@@@@@@@@@@B [email protected]       
//      [email protected]@P^^57 ^&@@@@@@@@@@@@@@@@@@@[email protected]@J                              [email protected]&:  !&@@@@@@@@&~ [email protected]:       
//      [email protected]  [email protected]  ~&@@@@@@@@@@@@@@@@@@:^@@B                               [email protected]?   ^[email protected]@@@@#Y: [email protected]?        
//     ^@B   [email protected]@~  ^#@@@@@@@@@@@@@@@@?  7??.                              ^#@7    ~JYJ~.  [email protected]         
//     !#~    [email protected]  :[email protected]@@@@@@@@@@@@&7  .PGY                                .Y&G?^.       J&?          
//            :#@P.   [email protected]@@@@@@@@@G^   [email protected]@5                                  :?G&&BY7~:7J:.           
//             :[email protected]#!    ^?5GBBGY7^    !&@B.                                     .!5B&@@@@PG#~         
//               ?#@G~             [email protected]@B:                                          .^~!!??7:         
//                [email protected]~.        [email protected]@@5.                                                             
//                   :?PB#PJ!^:~JP?^7J^                                                               
//                   [email protected]@@@@@&#GY^                                                                  
//                   .JBBGP5?7~:.                                                                     
//                                                                                                    
//                                                                                                    
//                                                                 .!.                                
//                                                       ^J7~^^:^!?J!                                 
//                                                        .^~!!!!~:                                   
//                                                                                                    
//                                                                                                    
//                                   ~ AAAAAAAAA IM BRIDGINGGGGG ~                                     
//                              Bitcoin Miladys ERC-20 => BRC-20E Bridge
//                                https://www.bitcoinmiladys.com/brc20e
//                                  Smart Contract by @shrimpyuk :^)
//

pragma solidity ^0.8.0;
 
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
 
contract BTCBridge {
    string private constant PREFIX = "bc1p";

    //Validate the BTC Address begins with bc1p to avoid people inputting the incorrect address. 
    function validateBTCAddress(string memory _btcAddress) internal pure returns (bool) {
        bytes memory addressBytes = bytes(_btcAddress);
        bytes memory prefixBytes = bytes(PREFIX);

        if (addressBytes.length < prefixBytes.length) {
            return false;
        }

        bool isValid;
        assembly {
            // Load prefixes byte pointers
            let addPtr := add(addressBytes, 0x20)
            let prePtr := add(prefixBytes, 0x20)
            let length := mload(prefixBytes)

            // Set initial validity to true
            isValid := 1

            for { let i := 0 } lt(i, length) { i := add(i, 1) } {
                let addByte := byte(0, mload(add(addPtr, i)))
                let preByte := byte(0, mload(add(prePtr, i)))
                if iszero(eq(addByte, preByte)) {
                    // If bytes are not equal, set isValid to 0 and break the loop
                    isValid := 0
                    break
                }
            }
        }

        return isValid;
    }


    /// @notice Burn ERC-20 Tokens to bridge them to Bitcoin as a BRC-20E
    /// @param _tokenAddress The Address of the Token's Contract to burn
    /// @param _amount Amount of tokens to Burn
    /// @param _btcAddress the Bitcoin Address to receive the tokens to. Ensure 
    function burnForBridge(address _tokenAddress, uint256 _amount, string memory _btcAddress) external {
        //Validate BTC Address
        require(validateBTCAddress(_btcAddress), "Invalid BTC Address");

        //Create ERC-20 Instance of Token
        IERC20 token = IERC20(_tokenAddress);
        //Validate wallet holds enough tokens and the token allowance is high enough
        require(token.balanceOf(msg.sender) >= _amount && token.allowance(msg.sender, address(this)) >= _amount, "Not enough tokens to burn or allowance too low");

        //Send tokens to 0x000000000000000000000000000000000000dEaD (Recognised Burn Wallet)
        bool success = token.transferFrom(msg.sender, 0x000000000000000000000000000000000000dEaD, _amount);
        require(success, "Token Burn Failed");

        //Emit Event for Bridge to process TX
        emit BurnForBridge(msg.sender, _tokenAddress, _amount, _btcAddress);
    }

    //Burn Event
    event BurnForBridge(address indexed user, address indexed token, uint256 amount, string btcAddress);
}