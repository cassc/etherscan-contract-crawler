// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IGems.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract BallerChains is ERC721, Ownable {

    /**

     _______  ________ __    __      _______   ______  __       __       ________ _______
    |       \|        \  \  |  \    |       \ /      \|  \     |  \     |        \       \
    | ▓▓▓▓▓▓▓\ ▓▓▓▓▓▓▓▓ ▓▓\ | ▓▓    | ▓▓▓▓▓▓▓\  ▓▓▓▓▓▓\ ▓▓     | ▓▓     | ▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓\
    | ▓▓__/ ▓▓ ▓▓__   | ▓▓▓\| ▓▓    | ▓▓__/ ▓▓ ▓▓__| ▓▓ ▓▓     | ▓▓     | ▓▓__   | ▓▓__| ▓▓
    | ▓▓    ▓▓ ▓▓  \  | ▓▓▓▓\ ▓▓    | ▓▓    ▓▓ ▓▓    ▓▓ ▓▓     | ▓▓     | ▓▓  \  | ▓▓    ▓▓
    | ▓▓▓▓▓▓▓\ ▓▓▓▓▓  | ▓▓\▓▓ ▓▓    | ▓▓▓▓▓▓▓\ ▓▓▓▓▓▓▓▓ ▓▓     | ▓▓     | ▓▓▓▓▓  | ▓▓▓▓▓▓▓\
    | ▓▓__/ ▓▓ ▓▓_____| ▓▓ \▓▓▓▓    | ▓▓__/ ▓▓ ▓▓  | ▓▓ ▓▓_____| ▓▓_____| ▓▓_____| ▓▓  | ▓▓
    | ▓▓    ▓▓ ▓▓     \ ▓▓  \▓▓▓    | ▓▓    ▓▓ ▓▓  | ▓▓ ▓▓     \ ▓▓     \ ▓▓     \ ▓▓  | ▓▓
     \▓▓▓▓▓▓▓ \▓▓▓▓▓▓▓▓\▓▓   \▓▓     \▓▓▓▓▓▓▓ \▓▓   \▓▓\▓▓▓▓▓▓▓▓\▓▓▓▓▓▓▓▓\▓▓▓▓▓▓▓▓\▓▓   \▓▓

     _______  ______ _______       ________ __    __ ________
    |       \|      \       \     |        \  \  |  \        \
    | ▓▓▓▓▓▓▓\\▓▓▓▓▓▓ ▓▓▓▓▓▓▓\     \▓▓▓▓▓▓▓▓ ▓▓  | ▓▓ ▓▓▓▓▓▓▓▓
    | ▓▓  | ▓▓ | ▓▓ | ▓▓  | ▓▓       | ▓▓  | ▓▓__| ▓▓ ▓▓__
    | ▓▓  | ▓▓ | ▓▓ | ▓▓  | ▓▓       | ▓▓  | ▓▓    ▓▓ ▓▓  \
    | ▓▓  | ▓▓ | ▓▓ | ▓▓  | ▓▓       | ▓▓  | ▓▓▓▓▓▓▓▓ ▓▓▓▓▓
    | ▓▓__/ ▓▓_| ▓▓_| ▓▓__/ ▓▓       | ▓▓  | ▓▓  | ▓▓ ▓▓_____
    | ▓▓    ▓▓   ▓▓ \ ▓▓    ▓▓       | ▓▓  | ▓▓  | ▓▓ ▓▓     \
     \▓▓▓▓▓▓▓ \▓▓▓▓▓▓\▓▓▓▓▓▓▓         \▓▓   \▓▓   \▓▓\▓▓▓▓▓▓▓▓

     _______  __        ______   ______  __    __  ______  __    __  ______  ______ __    __
    |       \|  \      /      \ /      \|  \  /  \/      \|  \  |  \/      \|      \  \  |  \
    | ▓▓▓▓▓▓▓\ ▓▓     |  ▓▓▓▓▓▓\  ▓▓▓▓▓▓\ ▓▓ /  ▓▓  ▓▓▓▓▓▓\ ▓▓  | ▓▓  ▓▓▓▓▓▓\\▓▓▓▓▓▓ ▓▓\ | ▓▓
    | ▓▓__/ ▓▓ ▓▓     | ▓▓  | ▓▓ ▓▓   \▓▓ ▓▓/  ▓▓| ▓▓   \▓▓ ▓▓__| ▓▓ ▓▓__| ▓▓ | ▓▓ | ▓▓▓\| ▓▓
    | ▓▓    ▓▓ ▓▓     | ▓▓  | ▓▓ ▓▓     | ▓▓  ▓▓ | ▓▓     | ▓▓    ▓▓ ▓▓    ▓▓ | ▓▓ | ▓▓▓▓\ ▓▓
    | ▓▓▓▓▓▓▓\ ▓▓     | ▓▓  | ▓▓ ▓▓   __| ▓▓▓▓▓\ | ▓▓   __| ▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓ | ▓▓ | ▓▓\▓▓ ▓▓
    | ▓▓__/ ▓▓ ▓▓_____| ▓▓__/ ▓▓ ▓▓__/  \ ▓▓ \▓▓\| ▓▓__/  \ ▓▓  | ▓▓ ▓▓  | ▓▓_| ▓▓_| ▓▓ \▓▓▓▓
    | ▓▓    ▓▓ ▓▓     \\▓▓    ▓▓\▓▓    ▓▓ ▓▓  \▓▓\\▓▓    ▓▓ ▓▓  | ▓▓ ▓▓  | ▓▓   ▓▓ \ ▓▓  \▓▓▓
     \▓▓▓▓▓▓▓ \▓▓▓▓▓▓▓▓ \▓▓▓▓▓▓  \▓▓▓▓▓▓ \▓▓   \▓▓ \▓▓▓▓▓▓ \▓▓   \▓▓\▓▓   \▓▓\▓▓▓▓▓▓\▓▓   \▓▓

    **/

    // RGV2YmVycnkjNDAzMCB3YXMgaGVyZQ==

    using Strings for uint256;

    mapping(uint => uint256) public burnedGems;

    // uint256s
    uint256 public _actualSupply = 0;

    // Addresses
    address public _gemsAddress = 0x2780086Dd9eF2589750BA1eEa901123ab84d1f10;

    bool public _paused = true;

    string private _baseTokenURI = "https://api.quandefi.io/go/ballerchain/";

    constructor() ERC721("BallerChains", "BC") {}

    /**
     * @dev Mint with Gem Ids
     */

    function mint(uint256[] calldata _tokenIds) public {
        require(_actualSupply<500,"MAX_MINTED");
        require(!_paused||Ownable.owner()==msg.sender,"PAUSED");
        require(_tokenIds.length == 10,"TEN_GEMS_REQUIRED");
        uint256 tokenId = _actualSupply;
        IGems gemsContract = IGems(_gemsAddress);
        _actualSupply += 1;
        require(tx.origin == msg.sender);
    unchecked {
        uint256 pack = 0;
        for (uint256 i; i < 10; i++) {
            require(gemsContract.ownerOf(_tokenIds[i])==msg.sender,"NOT_GEM_OWNER");
            pack <<= 16;
            pack |= _tokenIds[i];
            gemsContract.burn(_tokenIds[i]);
        }
        burnedGems[tokenId] = pack;
        _mint(msg.sender,tokenId);
    }
    }

    function togglePauseStatus() external onlyOwner {
        _paused = !_paused;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata newBaseTokenURI) public onlyOwner {
        _baseTokenURI = newBaseTokenURI;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId),"TOKEN_NOT_MINTED");
        uint256 pack = burnedGems[_tokenId];
        return string(abi.encodePacked(_baseTokenURI,
            _tokenId.toString(),"_",
            ((pack >> 144) & 0xffff).toString(),"_",
            string(abi.encodePacked(
                ((pack >> 128) & 0xffff).toString(),"_",
                ((pack >> 112) & 0xffff).toString(),"_",
                ((pack >>  96) & 0xffff).toString(),"_",
                ((pack >>  80) & 0xffff).toString(),"_",
                ((pack >>  64) & 0xffff).toString(),"_",
                ((pack >>  48) & 0xffff).toString(),"_",
                ((pack >>  32) & 0xffff).toString(),"_",
                ((pack >>  16) & 0xffff).toString(),"_",
                ((pack       ) & 0xffff).toString()
            )))
        );
    }

}