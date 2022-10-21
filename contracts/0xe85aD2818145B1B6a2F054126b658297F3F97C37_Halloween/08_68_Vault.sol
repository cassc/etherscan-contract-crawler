// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol';
import '@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol';
import '@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol';
//import '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '../core/SafeOwnable.sol';

contract Vault is SafeOwnable, Initializable, ERC721Holder, ERC1155Holder {
    using Address for address;

    event VerifierChanged(address oldVerifier, address newVerifier);
    event ReceiveERC721(address token, address from, address to, uint tokenId);
    event ReceiveERC1155(address token, address from, address to, uint tokenId, uint amount);
    event ReceiveNativeToken(address from, uint amount);
    event AssetUsed(bytes32 hash);

    address public verifier;
    mapping(bytes32 => bool) public nonces;

    function initialize(address _verifier, address _owner) external initializer {
        SafeOwnable._transferOwnership(_owner);
        verifier = _verifier;
        emit VerifierChanged(address(0), _verifier);
    }

    function setVerifier(address _verifier) external onlyOwner {
        require(_verifier != address(0), "illegal verifier");
        emit VerifierChanged(verifier, _verifier);
        verifier = _verifier;
    }

    function onERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory
    ) public virtual override returns (bytes4) {
        emit ReceiveERC721(msg.sender, from, to, tokenId);
        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory
    ) public virtual override returns (bytes4) {
        emit ReceiveERC1155(msg.sender, from, to, tokenId, amount);
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address from,
        address to,
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        bytes memory
    ) public virtual override returns (bytes4) {
        for (uint i = 0; i < tokenIds.length; i ++) {
            emit ReceiveERC1155(msg.sender, from, to, tokenIds[i], amounts[i]);
        }
        return this.onERC1155BatchReceived.selector;
    }

    receive() external payable {
        emit ReceiveNativeToken(msg.sender, msg.value);
    }

    function use(address _contract, bytes memory _data, uint _amount, uint _nonce, uint8 _v, bytes32 _r, bytes32 _s) external {
        bytes32 hash = keccak256(abi.encodePacked(address(this), _contract, keccak256(_data), _amount, _nonce));
        require(!nonces[hash], "already exist");
        require(ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)), _v, _r, _s) == verifier, "verify failed");
        _contract.functionCallWithValue(_data, _amount);
        emit AssetUsed(hash);
    }
}