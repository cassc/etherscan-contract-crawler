// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './pass.sol';
import './zonmus.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

contract ZONMUSMINTER is AccessControl {
    bool isPaused;
    address passAddress;
    address nftAddress;

    bytes32 public merkleRoot;
    mapping(address => uint256) public mintedAmount;

    constructor(
        address _nftaddress,
        address _passaddress,
        bytes32 _merkleRoot
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        nftAddress = _nftaddress;
        passAddress = _passaddress;
        merkleRoot = _merkleRoot;
    }

    function setPaused() public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(isPaused != true);
        isPaused = true;
    }

    function changeMerkleRoot(bytes32 _merkleRoot) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(isPaused != true);
        merkleRoot = _merkleRoot;
    }

    function checkRemainAmount(
        bytes32[] memory _proof,
        uint256 _amount,
        address _holderAddress
    ) public view returns(uint256) {

        uint256 _mintEnableAmount;
        uint256 _mintedAmount = mintedAmount[_holderAddress];

        if (ZONMUSPASS(passAddress).balanceOf(_holderAddress) >= 1) {
            _mintEnableAmount += 6;
        }

        if (_proof.length >= 1) {
            bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(_holderAddress, _amount))));

            if (MerkleProof.verify(_proof, merkleRoot, leaf) == true) {
                _mintEnableAmount += _amount;
            }
        }

        return _mintEnableAmount - _mintedAmount;
        
    }

    function checkMerkleRoot(
        bytes32[] memory _proof,
        uint256 _amount,
        address _holderAddress
    ) public view returns(bool) {
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(_holderAddress, _amount))));
        return MerkleProof.verify(_proof, merkleRoot, leaf);
    }

    function singleMint(
        bytes32[] memory _proof,
        uint256 _amount,
        uint256 _mintAmount
    ) public {
        require(isPaused != true);
        
        uint256 _mintEnableAmount;
        uint256 _mintedAmount = mintedAmount[msg.sender];

        if (ZONMUSPASS(passAddress).balanceOf(msg.sender) >= 1) {
            _mintEnableAmount += 6;
            if (ZONMUSPASS(passAddress).checkFreeze(msg.sender) == false) {
                ZONMUSPASS(passAddress).freezeToken(msg.sender);
            }
        }

        
        if (_proof.length > 0) {
            bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(msg.sender, _amount))));

            if (MerkleProof.verify(_proof, merkleRoot, leaf) == true) {
                _mintEnableAmount += _amount;
           }
        }
         
        require(_mintEnableAmount >= _mintAmount + _mintedAmount);
        ZONMUS(nftAddress).multiMint(1, msg.sender, _mintAmount, 1001);
        mintedAmount[msg.sender] += _mintAmount;

    }

    function ownerSingleMint() public onlyRole(DEFAULT_ADMIN_ROLE) {
        ZONMUS(nftAddress).singleMint(1, msg.sender, 1001);
    }

    function ownerMultiMint(uint256 times) public onlyRole(DEFAULT_ADMIN_ROLE) {
        ZONMUS(nftAddress).multiMint(1, msg.sender, times, 1001);
    }
    
    function ownerResidueMint() public onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 times = ZONMUS(nftAddress).remainingCheck(1);
        ZONMUS(nftAddress).multiMint(1, msg.sender, times, 1001);
    }
}