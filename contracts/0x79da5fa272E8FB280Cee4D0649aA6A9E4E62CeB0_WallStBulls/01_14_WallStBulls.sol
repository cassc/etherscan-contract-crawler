// SPDX-License-Identifier: MIT
/****
__          __   _ _    _____ _                 _     ____        _ _
\ \        / /  | | |  / ____| |               | |   |  _ \      | | |
 \ \  /\  / /_ _| | | | (___ | |_ _ __ ___  ___| |_  | |_) |_   _| | |___
  \ \/  \/ / _` | | |  \___ \| __| '__/ _ \/ _ \ __| |  _ <| | | | | / __|
   \  /\  / (_| | | |  ____) | |_| | |  __/  __/ |_  | |_) | |_| | | \__ \
    \/  \/ \__,_|_|_| |_____/ \__|_|  \___|\___|\__| |____/ \__,_|_|_|___/
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXXKK0KKKXXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNX0OOkkxxxxxxkkOO0OONMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWN0kkxxxkOO000KKXXNNNNXk0MMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKOOKKdcokOOO00KKXXNNNNXXK0kKMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOxxkOKKkccdkOOKXNNNNNXK00O00KNMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0xxkO000KKKkoodOXNNNNXK0OOkkkO0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKxdOKK000000XXXXXNNXKK0OOkkkkxddoOWMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXKO0XXXK0KKXXNNWWWKOxdxkkkkkkkxdocoKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0kO000KNWWK0XXNNXKKKKXXNWWNNNX0xc:lxxxkkxdoolckWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOl;coxxxOXN0xkxdx0KKXXXNNNNXXK0OOOkoccc:loollc:xNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0o;;okO000KOooxxolcdKXXXXKKKKKOdooodkOxoloool,,;dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKd:;cdOOOO00xclk0Okxxod0K0OOOOOxlldoc:llcooxOOd;;kNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWOololdOOOxdxxloOXNNK0klclkOkkkkocod;.    .:oodocl0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKO00kdkOOxoxOdlkXNNXOkdlc;;oxkkd:co,.   ..,cllc:dXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNXOolooookNXdckKKOxolc;;:llldxl;lo' ..',;:::co0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0KKOxddxOOxxkkl,,cdoc,'.':okkddkxc;:ol,;lc;;;:d0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXdldxOKNWN0ddOKKd;;;;'..coxOOkkkkkdll:;,;;;;;lxKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWkoOXWMWXkxdkKXNXk:'..'';cloddddddoccc:,'.',lONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNNMMWXOdx0XXNN0o,';cc:,,',,,,,,,;;:::ccccoONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0xdxOKXNN0l;:dOXN0xoc;,:oxc;ldxkOKXNKKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKX0od0KKKKOdloOXNNNNXK0xddO0OxdO0000XX0KNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0ooold0K0xodkKXNNNXX0kkk00Odok00000000kd0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOkxlcx0KK0OOKKKKKKK0xokXWWx:cdO000OOOkxldXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKOo:dOKKKKKKKKKKKOddkKWMWOc:ldxxxdooc:cdKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWOllok0KKK0kxxxkxdokNMMMWXOxxddoc:;:ldOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWOcokOOkxxxdl:okkO0XWMMWXkddolc:cldOKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKllkkkxl:cdod0NMMMMMMMNOl;:codxOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk:cllc:cxXNOkXMMMMMMMMNOdk0NWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXxodddxOXWMMWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
*****/
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract WallStBulls is ERC721Enumerable, Ownable {
    uint256 public constant MAX_BULLS = 10000;
    uint256 public constant PRICE = 0.069 ether;
    uint256 public constant RESERVED_BULLS = 300;
    uint256 public constant MAX_MINT = 10;

    mapping(address => uint256) public totalMinted;
    string public baseURI;
    bool public baseURIFinal;
    bool public publicSaleActive;
    bool public presaleActive;

    bytes32 private _presaleMerkleRoot;


    event BaseURIChanged(string baseURI);
    event BullMint(address minter, uint256 mintCount);

    constructor(string memory _initialBaseURI) ERC721("Wall Street Bulls", "WSB")  {
        baseURI = _initialBaseURI;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        require(!baseURIFinal, "Base URL is unchangeable");
        baseURI = _newBaseURI;
        emit BaseURIChanged(baseURI);
    }

    function finalizeBaseURI() external onlyOwner {
        baseURIFinal = true;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function togglePresaleActive() external onlyOwner {
        presaleActive = !presaleActive;
    }

    function togglePublicSaleActive() external onlyOwner {
        publicSaleActive = !publicSaleActive;
    }

    function setPresaleMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        _presaleMerkleRoot = _merkleRoot;
    }

    function withdraw(address _to, uint256 _amount) external onlyOwner {
        (bool success, ) = _to.call{ value: _amount }("");
        require(success, "Failed to withdraw Ether");
    }

    function mintReserved(address _to, uint256 _bullCount) external onlyOwner {
        require(totalMinted[msg.sender] + _bullCount <= RESERVED_BULLS, "All Reserved Bulls have been minted");
        _mintBull(_to, _bullCount);
    }

    function _verifyPresaleEligible(address _account, uint8 _maxAllowed, bytes32[] calldata _merkleProof) private view returns (bool) {
        bytes32 node = keccak256(abi.encodePacked(_account, _maxAllowed));
        return MerkleProof.verify(_merkleProof, _presaleMerkleRoot, node);
    }

    function mintBullPresale(uint256 _bullCount, uint8 _maxAllowed, bytes32[] calldata _merkleProof) external payable {
        require(presaleActive && !publicSaleActive, "Presale sale is not active");
        require(_verifyPresaleEligible(msg.sender, _maxAllowed, _merkleProof), "Address not found in presale allow list");
        require(totalMinted[msg.sender] + _bullCount <= uint256(_maxAllowed), "Purchase exceeds max presale mint count");
        require(PRICE * _bullCount == msg.value, "ETH amount is incorrect");

        _mintBull(msg.sender, _bullCount);
    }

    function mintBull(uint256 _bullCount) external payable {
        require(publicSaleActive, "Public sale is not active");
        require(totalMinted[msg.sender] + _bullCount <= MAX_MINT, "Purchase exceeds max mint count");
        require(PRICE * _bullCount == msg.value, "ETH amount is incorrect");

        _mintBull(msg.sender, _bullCount);
    }

    function _mintBull(address _to, uint256 _bullCount) private {
        uint256 totalSupply = totalSupply();
        require(totalSupply + _bullCount <= MAX_BULLS, "All Bulls have been minted. Hit the trading floor");
        require(_bullCount > 0, "Must mint at least one bull");

        for (uint256 i = 1; i <= _bullCount; i++) {
            totalMinted[msg.sender] += 1;
            _safeMint(_to, totalSupply + i);
        }

        emit BullMint(_to, _bullCount);
    }
}