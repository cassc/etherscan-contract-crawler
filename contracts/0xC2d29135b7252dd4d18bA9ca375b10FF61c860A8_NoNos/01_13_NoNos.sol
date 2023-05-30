// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/*

     .-') _                         .-') _                .-')    
    ( OO ) )                       ( OO ) )              ( OO ).  
,--./ ,--,'  .-'),-----.       ,--./ ,--,'  .-'),-----. (_)---\_) 
|   \ |  |\ ( OO'  .-.  '      |   \ |  |\ ( OO'  .-.  '/    _ |  
|    \|  | )/   |  | |  |      |    \|  | )/   |  | |  |\  :` `.  
|  .     |/ \_) |  |\|  |      |  .     |/ \_) |  |\|  | '..`''.) 
|  |\    |    \ |  | |  |      |  |\    |    \ |  | |  |.-._)   \ 
|  | \   |     `'  '-'  '      |  | \   |     `'  '-'  '\       / 
`--'  `--'       `-----'       `--'  `--'       `-----'  `-----'  

No Nos Dev - @nonos_nft
nonosnft.com

*/

contract NoNos is ERC721A, Ownable {
    string private _baseTokenURI;
    uint256 private _price = 0.06 ether;
    uint256 private _maxNoNos = 10001;
    uint256 private _maxTX = 3;
    uint256 private _maxNoNosPerAddressDuringMint = 3;
    bool public _pausedPublic = true;
    bool public _pausedPrivate = true;
    uint256 private _publicSaleKey = 707;

    //NO NO LIST
    bytes32 public _nonoListRoot =
        0x6e337f837f55c7cb65aa1479873ebb78f9b696009993700a71b94ca4fff9e8a9;

    //No No Provenance
    string public _nonoProvenance =
        "97483f2fe73dbcb16c261cf1a8258effdfa26e15e389c1000f368145ca754a9f";

    constructor() ERC721A("NoNos", "NONOS") {}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setNoNoListRoot(bytes32 nonoListRoot) external onlyOwner {
        _nonoListRoot = nonoListRoot;
    }

    function setNewProvenance(string memory newProvenance) external onlyOwner {
        _nonoProvenance = newProvenance;
    }

    function buyTicketNoNoList(uint256 quantity, bytes32[] calldata merkleProof)
        external
        payable
        callerIsUser
    {
        require(!_pausedPrivate, "No No List sale is Paused.");
        require(
            quantity < _maxTX,
            "Exceeds maximum of No Nos per transaction."
        );
        require(
            totalSupply() + quantity < _maxNoNos,
            "Reached maximum capacity of No Nos in the Spaceship!"
        );
        require(
            numberMinted(msg.sender) + quantity < _maxNoNosPerAddressDuringMint,
            "Can not mint this many No Nos."
        );
        require(msg.value >= _price * quantity, "Ether sent is not correct.");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(merkleProof, _nonoListRoot, leaf),
            "This wallet is not in the No No List."
        );
        _safeMint(msg.sender, quantity);
    }

    function buyTicket(uint256 quantity, uint256 callerPublicSaleKey)
        external
        payable
        callerIsUser
    {
        require(
            _publicSaleKey == callerPublicSaleKey,
            "Wrong Secret Sale Key."
        );
        require(!_pausedPublic, "Public sale is Paused.");
        require(
            quantity < _maxTX,
            "Exceeds maximum of No Nos per transaction."
        );
        require(
            totalSupply() + quantity < _maxNoNos,
            "Reached maximum capacity of No Nos in the Spaceship!"
        );
        require(
            numberMinted(msg.sender) + quantity < _maxNoNosPerAddressDuringMint,
            "Can not mint this many No Nos."
        );
        require(msg.value >= _price * quantity, "Ether sent is not correct.");

        _safeMint(msg.sender, quantity);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }

    function giveAwayTickets(address _to, uint256 quantity) external onlyOwner {
        require(
            totalSupply() + quantity < _maxNoNos,
            "Reached maximum capacity of No Nos in the Spaceship!"
        );
        _safeMint(_to, quantity);
    }

    function setSaleKey(uint256 _newSaleKey) public onlyOwner {
        _publicSaleKey = _newSaleKey;
    }

    function pausePublic(bool val) public onlyOwner {
        _pausedPublic = val;
    }

    function pausePrivate(bool val) public onlyOwner {
        _pausedPrivate = val;
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        _price = _newPrice;
    }

    function getPrice() public view returns (uint256) {
        return _price;
    }

    function setMaxNoNosPerAddress(uint256 _newMax) public onlyOwner {
        _maxNoNosPerAddressDuringMint = _newMax;
    }

    function getMaxNoNosPerAddress() public view returns (uint256) {
        return _maxNoNosPerAddressDuringMint;
    }

    function setMaxNoNos(uint256 _newMax) public onlyOwner {
        _maxNoNos = _newMax;
    }

    function getMaxNoNos() public view returns (uint256) {
        return _maxNoNos;
    }

    function setMaxTX(uint256 _newMaxTX) public onlyOwner {
        _maxTX = _newMaxTX;
    }

    function getMaxTX() public view returns (uint256) {
        return _maxTX;
    }

    function withdrawAll() public onlyOwner {
        uint256 _balance = address(this).balance;
        payable(msg.sender).transfer(_balance);
    }
}