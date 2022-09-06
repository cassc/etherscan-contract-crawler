// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.13;

/* solhint-disable */
// -╖╖╖╖╖╖╖╖╖╖╖»─  ─┬╖╖╖╖─~  -╖╖╖╖╖╖╖╖╖╖╖»─    -╖╖╖╖╖╖╖╖╖╖»─   ~─╖╖╖╖╖╖╖╖╖╖╖~
//    ███   `███      ███▌      ███   `███      ┌▓██^ █ ╙██╗     á███^   ╔██
//    █B█     ███▌    █I█Γ      █B█     ███▌    █O█   █   ███▄   █S█▌    ███
//    ███    ╒███     ███Γ      ███    ╒███    ███    █    ███   ▀██▓    ██
//    ███   á██▀      ███Γ      ███   #██╜    ╞███    █    ███    `███▄  '█╕
//    ███▄▓██▄        ███Γ      ███▄▓██▄      ╞██▌    █    ███       ╙██╗  `
//    ███    "██▌     ███Γ      ███    "██▌   '██▌    █'   ███   ,╗█"   ▀██w
//   ▓███      ▓██    ████     ▓███      ███   ███    █   ┌██   ██        ███▓
//    ███      ▐███  ^╙███     └███      ╞███   ██╕   ╫   ██▌  ██          ███
//    █B█      â██▌    I▐█      █B█      ║██▌    █O┐  ║   █▀   ██          █S█
//    ███     #██`     ╓▓█      ███     #██`      └█▌ ║ ╣█     ║█ε        ╒███
//   ╔██▓╗╗@▀╝^        "╙██┐   á██▓╗╗@▀╨^           `▀██        '█╗     ,Æ██`
//                         "▀≥»-                      ╞            ^╙▀▀╜"
/* solhint-enable */

import {ERC721} from "solmate/tokens/ERC721.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {Render} from "libraries/Render.sol";

error InsufficentValue();
error MintedOut();
error InvalidTokenId();
error AmountNotAvailable();

contract Bibos is ERC721, Owned {
    /*//////////////////////////////////////////////////////////////
                                  STATE
    //////////////////////////////////////////////////////////////*/

    uint256 public constant price = .1 ether;
    uint256 public constant maxSupply = 1111;

    uint256 public totalSupply;
    mapping(uint256 => bytes32) public seeds; // (tokenId => seed)

    /*//////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier OnlyIfYouPayEnough(uint256 _amount) {
        if (msg.value != _amount * price) revert InsufficentValue();
        _;
    }

    modifier OnlyIfNotMintedOut() {
        if (totalSupply >= maxSupply) revert MintedOut();
        _;
    }

    modifier OnlyIfAvailableSupply(uint256 _amount) {
        if (_amount + totalSupply > maxSupply) revert AmountNotAvailable();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() ERC721("Bibos", "BIBO") Owned(msg.sender) {}

    /*//////////////////////////////////////////////////////////////
                                TOKENURI
    //////////////////////////////////////////////////////////////*/

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        if (_tokenId >= totalSupply) revert InvalidTokenId();
        bytes32 seed = seeds[_tokenId];

        return Render.tokenURI(_tokenId, seed);
    }

    /*//////////////////////////////////////////////////////////////
                                  MINT
    //////////////////////////////////////////////////////////////*/

    function mint() public payable OnlyIfNotMintedOut OnlyIfYouPayEnough(1) {
        _mint(msg.sender);
    }

    function mint(uint256 _amount)
        public
        payable
        OnlyIfNotMintedOut
        OnlyIfAvailableSupply(_amount)
        OnlyIfYouPayEnough(_amount)
    {
        for (; _amount > 0; ) {
            _mint(msg.sender);
            --_amount;
        }
    }

    /*//////////////////////////////////////////////////////////////
                                WITHDRAW
    //////////////////////////////////////////////////////////////*/

    function withdraw(address payable _to) public onlyOwner {
        _to.transfer(address(this).balance);
    }

    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/

    function _mint(address _to) internal {
        uint256 tokenId = totalSupply++;
        seeds[tokenId] = _seed(tokenId);
        ERC721._mint(_to, tokenId);
    }

    function _seed(uint256 _tokenId) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(msg.sender, block.timestamp, _tokenId));
    }
}