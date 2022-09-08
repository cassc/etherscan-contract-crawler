// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract Keyo is ERC721, ERC721Enumerable, Pausable, Ownable {
    // ===== 1. Property Variables ==== = //
    struct GameData {
        uint256 game;
        uint256 rank;
        string name;
        string image;
    }

    mapping(uint256 => GameData) private tokenIdToGame;

    mapping(bytes => uint8) private usedSignatures;

    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    uint256[] public games;

    uint256 public INCREMENT_PRICE = 0.01 ether;

    // ===== 2. Lifecycle Methods ===== //

    constructor() ERC721("Keyo", "KYO") {
        games.push(0);
    }

    function withdraw() public onlyOwner {
        require(address(this).balance > 0, "Balance is zero");
        payable(owner()).transfer(address(this).balance);
    }

    // ===== 3. Pauseable Functions ===== //

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // ===== 3. Mint Functions ===== //

    function safeMint(
        bytes32 _hash,
        string memory _name,
        string memory _image,
        bytes memory _signature,
        uint256 gameIdx
    ) public payable {
        // check if passed signature is signed by
        require(
            ECDSA.recover(ECDSA.toEthSignedMessageHash(_hash), _signature) ==
                owner(),
            "Verified signature does not match owners address"
        );
        require(usedSignatures[_signature] == 0, "Invalid signature. It has been used before.");
        
        // if new idx, then it'll be a free mint. if not, get current price
        uint256 price = gameIdx > games.length - 1 ? 0 : currentPrice();

        // Check if ether value is correct
        require(msg.value >= price, "Not enough ether sent.");

        // after checking valid ether sent, check if its a new game
        if (gameIdx > games.length - 1) {
            games.push(0);
        }

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        // updates num of winners for game
        games[games.length - 1]++;

        // updates metadata for specific tokenId
        tokenIdToGame[tokenId] = GameData(
            games.length - 1,
            games[games.length - 1],
            _name,
            _image
        );
        // makes this current signature unusable for future
        usedSignatures[_signature] = 1;

        _safeMint(msg.sender, tokenId);
    }

    function currentPrice() public view returns (uint256) {
        return 0 + (INCREMENT_PRICE * games[games.length - 1]);
    }

    function currentGameId() public view returns (uint) {
        return games.length - 1;
    }

    // ===== 5. Other Functions ===== //

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        GameData memory token = tokenIdToGame[tokenId];

        string memory name = token.game < games.length - 1 ? token.name : "?????";
        string memory image = string(abi.encodePacked("ipfs://",token.image));

        bytes memory dataURI = abi.encodePacked(
            "{",
            '"name": "',
            "Game ",
            Strings.toString(token.game),
            ": ",
            name,
            " #",
            Strings.toString(token.rank),
            '",',
            '"image": "',
            image,
            '",',
            '"attributes": [{"trait_type": "Rank", "value": ',
            Strings.toString(token.rank),
            "},",
            '{"trait_type": "Game Number", "value": ',
            Strings.toString(token.game),
            "}]",
            "}"
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(dataURI)
                )
            );
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}