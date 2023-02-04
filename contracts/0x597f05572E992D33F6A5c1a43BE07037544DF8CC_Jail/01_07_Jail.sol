// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

/**
 * JoJo's Jail
 **/

///@author WhiteOakKong

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "erc721a/contracts/IERC721A.sol";

contract Jail is Ownable {
    using ECDSA for bytes32;

    IERC721A public immutable JoJo;

    bool public paused;

    address private signer = 0xA4753b764885142D21856F8B3b30326EB83a599E;

    event TokensStaked(uint256[] tokens, address owner, uint256 timeStamp);
    event TokensUnstaked(uint256[] tokens, address owner, uint256 timeStamp);

    modifier isNotPaused() {
        require(!paused, "Jail: Contract Paused");
        _;
    }

    constructor(address _JoJo) {
        JoJo = IERC721A(_JoJo);
    }

    function stake(uint256[] memory tokens) external isNotPaused {
        unchecked {
            for (uint256 i; i < tokens.length; i++) {
                _stake(tokens[i]);
            }
        }
        emit TokensStaked(tokens, msg.sender, block.timestamp);
    }

    function _stake(uint256 token) internal {
        JoJo.transferFrom(msg.sender, address(this), token);
    }

    function unstake(uint256[] memory tokens, bytes memory signature) public isNotPaused {
        require(_isValidSignature(signature, msg.sender, tokens));
        unchecked {
            for (uint256 i; i < tokens.length; i++) {
                _unstake(tokens[i]);
            }
        }
        emit TokensUnstaked(tokens, msg.sender, block.timestamp);
    }

    function _unstake(uint256 token) internal {
        JoJo.transferFrom(address(this), msg.sender, token);
    }

    ///@notice Signature validation internal function
    ///@param signature Signature that must be validated to allow unstaking of tokens.
    ///@param operator Address attempting to perform unstaking.
    ///@param tokens Array of tokens to be unstaked.
    function _isValidSignature(
        bytes memory signature,
        address operator,
        uint256[] memory tokens
    ) internal view returns (bool) {
        bytes32 data = keccak256(abi.encodePacked(operator, "_", tokens));
        return signer == data.toEthSignedMessageHash().recover(signature);
    }

    ///@notice Function to set the signer address.
    ///@param _signer - address of the signer.
    function updateSigner(address _signer) external onlyOwner {
        require(_signer != address(0), "Invalid address");
        signer = _signer;
    }

    function emergencyUnstake(address[] memory owners, uint256[] memory tokens) external onlyOwner {
        for (uint256 i; i < tokens.length; i++) {
            JoJo.transferFrom(address(this), owners[i], tokens[i]);
        }
    }

    function pause() external onlyOwner {
        paused = true;
    }
}