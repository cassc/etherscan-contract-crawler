//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "contracts/MinterRole.sol";
import "./interfaces/ISBT721.sol";

contract EQ8_SBT is ERC721, MinterRole {
    address public owner;
    address public baptContract;

    struct sbt {
        uint256 MembershipID;
        string Status;
        string WalletType;
    }

    uint256 public SBT_ID = 1;
    mapping(uint256 => sbt) public sbtInfo;
    mapping(address => uint256) public userSbtID;
    mapping(address => sbt) public userSbtInfo;
    event SBT_mint(address minter, address receiver, uint256 SBT_ID);
    event SBT_burn(uint256 SBT_ID);

    constructor() ERC721("EQ8_SoulBoundToken", "EQ8_SBT") {
        owner = msg.sender;
    }

    function mint(address _to, sbt memory self)
        external
        onlyMinter(_msgSender())
    {
        _mint(_to, SBT_ID);

        userSbtID[_to] = SBT_ID;
        sbtInfo[SBT_ID] = self;
        userSbtInfo[_to] = self;

        emit SBT_mint(owner, _to, SBT_ID);
        SBT_ID++;
    }

    function burn(uint256 _sbtId) external onlyMinter(_msgSender()) {
        _burn(_sbtId);
        emit SBT_burn(_sbtId);
    }

    function _transfer(
        address from,
        address to,
        uint256 _sbtId
    ) internal override {
        require(false, "NON-transferable");
        super._transfer(from, to, _sbtId);
    }
}