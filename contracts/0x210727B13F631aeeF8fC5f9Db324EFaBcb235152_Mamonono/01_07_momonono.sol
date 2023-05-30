// SPDX-License-Identifier: MIT                                                                                                                                                                                                                           
pragma solidity =0.8.9;

/*
 HELLO ETH2.0 POS! 
 SOCIALFI IS COMMING!
   _____  ____    ______   _____  ____    ______   _______    ______   _______    ______                                    
  /     \/    \  /      \ /     \/    \  /      \ /       \  /      \ /       \  /      \                                   
  $$$$$$ $$$$  | $$$$$$  |$$$$$$ $$$$  |/$$$$$$  |$$$$$$$  |/$$$$$$  |$$$$$$$  |/$$$$$$  |                                  
  $$ | $$ | $$ | /    $$ |$$ | $$ | $$ |$$ |  $$ |$$ |  $$ |$$ |  $$ |$$ |  $$ |$$ |  $$ |                                  
  $$ | $$ | $$ |/$$$$$$$ |$$ | $$ | $$ |$$ \__$$ |$$ |  $$ |$$ \__$$ |$$ |  $$ |$$ \__$$ |                                  
  $$ | $$ | $$ |$$    $$ |$$ | $$ | $$ |$$    $$/ $$ |  $$ |$$    $$/ $$ |  $$ |$$    $$/                                   
  $$/  $$/  $$/  $$$$$$$/ $$/  $$/  $$/  $$$$$$/  $$/   $$/  $$$$$$/  $$/   $$/  $$$$$$/                                    
                                                                                                                            
                                                                                                                            
                                                                                                                            
               __      __         ______        ______                                       __            __   ______   __ 
              /  |    /  |       /      \      /      \                                     /  |          /  | /      \ /  |
    ______   _$$ |_   $$ |____  /$$$$$$  |    /$$$$$$  |        _______   ______    _______ $$/   ______  $$ |/$$$$$$  |$$/ 
   /      \ / $$   |  $$      \ $$____$$ |    $$$  \$$ |       /       | /      \  /       |/  | /      \ $$ |$$ |_ $$/ /  |
  /$$$$$$  |$$$$$$/   $$$$$$$  | /    $$/     $$$$  $$ |      /$$$$$$$/ /$$$$$$  |/$$$$$$$/ $$ | $$$$$$  |$$ |$$   |    $$ |
  $$    $$ |  $$ | __ $$ |  $$ |/$$$$$$/      $$ $$ $$ |      $$      \ $$ |  $$ |$$ |      $$ | /    $$ |$$ |$$$$/     $$ |
  $$$$$$$$/   $$ |/  |$$ |  $$ |$$ |_____  __ $$ \$$$$ |       $$$$$$  |$$ \__$$ |$$ \_____ $$ |/$$$$$$$ |$$ |$$ |      $$ |
  $$       |  $$  $$/ $$ |  $$ |$$       |/  |$$   $$$/       /     $$/ $$    $$/ $$       |$$ |$$    $$ |$$ |$$ |      $$ |
   $$$$$$$/    $$$$/  $$/   $$/ $$$$$$$$/ $$/  $$$$$$/        $$$$$$$/   $$$$$$/   $$$$$$$/ $$/  $$$$$$$/ $$/ $$/       $$/ 
*/                                                                                                                                                                                                                                     

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


enum MintStep {
    NotOpen,
    Open,
    Close
}


contract Mamonono is ERC721A, Ownable {
    using Strings for uint256;

    // constant
    uint256 public constant maxSupply = 10000;

    uint256 public mintPrice = 0.1 ether;

    uint256 public maxMintAmount = 5;

    // state
    mapping(address => bool) public whitelistClaimed;

    MintStep public mintStep = MintStep.NotOpen;

    bool public isRevealed = false;

    bytes32 public merkleRoot;

    string baseTokenURI;

    string notRevealedURI;

    string public baseExtension = ".json";


    constructor(
        string memory _baseTokenURI,
        string memory _notRevealedURI,
        bytes32 _merkleRoot
    ) ERC721A("Mamonono2022", "MAMONONO") {
        baseTokenURI = _baseTokenURI;
        notRevealedURI = _notRevealedURI;
        merkleRoot = _merkleRoot;
    }

    // overrides
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    // get states
    function getBalance() public view onlyOwner returns (uint256) {
        return address(this).balance;
    }

    function getBaseURI() public view onlyOwner returns (string memory) {
        return baseTokenURI;
    }

    function getNotRevealedURI() public view onlyOwner returns (string memory) {
        return notRevealedURI;
    }

    function getOwnList(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = _startTokenId();
        uint256 ownedTokenIndex = 0;
        address latestOwnerAddress;
        uint256 currentIndex = totalSupply();
        while (
            ownedTokenIndex < ownerTokenCount && currentTokenId <= currentIndex
        ) {
            TokenOwnership memory ownership = _ownershipAt(currentTokenId);

            if (!ownership.burned) {
                if (ownership.addr != address(0)) {
                    latestOwnerAddress = ownership.addr;
                }

                if (latestOwnerAddress == _owner) {
                    ownedTokenIds[ownedTokenIndex] = currentTokenId;

                    ownedTokenIndex++;
                }
            }

            currentTokenId++;
        }

        return ownedTokenIds;
    }
    
    function isWhiteClaimed() public view returns (bool) {
        if(whitelistClaimed[msg.sender] == true) {
            return true;
        }
        return false;
    }

    // set states
    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedURI = _notRevealedURI;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }

    function setMaxMintAmount(uint256 _maxMintAmount) public onlyOwner {
        maxMintAmount = _maxMintAmount;
    }

    function toggleOpenStatus(MintStep _mintStep) public onlyOwner {
        mintStep = _mintStep;
    }

    function toggleRevealStatus() public onlyOwner {
        isRevealed = !isRevealed;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (isRevealed == false) {
            return notRevealedURI;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function mintForWhite(bytes32[] calldata _merkleProof) public payable {
        // Verify whitelist requirements
        require(mintStep == MintStep.Open, "Mint is not open!");
        require(!whitelistClaimed[msg.sender], "Address already claimed!");
        require(totalSupply() + 1 <= maxSupply, "Max supply exceeded!");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Invalid proof!"
        );

        whitelistClaimed[msg.sender] = true;
        _safeMint(msg.sender, 1);
    }

    function mint(uint256 _mintAmount) public payable {
        require(mintStep == MintStep.Open, "Mint is not open!");
        require(
            _mintAmount > 0 && _mintAmount <= maxMintAmount,
            "Invalid mint amount!"
        );
        require(
            balanceOf(msg.sender) + _mintAmount <= maxMintAmount,
            "Sale exceed max balance per address!"
        );
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Max supply exceeded!"
        );
        require(msg.value >= mintPrice * _mintAmount, "Insufficient funds!");
        _safeMint(msg.sender, _mintAmount);
    }

    function mintForAddress(uint256 _mintAmount, address _receiver)
        public
        onlyOwner
    {
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Max supply exceeded!"
        );
        _safeMint(_receiver, _mintAmount);
    }

    // withdraw
    function withdraw() public onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "withdraw fail");
    }
}