// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

contract SignersRepository is Ownable {

    mapping(address => bool) public signers;
    uint8 public numSigners;

    event SignerAdded(address signer, address sender, uint8 numSigners);
    event SignerRemoved(address signer, address sender, uint8 numSigners);

    constructor(address[] memory _signers) Ownable() {
        for (uint i = 0; i < _signers.length; i++){
            _addSigner(_signers[i]);
        }
    }

    function containsSigners(address[] memory _signers) external view returns (bool){
        if (numSigners != _signers.length){
            return false;
        }

        for (uint i = 0; i < _signers.length; i++){
            if (!signers[_signers[i]]){
                return false;
            }
        }

        return true;
    }

    function containsSigner(address _signer) external view virtual returns (bool){
        return signers[_signer];
    }

    function signersLength() view external returns (uint256){
        return numSigners;
    }

    function setupSigner(address _signer) onlyOwner external {
        _addSigner(_signer);
    }

    function revokeSigner(address _signer) onlyOwner external virtual {
        _removeSigner(_signer);
    }


    function _removeSigner(address _signer) private {
        signers[_signer] = false;
        numSigners--;
        emit SignerRemoved(_signer, msg.sender, numSigners);
    }

    function _addSigner(address _signer) private {
        signers[_signer] = true;
        numSigners++;
        emit SignerAdded(_signer, msg.sender, numSigners);
    }
}