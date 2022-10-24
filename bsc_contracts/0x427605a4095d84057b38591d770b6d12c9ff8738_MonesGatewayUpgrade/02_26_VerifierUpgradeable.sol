// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract MonesVerifierUpgradeable is Initializable {
    address public signer;

    function __SignatureVerifier_init(address _signer) internal initializer {
        __SignatureVerifier_init_unchained(_signer);
    }

    function __SignatureVerifier_init_unchained(address _signer) internal initializer {
        signer = _signer;
    }

    function verifyERC20(address _receiver, address _erc20, uint256 _amount, uint256 _nonce, bytes memory _signature) public view returns(bool) {
        bytes32 messageHash = getMessageHashERC20(_receiver, _erc20, _amount, _nonce);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, _signature) == signer;
    }

    function getMessageHashERC20(address receiver, address erc20, uint256 amount, uint256 nonce)
        public
        view
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(receiver, erc20, amount, nonce, address(this)));
    }

    function verifyERC721(address _receiver, address _erc721, uint256 _id, bool _isNew, uint256 _nonce, bytes memory _signature) public view returns(bool) {
        bytes32 messageHash = getMessageHashERC721(_receiver, _erc721, _id, _isNew, _nonce);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, _signature) == signer;
    }

    function getMessageHashERC721(address receiver, address erc721, uint256 id, bool isNew, uint256 nonce)
        public
        view
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(receiver, erc721, id, isNew, nonce, address(this)));
    }

    function verifyERC721WithAttribute(address _receiver, address _erc721, uint256 _id, uint256 _heroId, uint8 _rarity, uint8 _star, uint8 _level, uint8 _enhancement, uint256 _nonce, bytes memory _signature) public view returns(bool) {
        bytes32 messageHash = getMessageHashERC721WithAttribute(_receiver, _erc721, _id, _heroId, _rarity, _star, _level, _enhancement, _nonce);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, _signature) == signer;
    }

    function getMessageHashERC721WithAttribute(address receiver, address erc721, uint256 id, uint256 heroId, uint8 rarity, uint8 star, uint8 level, uint8 enhancement, uint256 nonce)
        public
        view
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(receiver, erc721, id, heroId, rarity, star, level, enhancement, nonce, address(this)));
    }

    function verifyERC1155(address _receiver, address _erc1155, uint256 _id, uint256 _amount, bool _isNew, uint256 _nonce, bytes memory _signature) public view returns(bool) {
        bytes32 messageHash = getMessageHashERC1155(_receiver, _erc1155, _id, _amount, _isNew, _nonce);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, _signature) == signer;
    }

    function getMessageHashERC1155(address receiver, address erc1155, uint256 id, uint256 amount, bool isNew, uint256 nonce)
        public
        view
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(receiver, erc1155, id, amount, isNew, nonce, address(this)));
    }

    function verifyReferChest(address _receiver, address _chestAddress, uint256 _chestId, uint256 _amount, uint256 _rewardConfigId,  uint256 _nonce, bytes memory _signature) public view returns(bool) {
        bytes32 messageHash = getMessageHashReferChest(_receiver, _chestAddress, _chestId, _amount, _rewardConfigId, _nonce);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, _signature) == signer;
    }

    function getMessageHashReferChest(address receiver, address chestAddress, uint256 chestId, uint256 amount, uint256 rewardConfigId, uint256 nonce)
    public
    view
    returns (bytes32)
    {
        return keccak256(abi.encodePacked(receiver, chestAddress, chestId, amount, rewardConfigId, nonce, address(this)));
    }


    function verifyWalletRewardChest(address _receiver, address _chestAddress, uint256 _chestId, uint256 _amount,  uint256 _deadline, uint256 _nonce, bytes memory _signature) public view returns(bool) {
        bytes32 messageHash = getMessageHashWalletRewardChest(_receiver, _chestAddress, _chestId, _amount, _deadline, _nonce);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, _signature) == signer;
    }

    function getMessageHashWalletRewardChest(address receiver, address chestAddress, uint256 chestId, uint256 amount, uint256 deadline, uint256 nonce)
    public
    view
    returns (bytes32)
    {
        return keccak256(abi.encodePacked(receiver, chestAddress, chestId, amount, deadline, nonce, address(this)));
    }

    function verifyERC20Deadline(address _receiver, address _erc20, uint256 _amount, uint256 _deadline, uint256 _nonce, bytes memory _signature) public view returns(bool) {
        bytes32 messageHash = getMessageHashERC20Deadline(_receiver, _erc20, _amount, _deadline, _nonce);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, _signature) == signer;
    }

    function getMessageHashERC20Deadline(address receiver, address erc20, uint256 amount, uint256 deadline, uint256 nonce)
    public
    view
    returns (bytes32)
    {
        return keccak256(abi.encodePacked(receiver, erc20, amount, deadline, nonce, address(this)));
    }


    function getEthSignedMessageHash(bytes32 messageHash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    messageHash
                )
            );
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory signature)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(signature.length == 65, "invalid signature length");

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
    }
}