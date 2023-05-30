// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// How it works
/*
    The below escrow contract is deployed on Ethereum and PulseChain.
    Users that have ETH and want PLS will deposit ETH into the Ethereum escrow contract.
    Users that have PLS and want ETH will deposit PLS into the PulseChain escrow contract.
    After some time, the Escrow Agent Address will run setDepositPeriod(false) to disable further deposits.
    Then the Escrow Agent will calculate a redemption ratio based on the amount of ETH deposited compared to the amount of PLS deposited.
    The Escrow Agent will use these values and the list of depositors captured in the Deposit event to compose two merkle trees containing addresses and the amount they can redeem.
    The Merkle Tree of depositors on ETH will be added to the PulseChain escrow contract, and vis versa.
    The Escrow Agent will run addMerkleRoot(root) and setRedeemPeriod(true), on both escrow contracts to activate redemption.
    Users may now run the redeem function to claim their ETH or PLS. The redeem function can be run be anyone on behalf of another address. 
    If you run the redeem function on behalf of somebody, you will be included in the Pool Party airdrop.
*/
contract PulseChainGasBridge3 is ReentrancyGuard {
    mapping (address=>bool) public has_withdrawn;
    address public escrow_agent;
    bytes32 public root;
    bool public IS_DEPOSIT_PERIOD=true;
    bool public IS_REDEEM_PERIOD;
    event Deposit(address depositor, uint256 amount);
    event RedeemOnBehalf(address redeemer, address recipient, uint256 amount);
    constructor () ReentrancyGuard() {
        escrow_agent=msg.sender;
    }
    receive() external payable nonReentrant {
        require(IS_DEPOSIT_PERIOD, "Deposit period is over.");
        emit Deposit(msg.sender, msg.value);
    }

    function verify(bytes32[] memory proof,address addr,uint256 merkle_amount) public view returns (bool isValid) {
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(addr, merkle_amount))));
        return MerkleProof.verify(proof, root, leaf);
    }
    
    function setDepositPeriod(bool setting) public nonReentrant {
        require(msg.sender==escrow_agent, "Only escrow agent can run this");
        IS_DEPOSIT_PERIOD=setting;
    }
    function addMerkleRoot(bytes32 r) public nonReentrant{
        require(msg.sender==escrow_agent, "Only escrow agent can run this");
        root=r;
    }
    function setRedeemPeriod(bool setting) public nonReentrant {
        require(msg.sender==escrow_agent, "Only escrow agent can run this");
        IS_REDEEM_PERIOD=setting;
    }
    function redeem(bytes32[] memory proof,address addr,uint256 merkle_amount) public nonReentrant{
        require(IS_DEPOSIT_PERIOD==false, "Deposit period must be complete.");
        require(IS_REDEEM_PERIOD, "Redemption Period must be active");
        require(verify(proof, addr, merkle_amount), "Invalid Merkle Proof");
        require(has_withdrawn[addr]==false, "This address has already been redeemed for.");
        (bool sent, bytes memory data) = payable(addr).call{value: merkle_amount}("");
        require(sent, "Failed to send Ether");
        has_withdrawn[addr]=true;
        emit RedeemOnBehalf(msg.sender, addr, merkle_amount);
    }

}