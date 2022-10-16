pragma solidity 0.8.17;
// SPDX-License-Identifier: MIT

/* fabrik HausToken Bridge

Post-deployment operations:
- 1. Set hausToken addresses using the setHausToken() function.
        - Set the _setLegacy flag to 'true' to set the old haustokens address. 'false' to set the new one'
- 2. Set the merkle root hash for missing rewards of oldHT using the setMerkleRoot() function.
- 3. Unpause the contract
*/

import { ReentrancyGuard } from "./lib/solmate/utils/ReentrancyGuard.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

interface IERC20 {
    function burn(uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function mint(address _to, uint _amount) external;
}

contract HTConvert is Ownable, Pausable, ReentrancyGuard {
    constructor() {
        _pause();
    }
    /////////////////////////////////////////////////////////
    /// Global variables
    /////////////////////////////////////////////////////////
    IERC20 LHT;
    IERC20 HT;

    mapping (address => uint) public missingTokensClaimed;
    bytes32 merkleRoot;

    /////////////////////////////////////////////////////////
    /// Modifiers
    /////////////////////////////////////////////////////////
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    /////////////////////////////////////////////////////////
    /// Main functions
    /////////////////////////////////////////////////////////

    /// @notice                     Convert legacy hausTokens to new haustokens
    /// @param _amount              Amount of HT to convert
    function convert(uint _amount) public nonReentrant whenNotPaused {
        require(LHT.allowance(msg.sender, address(this)) >= _amount, "Not enough allowance");
        bool ts = LHT.transferFrom(msg.sender, address(this), _amount);
        require(ts, "Transfer unsuccessful");
        HT.mint(msg.sender, _amount);
    }

    /// @notice                     Claim missing oldHT balances in newHT
    /// @param _amount              Amount of tokens to claim
    /// @param _allowedQuantity     Maximum allowed tokens to claim
    /// @param _proof               Merkle proof
    function claimMissingTokens(uint _amount, uint _allowedQuantity, bytes32[] calldata _proof) external callerIsUser {
        require(verifyMP(msg.sender, _allowedQuantity, _proof), "Whitelist check failed");
        require(missingTokensClaimed[msg.sender] + _amount <= _allowedQuantity, "Exceeding allowance");
        missingTokensClaimed[msg.sender] += _amount;
        HT.mint(msg.sender, _amount * 1e18);
    }

    /// @notice     Burns all the legacy hausTokens that are stored in the contract
    function burnLegacy() external onlyOwner {
        LHT.burn(LHT.balanceOf(address(this)));
    }
    
    /////////////////////////////////////////////////////////
    /// Helper functions
    /////////////////////////////////////////////////////////
    /// @notice                         Verify merkle proof validity
    /// @param _account                 Address
    /// @param _allowedQuantity         Maximum amount of haustokens allowed to claim
    /// @param _proof                   Merkle proof
    function verifyMP(address _account, uint256 _allowedQuantity, bytes32[] calldata _proof) public view returns (bool) {
        return MerkleProof.verify(
            _proof,
            merkleRoot,
            keccak256(abi.encodePacked(_account, _allowedQuantity))
        );
    }

    /////////////////////////////////////////////////////////
    /// SET Functions
    /////////////////////////////////////////////////////////
    /// @notice     Sets the hausToken contract address
    /// @param _setLegacy       false - set new haustoken address; true - set legacy haustoken address
    function setHausToken(bool _setLegacy, address _hausToken) external onlyOwner {
        _setLegacy ? LHT = IERC20(_hausToken) : HT = IERC20(_hausToken);
    }

    /// @notice     Sets the merkle root for missing oldHT whitelist
    /// @param _merkleRoot      Root hash of the whitelist
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /// @notice     Pause/unpause the contract
    /// @param _state           True/false
    function pause(bool _state) external onlyOwner {
        _state ? _pause() : _unpause();
    }
}