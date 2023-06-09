// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract FFU is ERC721A, Ownable {
    using Address for address;
    using MerkleProof for bytes32[];
    using Strings for uint256;

    string baseURI;
    string public baseExtension = ".json";
    string public notRevealedUri;
    uint256 public mintPrice = .345 ether;
    uint256 public MAX_SUPPLY = 10000;
    uint256 public resMintMax = 10000;
    uint256 public foundersMintMax = 600;
    uint256 public maxFightersPerWallet = 3;
    uint256 public maxFightersPerTx = 3;

    bool public reservationMintPaused = true;
    bool public publicMintPaused = true;
    bool public revealed = false;

    bytes32 rezlistMerkleRoot;
    mapping(address => uint256) private rezlistMintedAmount;
    mapping(address => uint256) private publicMintedAmount;
    address payable public payments;

    //Constructor
    constructor(address _payments) ERC721A(" Food Fighters Universe ", "FFU", 3) {
       payments = payable(_payments);
    } 
    //Internal
    function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }
    
    //Modifer
   function _onlySender() private view {
        require(msg.sender == tx.origin);
    }
    modifier onlySender {
        _onlySender();
        _;
    }

    //treasuryMint
      function treasuryMint(uint256 _numberOfMints) external onlyOwner {
        _safeMint(msg.sender, _numberOfMints);
    }

    //Reservation Mint
    function resMint(address _address, bytes32[] memory proof) external payable onlySender {
        require(!reservationMintPaused, "Reservation mint is paused");
        require(
            isAddressRezlisted(proof, _address),
            "You are not eligible for a Reservation mint"
        );
        uint256 amount = _getMintAmount(msg.value);
        require(amount >0, "Must mint more than 1");
        require(
            rezlistMintedAmount[_address] + amount <= maxFightersPerWallet,
            "Minting amount exceeds allowance per wallet"
        );

        rezlistMintedAmount[_address] += amount;
        _safeMint(_address, amount);
    }

    //Public Mint 
    function publicMint(address _address) external payable onlySender  {
        require(!publicMintPaused, "Public mint is paused");
        uint256 amount = _getMintAmount(msg.value);
        require(amount >0, "Must mint more than 1");
        require(
            amount <= maxFightersPerTx,
            "Minting amount exceeds allowance per tx"
        );
        require(
            publicMintedAmount[_address] + amount <= maxFightersPerWallet,
            "Minting amount exceeds allowance per wallet"
        );

        publicMintedAmount[_address] += amount;
        _safeMint(_address, amount);
    }

    //Helper
    function _getMintAmount(uint256 value) internal view returns (uint256) {
        uint256 remainder = value % mintPrice;
        require(remainder == 0, "Send a divisible amount of eth");
        uint256 amount = value / mintPrice;
        require(amount > 0, "Amount to mint is 0");
        require(
            (totalSupply() + amount) <= MAX_SUPPLY,
            "Sold out!"
        );
        return amount;
    }

    function isAddressRezlisted(bytes32[] memory proof, address _address)
        public
        view
        returns (bool)
    {
        return isAddressInMerkleRoot(rezlistMerkleRoot, proof, _address);
    }
    function isAddressInMerkleRoot(
        bytes32 merkleRoot,
        bytes32[] memory proof,
        address _address
    ) internal pure returns (bool) {
        return proof.verify(merkleRoot, keccak256(abi.encodePacked(_address)));
    }

    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    
    if(revealed == false) {
        return notRevealedUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

    //owner only
    function setFoundersMintMax(uint256 _foundersMintMax) external onlyOwner {
        foundersMintMax = _foundersMintMax;
    }
    function setPublicMintPaused(bool _publicMintPaused) external onlyOwner {
        publicMintPaused = _publicMintPaused;
    }
    function setReservationMintPaused(bool _reservationMintPaused)
        external
        onlyOwner
    {
        reservationMintPaused = _reservationMintPaused;
    }
    function setReservationMintMax(uint256 _resMintMax)
        external
        onlyOwner
    {
        resMintMax = _resMintMax;
    }
    function setReservationMintMerkleRoot(bytes32 _rezlistMerkleRoot)
        external
        onlyOwner
    {
        rezlistMerkleRoot = _rezlistMerkleRoot;
    }
    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }
    function setMaxFightersPerTx(uint256 _maxFightersPerTx) external onlyOwner {
        maxFightersPerTx = _maxFightersPerTx;
    }
    function setMaxFightersPerWallet(uint256 _maxFightersPerWallet) external onlyOwner {
        maxFightersPerWallet = _maxFightersPerWallet;
    }
      function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }
  
    function reveal() public onlyOwner {
      revealed = true;
  }

    // Withdraw to owner
    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(payments).call{value: address(this).balance}("");
        require(success, "Failed to send ether");
    }

   receive() external payable {}
}