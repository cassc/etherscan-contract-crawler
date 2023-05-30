// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


interface IDescriptors {
    function tokenURI(uint256 tokenId, AnimalColoringBook animalColoringBook) external view returns(string memory);
}

interface IMintableBurnable {
    function mint(address mintTo) external;
    function burn(uint256 tokenId) external;
}

interface IGTAP1 {
    function copyOf(uint256 tokenId) external returns(uint256);
}

struct Animal {
    uint8 animalType;
    uint8 mood;
}

// types = cat = 1, bunny  = 2, mouse = 3, skull = 4, unicorn = 5, creator = 6 

contract AnimalColoringBook is ERC721Enumerable, Ownable {
    IDescriptors public immutable descriptors;
    address public immutable gtap1Contract;
    address public immutable wrappedGtap1Contract;
    address public eraserContract;
    uint256 public immutable publicMintintingOpenBlock;
    uint256 public immutable mintFeeWei = 2e17;
    uint256 public immutable eraserMintFeeWei = 1e17;
    uint256 public immutable maxNonOGCount = 936;
    bytes32 public immutable merkleRoot;
    uint256 private _nonce;

    mapping(uint256 => Animal) public animalInfo;
    mapping(uint256 => address[]) private _transferHistory;
    // Can mint 1 per GTAP1 OG
    mapping(uint256 => uint256) public ogMintCount;
    // each GTAP1 holder can mint 2
    mapping(address => uint256) public gtapHolderMintCount;

    constructor(address _owner, bytes32 _merkleRoot, IDescriptors _descriptors, address _gtap1Contract, address _wrappedGtap1Contract) ERC721("Animal Coloring Book", "GTAP2") {
        transferOwnership(_owner);
        descriptors = _descriptors;
        publicMintintingOpenBlock = block.number + 12300; // ~48 hrs
        merkleRoot = _merkleRoot;
        gtap1Contract = _gtap1Contract;
        wrappedGtap1Contract = _wrappedGtap1Contract;
    }

    function transferHistory(uint256 tokenId) external view returns (address[] memory){
        return _transferHistory[tokenId];
    }

    function mint(address mintTo, bool mintEraser) payable external {
        uint256 mintFee = mintEraser ? mintFeeWei + eraserMintFeeWei : mintFeeWei;
        require(msg.value >= mintFee, "AnimalColoringBook: fee too low");
        require(block.number >= publicMintintingOpenBlock, 'AnimalColoringBook: public minting not open yet');
        require(_nonce < maxNonOGCount, 'AnimalColoringBook: minting closed');
        _mint(mintTo, mintEraser);
    }

    function gtap1HolderMint(address mintTo, bool mintEraser, bytes32[] calldata merkleProof) payable external {
        uint256 mintFee = mintEraser ? mintFeeWei + eraserMintFeeWei : mintFeeWei;
        require(msg.value >= mintFee, "AnimalColoringBook: fee too low");
        bytes32 node = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), 'AnimalColoringBook: invalid proof');
        require(gtapHolderMintCount[msg.sender] < 2, 'AnimalColoringBook: reached max mint');
        require(_nonce < maxNonOGCount, 'AnimalColoringBook: minting closed');
        _mint(mintTo, mintEraser);
        gtapHolderMintCount[msg.sender]++;
    }

    function gtap1OGHolderMint(address mintTo, uint256 gtap1TokenId) external {
        require(ogMintCount[gtap1TokenId] == 0, 'AnimalColoringBook: reached max mint');
        require(_isOgHolder(gtap1TokenId), 'AnimalColoringBook: must be gtap1 original owner');
        _mint(mintTo, true);
        ogMintCount[gtap1TokenId]++;
    }

    function _isOgHolder(uint256 gtap1TokenId) private returns(bool){
        if(IERC721(gtap1Contract).ownerOf(gtap1TokenId) == msg.sender && IGTAP1(gtap1Contract).copyOf(gtap1TokenId) == 0 ){
            return true;
        }
        return IERC721(wrappedGtap1Contract).ownerOf(gtap1TokenId) == msg.sender;
    }

    function _mint(address mintTo, bool mintEraser) private {
        require(_nonce < 1000, 'AnimalColoringBook: reached max mint');
        _safeMint(mintTo, ++_nonce, "");

        uint256 randomNumber = _randomishIntLessThan("animal", 101);
        uint8 animalType = (
         (randomNumber < 31 ? 1 :
          (randomNumber < 56 ? 2 :
           (randomNumber < 76 ? 3 :
            (randomNumber < 91 ? 4 :
             (randomNumber < 99 ? 5 : 6))))));
        
        animalInfo[_nonce].animalType = animalType;

        if(mintEraser){
            IMintableBurnable(eraserContract).mint(mintTo);
        }
    }

    function erase(uint256 tokenId, uint256 eraserTokenId) external {
        IMintableBurnable(eraserContract).burn(eraserTokenId);
        address[] memory fresh;
        _transferHistory[tokenId] = fresh;
        animalInfo[tokenId].mood = 0;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        super.transferFrom(from, to, tokenId);
         if(_transferHistory[tokenId].length < 4) {
            _transferHistory[tokenId].push(to);
            if(_transferHistory[tokenId].length == 4){
                uint8 random = _randomishIntLessThan("mood", 10) + 1;
                animalInfo[tokenId].mood = random > 6  ? 1 : random;
            }
        }
    }
    
    function tokenURI(uint256 tokenId) public override view returns(string memory) {
        return descriptors.tokenURI(tokenId, this);
    }

    function setEraser(address _eraserContract) external {
        require(address(eraserContract) == address(0), 'set');
        eraserContract = _eraserContract;
    }

    function _randomishIntLessThan(bytes32 salt, uint8 n) private view returns (uint8) {
        if (n == 0)
            return 0;
        return uint8(keccak256(abi.encodePacked(block.timestamp, _nonce, msg.sender, salt))[0]) % n;
    }

    function payOwner(address to, uint256 amount) public onlyOwner() {
        require(amount <= address(this).balance, "amount too high");
        payable(to).transfer(amount);
    }
}