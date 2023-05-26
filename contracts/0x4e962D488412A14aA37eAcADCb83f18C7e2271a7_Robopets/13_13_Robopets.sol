// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract RobotosContract {
    function ownerOf(uint256 tokenId) public view virtual returns (address);

    function balanceOf(address owner)
        external
        view
        virtual
        returns (uint256 balance);
}

contract Robopets is ERC721Enumerable, Ownable {
    RobotosContract private ROBO;

    uint256 public MAX_ROBOPET_ADOPTION = 50;
    uint256 public constant MAX_SUPPLY = 9999;

    bool public workshopIsOpen = false;

    string private baseURI;

    event SaleStateChanged(bool status);
    event AdoptedPet(address adopter, uint256 amount);

    constructor(address dependentContractAddress)
        ERC721("Robopets", "ROBOPET")
    {
        ROBO = RobotosContract(dependentContractAddress);
    }

    function adoptRobopet(uint256 robotosTokenId) public {
        require(workshopIsOpen, "WORKSHOP_CLOSED");
        require(robotosTokenId < MAX_SUPPLY, "INVALID_TOKEN_ID");
        require(!_exists(robotosTokenId), "ALREADY_ADOPTED");
        require(
            ROBO.ownerOf(robotosTokenId) == msg.sender,
            "MISSING_ASSOCIATED_ROBOTO"
        );

        _safeMint(msg.sender, robotosTokenId);
        emit AdoptedPet(msg.sender, 1);
    }

    function adoptRobopets(uint256[] calldata robotoIds) public {
        uint256 numRobotos = robotoIds.length;
        uint256 balance = ROBO.balanceOf(msg.sender);
        require(workshopIsOpen, "WORKSHOP_CLOSED");
        require(numRobotos <= MAX_ROBOPET_ADOPTION, "MAX_TRANSACTION_SIZE");
        require(totalSupply() + numRobotos < MAX_SUPPLY, "SOLD_OUT");
        require(balance > 0, "NO_ROBOTOS");
        require(balance >= numRobotos, "INVALID_TOKEN_IDS");

        for (uint256 i = 0; i < numRobotos; i++) {
            uint256 robotosTokenId = robotoIds[i];
            require(robotosTokenId < MAX_SUPPLY, "INVALID_TOKEN_ID");
            require(
                ROBO.ownerOf(robotosTokenId) == msg.sender,
                "MISSING_ASSOCIATED_ROBOTO"
            );
            require(!_exists(robotosTokenId), "ALREADY_ADOPTED");

            _safeMint(msg.sender, robotosTokenId);
        }

        emit AdoptedPet(msg.sender, numRobotos);
    }

    function tokensOfOwner(address owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokenIds;
    }

    function isAdopted(uint256 tokenId) external view returns (bool) {
        require(tokenId < MAX_SUPPLY, "INVALID_TOKEN_ID");

        return _exists(tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function setDependentContract(address dependentContractAddress)
        public
        onlyOwner
    {
        ROBO = RobotosContract(dependentContractAddress);
    }

    function flipSaleState() public onlyOwner {
        workshopIsOpen = !workshopIsOpen;
        emit SaleStateChanged(workshopIsOpen);
    }

    function setMaxPerTransaction(uint256 amount) public onlyOwner {
        MAX_ROBOPET_ADOPTION = amount;
    }
}