// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./VerifySignature.sol";

contract SPCDust is ERC20, Ownable, VerifySignature {
    bool public isMintingActive = true;
    
    address public signer;
    uint256 public mintingFee;    

    constructor(
        address _signer,
        uint256 _mintingFee
    ) ERC20("Space Cartels Dust", "DUST") {
        signer = _signer;
        mintingFee = _mintingFee;
    }

    function mint(uint256 tokensAmount, uint256 _nonce, bytes calldata _signature) external payable {
        require(isMintingActive, "Minting is not activated.");
        require(mintingFee <= msg.value, "Ether value sent is not correct.");
        require(verify(signer, tokensAmount, _nonce, _signature), "You are not verified.");

        _mint(msg.sender, tokensAmount);
    }

    function setSigner(address _signer) external onlyOwner { 
        signer = _signer;
    }

    function setMintingFee(uint256 _mintingFee) external onlyOwner {
        mintingFee = _mintingFee;
    }

    function setIsMintingActive(bool _isMintingActive) external onlyOwner {
        isMintingActive = _isMintingActive;
    }

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function burn(uint256 value) public {
      _burn(msg.sender, value);
    }
}