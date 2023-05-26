// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "./library/Ownable.sol";
import "./library/MerkleProof.sol";


// _________  ___  ___  _______           ________  ________  ___       ___       _______   ________ _________  ___  ___      ___ _______
//|\___   ___\\  \|\  \|\  ___ \         |\   ____\|\   __  \|\  \     |\  \     |\  ___ \ |\   ____\\___   ___\\  \|\  \    /  /|\  ___ \
//\|___ \  \_\ \  \\\  \ \   __/|        \ \  \___|\ \  \|\  \ \  \    \ \  \    \ \   __/|\ \  \___\|___ \  \_\ \  \ \  \  /  / | \   __/|
//     \ \  \ \ \   __  \ \  \_|/__       \ \  \    \ \  \\\  \ \  \    \ \  \    \ \  \_|/_\ \  \       \ \  \ \ \  \ \  \/  / / \ \  \_|/__
//      \ \  \ \ \  \ \  \ \  \_|\ \       \ \  \____\ \  \\\  \ \  \____\ \  \____\ \  \_|\ \ \  \____   \ \  \ \ \  \ \    / /   \ \  \_|\ \
//       \ \__\ \ \__\ \__\ \_______\       \ \_______\ \_______\ \_______\ \_______\ \_______\ \_______\  \ \__\ \ \__\ \__/ /     \ \_______\
//        \|__|  \|__|\|__|\|_______|        \|_______|\|_______|\|_______|\|_______|\|_______|\|_______|   \|__|  \|__|\|__|/       \|_______|
//

contract TheCollective is ERC721A, Ownable {

    uint256 public immutable maxSupply;
    uint256 public price = 1 ether;

    bool public presaleActive;
    bool public saleActive;

    string public baseTokenURI;

    bytes32 public whitelistMerkleRoot = 0x0;
    mapping(address => uint256) public claimed;

    address treasury;

    error SaleInactive();
    error MaxSupplyExceeded();
    error MaxMint();
    error ValueSentIncorrect();
    error MaxCollectionReached();
    error NotWhitelisted();

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseTokenURI,
        uint256 _maxSupply,
        address _treasury
    ) ERC721A(_name, _symbol){
        baseTokenURI = _baseTokenURI;
        maxSupply = _maxSupply;
        treasury = _treasury;
    }

    function mint() external payable {
        if (!saleActive) revert SaleInactive();
        if (totalSupply() + 1 > maxSupply) revert MaxSupplyExceeded();
        if (price != msg.value) revert ValueSentIncorrect();

        _safeMint(msg.sender, 1);
    }

    function mintPresale(uint256 _quantity, bytes32[] calldata _merkleProof) external payable {
        if (!presaleActive) revert SaleInactive();
        if (totalSupply() + _quantity > maxSupply) revert MaxSupplyExceeded();
        if (!isWhitelisted(_merkleProof, msg.sender)) revert NotWhitelisted();
        if (claimed[msg.sender] + _quantity > 3) revert MaxMint();
        if (price * _quantity != msg.value) revert ValueSentIncorrect();

        claimed[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function isWhitelisted(bytes32[] calldata _merkleProof, address _address) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_address));
        return MerkleProof.verify(_merkleProof, whitelistMerkleRoot, leaf);
    }

    // ADMIN

    function toggleSale() external onlyOwner {
        saleActive = !saleActive;
    }

    function togglePresale() external onlyOwner {
        presaleActive = !presaleActive;
    }

    function reserve(uint256 _quantity) external onlyOwner {
        if (totalSupply() + _quantity > maxSupply) revert MaxSupplyExceeded();
        _safeMint(treasury, _quantity);
    }

    function reserve(address[] memory _addresses) external onlyOwner {
        if (totalSupply() + _addresses.length > maxSupply) revert MaxSupplyExceeded();

        for (uint i = 0; i < _addresses.length; i++) {
            _safeMint(_addresses[i], 1);
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(
        string calldata _baseTokenURI
    ) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setWhitelistMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        whitelistMerkleRoot = _merkleRoot;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function withdraw() public onlyOwner {
        address payable to = payable(treasury);
        to.transfer(address(this).balance);
    }
}