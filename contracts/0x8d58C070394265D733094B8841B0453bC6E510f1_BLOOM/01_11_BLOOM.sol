// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

/* 
......................................................................................
.................................       ..............................................
..........................   ..:^^~~~~~^:.   .........................................
....................... .:!JPB#&&&&&&&&&&#P?^. .......     ...........................
.................... .:JB&&&&#BG5YJ??JY5G#&&&G~..  ..:^^~~^:..  ......................
................... :P&&&#P7~:...........:7G&&&5.^?P#&&&&&&&#B5!:. ...................
...................7&&&B7:..................7&&&#&&&#G5YJJ5PB&&&&G7. .................
................. !&&&P:.....................7&&&#5!:.......:^?G&&&#?. ...............
..................#&&B:.......................B&Y:..............^Y#&&#?. .............
................ ^&&&Y........................?!..................^Y&&&B^ ............
................ :&&&Y..............................................~B&&&! ...........
..................#&&B...............................................:G&&&~ ..........
................. J&&&7...............................................:#&&B...........
................  .B&&#^...............................................P&&&:..........
............. .:~JP#&&&#^.............................................:B&&#...........
........... .~P#&&&#BGPPY:..............:^^^^:.......................:P&&&! ..........
.......... :G&&&G?~:.................~YB#&&&&#G?^..................^?#&&#! ...........
......... ^#&&#!...................:P&&#Y!^^75&&#J..............:7P&&&&#^ ............
.........:#&&#^...................:G&&J       .P&&J.............:^!JG&&&#Y: ..........
........ Y&&&!....................~&&#  BLOOM  :&&#:.................^J#&&#! .........
.........B&&B:....................:#&&~        Y&&P....................:P&&&! ........
.........#&&B......................~B&&5~...:!B&&P:.....................:#&&B.........
.........G&&#:......................:?G&&&&&&&#P!.......................:#&&#.........
........ ~&&&P.........................:~!?7!~:.........................7&&&Y ........
..........?&&&G!:......................................................7&&&G..........
.......... ~G&&&B5?!^^::::^^~!:......................................:5&&&P...........
........... .^YB&&&&&&&&&#&&&5........................~7:..........:?#&&#?............
.............  .:~7JYPPPP#&&&^.........................P&GJ!~^^^!?P#&&#Y: ............
.................       .#&&G..........................^&&&&&&&&&&&&G?: ..............
........................:&&&5...........................G&&&555YJ7~:. ................
........................:&&&P...........................P&&#.      ...................
.........................B&&#:.........................:#&&G..........................
........................ !&&&5.........................P&&&~ .........................
..........................J&&&P^.....................~G&&&? ..........................
...........................7#&&#5!:.............:^!JB&&&G^ ...........................
........................... .?B&&&&BP5JJ???JJ5PG#&&&&#5~. ............................
............................. .^?PB#&&&&&&&&&&&&#G57^.  ..............................
...............................   ..:^~~~~~~^^:...   .................................
.....................................         ........................................
...................................................................................... 
*/

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BLOOM is ERC721, Ownable {
    using Strings for uint256;

    uint256 public constant maxSupply = 3003;
    uint256 private constant reservedAmount = 280;
    uint256 public BloomingStartTime;
    uint256 public tokenCounter;

    string private baseUri = "https://ymh.mypinata.cloud/ipfs/";
    string private baseExtension = ".json";

    mapping(uint256 => uint256) public timeOfLastTransfer;

    constructor() ERC721("BLOOM", "BLOOM") {
        BloomingStartTime = block.timestamp;
    }

    function airdropTokens(
        address[] calldata listOfAddresses,
        uint256[] calldata Ids
    ) external onlyOwner {
        require(tokenCounter + Ids.length <= maxSupply, "max Supply reached");
        tokenCounter = tokenCounter + Ids.length;
        for (uint256 i = 0; i < listOfAddresses.length; i++) {
            _mint(listOfAddresses[i], Ids[i]);
        }
    }

    /**
      @dev resets Blooming time on Tokentransfer
     */
    function _beforeTokenTransfer(
        address,
        address,
        uint256 tokenId
    ) internal virtual override {
        timeOfLastTransfer[tokenId] = block.timestamp;
    }

    function getBloomingTime(uint256 tokenId) private view returns (uint256) {
        uint256 res;
        if (_exists(tokenId)) {
            if (timeOfLastTransfer[tokenId] > 0) {
                res = block.timestamp - timeOfLastTransfer[tokenId];
            } else {
                res = block.timestamp - BloomingStartTime;
            }
        }
        return res;
    }

    function getBloomingTimes(uint256[] calldata tokenIds)
        external
        view
        returns (uint256[] memory)
    {
        uint256 resLength = tokenIds.length;
        uint256[] memory tokenIDsTimes = new uint256[](resLength);
        for (uint256 i = 0; i < resLength; i++) {
            tokenIDsTimes[i] = getBloomingTime(tokenIds[i]);
        }
        return tokenIDsTimes;
    }

    function setBaseExtension(string memory newBaseExtension)
        external
        onlyOwner
    {
        baseExtension = newBaseExtension;
    }

    function setBaseUri(string memory newBaseUri) external onlyOwner {
        baseUri = newBaseUri;
    }

    function setBloomingStartTime(uint256 newBloomingStartTime)
        external
        onlyOwner
    {
        BloomingStartTime = newBloomingStartTime;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        string memory _tokenURI = "Token with that ID does not exist.";
        if (_exists(tokenId)) {
            _tokenURI = string(
                abi.encodePacked(baseUri, tokenId.toString(), baseExtension)
            );
        }
        return _tokenURI;
    }

    function totalSupply() public view returns (uint256) {
        return tokenCounter;
    }

    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;
        while (
            ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply
        ) {
            address currentTokenOwner = ownerOf(currentTokenId);
            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;
                ownedTokenIndex++;
            }
            currentTokenId++;
        }
        return ownedTokenIds;
    }
}