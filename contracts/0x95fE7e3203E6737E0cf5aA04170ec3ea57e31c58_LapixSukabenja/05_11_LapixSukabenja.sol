// SPDX-License-Identifier: MIT

/*
  


*/

pragma solidity ^0.8.17;


import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';


abstract contract LAPIXZERO {
    function mintMecha(address to, uint[] memory ids) public virtual;
}


contract LapixSukabenja is ERC721AQueryable, ERC721ABurnable, Ownable, ReentrancyGuard {

    event CrateClaimed(uint256 _totalClaimed, address _owner, uint256 _numOfCrates);
    event FuseMecha(address _address, uint[] _tokenIds);

    bytes32 public alphaMerkleRoot;
    bytes32 public laplistMerkleRoot;

    bool public publicMint = false;
    bool public whitelistMint = false;
    bool public fuseEnabled = false;

    string private _baseTokenURI;

    uint public partsPerCrate = 6;
    uint public maxPerAddress = 2;
    uint public maxCrates = 5555;
    uint public cratesMinted = 0;

    uint public alphaPrice = 0.0375 ether;
    uint public laplistPrice = 0.045 ether;
    uint public publicPrice = 0.05 ether;

    LAPIXZERO lapixContract;
    
    constructor(string memory _metadataBaseURL) ERC721A("LapixSukabenja", "LPS") {
        _baseTokenURI = _metadataBaseURL;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function verify(bytes32[] memory proof, bool alpha) internal view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        bool status;

        if (alpha)
            status = MerkleProof.verify(proof, alphaMerkleRoot, leaf);
        else
            status = MerkleProof.verify(proof, laplistMerkleRoot, leaf);

        return status; 
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function mintCrate(uint256 quantity, bytes32[] memory proof, bool alpha) public payable {

        require(tx.origin == msg.sender, "Cannot mint from a contract");
        require(whitelistMint || publicMint, "Cannot claim now");
        require(_numberMinted(msg.sender) / partsPerCrate + quantity <= maxPerAddress, "Cannot claim these many crates");
        require(quantity > 0, "Invalid crate count");
        require(cratesMinted + quantity <= maxCrates, "Cannot claim these many tokens");
        
        if(whitelistMint){
            
            require(verify(proof, alpha), "Wallet not whitelisted");
            
            if (alpha) {
                require(msg.value >= (alphaPrice * quantity), "Insufficient funds to claim crates");
            }
            else {
                require(msg.value >= (laplistPrice * quantity), "Insufficient funds to claim crates");
            }
        }
        else {
            require(msg.value >= (publicPrice * quantity), "Insufficient funds to claim crates");
        }

        _safeMint(msg.sender, quantity * partsPerCrate);
        cratesMinted = cratesMinted + quantity;

        emit CrateClaimed(cratesMinted, msg.sender, quantity);
    }

    function fuse(uint[] memory tokenIds) public {

        require(fuseEnabled, "Cannot fuse parts");
        require(tokenIds.length == partsPerCrate, "Must have six parts to fuse");

        uint[] memory partCount = new uint[](partsPerCrate);
        
        for (uint i=0; i<tokenIds.length; i++) {

            require(msg.sender == ownerOf(tokenIds[i]), "Must be part owner to fuse");

            uint partType = tokenIds[i] % partsPerCrate;
            partCount[partType] = partCount[partType] + 1;
        }

        for (uint i=0; i<tokenIds.length; i++)
            require(partCount[i] == 1, "Cannot fuse with duplicate parts");
        
        lapixContract.mintMecha(msg.sender, tokenIds);

        for (uint i=0; i<tokenIds.length; i++)
            burn(tokenIds[i]);

        emit FuseMecha(msg.sender, tokenIds);
    }

    function mintParts(address[] memory _addresses) external onlyOwner {
        
        for (uint i=0; i<_addresses.length; i++) {
            address _to = address(_addresses[i]);
            _safeMint(_to, 1);
        }
    }

    function mintCratesToAddress(address _address, uint quantity) external onlyOwner {
        require(cratesMinted + quantity <= maxCrates, "Cannot mint these many crates");
        _safeMint(_address, quantity * partsPerCrate);
    }


    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setAlphaRoot(bytes32 _root) external onlyOwner {
        alphaMerkleRoot = _root;
    }

    function setLaplistRoot(bytes32 _root) external onlyOwner {
        laplistMerkleRoot = _root;
    }

    function flipPublicMintState() external onlyOwner {
        publicMint = !publicMint;
    }

    function flipWhitelistState() external onlyOwner {
        whitelistMint = !whitelistMint;
    }

    function flipFuseEnabled() external onlyOwner {
        fuseEnabled = !fuseEnabled;
    }

    function setMaxCrates(uint _supply) external onlyOwner {
        maxCrates = _supply;
    }

    function setMaxPerAddress(uint _max) external onlyOwner {
        maxPerAddress = _max;
    }

    function setPrices(uint _alpha, uint _laplist, uint _public) external onlyOwner {
        alphaPrice = _alpha;
        laplistPrice = _laplist;
        publicPrice = _public;
    }

    function setLapixContract(address _address) external onlyOwner {
        lapixContract = LAPIXZERO(_address);
    }


    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

}