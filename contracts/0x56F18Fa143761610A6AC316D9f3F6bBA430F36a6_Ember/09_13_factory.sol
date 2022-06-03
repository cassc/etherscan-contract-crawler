//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import "./proxy.sol";
contract factory {
    event deployed(address addr,  uint256 _salt);

    //1:get bytecode contract to be deployed 
    function getbytecode(address stakingAddress, address proxyOwner) public pure returns(bytes memory) {
        
        bytes memory bytecode = type(Proxy).creationCode;
        return abi.encodePacked(bytecode, abi.encode(stakingAddress, proxyOwner)); //constructor argument of bytecode
        
    }

    //2:compute address of contract to be deployed
    function getAddress(bytes memory bytecode, uint256 _salt) public view returns(address){
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),//address of deployer: proxy will be deployed from factory
                _salt, // a random number
                keccak256(bytecode)
                )
        );

        //cast last 20 bytes of hash to address
        return address(uint160(uint256(hash)));
    }

    //3 deploy contract
    function deploy(bytes memory bytecode, uint256 _salt) public payable returns(address){
        address addr;
        //how to call create2
            //create2(v,p,n,s)
            //1:v-amount of ETH to send 
            //2:p-pointer to start of the code in memory
            //3:n-size of code
            //4:s-salt
        assembly{
            addr:= create2(
                0, // wei sent with current call
                add(bytecode,0x20), //actual code start after skipping the first 32 bytes
                mload(bytecode), //load the size of the code contained in the first 32 bytes
                _salt // a random number
            )
            //check contract is deployed: if not zero else revert the whole process
            if iszero(extcodesize(addr)) { 
                revert(0, 0) 
                }
        }
        emit deployed(addr, _salt);
        
        return addr;
           
    }
}