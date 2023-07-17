// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract JojoFigure is Ownable {
    mapping(address => uint256[]) public userBurnTokens;
    mapping(address => bool) public claimedFigure;

    uint256 public cost;
    uint256 public maxSupply = 1000;
    uint256 public maxMintAmountPerTx = 4;
    address public jojoAddress = 0x9278d95B79297e728ecF6F59dc0a6074c2e6Bf5a;
    address public burnAddress = 0x000000000000000000000000000000000000dEaD;
    uint256 public totalBurned;

    bool public burnEnabled = false;

    event BurnToken(uint256 token, uint256 timeStamp, address user);

    function burn(uint256[] calldata tokenIds) external {
        require(burnEnabled, "Burn is not enabled!");
        require(
            tokenIds.length == maxMintAmountPerTx,
            "You can only burn 4 tokens at a time!"
        );
        require(
            totalBurned + tokenIds.length <= maxSupply,
            "Max supply reached!"
        );
        require(claimedFigure[msg.sender] == false, "You have already minted!");

        IERC721 jojo = IERC721(jojoAddress);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                jojo.ownerOf(tokenIds[i]) == msg.sender,
                "You do not own this token!"
            );
            jojo.transferFrom(msg.sender, burnAddress, tokenIds[i]);
            userBurnTokens[msg.sender].push(tokenIds[i]);
            emit BurnToken(tokenIds[i], block.timestamp, msg.sender);
            totalBurned++;
        }
        claimedFigure[msg.sender] = true;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function setMaxMintAmountPerTx(
        uint256 _maxMintAmountPerTx
    ) public onlyOwner {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setBurnEnabled(bool _state) public onlyOwner {
        burnEnabled = _state;
    }

    function isClaimedFigure(address _user) public view returns (bool) {
        return claimedFigure[_user];
    }

    function setJoJoAddress(address _jojoAddress) public onlyOwner {
        jojoAddress = _jojoAddress;
    }

    function balanceOfBurned(address _user) public view returns (uint256) {
        return userBurnTokens[_user].length;
    }
    
}