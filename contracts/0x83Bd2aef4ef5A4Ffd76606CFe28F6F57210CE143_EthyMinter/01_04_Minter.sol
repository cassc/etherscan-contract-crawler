// SPDX-License-Identifier: AGPL-3.0
// ©2023 Ponderware Ltd

pragma solidity ^0.8.17;

import "./lib/SignaturePass.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IEthyToken {
    function mint (address to, bytes31 parameters, bytes32 extension) external;
}

contract EthyMinter is SignaturePass, Ownable {

    address immutable EthyTokenAddress;

    constructor (address ethyTokenAddress, address passSignerAddress)
        SignaturePass(passSignerAddress, "ETHY")
        {
            EthyTokenAddress = ethyTokenAddress;
        }

    function mint (bytes31 parameters, uint nonce, bytes memory pass) public {
        validatePass(msg.sender, nonce, "", pass);
        IEthyToken(EthyTokenAddress).mint(msg.sender, parameters, "");
    }

    function extendNonces (uint256 count) public onlyOwner {
        _extendNonces(count);
    }

    function setPassSigner (address passSignerAddress) public onlyOwner {
        _setPassSigner(passSignerAddress);
    }

}