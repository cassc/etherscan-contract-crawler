// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract IPoisonedBananas is IERC1155 {
    function burnSingle(address bananaOwner, uint256 bananaType) external {}
}

contract IInfectedApePlanet {
    function mintTo(uint256 amount, address _to) external {}
}

contract PrimeApeInfector is Ownable {
    IERC721 public primeApeNFT;
    IPoisonedBananas public bananas;
    IInfectedApePlanet public infectedApes;

    bool public infectingOpen;
    uint256 public primeApeOffset = 7979;
    uint256 public nextLevelThreeId = 1;
    mapping(uint256 => mapping(uint256 => bool)) public apeInfected;
    mapping(uint256 => bool) public isLegendary;

    event Infect(address infector, uint256 indexed apeId, uint256 indexed bananaType, uint256 indexed infectedApeId);
    event ReceivedEther(address indexed sender, uint256 indexed amount);
    event WithdrawAllEvent(address indexed to, uint256 amount);

    constructor(
        address _ape,
        address _banana,
        address _infected
    ) Ownable() {
        primeApeNFT = IERC721(_ape);
        bananas = IPoisonedBananas(_banana);
        infectedApes = IInfectedApePlanet(_infected);
    }

    function _getInfectedApeId(uint256 apeId, uint256 bananaType) internal view returns (uint256) {
        if (bananaType == 2) {
            return nextLevelThreeId + primeApeOffset * bananaType;
        }
        return apeId + primeApeOffset * bananaType;
    }

    function infectApe(uint256 apeId, uint256 bananaType) external {
        require(infectingOpen, "Infection closed");

        require(primeApeNFT.ownerOf(apeId) == msg.sender, "Sender not owner of ape");
        require(bananas.balanceOf(msg.sender, bananaType) > 0, "Sender not owner of banana type"); 
        require(bananaType < 3, "Wrong banana type");       

        if (isLegendary[apeId]) {
            require(!apeInfected[apeId][0] && !apeInfected[apeId][1] && !apeInfected[apeId][2], "Legendary already infected");
            nextLevelThreeId++;
        } else {
            require(!apeInfected[apeId][bananaType], "Ape already infected by banana");
        }

        apeInfected[apeId][bananaType] = true;

        uint256 infectedApeId = _getInfectedApeId(apeId, bananaType);
        bananas.burnSingle(msg.sender, bananaType);
        infectedApes.mintTo(infectedApeId, msg.sender);

        emit Infect(msg.sender, apeId, bananaType, infectedApeId);
    }

    /** === View === */
    function getInfectedByLevel(uint256[] calldata apeIds, uint256 bananaType) external view returns (uint256[] memory) {
        uint256 length = apeIds.length;
        uint256[] memory infectedApesByLevel = new uint256[](length);
        uint256 counter;

        for (uint256 i = 0; i < apeIds.length; i++) {
            uint256 apeId = apeIds[i];
                
            if (apeInfected[apeId][bananaType]) {
                infectedApesByLevel[counter] = apeId;
                counter++;
            }
        }

        return infectedApesByLevel;
    }

    function setContracts(address _ape, address _banana, address _infected) external onlyOwner {
        primeApeNFT = IERC721(_ape);
        bananas = IPoisonedBananas(_banana);
        infectedApes = IInfectedApePlanet(_infected);
    }

    function setLegendaries(uint256[] calldata legendaryIds) external onlyOwner {
        for (uint i = 0; i < legendaryIds.length; i++) {
            isLegendary[legendaryIds[i]] = true;
        }
    }

    function resetLegendaries(uint256[] calldata legendaryIds) external onlyOwner {
        for (uint i = 0; i < legendaryIds.length; i++) {
            isLegendary[legendaryIds[i]] = false;
        }
    }

    function setInfectingOpen(bool open) external onlyOwner {
        infectingOpen = open;
    }
    
    function withdrawAll(address _to) external onlyOwner {
        require(_to != address(0), "CANNOT WITHDRAW TO ZERO ADDRESS");
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "NO ETHER TO WITHDRAW");
        payable(_to).transfer(contractBalance);
        emit WithdrawAllEvent(_to, contractBalance);
    }

    receive() external payable {
        emit ReceivedEther(msg.sender, msg.value);
    }
}