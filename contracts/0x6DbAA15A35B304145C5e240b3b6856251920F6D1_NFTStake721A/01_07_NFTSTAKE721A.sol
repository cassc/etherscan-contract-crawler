// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract NFTStake721A is Ownable, Pausable {
    /* Variable */
    using SafeMath for uint256;
    address signerAddress;
    address holderAddress;
    address tokenAddress;
    mapping(string => bool) internal nonceMap;
    mapping(address => mapping(uint256 => bool)) internal stakeMap;

    /* Event */
    event Stake721A(address indexed fromAddress, address indexed toAddress, address indexed tokenAddress, uint256[] tokenIds, string nonce);
    event Redeem721A(address indexed fromAddress, address indexed toAddress, address indexed tokenAddress, uint256[] tokenIds, string nonce);

    constructor (){}

    // setup
    function setHolderAddress(address _holderAddress) public onlyOwner {
        holderAddress = _holderAddress;
    }

    function setSignerAddress(address _signerAddress) public onlyOwner {
        signerAddress = _signerAddress;
    }

    function setTokenAddress(address _tokenAddress) public onlyOwner {
        tokenAddress = _tokenAddress;
    }
    //end setup

    function stake721A(uint256[] memory tokenIds, bytes32 hash, bytes memory signature, uint256 blockHeight, string memory nonce) public {
        require(!nonceMap[nonce], "Nonce already exist!");
        //require(blockHeight >= block.number, "The block has expired!");
        require(hashStake721A(tokenAddress, tokenIds, blockHeight, nonce) == hash, "Invalid hash!");
        require(matchAddressSigner(hash, signature), "Invalid signature!");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            stakeMap[msg.sender][tokenIds[i]] = true;
        }
        nonceMap[nonce] = true;

        IERC721A NFTContract = IERC721A(tokenAddress);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            NFTContract.safeTransferFrom(msg.sender, holderAddress, tokenIds[i], abi.encode(msg.sender));
        }

        emit Stake721A(msg.sender, holderAddress, tokenAddress, tokenIds, nonce);
    }

    function redeem721A(uint256[] memory tokenIds, bytes32 hash, bytes memory signature, uint256 blockHeight, string memory nonce) public {
        require(!nonceMap[nonce], "Nonce already exist!");
        //require(blockHeight >= block.number, "The block has expired!");
        require(hashRedeem721A(tokenAddress, tokenIds, blockHeight, nonce) == hash, "Invalid hash!");
        require(matchAddressSigner(hash, signature), "Invalid signature!");

        bool isIn = true;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            isIn = isIn && stakeMap[msg.sender][tokenIds[i]];
        }
        require(isIn, "No such staking record!");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            stakeMap[msg.sender][tokenIds[i]] = false;
        }

        IERC721A NFTContract = IERC721A(tokenAddress);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            NFTContract.safeTransferFrom(holderAddress, msg.sender, tokenIds[i], abi.encode(msg.sender));
        }

        emit Redeem721A(holderAddress, msg.sender, tokenAddress, tokenIds, nonce);
    }

    function checkStakeStatus(address _owner, uint256 _tokenId) public view returns (bool){
        return (stakeMap[_owner][_tokenId]);
    }

    function hashStake721A(address _tokenAddress, uint256[] memory _tokenIds, uint256 blockHeight, string memory nonce) private view returns (bytes32) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(msg.sender, _tokenAddress, _tokenIds, blockHeight, nonce, "stake_721A"))
            )
        );
        return hash;
    }

    function hashRedeem721A(address _tokenAddress, uint256[] memory tokenIds, uint256 blockHeight, string memory nonce) private view returns (bytes32) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(msg.sender, _tokenAddress, tokenIds, blockHeight, nonce, "redeem_721A"))
            )
        );
        return hash;
    }

    function matchAddressSigner(bytes32 hash, bytes memory signature) internal view returns (bool) {
        return signerAddress == recoverSigner(hash, signature);
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) internal pure returns (address){
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig) internal pure returns (bytes32 r, bytes32 s, uint8 v){
        require(sig.length == 65, "Invalid signature length!");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
}