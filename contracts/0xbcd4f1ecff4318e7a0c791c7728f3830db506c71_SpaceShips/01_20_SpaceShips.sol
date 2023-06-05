// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.0;

import "./ERC721PresetMinterPauser.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SpaceShips is ERC721PresetMinterPauser, Ownable {
    bytes32 public constant MODEL_CREATOR_ROLE =
        keccak256("MODEL_CREATOR_ROLE");

    mapping(uint256 => uint256) public nextId;
    mapping(uint256 => uint256) public supply;

    uint32 public constant ID_TO_MODEL = 1000000;
    event NewModel(uint256 id, uint256 maxSupply);

    constructor()
        public
        ERC721PresetMinterPauser(
            "cometh spaceships",
            "SPACESHIP",
            "https://nft.service.cometh.io/"
        )
    {}

    function newModel(uint256 id, uint256 maxSupply) external {
        require(
            hasRole(MODEL_CREATOR_ROLE, _msgSender()),
            "SpaceShips: require model creator role"
        );
        require(maxSupply <= ID_TO_MODEL, "SpaceShips: max supply too high");
        require(supply[id] == 0, "SpaceShips: model already exist");

        supply[id] = maxSupply;
        NewModel(id, maxSupply);
    }

    function mint(address to, uint256 model) public override {
        require(supply[model] != 0, "SpaceShips: does not exist");
        require(nextId[model] < supply[model], "SpaceShips: sold out");
        uint256 tokenId = model * ID_TO_MODEL + nextId[model];
        nextId[model]++;
        super.mint(to, tokenId);
    }
}