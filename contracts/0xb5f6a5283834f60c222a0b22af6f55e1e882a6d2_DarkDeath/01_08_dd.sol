//                                            .""--.._
//                                            []      `'--.._
//                                            ||__           `'-,
//                                          `)||_ ```'--..       \
//                      _                    /|//}        ``--._  |
//                   .'` `'.                /////}              `\/
//                  /  .""".\              //{///    
//                 /  /_  _`\\            // `||
//                 | |(_)(_)||          _//   ||
//                 | |  /\  )|        _///\   ||
//                 | |L====J |       / |/ |   ||
//                /  /'-..-' /    .'`  \  |   ||
//               /   |  :: | |_.-`      |  \  ||
//              /|   `\-::.| |          \   | ||
//            /` `|   /    | |          |   / ||
//          |`    \   |    / /          \  |  ||
//         |       `\_|    |/      ,.__. \ |  ||
//         /                     /`    `\ ||  ||
//        |           .         /        \||  ||
//        |                     |         |/  ||
//        /         /           |         (   ||
//       /          .           /          )  ||
//      |            \          |             ||
//     /             |          /             ||
//    |\            /          |              ||
//    \ `-._       |           /              ||
//     \ ,//`\    /`           |              ||
//      ///\  \  |             \              ||
//     |||| ) |__/             |              ||
//     |||| `.(                |              ||
//     `\\` /`                 /              ||
//        /`                   /              ||
//       /                     |              ||
//      |                      \              ||
//     /                        |             ||
//   /`                          \            ||
// /`                            |            ||
// `-.___,-.      .-.        ___,'            ||
//  DARK DEATH
//              DARK DEATH
//                              DARK DEATH


// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract DarkDeath is Ownable, ERC721A, ReentrancyGuard {
    using ECDSA for bytes32;

    uint256 public cost = 0.0044 ether;
    uint256 public maxSupply = 6666;
    uint256 public maxMintAmountPerTx = 5;

    bool public paused = true;
    bool public whitelistMintEnabled = false;

    string private baseMetadataUri;
    address private openSeaRegistryAddress;
    mapping(address => bool) private deathsMinion;
    mapping(address => uint) private mintedPerAddress;

    constructor() ERC721A('DarkDeath', 'DarkDeath') {}

    function addMinion(address a) public onlyOwner {
        deathsMinion[a] = true;
    }

    function removeMinion(address a) public onlyOwner {
        deathsMinion[a] = false;
    }

    modifier onlyMinions() {
        require(deathsMinion[_msgSender()], 'you are not deaths minion');
        _;
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
        require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
        _;
    }

    modifier mintPriceCompliance(uint256 _mintAmount) {
        uint256 realCost = cost * _mintAmount;

        if (balanceOf(_msgSender()) == 0){
            realCost -= cost;
        }

        require(msg.value >= realCost, 'Insufficient funds!');
        _;
    }

    function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
        require(!paused, 'The contract is paused!');
        _safeMint(_msgSender(), _mintAmount);
    }

    function mintWhitelist(bytes calldata proof) public mintCompliance(1) {
        require(isValidProof(_msgSender(), proof), "User has no valid proof");
        mintedPerAddress[_msgSender()] += 1;
        _safeMint(_msgSender(), 1);
    }

    function mintFromDeath(address a, uint quantity) public onlyMinions mintCompliance(quantity) {
        _safeMint(a, quantity);
    }

    function burnFromDeath(uint256 tokenId) public onlyMinions {
        require(_exists(tokenId), 'Token does not exist');
        _burn(tokenId);
    }

    function setBaseMetadataUri(string memory a) public onlyOwner {
        baseMetadataUri = a;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function withdraw() public onlyOwner nonReentrant {
    
        (bool os, ) = payable(owner()).call{value: address(this).balance}('');
        require(os);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseMetadataUri;
    }

    function isValidProof(address a, bytes memory proof) internal view returns (bool) {
        bytes32 data = keccak256(abi.encodePacked(a));
        return owner() == data.toEthSignedMessageHash().recover(proof);
    }

    function setOpenSeaRegistryAddress(address a) public onlyOwner {
        openSeaRegistryAddress = a;
    }

    function isApprovedForAll(address owner, address operator) public override view returns (bool) {
        ProxyRegistry openSeaRegistry = ProxyRegistry(openSeaRegistryAddress);

        if (address(openSeaRegistry.proxies(owner)) == operator) {
            return true;
        }

        if (deathsMinion[operator]) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }
}