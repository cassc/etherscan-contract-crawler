// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./IDigitalAnimals.sol";
import "./ReentrancyGuard.sol";

contract DigitalAnimalsSoulPasses is ERC1155, Ownable, ReentrancyGuard {
    event NoOneCanStopDeath(
        address indexed from
    );

    enum Pass { NONE, COMMITED, SOULBOURNE, SOUL_REAPERS, LORD_OF_THE_REAPERS }

    string public name = "Digital Animals Soul Passes";
    string public symbol = "DASP";

    string private _baseTokenURI;

    // DA Contract
    IDigitalAnimals private _originalContract;

    mapping(address => Pass) public usersPass;
    mapping(Pass => uint256) public mintedPass;

    constructor(IDigitalAnimals originalContract) ERC1155("") { 
        _originalContract = originalContract;
        _baseTokenURI = "https://digitalanimals.club/soul_tokens/";
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        _baseTokenURI = baseURI_;
    }

    function mint(Pass pass) public lock {
        require(canMint(msg.sender, pass), "You can't mint this pass");
        require(pass != Pass.NONE, "Pass can't be empty");
        require(usersPass[msg.sender] == Pass.NONE, "You already minted pass");

        uint256 limit = passLimit(pass);
        uint256 alreadyMinted = mintedPass[pass];

        require(alreadyMinted < limit, "No passed of this level left");

        if (pass == Pass.LORD_OF_THE_REAPERS) {
            _mint(msg.sender, 4 + alreadyMinted, 1, "");
        } else {
            _mint(msg.sender, uint256(pass), 1, "");
        }

        if (pass == Pass.LORD_OF_THE_REAPERS || pass == Pass.SOUL_REAPERS) {
            emit NoOneCanStopDeath(msg.sender);
        }

        usersPass[msg.sender] = pass;
        mintedPass[pass] = alreadyMinted + 1;
    }
    
    function uri(uint256 index) public view virtual override returns (string memory) {
        require(index > 0 && index < 9, "URI query for nonexistent token");
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(index), ".json"));
    }

    function canMint(address operator, Pass pass) public view returns (bool) {
        uint256 minted = _originalContract.mintedAllSales(operator);
        uint256 own = _originalContract.balanceOf(operator);

        if (minted == 0) {
            if (pass == Pass.SOUL_REAPERS) {
                return own >= 10;
            }
            return false;
        } else if (own > 0) {
            if (pass == Pass.COMMITED) {
                return true;
            } else if (pass == Pass.SOULBOURNE) {
                return own >= 3;
            } else if (pass == Pass.SOUL_REAPERS) {
                return own >= 10;
            } else if (pass == Pass.LORD_OF_THE_REAPERS) {
                return own >= 20;
            }
        }

        return false;
    }

    function passLimit(Pass pass) public pure returns (uint256) {
        if (pass == Pass.COMMITED) {
            return 8888;
        }
        if (pass == Pass.SOULBOURNE) {
            return 1000;
        }
        if (pass == Pass.SOUL_REAPERS) {
            return 100;
        }
        if (pass == Pass.LORD_OF_THE_REAPERS) {
            return 5;
        }
        return 0;
    }
}