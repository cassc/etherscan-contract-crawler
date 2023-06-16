// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

interface IERC1043 {
    function tokenMeta(uint256 id) external view returns (bytes memory);
}

contract GroupAssetManagement is Ownable {

    struct Proposal {
        bytes   meta;
        address sender;
        uint256 amount;
        address addr;
        address payable recipient;
        ProposalStatus status;
    }
    enum ProposalStatus { NORMAL, PASS}
    
    address public _sbt;
    address public _signOwner;
    mapping(address => uint256)  public _nonces;
    mapping(uint256 => Proposal) public _proposals;
    mapping(bytes => mapping(address => uint256)) private _groups;

    event Donation(address indexed donater, address indexed token_address, bytes meta, uint256 amount);
    event ProposalSubmitted(address indexed sender, uint256 pid);
    event ProposalExecuted(address indexed sender, uint256 pid);

    constructor(address ca, address owner) {
        _sbt = ca;
        _signOwner = owner;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function setSignOwner(address owner) external onlyOwner() {
        require(owner != address(0), "The address is invalid");
        _signOwner = owner;
    }

    function setSbtContract(address ca) external onlyOwner {
        require(ca != address(0), "The contract address is invalid");
        _sbt = ca;
    }

    function getBalance(bytes memory meta, address token_address) external view returns(uint256) {
        return _groups[meta][token_address];
    }

    function isPrefixOf(bytes memory a, bytes memory b) internal pure returns (bool) {
        if (a.length > b.length) {
            return false;
        }
        for (uint i = 0; i < a.length; i++) {
            if (a[i] != b[i]) {
                return false;
            }
        }
        return true;
    }

    function donate(bytes memory meta, uint256 amount, address token_addr) external callerIsUser {
        require(amount > 0, "The donation should be greater than 0");
        (bool res, bytes memory data) = token_addr.call(abi.encodeWithSelector(0x23b872dd, msg.sender, address(this), amount));
        require(res && (data.length == 0 || abi.decode(data, (bool))), "The payable call is not success");
        _groups[meta][token_addr] += amount;
        emit Donation(msg.sender, token_addr, meta, amount);
    }

    function donateMainToken(bytes memory meta, uint256 amount) external payable callerIsUser {
        require(amount > 0, "The donation should be greater than 0");
        require(msg.value == amount, "The ether value is incorrect");
        _groups[meta][address(0)] += amount;
        emit Donation(msg.sender, address(0), meta, amount);
    }

    function submitProposal(Proposal memory proposal, uint256 pid, uint256 tid, bytes memory signature) external callerIsUser {
        require(proposal.amount > 0, "The token amount should be greater than 0");
        require(_proposals[pid].sender == address(0) , "The proposal is exist");
        require(_groups[proposal.meta][proposal.addr] >= proposal.amount, "No sufficient balance");
        require(IERC721(_sbt).ownerOf(tid) == msg.sender, "You are not owner of this SBT");
        require(isPrefixOf(proposal.meta, IERC1043(_sbt).tokenMeta(tid)), "The SBT is invalid");
        bytes32 message = keccak256(abi.encodePacked(msg.sender, block.chainid, proposal.meta, proposal.amount,
            proposal.addr, proposal.recipient, pid, tid, _nonces[msg.sender]));
        require(ECDSA.recover(message, signature) == _signOwner, "The signature is invalid");
        // update status
        proposal.sender = msg.sender;
        proposal.status = ProposalStatus.NORMAL;
        _proposals[pid] = proposal;
        _nonces[msg.sender] += 1;
        emit ProposalSubmitted(msg.sender, pid);
    }

    function executeProposal(uint256 pid, bytes memory signature) external callerIsUser {
        Proposal storage proposal = _proposals[pid];
        require(proposal.sender == msg.sender, "Execute the proposal must be sender");
        require(proposal.status == ProposalStatus.NORMAL, "The proposal is executed");
        bytes32 message = keccak256(abi.encodePacked(msg.sender, block.chainid, pid, _nonces[msg.sender]));
        require(ECDSA.recover(message, signature) == _signOwner, "The signature is invalid");
        require(_groups[proposal.meta][proposal.addr] >= proposal.amount, "No sufficient balance");
        // update status and transfer
        proposal.status = ProposalStatus.PASS;
        _groups[proposal.meta][proposal.addr] -= proposal.amount;
        _nonces[msg.sender] += 1;
        if (proposal.addr == address(0)) {
            require(address(this).balance >= proposal.amount, "No sufficient balance");
            (bool res,) = payable(proposal.recipient).call{ value: proposal.amount }("");
            require(res, "The payable call is not success");
        }
        else {
            require(IERC20(proposal.addr).balanceOf(address(this)) >= proposal.amount, "No sufficient balance");
            (bool res, bytes memory data) = proposal.addr.call(abi.encodeWithSelector(0xa9059cbb, proposal.recipient, proposal.amount));
            require(res && (data.length == 0 || abi.decode(data, (bool))), "The payable call is not success");
        }
        emit ProposalExecuted(msg.sender, pid);
    }
}