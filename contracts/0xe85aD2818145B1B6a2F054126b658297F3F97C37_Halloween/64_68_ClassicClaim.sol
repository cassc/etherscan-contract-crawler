// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

import '../interfaces/IMintableERC721.sol';
import '../core/SafeOwnable.sol';
import '../core/Verifier.sol';

contract ClassicClaim is SafeOwnable, Verifier {

    event Claim(uint nonce, address user, uint nftId);

    IMintableERC721 public immutable nft;
    uint public immutable startAt;
    uint public immutable finishAt;

    mapping(uint => bool) public nonces;
    uint public totalMintNum;

    constructor(IMintableERC721 _nft, uint _startAt, uint _finishAt, address _verifier) Verifier(_verifier) {
        require(address(_nft) != address(0), "illegal nft");
        nft = _nft;
        require(_startAt > block.timestamp && _finishAt > _startAt, "illegal time");
        startAt = _startAt;
        finishAt = _finishAt;
    }
    
    modifier AlreadyBegin() {
        require(block.timestamp >= startAt, "not begin");
        _;
    }
    
    modifier NotFinish() {
        require(block.timestamp <= finishAt, "already finish");
        _;
    }

    function mint(uint _nonce, uint _num, uint8 _v, bytes32 _r, bytes32 _s) external AlreadyBegin NotFinish {
        require(_num > 0 && !nonces[_nonce], "nonce already used");
        require(
            ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked(address(this), _nonce, msg.sender, _num)))), _v, _r, _s) == verifier,
            "verify failed"
        );
        nft.mint(msg.sender, _num);
        uint lastTokenId = nft.totalSupply();
        for (uint i = 0; i < _num; i ++) {
            emit Claim(_nonce, msg.sender, lastTokenId - i);
        }
        nonces[_nonce] = true;
        totalMintNum += _num;
    }
}