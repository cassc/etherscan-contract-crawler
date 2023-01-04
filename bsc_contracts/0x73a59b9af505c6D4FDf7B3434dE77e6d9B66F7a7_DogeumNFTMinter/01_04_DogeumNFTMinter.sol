// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IDogeumNFT {
    function mintFor(address _to, uint256 _amount) external payable;
    function airDrop(address _to, uint256 _amount) external;
    function reveal() external;
    function setCost(uint256 _newCost) external;
    function setTokenAmount(uint256 _newTokenAmount) external;
    function setNotRevealedURI(string memory _notRevealedURI) external;
    function setBaseURI(string memory _newBaseURI) external;
    function setBaseExtension(string memory _newBaseExtension) external;
    function pause(bool _state) external;
    function withdraw() external;
    function emergencyTokenWithdraw() external;

    function transferOwnership(address newOwner) external;

    function totalSupply() external view returns (uint256);
    function cost() external view returns (uint256);
    function maxSupply() external view returns (uint256);
    function paused() external view returns (bool);
    function tokenAmount() external view returns (uint256);
}


/** Mint adapter to allow free mint per wallet through owner interface */
contract DogeumNFTMinter is Ownable, ReentrancyGuard {

    IDogeumNFT public constant DOGEUM_NFT = IDogeumNFT(0x85a59D34E5B1Aa00eC157d25FEf3A3b403d0ACf8);
    uint256 public freeMintSupply = 500;
    uint256 public freeMintsPerWallet = 1;

    mapping(address => uint256) public usedFreeMints;
    

    function mintFor(address _to, uint256 _amount) external payable nonReentrant {
        uint256 supply = DOGEUM_NFT.totalSupply();
        uint256 costForUser = cost(_to);
        
        if (costForUser == 0) {
            require(msg.value == 0, "Value missmatch");
            require(usedFreeMints[_to] + _amount <= freeMintsPerWallet, "Exeeds users free mints");
            require(supply + _amount <= freeMintSupply, "Exeeds free mints");

            usedFreeMints[_to] += _amount;

            // temporary set cost and tokenAmount to free mint and revert back
            uint256 _cost = DOGEUM_NFT.cost();
            uint256 _tokenAmount = DOGEUM_NFT.tokenAmount();
            DOGEUM_NFT.setCost(0);
            DOGEUM_NFT.setTokenAmount(0);
            DOGEUM_NFT.mintFor{value: msg.value}(_to, _amount);
            DOGEUM_NFT.setCost(_cost);
            DOGEUM_NFT.setTokenAmount(_tokenAmount);
        } else {
            DOGEUM_NFT.mintFor{value: msg.value}(_to, _amount);
        }
    }


    function configureFreeMint(uint256 _freeMintSupply, uint256 _freeMintsPerWallet) external onlyOwner {
        freeMintSupply = _freeMintSupply;
        freeMintsPerWallet = _freeMintsPerWallet;
    }

    function revertDogeumNFTOwnership() external onlyOwner {
        DOGEUM_NFT.transferOwnership(owner());
    }

    function renounceOwnership() public override view onlyOwner {
        revert("Can not renounce ownership");
    }


    function cost(address _user) public view returns (uint256) {
        if (usedFreeMints[_user] < freeMintsPerWallet && DOGEUM_NFT.totalSupply() < freeMintSupply) {
            return 0;
        } else {
            return DOGEUM_NFT.cost();
        }
    }

    // forward interface

    function airDrop(address _to, uint256 _amount) external onlyOwner {
        DOGEUM_NFT.airDrop(_to, _amount);
    }

    function reveal() external onlyOwner {
        DOGEUM_NFT.reveal();
    }

    function setCost(uint256 _newCost) external onlyOwner {
        DOGEUM_NFT.setCost(_newCost);
    }

    function setTokenAmount(uint256 _newTokenAmount) external onlyOwner {
        DOGEUM_NFT.setTokenAmount(_newTokenAmount);
    }

    function setNotRevealedURI(string memory _notRevealedURI) external onlyOwner {
        DOGEUM_NFT.setNotRevealedURI(_notRevealedURI);
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        DOGEUM_NFT.setBaseURI(_newBaseURI);
    }

    function setBaseExtension(string memory _newBaseExtension) external onlyOwner {
        DOGEUM_NFT.setBaseExtension(_newBaseExtension);
    }

    function pause(bool _state) external onlyOwner {
        DOGEUM_NFT.pause(_state);
    }

    function withdraw() external onlyOwner {
        DOGEUM_NFT.withdraw();

        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function emergencyTokenWithdraw() external onlyOwner {
        DOGEUM_NFT.emergencyTokenWithdraw();
    }

}