//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

// ██████╗░░█████╗░░██████╗████████╗███████╗██╗░░░░░
// ██╔══██╗██╔══██╗██╔════╝╚══██╔══╝██╔════╝██║░░░░░
// ██████╔╝███████║╚█████╗░░░░██║░░░█████╗░░██║░░░░░
// ██╔═══╝░██╔══██║░╚═══██╗░░░██║░░░██╔══╝░░██║░░░░░
// ██║░░░░░██║░░██║██████╔╝░░░██║░░░███████╗███████╗
// ╚═╝░░░░░╚═╝░░╚═╝╚═════╝░░░░╚═╝░░░╚══════╝╚══════╝
// ██████╗░███████╗██████╗░░██████╗░█████╗░███╗░░██╗░██████╗
// ██╔══██╗██╔════╝██╔══██╗██╔════╝██╔══██╗████╗░██║██╔════╝
// ██████╔╝█████╗░░██████╔╝╚█████╗░██║░░██║██╔██╗██║╚█████╗░
// ██╔═══╝░██╔══╝░░██╔══██╗░╚═══██╗██║░░██║██║╚████║░╚═══██╗
// ██║░░░░░███████╗██║░░██║██████╔╝╚█████╔╝██║░╚███║██████╔╝
// ╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═════╝░░╚════╝░╚═╝░░╚══╝╚═════╝░
// ░░░░░ AN ░░░ INCLUSIVE ░░░ FAMILY-FRIENDLY ░░░ NFT ░░░░░░

