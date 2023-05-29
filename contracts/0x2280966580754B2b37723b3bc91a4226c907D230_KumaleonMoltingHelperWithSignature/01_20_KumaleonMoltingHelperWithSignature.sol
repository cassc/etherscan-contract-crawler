//SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./Kumaleon.sol";

contract KumaleonMoltingHelperWithSignature is Ownable, ReentrancyGuard {

    address public nftAddress;
    address public signer; 
    bool public isMoltActive;

    constructor(address _signer, address _nftAddress) {
        signer = _signer; 
        nftAddress = _nftAddress;
    }

    function molt(
        uint256[] memory _kumaleonTokenIds,
        uint256[] memory _childTokenIds,
        bytes[] memory signatures
    ) external nonReentrant {
        require(isMoltActive, "KumaleonMoltingHelperWithSignature: molt is not opened");
        require(_kumaleonTokenIds.length != 0, "KumaleonMoltingHelperWithSignature: no molting is available");
        require(
            _kumaleonTokenIds.length == _childTokenIds.length &&
                _childTokenIds.length == signatures.length,
            "KumaleonMoltingHelperWithSignature: invalid length"
        );
        for (uint256 i; i < _kumaleonTokenIds.length; i++) {
            require(
                signer == ECDSA.recover(
                    ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(msg.sender, _kumaleonTokenIds[i], _childTokenIds[i]))),
                    signatures[i]
                ),
                "KumaleonMoltingHelperWithSignature: incorrect signer"
            ); 
            require(
                !Kumaleon(nftAddress).isMolted(_kumaleonTokenIds[i]), 
                "KumaleonMoltingHelperWithSignature: kumaleon is already molted"
            ); 
        }

        Kumaleon(nftAddress).molt(msg.sender, _kumaleonTokenIds, _childTokenIds);
    }

    function setIsMoltActive(bool _isMoltActive) external onlyOwner {
        isMoltActive = _isMoltActive;
    }

    function setSigner(address _signer) external onlyOwner { 
        signer = _signer; 
    }
}