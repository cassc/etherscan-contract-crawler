// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Farmable} from "./Farmable.sol";
import {Chicken, Egg} from "./Farm.sol";

import {ERC721} from "openzeppelin/token/ERC721/ERC721.sol";
import {Strings} from "openzeppelin/utils/Strings.sol";
import {Base64} from "openzeppelin/utils/Base64.sol";

//
// ┌┬┐┬ ┬┌─┐  ┬┌┐┌┌─┐┬ ┬┌┐ ┌─┐┌┬┐┌─┐┬─┐
//  │ ├─┤├┤   │││││  │ │├┴┐├─┤ │ │ │├┬┘
//  ┴ ┴ ┴└─┘  ┴┘└┘└─┘└─┘└─┘┴ ┴ ┴ └─┘┴└─
//
//       Farmhand - Malone Hedges
//
contract Incubator is ERC721, Farmable {
    event ChickenAdded(address indexed farmer, uint256 indexed chicken);
    event IncubatorOpen();
    event EggAdded(address indexed holder, uint256 indexed egg);
    event IncubatorSealed();
    event ChickenHatched(
        uint256 indexed egg,
        uint256 indexed chicken,
        address indexed hatcher
    );
    event EggRemoved(address indexed holder, uint256 indexed egg);

    uint256 public chicken;
    uint256[] public incubatedEggs;
    address public hatcher;

    uint256 public incubatorOpenTime;
    uint256 public constant incubatorOpenDuration = 3 days;
    uint256 public incubatorSealedTime;
    uint256 public constant incubationDuration = 7 days;
    uint256 public chickenHatchedTime;

    Chicken public immutable chickenContract;
    Egg public immutable eggContract;

    constructor(address _chicken, address _egg)
        ERC721("The Incubator", "NQB8")
    {
        chickenContract = Chicken(_chicken);
        eggContract = Egg(_egg);
    }

    function addChicken(uint256 _chicken) public onlyFarmer {
        require(chicken == 0, "already have a chicken");
        require(incubatorOpenTime == 0, "only one chicken");

        chickenContract.transferFrom(msg.sender, address(this), _chicken);
        chicken = _chicken;
        emit ChickenAdded(farmer, chicken);

        incubatorOpenTime = block.timestamp;
        emit IncubatorOpen();
    }

    function incubateEgg(uint256 _eggId) external {
        // chicken comes before the egg
        require(chicken != 0, "no chicken");
        require(
            block.timestamp < incubatorOpenTime + incubatorOpenDuration,
            "you can't incubate your egg anymore"
        );

        eggContract.transferFrom(msg.sender, address(this), _eggId);
        _mint(msg.sender, _eggId);
        incubatedEggs.push(_eggId);
        emit EggAdded(msg.sender, _eggId);
    }

    function sealIncubator() external {
        require(chicken != 0, "no chicken");
        require(
            block.timestamp >= incubatorOpenTime + incubatorOpenDuration,
            "you can't seal the incubator yet"
        );
        require(incubatorSealedTime == 0, "incubator already sealed");

        incubatorSealedTime = block.timestamp;
        emit IncubatorSealed();
    }

    function hatchChicken() external {
        require(incubatorSealedTime != 0, "incubator not sealed yet");
        require(
            block.timestamp > incubatorSealedTime + incubationDuration,
            "incubation isn't finished yet"
        );
        require(incubatedEggs.length > 0, "no eggs to hatch");
        require(chicken != 0, "the chicken already hatched");

        uint256 fertilizedEggIndex = _getWinningEgg();
        uint256 fertilizedEgg = incubatedEggs[fertilizedEggIndex];
        address incubatedEggHolder = ownerOf(fertilizedEgg);

        eggContract.burn(fertilizedEgg);
        _burn(fertilizedEgg);
        uint256 _chicken = chicken;
        chickenContract.transferFrom(
            address(this),
            incubatedEggHolder,
            _chicken
        );
        hatcher = incubatedEggHolder;
        chicken = 0;

        chickenHatchedTime = block.timestamp;
        emit ChickenHatched(fertilizedEgg, _chicken, incubatedEggHolder);
    }

    function removeEgg(uint256 _eggId) external {
        require(incubatorSealedTime != 0, "incubator not sealed yet");
        require(
            block.timestamp > incubatorSealedTime + incubationDuration,
            "incubation period is not over"
        );
        require(ownerOf(_eggId) == msg.sender, "not your egg");

        _burn(_eggId);
        eggContract.transferFrom(address(this), msg.sender, _eggId);

        emit EggRemoved(msg.sender, _eggId);
    }

    function eggCount() external view returns (uint256) {
        return incubatedEggs.length;
    }

    function _getWinningEgg() internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(chicken, block.timestamp, block.basefee)
                )
            ) % incubatedEggs.length;
    }

    // farmer functions

    function rescueChicken() external onlyFarmer {
        require(chicken != 0, "no chicken");
        require(incubatorSealedTime != 0, "incubator not sealed yet");
        require(
            block.timestamp > incubatorSealedTime + incubationDuration,
            "incubation isn't finished yet"
        );
        require(
            incubatedEggs.length == 0,
            "can't rescue if any eggs were incubated"
        );

        chickenContract.transferFrom(address(this), msg.sender, chicken);
        chicken = 0;
    }

    // token

    string[3] public uris;

    function setURIs(string[3] memory _uris) external onlyFarmer {
        uris = _uris;
    }

    function imageURI() public view virtual returns (string memory) {
        if (incubatorSealedTime == 0) {
            return uris[0];
        }

        if (chicken != 0) {
            return uris[1];
        }

        return uris[2];
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        _requireMinted(tokenId);

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        "{",
                        '"name": "The Incubator ',
                        Strings.toString(tokenId),
                        '",',
                        '"description": "Just wait.",',
                        '"image": "',
                        imageURI(),
                        '"}'
                    )
                )
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", json));
    }
}