//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./IRandom.sol";

contract Raffle is Initializable, OwnableUpgradeable, PausableUpgradeable, IERC721Receiver {    
    using EnumerableSet for EnumerableSet.UintSet;

    IERC721 public nft;
    IRandom private randomizer;

    EnumerableSet.UintSet private _tokens;
    mapping(uint256 => address) private _tokenToOwner;

    uint256 public currentPrizeNumber;

    event WinnerChosen(uint256 tokenId, address owner, uint256 prizeNumber);
    event NftSet(address oldNFT, address newNFT);
    event Staked(address owner, uint256 id);
    event UnStaked(address owner, uint256 id);

    function initialize() public initializer {
        __Ownable_init();
        __Pausable_init();
        currentPrizeNumber = 1;
    }

    function stake(uint256[] calldata ids) external whenNotPaused {
        for(uint256 i = 0; i < ids.length; i++) {
            uint256 current = ids[i];
            _tokenToOwner[current] = msg.sender;
            _tokens.add(current);
            nft.safeTransferFrom(msg.sender, address(this), current);            
            emit Staked(msg.sender, current);
        }
    }
    
    function unstake(uint256[] calldata ids) external whenNotPaused {
        for(uint256 i = 0; i < ids.length; i++) {            
            uint256 current = ids[i];
            require(_tokenToOwner[current] == msg.sender, "Not Owner");
            delete _tokenToOwner[current];
            _tokens.remove(current);
            nft.safeTransferFrom(address(this), msg.sender, current);            
            emit UnStaked(msg.sender, current);
        }
    }

    function raffleSamePrize(uint256 numberOfWinners) external onlyOwner {
        for(uint256 i = 0; i < numberOfWinners; i++) {
            uint256 id = _random(i);
            address winner = _tokenToOwner[id];
            emit WinnerChosen(id, winner, currentPrizeNumber);            
        }
        currentPrizeNumber++;
    }

    function raffleDifferentPrizes(uint256 numberOfWinners) external onlyOwner {
        for(uint256 i = 0; i < numberOfWinners; i++) {
            uint256 id = _random(i);
            address winner = _tokenToOwner[id];
            emit WinnerChosen(id, winner, currentPrizeNumber);            
            currentPrizeNumber++;
        }
    }

    function _random(uint256 salt) internal view returns (uint256) {
        return randomizer.random(salt, _tokens.length());
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function setNFT(IERC721 _nft) external onlyOwner {
        IERC721 oldNFT = nft;
        nft = _nft;
        emit NftSet(address(oldNFT), address(_nft));
    }

    function setRandomizer(IRandom _randomizer) external onlyOwner {
        randomizer = _randomizer;
    }
}