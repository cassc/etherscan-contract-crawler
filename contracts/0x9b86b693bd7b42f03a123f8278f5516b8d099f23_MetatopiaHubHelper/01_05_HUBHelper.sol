// SPDX-License-Identifier: MIT LICENSE

pragma solidity 0.8.17;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IHUB } from "./interfaces/IHUB.sol";
import { IGameContract } from "./interfaces/IGameContract.sol";

contract MetatopiaHubHelper is Ownable {

    IHUB public HUB = IHUB(0x1FbeA078ad9f0f52FD39Fc8AD7494732D65309Fb);
    mapping(uint8 => IGameContract) public gameContracts; // 1 = BullRun, 2 = MoonForce, 3 = Doge World, 4 = PYE Market, 5 = Wastelands
    mapping(address => mapping(uint8 => bool)) public userUnstaked;
    mapping(uint16 => bool) public alphaUnstaked; 

    event AlphaReturned (address indexed _originalOwner, uint16 _id);

    constructor() {
        gameContracts[1] = IGameContract(0xBe2440C38Cdb7920Ed8D77df6c97112779957286);
        gameContracts[2] = IGameContract(0x7fF98F4140074D371e40cE81180D7E0e5d459271);
        gameContracts[3] = IGameContract(0x7Bfd981d7AdB787c48C9B95931DAABAE0270Ad21);
        gameContracts[4] = IGameContract(0x24d5eEed253782D3ADbccB0E1d1a7Ef33F609713);
        gameContracts[5] = IGameContract(0x4c26a956997A103c52F77303efaaB0b591cA3728);
    }

    function emergencyRescueAlphasByIds(uint16[] calldata _ids, uint8 gameId) external {
        uint16[] memory userStaked = HUB.getUserStakedAlphaGame(msg.sender, gameId);
        bool isAlphaOwner;
        for (uint i = 0; i < _ids.length; i++) {
            require(
                (
                    gameId == 5 ? 
                    gameContracts[gameId].getTopiaPerAlpha(_ids[i]) :
                    gameContracts[gameId].getUnclaimedAlpha(_ids[i])
                ) == 0, "Must claim earnings first"
            );
            require(_getUnclaimedAlpha(_ids[i], gameId) == 0, "Must claim earnings first");
            isAlphaOwner = false;
            for (uint s = 0; s < userStaked.length; s++) {
                if (_ids[i] == userStaked[s]) {
                    isAlphaOwner = true;
                    break;
                } else {
                    continue;
                }
            }
            require(isAlphaOwner, "Caller is not owner of Alpha");

            HUB.emergencyRescueAlpha(_ids[i], msg.sender);
            emit AlphaReturned(msg.sender, _ids[i]);
        }
        userUnstaked[msg.sender][gameId] = true;
    }

    function emergencyRescueAlphas(uint8 gameId) external {
        require(!userUnstaked[msg.sender][gameId], "User has already unstaked");
        require(HUB.devRescueEnabled(), "Rescue not enabled");
        uint16[] memory _ids = HUB.getUserStakedAlphaGame(msg.sender, gameId);
        for (uint i = 0; i < _ids.length; i++) {
            require(_getUnclaimedAlpha(_ids[i], gameId) == 0, "Must claim earnings first");

            HUB.emergencyRescueAlpha(_ids[i], msg.sender);
            if (gameId == 1) {
                alphaUnstaked[_ids[i]] = true;
            }
            emit AlphaReturned(msg.sender, _ids[i]);
        }
        userUnstaked[msg.sender][gameId] = true;
    }

    function _setGenesis(address genesis_) external onlyOwner {
        HUB.setGenesis(genesis_);
    }

    function _setTopia(address topia_) external onlyOwner {
        HUB.setTopia(topia_);
    }

    function _batchSetGenesisIdentifier(uint16[] calldata idNumbers_, uint8[] calldata types_) external onlyOwner {
        HUB.batchSetGenesisIdentifier(idNumbers_, types_);
    }

    function _setRescueEnabled(bool flag_) external onlyOwner {
        HUB.setRescueEnabled(flag_);
    }

    function _setDevRescueEnabled(bool flag_) external onlyOwner {
        HUB.setDevRescueEnabled(flag_);
    }

    function _setGameContract(address contract_, bool flag_) external onlyOwner {
        HUB.setGameContract(contract_, flag_);
    }

    function _transferHUBOwnership(address _newOwner) external onlyOwner {
        HUB.transferOwnership(_newOwner);
    }

    function _getUnclaimedAlpha(uint16 tokenId, uint8 gameId) public view returns (uint256 owed) {
        if (alphaUnstaked[tokenId]) {
            return 0;
        }
        owed = gameId == 5 ? gameContracts[gameId].getTopiaPerAlpha(tokenId) : gameContracts[gameId].getUnclaimedAlpha(tokenId);
        if (owed <= 10**17) {
            return 0;
        }
    }

    function _getUserStakedAlphaGame(address owner, uint8 gameId) external view returns (uint16[] memory stakedAlphas) {
        if (userUnstaked[owner][gameId]) {
            return stakedAlphas;
        } else {
            return HUB.getUserStakedAlphaGame(owner, gameId);
        }
    }

    function _getUserStakedAlphas(address owner) external view returns (uint16[] memory stakedAlphas) {
        uint16[] memory stakedIds1 = HUB.getUserStakedAlphaGame(owner, 1);
        uint16[] memory stakedIds2 = HUB.getUserStakedAlphaGame(owner, 2);
        uint16[] memory stakedIds3 = HUB.getUserStakedAlphaGame(owner, 3);
        uint16[] memory stakedIds4 = HUB.getUserStakedAlphaGame(owner, 4);
        uint16[] memory stakedIds5 = HUB.getUserStakedAlphaGame(owner, 5);

        uint256 length;
        if (!userUnstaked[owner][1]) {
            length += stakedIds1.length;
        }
        if (!userUnstaked[owner][2]) {
            length += stakedIds2.length;
        }
        if (!userUnstaked[owner][3]) {
            length += stakedIds3.length;
        }
        if (!userUnstaked[owner][4]) {
            length += stakedIds4.length;
        }
        if (!userUnstaked[owner][5]) {
            length += stakedIds5.length;
        }

        if (length > 0) {
            stakedAlphas = new uint16[](length);
            uint y = 0;
            uint L = 0;
            if (!userUnstaked[owner][1]) {
                L = stakedIds1.length;
                for(uint z = 0; z < L; z++) {
                    stakedAlphas[y] = stakedIds1[z];
                    y++;
                }
            }
            if (!userUnstaked[owner][2]) {
                L = stakedIds2.length;
                for(uint z = 0; z < L; z++) {
                    stakedAlphas[y] = stakedIds2[z];
                    y++;
                }
            }
            if (!userUnstaked[owner][3]) {
                L = stakedIds3.length;
                for(uint z = 0; z < L; z++) {
                    stakedAlphas[y] = stakedIds3[z];
                    y++;
                }
            }
            if (!userUnstaked[owner][4]) {
                L = stakedIds4.length;
                for(uint z = 0; z < L; z++) {
                    stakedAlphas[y] = stakedIds4[z];
                    y++;
                }
            }
            if (!userUnstaked[owner][5]) {
                L = stakedIds5.length;
                for(uint z = 0; z < L; z++) {
                    stakedAlphas[y] = stakedIds5[z];
                    y++;
                }
            }
        }
    }

}