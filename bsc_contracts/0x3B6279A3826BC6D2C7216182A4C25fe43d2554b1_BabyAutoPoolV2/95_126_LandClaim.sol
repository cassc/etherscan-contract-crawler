// SPDX-License-Identifier: MIT

pragma solidity 0.7.4;

import '@openzeppelin/contracts/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import "@openzeppelin/contracts/access/Ownable.sol";
import '../interfaces/IERC721Mintable.sol';
import '../libraries/TransferHelper.sol';
import '../interfaces/IWETH.sol';

contract LandClaim is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event NewVault(address oldVault, address newVault);
    event NewVerifier(address oldVerifier, address newVerifier);
    event Claimed(IERC20 _token, address _user, uint remain, uint totalAmount);

    address public vault;
    address public verifier;
    mapping(address => mapping(IERC20 => uint)) public claimed;

    function setVault(address _vault) external onlyOwner {
        emit NewVault(vault, _vault);
        vault = _vault;
    }

    function setVerifier(address _verifier) external onlyOwner {
        emit NewVerifier(verifier, _verifier);
        verifier = _verifier;
    }

    constructor(address _vault, address _verifier) {
        emit NewVault(vault, _vault);
        vault = _vault;
        emit NewVerifier(verifier, _verifier);
        verifier = _verifier;
    }

    function claim(IERC20 _token, uint _amount, uint8 _v, bytes32 _r, bytes32 _s) external {
        require(ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked(address(this), msg.sender, _token, _amount)))), _v, _r, _s) == verifier, "verify failed");
        uint remain = _amount.sub(claimed[msg.sender][_token]);
        if (remain > 0) {
            _token.safeTransferFrom(vault, msg.sender, remain);
            claimed[msg.sender][_token] = claimed[msg.sender][_token].add(remain);
        }
        emit Claimed(_token, msg.sender, remain, claimed[msg.sender][_token]);
    }
}