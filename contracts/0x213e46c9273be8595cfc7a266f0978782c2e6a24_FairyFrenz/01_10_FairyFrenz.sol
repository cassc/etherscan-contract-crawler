// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// @author: donatell0.wtf for ze FairyFrenz 
// "Anon, get me out of here! "

/*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#BBBBB##########&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#BBBBBBBBBBBBBBBBBBBBBB#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#BBBBBBBBBBBBBBBBBBBBBBBBBB#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#BBBBBBBBBBBBBBBBBBBBBBBBBBBBBB#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&##&#BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@G?YB&BBBBBBBBBBBBBBBB###&BBBBBBBBBBB&@@@@@@@&&@@@@@@@@@@#B&@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@##&J?#G##BBBBBBBBBBB##@PJ##BBBBBBBBBBBB&@@@@@@#[email protected]@@@@@@[email protected]@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@&BB##G&7?#&BBBBBBBB#&5JBBB&BB######BBBBB#@@@@@@@[email protected]@@@@P~J&@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@#BBBB&&JJ#P&BBBBB#B5#J?P&&##P?!^5J75#[email protected]@@@@@@&[email protected]@@@@?7&@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@#BBBBB###@Y#&B##@B??#B#&&BJ^:!JYBY! 7&[email protected]@@@@@@&[email protected]@@@@[email protected]@@@@@@@@@@@@@
@@@@@@@@@@@@@@@&&@@@@@@@@@@&BBBBBBB&G?~~!7!?G&####B#P.:Y&@@@@@@P~##[email protected]@@@@@@&[email protected]@@@&G&@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@&&@@@@@@@@@@#BBBBBB&? ^5B#&B? 5&BBBB#5J#@@@@&##PG&#BB#@@@@@@@&GB&@@@#G&@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@&&@@@@@@@@@@#[email protected]?#@@@@@@GB#BBBBB#B?JJ?!~^^[email protected]@@@@@@@@@@
@@@@@@@@@@@@@@&&@@@&&&&&&@&BBBBBBBBBB########BBBBBBBBB#BGGBY7?B!.................Y!.:::^[email protected]&@@@@@@@@@
@@@@@@@@@@@@@@&&&#BBBBBBB&#BBBBBBBBBBBBBBBBBBBBBBBBBBBBBB#G^^~P:..:::::::........5^::::!#BBB#&@@@@@@
@@@@@@@@@@@@@&&&BBBBBBBB&#BBBBB#&&&&&&&&&&&&&&&&&###BBBBB&Y^^:JJ...............:J#J^:::Y&BBBBBB#&&@@
@@@@@@@@@&@&@&&BBB&&&&##&BBBBB&@@@&&&&&&&&&&&&@@@@@@&&&&@&!^^^^J?Y7JJ????????77JJ!^:::~##BBBBBBBBBB#
@@@@@@&##&&&&&&BBB#BBB&&BBBB#@@&&&&&&&&&&&&&&&&&&&&&&&&&@5^^^^^::~J~^^^:::..^[email protected]
@@@&#BB&&&@&&&#BBBBBBB&#BBB&@&&&&&&&&&&&&&&&&&@@&&&@@@@&&!^^^^^:::.........~P7!YGG777!P&BBBBBBBBBBBB
&#BBB#&&&&&BBBBBBBBBBB&BBB&@@&&&&&&&@@&&&&&&&@B#@&&#BGPGP^^^^^^:::::.....7Y?~:7G?#!::^##BBBBBBBBBBBB
BBBB#&&&&[email protected]#&&@@@@@@5~#@@@@@@#.~&5YJYPB&7^^^^^^:::::....~P~::7#JY&~^:7&BBBBBBBBBBBBB
BBBB#&#BBBBBBBBBBBBBBB&&BBBBBB##&B#? !#B###B#P:~#GGB###5^~^^^^^:::::...:P!^^^!YJY?^^:5&BBBBBBBBBBBBB
BBBBBBBBBBBBBBBBBBBBBBB#&&##BBBBBB#5JBBPGGGBB#B#BBBBBB#!~~^^^^^:::::...^[email protected]#BBBBBBBBBBBBB
BBBBBBBBBBB#BBBBBBBBBBBBBBB##&##BBBBBBBBBBBBBBBBBBB##&5~~~^^^^::::::..........:::^^^[email protected]#BBBBBBBBBBBBB
BBBBBBBBBBBBBBBBBBBBBBBBBBBBBB#&&#BBBBBBBBBBBBBB&&####!~~^^~~~~^^::.::..........::^^[email protected]#BBBBBBBBBBBBB
BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB#&##BBBBBBBB#&&#BBB#5~~~JJ?777775Y??7777!J~7777?7^^~&&BBBBBBBBBBBBB
BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB####&###&##BBBBB&7~~5?     .JJ5~   . !BP~...:57^~#&BBBBBBBBBBBBB
BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB&7^!G.   .!Y!57 ..  ^PPJ     Y?^~#&BBBBBBBBBB#BB
BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB##5??GJ!!7!..!!777!!J^^[email protected]
BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB#BBBBBBBBBBBBB##G#Y!~^^^^^^^^^^^^^^~!!?#B5PB#BBBBBBBBBBBBBBB
BBBBBBBBBBBBBBBB#&BBBBBBBB&&BBBBBBBBBBBBBBBBBBB##&#BBBBBBBB#&&#[email protected]#BBBBBBBBBBB
BBBBBBBBBBBBBBBB&&BBBBBBBBB#BBBBBBBBBBBBBBB##&&##BBBBBBBBBBBB##&#BBBBBBBBBBBBBBBBBBBBB&@#BBBBBBBBBBB
BBBBBBBBBBBBBBBB&@#BBBBBBBBBBBBBBBBBBGG WWWTTTTTTTTFFFFF GGBBBBBBB#BBBBBBBBBBBBBBBBBB&@&#BBBBBBBBB*/

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "hardhat/console.sol";

