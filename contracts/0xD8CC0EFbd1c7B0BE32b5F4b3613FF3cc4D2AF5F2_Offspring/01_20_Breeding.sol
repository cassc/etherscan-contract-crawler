// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

// ,--------.,------.,------.  ,------.,--.   ,--.
// '--.  .--'|  .---'|  .-.  \ |  .-.  \\  `.'  /
//    |  |   |  `--, |  |  \  :|  |  \  :'.    /
//    |  |   |  `---.|  '--'  /|  '--'  /  |  |
//    `--'   `------'`-------' `-------'   `--'
// ,-----. ,------.  ,---.  ,------.
// |  |) /_|  .---' /  O  \ |  .--. '
// |  .-.  \  `--, |  .-.  ||  '--'.'
// |  '--' /  `---.|  | |  ||  |\  \
// `------'`------'`--' `--'`--' '--'
//  ,---.   ,-----.   ,--. ,--.  ,---.  ,------.
// '   .-' '  .-.  '  |  | |  | /  O  \ |  .-.  \
// `.  `-. |  | |  |  |  | |  ||  .-.  ||  |  \  :
// .-'    |'  '-'  '-.'  '-'  '|  | |  ||  '--'  /
// `-----'  `-----'--' `-----' `--' `--'`-------'
//                      __
//                     [  |
//      .---.  __   _   | |.--.   .--.
//     / /'`\][  | | |  | '/'`\ \( (`\]
//     | \__.  | \_/ |, |  \__/ | `'.'.
//     '.___.' '.__.'_/[__;.__.' [\__) )

// ( ˘▽˘)っ♨ cooked by @nftchef

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "./rewardToken.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// ERC20 $TOYS Token Interface
interface IRewardToken {
    function spend(address _from, uint256 _amount) external;

    function balanceOf(address _address) external returns (uint256);

    function getTotalClaimable(address _address) external;

    function updateReward(
        address _from,
        address _to,
        uint256 _qty
    ) external;
}