contract PastelPersons is ERC721A, Ownable {

  using Strings for uint256;

  address public futureContract;
  address public w1;
  address public w2;
  address public w3; 
  address public w4;
  address public w5; 
  address public w6;
   
  string public baseTokenURI; 
  bytes32 public prelistRoot;
 
  uint16 public maxMintPerPrelist = 2;
  uint16 public maxMintPerPresale = 5;
  uint16 public maxMintPerTx = 5; 
  uint16 public maxMintPerWallet = 12; 

  uint256 public maxSupply = 8900; 
  uint256 public prelistCost = 0.04 ether;
  uint256 public presaleCost = 0.05 ether;
  uint256 public cost = 0.06 ether;


  bool public prelistOpen = false;
  bool public presaleOpen = false;
  bool public publicOpen = false;
  bool public isRevealed = false; 

  mapping(address => uint256) private prelistRedeemed; // see if spots have already been minted (prelisted mints)

  
  constructor(
    string memory _name, 
    string memory _symbol,
    string memory _initBaseTokenURI, 
    address[] memory _withdrawAddresses,
    bytes32 _initRoot) 
    ERC721A(_name, _symbol)
     {
        baseTokenURI = _initBaseTokenURI; 
        setWithdrawAddresses(_withdrawAddresses);
        prelistRoot = _initRoot;
     }

    // to set future contracts for utility
    function setFutureContractAddress(address _bAddress) public onlyOwner {
      futureContract = _bAddress;
    }

    // this function can be called only from the extending future contract 
    function mintExternal(address _address, uint256 _mintAmount) external {
        require(
            msg.sender == futureContract,
            "Sorry you dont have permission to mint"
        );
        _safeMint(_address, _mintAmount);
    }
    
    function setBaseTokenURI(string calldata _baseTokenURI) external onlyOwner { 
        baseTokenURI = _baseTokenURI; 
    }

    function _baseURI() internal view virtual override returns (string memory) { 
        return baseTokenURI;
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
        

        if(isRevealed == false) {
            return bytes(baseTokenURI).length > 0 ? string(abi.encodePacked(baseTokenURI, "prereveal.json")) : "";
        }

        return bytes(baseTokenURI).length > 0 ? string(abi.encodePacked(baseTokenURI, tokenId.toString(), ".json")) : ""; 
    }

    // start token ID at 1 (erc721a f(x))
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
    
    // set costs per mitning phase
    function setPrelistRoot(bytes32 _root) external onlyOwner {
        prelistRoot = _root;
    }
    function setPrelistCost(uint256 _newCost) external onlyOwner {
        prelistCost = _newCost;
    }
    function setPresaleCost(uint256 _newCost) external onlyOwner {
        presaleCost = _newCost;
    }
    function setCost(uint256 _newCost) external onlyOwner {
        cost = _newCost;
    }

    //  set max mints allowed per minting phase
    function setMaxMintPerPrelist(uint16 _amount) external onlyOwner {
        maxMintPerPrelist = _amount;
    }
    function setMaxMintPerPresale(uint16 _amount) external onlyOwner {
        maxMintPerPresale = _amount;
    }
    function setMaxMintPerTx(uint16 _amount) external onlyOwner {
        maxMintPerTx = _amount;
    }
    function setMaxMintPerWallet(uint16 _amount) external onlyOwner {
        maxMintPerWallet = _amount;
    }

    // toggle phases
    function togglePrelist() external onlyOwner {
        prelistOpen = !prelistOpen;  // false by default
    }
    function togglePresale() external onlyOwner {
        presaleOpen = !presaleOpen;  // false by default
    }
    function togglePublic() external onlyOwner {
        publicOpen = !publicOpen; // false by default
    }
    function toggleReveal(string calldata _revealedMetadataURI) external onlyOwner {
        isRevealed = !isRevealed;
        baseTokenURI = _revealedMetadataURI;
    }

    function _mintLoop(address _receiver, uint256 _mintAmount) internal {
        _safeMint(_receiver, _mintAmount);
    }

    // Verify that a given leaf is in the tree.
    function _verify(
        bytes32 _leafNode,
        bytes32[] memory _merkleProof
    ) internal view returns (bool) {
        return MerkleProof.verify(_merkleProof, prelistRoot, _leafNode);
    }

    // Generate the leaf node (the hash of tokenID concatenated with the account address)
    function _leaf(address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    // prelist mint
    function mintPrelist(
        address account,
        bytes32[] calldata _merkleProof,
        uint256 _mintAmount
    ) external payable {
                require(msg.sender == account, "Not allowed");
                require(prelistOpen == true, "The prelist not open");
                require(
                    _verify(_leaf(msg.sender), _merkleProof),
                    "Invalid proof"
                );
                require(_mintAmount > 0, "Your mint amount should be greater than 0");
                require(
                    (prelistRedeemed[msg.sender] + _mintAmount) <=
                        maxMintPerPrelist,
                    "Your mint amount exceeds the max mint per prelist (2)"
                );
                require(totalSupply() + _mintAmount <= maxSupply,
                    "You would exceed the max supply of tokens"
                );
                 require(
                    msg.value == (prelistCost * _mintAmount),
                    "Insuffient funds"
                );
                // update state before external call to avoid reentrency
                prelistRedeemed[msg.sender] += _mintAmount;

                  //Mint
                _mintLoop(msg.sender, _mintAmount);
    }

    //  presale mint
    function mintPresale(uint256 _mintAmount) 
        external 
        payable 
    {
        // if (msg.sender != owner()) {
            require(!prelistOpen, "Prelist is open");
            require(presaleOpen == true, "Presale is not open"); // false by default
            require(!publicOpen, "Public sale is open"); // public is closed
            require(_mintAmount > 0, "Your mint amount should be greater than 0");
            require(
                _mintAmount <= maxMintPerPresale,
                "Your mint amount exceeds the max mint per presale (5)"
            );
            require(
                totalSupply() + _mintAmount <= maxSupply,
                "You would exceed the max supply of tokens"
            );
            require(msg.value == (presaleCost * _mintAmount), "Insuffient funds");
        _mintLoop(msg.sender, _mintAmount);
    }
    
    // public mint
    function mint(uint256 _mintAmount) 
        external 
        payable  
    {
        // if (msg.sender != owner()) {
            uint256 ownerTokenCount = balanceOf(msg.sender);

            require(!prelistOpen, "Prelist is open");
            require(!presaleOpen, "Presale is open");
            require(publicOpen == true, "Public sale is not open");
            require(_mintAmount > 0, "Your mint amount should be greater than 0");
            require(
                _mintAmount <= maxMintPerTx,
                "Your mint amount exceeds the max mint per public sale (5)"
            );
            require(
                totalSupply() + _mintAmount <= maxSupply,
                "Exceeds Max Supply"
            );
            require(
                (ownerTokenCount + _mintAmount) <= maxMintPerWallet,
                "Sorry, you cant mint more than (8) per wallet total"
            );

            require( msg.value == (cost * _mintAmount), "Insuffient funds");
        _mintLoop(msg.sender, _mintAmount);
    }

    function gift(address _to, uint256 _mintAmount) external onlyOwner {
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Gifting this amount would exceed the max supply"
        );
        _mintLoop(_to, _mintAmount);
    }

    function airdrop(address[] calldata _airdropAddresses) external onlyOwner {
        for (uint256 i = 0; i < _airdropAddresses.length; i++) {
            address to = _airdropAddresses[i];
            require(
                _airdropAddresses.length + totalSupply() <= maxSupply,
                "Airdropping this many addresses would exceed the max supply"
            );
            _mintLoop(to, 1);
        }
    }

    function setWithdrawAddresses(address[] memory wAddresses) public onlyOwner {
        w1 = wAddresses[0]; 
        w2 = wAddresses[1];
        w3 = wAddresses[2];
        w4 = wAddresses[3];
        w5 = wAddresses[4]; 
        w6 = wAddresses[5];
    }

    function withdraw() external onlyOwner {
        uint256 amount = address(this).balance;
        (bool s1, ) = payable(w1).call{value: (amount * 31) / 100}("");
        (bool s2, ) = payable(w2).call{value: (amount * 5) / 100}(""); 
        (bool s3, ) = payable(w3).call{value: (amount * 30) / 100}("");
        (bool s4, ) = payable(w4).call{value: (amount * 10) / 100}("");
        (bool s5, ) = payable(w5).call{value: (amount * 15) / 100}("");
        (bool s6, ) = payable(w6).call{value: (amount * 9) / 100}("");

        if (s1 && s2 && s3 && s4 && s5 && s6) return;
        // fallback to paying all to treasury
        (bool s7, ) = w1.call{value: amount}("");
        require(s7, "Not successful, the withdrawal failed");
    }

}