error PublicSaleNotLive();
error WhitelistNotLive();
error ExceededLimit();
error NotEnoughTokensLeft();
error WrongEther();
error InvalidMerkle();
error Paused();
error BankNotSet();

contract FairyFrenz is ERC721A, Ownable {
    using Address for address;
    using MerkleProof for bytes32[];
    using Strings for uint256;

    bytes32 public merkleRoot;
    uint256 public maxMints = 333;
    uint256 public whiteListMaxMints = 333;
    uint256 public maxSupply = 3333;
    uint256 public whiteListRate = 0.0333 ether;
    uint256 public mintRate = 0.0666 ether;
    string public baseExtension = ".json";
    string public baseURI = "";
    uint256 public mintPhase;
    bool public paused = false;
    address public zeBank = 0x0000000000000000000000000000000000000000;

    mapping(address => uint256) public whiteListUsedAddresses;
    mapping(address => uint256) public usedAddresses;

    constructor() ERC721A("FairyFrenz", "FFZ") {}

    function gm(uint256 quantity) external payable {

        if(paused) revert Paused();

        if (mintPhase != 2) revert PublicSaleNotLive();

        if (totalSupply() + quantity > maxSupply) {
            revert NotEnoughTokensLeft();
        }

        if (mintRate * quantity != msg.value) {
            revert WrongEther();
        }

        if (quantity + usedAddresses[msg.sender] > maxMints) {
            revert ExceededLimit();
        }

        if (zeBank == 0x0000000000000000000000000000000000000000) {
            revert BankNotSet();
        }

        (bool sent, /* bytes memory data */) = payable(zeBank).call{value: msg.value}("");
        require(sent, "Failed to transfer ETH to ze Bank!");

        usedAddresses[msg.sender] += quantity;
        _mint(msg.sender, quantity);
    }

    function gmairy(uint256 quantity, bytes32[] calldata proof)
        external
        payable
    {
        if(paused) revert Paused();

        if (mintPhase != 1) revert WhitelistNotLive();

        if (!isWhiteListed(msg.sender, proof)) revert InvalidMerkle();

        if (totalSupply() + quantity > maxSupply) {
            revert NotEnoughTokensLeft();
        }

        if (whiteListRate * quantity != msg.value) {
            revert WrongEther();
        }

        if (whiteListUsedAddresses[msg.sender] + quantity > whiteListMaxMints) {
            revert ExceededLimit();
        }

        if (zeBank == 0x0000000000000000000000000000000000000000) {
            revert BankNotSet();
        }

        (bool sent, /* bytes memory data */) = payable(zeBank).call{value: msg.value}("");
        require(sent, "Failed to transfer ETH to ze Bank!");

        _mint(msg.sender, quantity);
        whiteListUsedAddresses[msg.sender] += quantity;
    }

    function isWhiteListed(address _account, bytes32[] calldata _proof)
        public
        view
        returns (bool)
    {
        return _verify(leaf(_account), _proof);
    }

    function leaf(address _account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account));
    }

    function _verify(bytes32 _leaf, bytes32[] memory _proof)
        internal
        view
        returns (bool)
    {
        return MerkleProof.verify(_proof, merkleRoot, _leaf);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "token does not exist!");

        return
            string(
                abi.encodePacked(
                    baseURI,
                    _tokenId.toString(),
                    baseExtension
                )
            );
       
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function setMerkleRoot(bytes32 _root) public onlyOwner {
        merkleRoot = _root;
    }

    function setMintPhase(uint256 _phase) public onlyOwner {
        mintPhase = _phase;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setPaused(bool _paused) public onlyOwner {
        paused = _paused;
    }

    function callZeBankFirst(address _addr) public onlyOwner {
        zeBank = _addr;
    }
}