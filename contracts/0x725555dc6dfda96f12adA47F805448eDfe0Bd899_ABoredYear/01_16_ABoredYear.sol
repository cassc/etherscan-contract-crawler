// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract ABoredYear is ERC721, Ownable, DefaultOperatorFilterer {
    using Strings for uint256;
    using Counters for Counters.Counter;
    
    Counters.Counter private LEsupply;
    Counters.Counter private BEsupply;

    bytes32 public merkleRoot;
    bytes32 public allowMerkleRoot;
    string  public baseURI;
    string  public extension;
    uint256 public maxSupply                  = 5000;
    uint256 public limitedEdition             = 1000;
    uint256 public boredEdition               = 4000;
    uint256 public PP1                        = 0.08 ether;
    uint256 public PP2                        = 0.1 ether;
    uint256 public PP3                        = 0.12 ether;
    uint256 public PP4                        = 0.14 ether;
    uint256 public phase                      = 0;
    bool    public claiming                   = false;
    bool    public reserved                   = false;

    mapping(address => uint256) public _phase1Mints;
    mapping(address => uint256) public _phase2Mints;
    mapping(address => uint256) public _phase3Mints;
    mapping(uint256 => bool)    public claimed;

    address public constant w1 = 0xf98903F0E58b8063B67fB1c426b17d4227B6380C;
    address public constant w2 = 0xa5bd70354c6289CE6FbBa390FBF003c0a92f8879;
    address public constant w3 = 0x88375f4c4Dfe2f40154e76C3175DE7ceD551Dd33;
    address public constant w4 = 0xf8eCc89703a21DD0Db39988fABB6F8925FB1A232;
    address public constant w5 = 0xa2004B13Db88F0f8c5EE71a18D42EC653A61DA05;
    address public constant w6 = 0x98d8d01Cfe9078FD22acC91b876bC08edcD8BA52;
    address public constant w7 = 0x5554Ce83f7a8A82b81650A055310ac19bD915Aee;
    address public constant w8 = 0x207Ad8A7A3714e0b5d090c4d9d9cB116245D9B4E;
    address public constant w9 = 0xB14289984581c3D8CDc24663F5D0d6035eEd642c;

    IERC721 public immutable bayc = IERC721(0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D);
    IERC721 public immutable mayc = IERC721(0x60E4d786628Fea6478F785A6d7e704777c86a7c6);

    constructor() ERC721("A Bored Year", "ABY"){}

    event BookClaimed(uint256 tokenId, address holder);

    function mintLE(uint256 amount, address to, bytes32[] calldata merkleProof) external payable {
        require(phase > 0, "Mint is not live yet");
        require(phase < 4, "Mint is not live yet");
        require(msg.sender == tx.origin, "No contracts");
        require(ownsApe(to), "Not an ape holder, try Bored Edition");
        uint256 supply = LEsupply.current();
        require(supply + amount < limitedEdition + 1, "No more Limited Edition left");
        if (phase == 1) {
            // private
            require(MerkleProof.verify(merkleProof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "Not on the Private List");
            require(msg.value >= amount * PP2, "Not enough ETH");
            require(_phase1Mints[msg.sender] + amount < 3, "Too many per wallet");
            require(totalSupply() + amount < 867, "No more left in private sale");
            _phase1Mints[msg.sender] += amount;
        } else if (phase == 2) {
            // allow list
            require(MerkleProof.verify(merkleProof, allowMerkleRoot, keccak256(abi.encodePacked(msg.sender))), "Not on the Allow List");
            require(msg.value >= amount * PP3, "Not enough ETH");
            require(_phase2Mints[msg.sender] + amount < 6, "Too many per wallet");
            _phase2Mints[msg.sender] += amount;
        } else if (phase == 3) {
            // public
            require(msg.value >= amount * PP4, "Not enough ETH");
            require(_phase3Mints[msg.sender] + amount < 11, "Too many per wallet");
            _phase3Mints[msg.sender] += amount;
        }
        
        for (uint256 i = 1; i <= amount; i++) {
            LEsupply.increment();
            _safeMint(to, supply + i);
        }
    }

    function mintBE(uint256 amount, address to, bytes32[] calldata merkleProof) external payable {
        require(phase > 0, "Mint is not live yet");
        require(phase < 4, "Mint is not live yet");
        require(msg.sender == tx.origin, "No contracts");
        uint256 supply = BEsupply.current();
        require(supply + amount < boredEdition + 1, "No more Bored Edition left");
        if (phase == 1) {
            // private
            require(MerkleProof.verify(merkleProof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "Not on the Private List");
            require(msg.value >= amount * PP1, "Not enough ETH");
            require(_phase1Mints[msg.sender] + amount < 3, "Too many per wallet");
            require(totalSupply() + amount < 867, "No more left in private sale");
            _phase1Mints[msg.sender] += amount;
        } else if (phase == 2) {
            // allow list
            require(MerkleProof.verify(merkleProof, allowMerkleRoot, keccak256(abi.encodePacked(msg.sender))), "Not on the Allow List");
            require(msg.value >= amount * PP2, "Not enough ETH");
            require(_phase2Mints[msg.sender] + amount < 6, "Too many per wallet");
            _phase2Mints[msg.sender] += amount;
        } else if (phase == 3) {
            // public
            require(msg.value >= amount * PP3, "Not enough ETH");
            require(_phase3Mints[msg.sender] + amount < 11, "Too many per wallet");
            _phase3Mints[msg.sender] += amount;
        }
        
        for (uint256 i = 1; i <= amount; i++) {
            BEsupply.increment();
            _safeMint(to, supply + i + 1000);
        }
    }

    function claim(uint256 tokenId) external {
        require(_exists(tokenId), "Nonexistent token");
        require(claiming, "Claiming not open");
        require(ownerOf(tokenId) == msg.sender, "Not yours to claim");
        claimed[tokenId] = true;
        emit BookClaimed(tokenId, msg.sender);
    }

    function isClaimed(uint256 tokenId) public view returns (bool) {
        return claimed[tokenId] == true ? true : false;
    }

    function isMinted(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Nonexistent token");

	    string memory currentBaseURI = _baseURI();
	    return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, tokenId.toString(), extension)) : "";
    }
    
    function totalSupply() public view returns (uint256) {
        return LEsupply.current() + BEsupply.current();
    }

    function LESupply() public view returns (uint256) {
        return LEsupply.current();
    }

    function BESupply() public view returns (uint256) {
        return BEsupply.current();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function ownsApe(address _holder) public view returns (bool) {
        uint256 baycOwned = bayc.balanceOf(_holder);
        uint256 maycOwned = mayc.balanceOf(_holder);
        return baycOwned + maycOwned > 0 ? true : false;
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
        if (_exists(currentTokenId)) {
            address currentTokenOwner = ownerOf(currentTokenId);

            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;

                ownedTokenIndex++;
            }
        }

        currentTokenId++;
        }

        return ownedTokenIds;
    }

    function setBaseUri(string memory _baseuri) public onlyOwner {
        baseURI = _baseuri;
    }

    function setExtension(string memory _extension) public onlyOwner {
        extension = _extension;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setAllowMerkleRoot(bytes32 _allowMerkleRoot) external onlyOwner {
        allowMerkleRoot = _allowMerkleRoot;
    }

    function toggleClaiming() external onlyOwner {
        claiming = !claiming;
    }

    function setPrices(uint256[] calldata _prices) external onlyOwner {
        PP1 = _prices[0];
        PP2 = _prices[1];
        PP3 = _prices[2];
        PP4 = _prices[3];
    }

    function setPhase(uint256 _phase) external onlyOwner {
        phase = _phase;
    }

    function reduceSupply(uint256 _limitedEditions, uint256 _boredEditions) external onlyOwner {
        require(_limitedEditions + _boredEditions < maxSupply, "Can't increase supply.");
        limitedEdition = _limitedEditions;
        boredEdition = _boredEditions;
        maxSupply = _limitedEditions + _boredEditions;
    }

    function reserve() external onlyOwner {
        require(!reserved, "Already reserved 40 books");
        reserved = true;
        // Reserve 35 Bored Editions
        for (uint256 i = 1; i <= 35; i++) {
            BEsupply.increment();
            _safeMint(msg.sender, i + 1000);
        }

        // Reserve 5 Limited Editions
        for (uint256 i = 1; i <= 5; i++) {
            LEsupply.increment();
            _safeMint(msg.sender, i);
        }
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");
        _withdraw(w1, ((balance * 109) / 200));
        _withdraw(w2, ((balance * 20) / 100));
        _withdraw(w3, ((balance * 10) / 100));
        _withdraw(w4, ((balance * 10) / 100));
        _withdraw(w5, ((balance * 3) / 100));
        _withdraw(w6, ((balance * 1) / 100));
        _withdraw(w7, ((balance * 1) / 200));
        _withdraw(w8, ((balance * 1) / 200));
        _withdraw(w9, ((balance * 1) / 200));
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Failed to withdraw Ether");
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}