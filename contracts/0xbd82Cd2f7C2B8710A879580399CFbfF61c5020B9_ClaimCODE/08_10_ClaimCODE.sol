//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ICODE.sol";
import "./MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";

contract ClaimCODE is Ownable, Pausable {
    using BitMaps for BitMaps.BitMap;

    BitMaps.BitMap private claimed;

    bytes32 public merkleRoot;
    uint256 public claimPeriodEnds;

    ICODE public immutable codeToken;

    event Claim(address indexed _claimant, uint256 _amount);
    event Sweep20(address _token);
    event Sweep721(address _token, uint256 _tokenID);

    error Address0Error();
    error InvalidProof();
    error AlreadyClaimed();
    error ClaimEnded();
    error ClaimNotEnded();
    error InitError();

    constructor(
        uint256 _claimPeriodEnds,
        address _codeToken,
        bytes32 _merkleRoot
    ) {
        if (_codeToken == address(0)) revert Address0Error();
        claimPeriodEnds = _claimPeriodEnds;
        codeToken = ICODE(_codeToken);
        merkleRoot = _merkleRoot;
        _pause();
    }

    function verify(bytes32[] calldata _proof, bytes32 _leaf) public view returns (bool, uint256) {
        return MerkleProof.verify(_proof, merkleRoot, _leaf);
    }

    function claimTokens(uint256 _amount, bytes32[] calldata _merkleProof) external whenNotPaused {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _amount));
        (bool valid, uint256 index) = verify(_merkleProof, leaf);
        if (!valid) revert InvalidProof();
        if (isClaimed(index)) revert AlreadyClaimed();
        if (block.timestamp > claimPeriodEnds) revert ClaimEnded();

        claimed.set(index);
        emit Claim(msg.sender, _amount);

        codeToken.claim_delegate(msg.sender, msg.sender);
        codeToken.transfer(msg.sender, _amount);
    }

    function isClaimed(uint256 _index) public view returns (bool) {
        return claimed.get(_index);
    }

    function sweep20(address _tokenAddr) external onlyOwner {
        IERC20 token = IERC20(_tokenAddr);
        if (_tokenAddr == address(codeToken) && block.timestamp <= claimPeriodEnds) revert ClaimNotEnded();
        token.transfer(owner(), token.balanceOf(address(this)));
        emit Sweep20(_tokenAddr);
    }

    function sweep721(address _tokenAddr, uint256 _tokenID) external onlyOwner {
        IERC721 token = IERC721(_tokenAddr);
        token.transferFrom(address(this), owner(), _tokenID);
        emit Sweep721(_tokenAddr, _tokenID);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}