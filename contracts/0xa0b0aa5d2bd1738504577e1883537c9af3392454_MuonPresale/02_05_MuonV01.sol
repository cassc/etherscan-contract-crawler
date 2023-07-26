// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract MuonV01 is Ownable {
    using ECDSA for bytes32;

    event Transaction(bytes reqId);

    mapping(address => bool) public signers;

    constructor(){
        //initial nodes
        signers[0x06A85356DCb5b307096726FB86A78c59D38e08ee] = true;
        signers[0x4513218Ce2e31004348Fd374856152e1a026283C] = true;
        signers[0xe4f507b6D5492491f4B57f0f235B158C4C862fea] = true;
        signers[0x2236ED697Dab495e1FA17b079B05F3aa0F94E1Ef] = true;
        signers[0xCA40791F962AC789Fdc1cE589989444F851715A8] = true;
        signers[0x7AA04BfC706095b748979FE3E3dB156C3dFb9451] = true;
        signers[0x60AA825FffaF4AC68392D886Cc2EcBCBa3Df4BD9] = true;
        signers[0x031e6efe16bCFB88e6bfB068cfd39Ca02669Ae7C] = true;
        signers[0x27a58c0e7688F90B415afA8a1BfA64D48A835DF7] = true;
        signers[0x11C57ECa88e4A40b7B041EF48a66B9a0EF36b830] = true;
    }

    function verify(bytes calldata _reqId, bytes32 hash, bytes[] calldata sigs) public returns (bool) {
        uint i;
        address signer;
        for(i=0 ; i<sigs.length ; i++){
            signer = hash.recover(sigs[i]);
            // require(attualSigner == signer, "Signature not confirmed");
            if(signers[signer] != true)
                return false;
        }
        if(sigs.length > 0){
            emit Transaction(_reqId);
            return true;
        }
        else{
            return false;
        }
    }

    function ownerAddSigner(address _signer) public onlyOwner {
        signers[_signer] = true;
    }

    function ownerRemoveSigner(address _signer) public onlyOwner {
        delete signers[_signer];
    }
}