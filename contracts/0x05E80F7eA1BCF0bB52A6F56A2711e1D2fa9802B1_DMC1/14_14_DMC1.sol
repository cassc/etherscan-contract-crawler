// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/*
               ,---.        ,-,--.                ___     _,.---._                    ,----.             
  _,..---._  .--.'  \     ,-.'-  _\        .-._ .'=.'\  ,-.' , -  `.   _,..---._   ,-.--` , \   _.-.     
/==/,   -  \ \==\-/\ \   /==/_ ,_.'       /==/ \|==|  |/==/_,  ,  - \/==/,   -  \ |==|-  _.-` .-,.'|     
|==|   _   _\/==/-|_\ |  \==\  \          |==|,|  / - |==|   .=.     |==|   _   _\|==|   `.-.|==|, |     
|==|  .=.   |\==\,   - \  \==\ -\         |==|  \/  , |==|_ : ;=:  - |==|  .=.   /==/_ ,    /|==|- |     
|==|,|   | -|/==/ -   ,|  _\==\ ,\        |==|- ,   _ |==| , '='     |==|,|   | -|==|    .-' |==|, |     
|==|  '='   /==/-  /\ - \/==/\/ _ |       |==| _ /\   |\==\ -    ,_ /|==|  '='   /==|_  ,`-._|==|- `-._  
|==|-,   _`/\==\ _.\=\.-'\==\ - , /       /==/  / / , / '.='. -   .' |==|-,   _`//==/ ,     //==/ - , ,/ 
`-.`.____.'  `--`         `--`---'        `--`./  `--`    `--`--''   `-.`.____.' `--`-----`` `--`-----'  
Volume 1 - September 2022
Have You Tried Turning It Off And On Again?
*/

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { IERC2981, IERC165 } from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DMC1 is ERC721, IERC2981, Ownable, ReentrancyGuard {
    using Strings for uint;

    /* ========== STATE VARIABLES ========== */
    uint public constant MAX_SUPPLY = 512;
    uint public constant MAX_MINT_PUBLIC_PER_TX = 2;
    uint public mintPricePublic = 0 ether;
    uint public mintPriceAllow = 0 ether;
    bool public isActivePublic = false;
    bool public isActiveAllow = false;
    address public beneficiary;
    address public royalties;
    string public baseURI;
    uint private _currentId;
    bytes32 public merkleRoot;
    mapping(address => uint) private _alreadyMinted;

    /* ========== CONSTRUCTOR ========== */
    constructor(
        address _beneficiary,
        address _royalties,
        string memory _initialBaseURI
    ) ERC721("Volume 1 by Das Model Collective", "DMC1") Ownable() {
        require(_beneficiary != address(0));
        require(_royalties != address(0));
        beneficiary = _beneficiary;
        royalties = _royalties;
        baseURI = _initialBaseURI;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */
    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setActivePublic(bool _isActivePublic) public onlyOwner {
        isActivePublic = _isActivePublic;
    }

    function setActiveAllow(bool _isActiveAllow) public onlyOwner {
        isActiveAllow = _isActiveAllow;
    }

    function setBeneficiary(address _beneficiary) public onlyOwner {
        beneficiary = _beneficiary;
    }

    function setRoyalties(address _royalties) public onlyOwner {
        royalties = _royalties;
    }

    function setMintPricePublic(uint _mintPricePublic) public onlyOwner {
        mintPricePublic = _mintPricePublic;
    }

    function setMintPriceAllow(uint _mintPriceAllow) public onlyOwner {
        mintPriceAllow = _mintPriceAllow;
    }

    function setMerkleProof(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function alreadyMinted(address addr) public view returns (uint) {
        return _alreadyMinted[addr];
    }

    function withdraw() public onlyOwner {
        payable(beneficiary).transfer(address(this).balance);
    }

    function totalSupply() public view returns (uint) {
        return _currentId;
    }

    /* ========== MINT FUNCTIONS ========== */
    function mintPublic(uint quantity) public payable {
        address sender = _msgSender();

        require(isActivePublic, "Sale is closed");
        require(quantity <= MAX_MINT_PUBLIC_PER_TX, "Exceeded max token purchase");
        require(mintPricePublic * quantity <= msg.value, "Incorrect payable amount");

        _internalMint(sender, quantity);
    }

    function mintAllow(uint quantity, bytes32[] calldata merkleProof, uint maxQuantity) public payable nonReentrant {
        address sender = _msgSender();

        require(isActiveAllow, "Sale is closed");
        require(quantity <= maxQuantity - _alreadyMinted[sender], "Insufficient mints left");
        require(_verify(merkleProof, sender, maxQuantity), "Invalid proof");
        require(msg.value == mintPriceAllow * quantity, "Incorrect payable amount");

        _alreadyMinted[sender] += quantity;
        _internalMint(sender, quantity);
    }

    function mintOwner(address to, uint quantity) public onlyOwner {
        _internalMint(to, quantity);
    }

    /* ========== PRIVATE FUNCTIONS ========== */
    function _internalMint(address to, uint quantity) private {
        require(_currentId + quantity <= MAX_SUPPLY, "Will exceed maximum supply");

        for (uint i = 1; i <= quantity; i++) {
            _currentId++;
            _safeMint(to, _currentId);
        }
    }

    function _verify(bytes32[] calldata merkleProof, address sender, uint maxQuantity) private view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(sender, maxQuantity));
        return MerkleProof.verify(merkleProof, merkleRoot, leaf);
    }

    /* ========== ROYALTIES - ERC2981 ========== */
    // ERC165
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, IERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    // IERC2981
    function royaltyInfo(uint _tokenId, uint _salePrice) external view returns (address, uint royaltyAmount) {
        _tokenId; // silence solc warning
        royaltyAmount = (_salePrice * 750) / 10000; // 7.5%
        return (royalties, royaltyAmount);
    }
}