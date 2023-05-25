// SPDX-License-Identifier: DOGE WORLD
pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../SafelyOwned.sol";
import "./IDogecoin.sol";

contract Dogecoin is ERC20("Dogecoin", "DOGE", 8), SafelyOwned, IDogecoin
{
    string public constant url = "https://doge.gay";

    mapping (uint256 => bool) public override instructionFulfilled;
    mapping (address => bool) public override minters;

    bytes32 private constant joinPartyTypeHash = keccak256("JoinParty(address to,uint256 amount,uint256 instructionId)");

    function setMinter(address _minter, bool _canMint) public ownerOnly()
    {
        minters[_minter] = _canMint;
        emit Minter(_minter, _canMint);
    }
    
    function joinParty(address _to, uint256 _amount, uint256 _instructionId, uint8 _v, bytes32 _r, bytes32 _s) public override
    {
        require (!instructionFulfilled[_instructionId], "Instruction already fulfilled");
        bytes32 hash = getSigningHash(keccak256(abi.encode(joinPartyTypeHash, _to, _amount, _instructionId)));
        address signer = ecrecover(hash, _v, _r, _s);
        require(minters[signer], "Not signed by a minter");

        mintCore(_to, _amount);
        
        instructionFulfilled[_instructionId] = true;
        emit DogeJoinedTheParty(_instructionId, _to, _amount);
    }

    function multiJoinParty(JoinPartyInstruction[] calldata _instructions) public override
    {
        uint256 len = _instructions.length;
        bool anySuccess = false;

        for (uint256 x=0; x<len; ++x) {
            uint256 instructionId = _instructions[x].instructionId;
            if (instructionFulfilled[instructionId]) { continue; }

            address to = _instructions[x].to;
            uint256 amount = _instructions[x].amount;
            bytes32 hash = getSigningHash(keccak256(abi.encode(joinPartyTypeHash, to, amount, instructionId)));
            address signer = ecrecover(hash, _instructions[x].v, _instructions[x].r, _instructions[x].s);
            if (!minters[signer]) { continue; }

            mintCore(to, amount);

            instructionFulfilled[instructionId] = true;
            anySuccess = true;
            emit DogeJoinedTheParty(instructionId, to, amount);
        }
        require (anySuccess, "No success");
    }

    function crossBridge(address _controller, uint256 _amount) public override
    {
        burnCore(msg.sender, _amount);
        emit DogeCrossingBridge(_controller, _amount);
    }

    function transfer(address _to, uint256 _amount) public override returns (bool)
    {
        if (_to == address(this)) {
            crossBridge(msg.sender, _amount);
            return true;
        }
        return super.transfer(_to, _amount);
    }

    function transferFrom(address _from, address _to, uint256 _amount) public override returns (bool)
    {
        require(_to != address(this), "Use crossBridge() or transfer() to transfer DOGE back to the bridge");
        return super.transferFrom(_from, _to, _amount);
    }
}