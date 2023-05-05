// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract SAFT {
    address public owner;
    address public multisig;
    bytes32 public merkleRoot;
    address public usdc;
    mapping(address => uint) public contributed;
    address[] public contributors;

    event Contribution(address user, uint amount);
    
    constructor() {
        owner = msg.sender;
        multisig = 0x7ae230223c4803961A9F41B960cA6e31095706Ed;
        merkleRoot = 0x6b6e7beafa3fd8c7e295477c835467eb65f1d416dd26d2d6be5999d038fc356b;
        usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    }

    function checkProof(address _user, bytes32[] calldata _merkleProof) public view returns(bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_user));
        bool result = MerkleProof.verify(_merkleProof, merkleRoot, leaf);
        return result;
    }

    function contribute(uint _amountUSDC, bytes32[] calldata _merkleProof) external {
        require (_amountUSDC >= 500e6, "Contribution Too Low");
        require (_amountUSDC + contributed[msg.sender] <= 25000e6, "Contribution Too High");
        require(checkProof(msg.sender, _merkleProof) == true, "Merkle proof does not validate");
        IERC20(usdc).transferFrom(msg.sender, address(this), _amountUSDC);
        contributed[msg.sender] += _amountUSDC;
        contributors.push(msg.sender); // may be duplicate addresses
        emit Contribution(msg.sender, _amountUSDC);
    }

    // owner functions
    function updateMerkleRoot(bytes32 _whitelistRoot) external {
        require(msg.sender == owner, "only owner has access");
        merkleRoot = _whitelistRoot;
    }

    function updateToken(address _usdc) external {
        require(msg.sender == owner, "only owner has access");
        usdc = _usdc;
    }

    // multisig functions
    function updateMultisig(address _multisig) external {
        require(msg.sender == multisig, "only multisig has access");
        multisig = _multisig;
    }

    function claimToken(IERC20 _token) external {
        require(msg.sender == multisig || msg.sender == owner, "only multisig and owner has access");
        uint balance = _token.balanceOf(address(this));
        _token.transfer(multisig, balance);
    }

    function claimETH() external {
        require(msg.sender == multisig || msg.sender == owner, "only multisig and owner has access");
        payable(multisig).transfer(address(this).balance);
    }

}