contract Offspring is ERC721, Ownable, Pausable, ReentrancyGuard {
    using Strings for uint256;
    using ECDSA for bytes32;

    uint256 public BREED_PRICE = 400 ether; // 400 $TOYS
    uint256 public NAMING_PRICE;

    string internal baseTokenURI;
    bool public NAMING_OPEN;
    address internal _SIGNER;

    IRewardToken public RewardToys;

    enum ROOMS {
        FIRE,
        WATER,
        EARTH,
        AIR
    }

    struct Room {
        uint256 startIndex;
        uint256 supply;
        uint256 count;
    }

    mapping(ROOMS => Room) public supply;

    address private _treasury = 0x8fBc1fB5fd267aFefF5cc4e69b3ca6D41567dc01;

    event BabyNamed(uint256 tokenId, string name, address parent);

    modifier hasSignature(bytes32 _hash, bytes memory _signature) {
        require(checkHash(_hash, _signature), "Invalid Signature");
        _;
    }

    constructor(IRewardToken _rewardTokenAddress)
        payable
        ERC721("Teddy Bear Squad Cubs", "TBSC")
        Pausable()
    {
        RewardToys = IRewardToken(_rewardTokenAddress);

        baseTokenURI = "https://teddybearsquad.io/babydata/";

        // Set the starting supply

        //                   start init.supply  mint counter
        //                       \     ┃       /
        //                        v    v     v
        supply[ROOMS.FIRE] = Room(0, 500, 0);
        supply[ROOMS.WATER] = Room(5000, 500, 0);
        supply[ROOMS.EARTH] = Room(10000, 500, 0);
        supply[ROOMS.AIR] = Room(15000, 500, 0);
    }

    /**
     * @notice Retrieve a rooms current state.
     * @param _room The Enum Index for a given room to return
     */
    function getRoom(ROOMS _room) public view returns (Room memory room) {
        return supply[_room];
    }

    /**
     * @notice Multiple mint wrapper for breed(). Breeding from the contract
     * is disabled.
     */
    function breedMultiple(
        ROOMS _room,
        uint256 _quantity,
        bytes32 _hash,
        bytes memory _signature
    ) public nonReentrant whenNotPaused hasSignature(_hash, _signature) {
        require(
            RewardToys.balanceOf(msg.sender) >= BREED_PRICE * _quantity,
            "Not Enough $TOYS"
        );
        require(
            supply[_room].count + _quantity <= supply[_room].supply,
            "Quantity exeeds available supply"
        );
        for (uint256 i = 0; i < _quantity; i++) {
            uint256 tokenID = supply[_room].startIndex +
                supply[_room].count +
                i;

            _safeMint(msg.sender, tokenID, "");
        }
        supply[_room].count += _quantity;
        RewardToys.spend(msg.sender, BREED_PRICE * _quantity);
    }

    /**
     * @notice breeding (minting) from the contract is disabled.
     */
    function breed(
        ROOMS _room,
        bytes32 _hash,
        bytes memory _signature
    ) public nonReentrant whenNotPaused hasSignature(_hash, _signature) {
        require(
            supply[_room].count < supply[_room].supply,
            "No Tokens available in room"
        );
        // Will revert if msg.sender balance is below burn amount, totalPrice
        RewardToys.spend(msg.sender, BREED_PRICE);

        uint256 tokenID = supply[_room].startIndex + supply[_room].count;

        supply[_room].count++;
        _safeMint(msg.sender, tokenID, "");
    }

    /**
     * @notice name a given baby. Naming from the contract is disabled
     * @param _tokenId the Baby to name
     * @param _name a String name to name the baby. Name limtations are controlled via the dapp.
     * @param _hash valid hash
     * @param _signature valid signature
     */
    function nameBaby(
        uint256 _tokenId,
        string memory _name,
        bytes32 _hash,
        bytes memory _signature
    ) external hasSignature(_hash, _signature) {
        require(NAMING_OPEN, "Naming  is Closed");
        require(
            ownerOf(_tokenId) == msg.sender,
            "Only the baby's parent can name the baby"
        );
        // Will revert if msg.sender balance is below burn amount, totalPrice
        RewardToys.spend(msg.sender, NAMING_PRICE);
        emit BabyNamed(_tokenId, _name, msg.sender);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), '"ERC721Metadata: tokenId does not exist"');

        return string(abi.encodePacked(baseTokenURI, tokenId.toString()));
    }

    function senderMessageHash() internal view returns (bytes32) {
        bytes32 message = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(address(this), msg.sender))
            )
        );
        return message;
    }

    function checkHash(bytes32 _hash, bytes memory _signature)
        internal
        view
        returns (bool)
    {
        bytes32 senderHash = senderMessageHash();
        if (senderHash != _hash) {
            return false;
        }
        return _hash.recover(_signature) == _SIGNER;
    }

    // ｡☆✼★━━━━━━━━ ( ˘▽˘)っ♨  only owner ━━━━━━━━━━━━━★✼☆｡

    function setSigner(address _address) external onlyOwner {
        _SIGNER = _address;
    }

    function setRewardTokenAddress(address _rAddress) external onlyOwner {
        RewardToys = IRewardToken(_rAddress);
    }

    function setPaused(bool _state) external onlyOwner {
        _state ? _pause() : _unpause();
    }

    function setBaseURI(string memory _URI) external onlyOwner {
        baseTokenURI = _URI;
    }

    /**
     * @dev Tokens have a hard coded maximum tokenID range. Given that a new supply
     * number is <= the allocated range, the owner may increase the suppply for a
     * given ROOM
     * @param _room the ROOMS enum index to update
     * @param _supply the new supply to set
     */
    function updateRoomSupply(ROOMS _room, uint256 _supply) external onlyOwner {
        require(_supply > supply[_room].supply, "Supply can not decraese");
        // Calculate the poossible max
        uint256 ceiling;
        // 3 is the last room.
        if (uint256(_room) == 3) {
            ceiling = 20000;
        } else {
            ceiling = supply[ROOMS(uint256(_room) + 1)].startIndex;
        }
        require(
            supply[_room].startIndex + _supply <= ceiling,
            "Above token ceiling"
        );
        supply[_room].supply = _supply;
    }

    /**
     * @notice Change the $TOYS price per/mint (breeding).
     */
    function updatePrice(uint256 _price) external onlyOwner {
        BREED_PRICE = _price;
    }

    function setNamingState(bool _state) external onlyOwner {
        NAMING_OPEN = _state;
    }

    function setNamingPrice(uint256 _price) external onlyOwner {
        NAMING_PRICE = _price;
    }

    /// Nobody should be sending any ether to this contract, but just in case..
    function withdraw() external onlyOwner {
        (bool success, ) = _treasury.call{value: address(this).balance}("");
        require(success, "Failed to send to vault.");
    }
}