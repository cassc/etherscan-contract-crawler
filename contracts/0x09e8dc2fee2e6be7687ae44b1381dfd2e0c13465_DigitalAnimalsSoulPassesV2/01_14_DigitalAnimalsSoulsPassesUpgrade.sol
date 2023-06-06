// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./IDigitalAnimals.sol";
import "./ReentrancyGuard.sol";
import "./IDigitalAnimalsSoulPasses.sol";

contract DigitalAnimalsSoulPassesV2 is IDigitalAnimalsSoulPasses, ERC1155, Ownable, ReentrancyGuard {
    string public name = "Digital Animals Soul Passes v2";
    string public symbol = "DASP";

    string private _baseTokenURI;

    // DA Contract
    IDigitalAnimals private _originalContract;
    IDigitalAnimalsSoulPasses private _preveousVersion;

    mapping(address => Pass) private _usersPass;
    mapping(Pass => int256) private _mintedPass;
    mapping(address => bool) private _burnedOld;

    address private _burnAddress = 0x000000000000000000000000000000000000dEaD;
    address private _burnAccessAddress;

    constructor(IDigitalAnimals originalContract, IDigitalAnimalsSoulPasses preveousVersion) ERC1155("") { 
        _originalContract = originalContract;
        _preveousVersion = preveousVersion;
        _baseTokenURI = "https://digitalanimals.club/soul_tokens_v2/";
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        _baseTokenURI = baseURI_;
    }

    function migrate(Pass pass) public lock {
        require(canMigrate(msg.sender, pass), "You can't migrate");
        require(_preveousVersion.isApprovedForAll(msg.sender, address(this)), "Contract can't burn");

        Pass oldPass = _preveousVersion.usersPass(msg.sender);
        require(pass >= oldPass, "Pass should be at least same level");

        uint256 lordIndex = 0;
        if (oldPass == Pass.LORD_OF_THE_REAPERS) {
            for (uint i = 4; i < 9; i++) {
                if (_preveousVersion.balanceOf(msg.sender, i) == 1) {
                    lordIndex = i;
                    break;
                }
            }
        }

        if (oldPass == Pass.LORD_OF_THE_REAPERS) {
            _preveousVersion.safeTransferFrom(msg.sender, _burnAddress, lordIndex, 1, "");
        } else {
            _preveousVersion.safeTransferFrom(msg.sender, _burnAddress, uint256(oldPass), 1, "");
        }

        if (oldPass == pass) {
            _usersPass[msg.sender] = pass;
            _burnedOld[msg.sender] = true;

            if (oldPass == Pass.LORD_OF_THE_REAPERS) {
                _mint(msg.sender, lordIndex, 1, "");
            } else {
                _mint(msg.sender, uint256(pass), 1, "");
            }
        } else {
            _burnedOld[msg.sender] = true;

            _mintedPass[oldPass] -= 1;
            _mintedPass[pass] += 1;

            _usersPass[msg.sender] = pass;

            _mint(msg.sender, uint256(pass), 1, "");
        }

        if (pass == Pass.LORD_OF_THE_REAPERS || pass == Pass.SOUL_REAPERS) {
            emit NoOneCanStopDeath(msg.sender);
        }
    }

    function mintOrUpgrade(Pass pass) public lock {
        require(shouldMigrate(msg.sender) == false, "Should migrate first");
        require(canMint(msg.sender, pass), "You can't mint this pass");
        require(pass != Pass.NONE, "Pass can't be empty");

        Pass oldPass = usersPass(msg.sender);
        require(uint256(oldPass) < uint256(pass), "You already minted pass of current or lower level");

        if (pass == Pass.SOUL_REAPERS) {
            emit NoOneCanStopDeath(msg.sender);
        }

        if (oldPass != Pass.NONE) {
            _burn(msg.sender, uint256(oldPass), 1);
            _mintedPass[oldPass] -= 1;
        }

        _usersPass[msg.sender] = pass;
        _mintedPass[pass] += 1;
        _mint(msg.sender, uint256(pass), 1, "");
    }

    function setBurnAccess(address burnAccessAddress) public onlyOwner lock {
        _burnAccessAddress = burnAccessAddress;
    }

    function burnOnePass(address operator, Pass pass) public lock {
        require(msg.sender == _burnAccessAddress, "You can't access this function");
        _burn(operator, uint256(pass), 1);
    }
    
    function uri(uint256 index) public view virtual override returns (string memory) {
        require(index > 0 && index < 9, "URI query for nonexistent token");
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(index), ".json"));
    }

    function canUpgrade(address operator) public view returns (bool) {
        return canUpgrade(operator, maximumAvailablePass(operator));
    }

    function canUpgrade(address operator, Pass pass) public view returns (bool) {
        Pass currentPass = _usersPass[operator];
        bool _canMint = canMint(operator, pass);
        return currentPass != Pass.NONE && currentPass < pass && _canMint;
    }

    function shouldMigrate(address operator) public view returns (bool) {
        Pass oldPass = _preveousVersion.usersPass(operator);
        bool burned = _burnedOld[operator];
        return oldPass != Pass.NONE && burned == false;
    }

    function canMigrate(address operator, Pass pass) public view returns (bool) {
        Pass oldPass = _preveousVersion.usersPass(operator);
        bool burned = _burnedOld[operator];
        return (oldPass == pass || pass == maximumAvailablePass(operator)) && burned == false;
    }

    function maximumAvailablePass(address operator) public view returns (Pass pass) {
        uint256 minted = _originalContract.mintedAllSales(operator);
        uint256 own = _originalContract.balanceOf(operator);

        if (own >= 10) {
            if (isPassAvailable(Pass.SOUL_REAPERS)) {
                return Pass.SOUL_REAPERS;
            }
        }

        if (minted > 0) {
            if (own >= 3) {
                if (isPassAvailable(Pass.SOULBOURNE)) {
                    return Pass.SOULBOURNE;
                }
            }
            
            if (own >= 1) {
                return Pass.COMMITED;
            }
        }

        return Pass.NONE;
    }

    function canMint(address operator, Pass pass) public view returns (bool) {
        bool available = pass <= maximumAvailablePass(operator);
        return available && isPassAvailable(pass);
    }

    function isPassAvailable(Pass pass) public view returns (bool) {
        return mintedPass(pass) < passLimit(pass);
    }

    function passLimit(Pass pass) public pure returns (uint256) {
        if (pass == Pass.COMMITED) {
            return 8888;
        }
        if (pass == Pass.SOULBOURNE) {
            return 1000;
        }
        if (pass == Pass.SOUL_REAPERS) {
            return 170;
        }
        if (pass == Pass.LORD_OF_THE_REAPERS) {
            return 5;
        }
        return 0;
    }

    function hasToken(address operator) public view returns (bool) {
        return maximumOwnedToken(operator) != Pass.NONE;
    }

    function maximumOwnedToken(address operator) public view returns (Pass pass) {
        for (uint i = 8; i >= 1; i--) {
            if ((balanceOf(operator, i) >= 1) || (_preveousVersion.balanceOf(operator, i) >= 1)) {
                if (i >= 4) {
                    return Pass.LORD_OF_THE_REAPERS;
                }
                return Pass(i);
            }
        }

        return Pass.NONE;
    }

    function usersPass(address operator) override public view returns (Pass pass) {
        Pass newPass = _usersPass[operator];
        if (newPass != Pass.NONE) {
            return newPass;
        }
        Pass oldPass = _preveousVersion.usersPass(operator);   
        return oldPass;
    }

    function mintedPass(Pass pass) override public view returns (uint256 minted) {
        int256 alreadyMinted = _mintedPass[pass] + int256(_preveousVersion.mintedPass(pass));
        return alreadyMinted >= 0 ? uint256(alreadyMinted) : 0;
    }

    function hasOldPass(address operator) private view returns (bool) {
        return _preveousVersion.usersPass(operator) != Pass.NONE;
    }
}