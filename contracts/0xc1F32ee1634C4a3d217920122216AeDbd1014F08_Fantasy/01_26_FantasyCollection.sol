// SPDX-License-Identifier: MIT LICENSE

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./FNFTDrop.sol";
import "./FNFTStaking.sol";
import "./FNFTVault.sol";
import "./FNFTToken.sol";

contract Fantasy is ERC721Enumerable, Ownable {

  struct TokenInfo {
        IERC20 paytoken;
        uint256 costvalue;
    }
  
    event SupplyAmountSet(uint amount, address byOwner);
    
     TokenInfo[] public AllowedCrypto;

    using Strings for uint256;
    string public baseURI;
    string public baseExtension = ".json";
    uint256 public price = 0.03 ether;
    uint256 public maxSupply = 6000;
    uint256 public maxMintAmount = 10;
    bool public paused = false;

    using MerkleProof for bytes32[];

    mapping(address => bool) public alreadyMinted;

    uint16 public reserveFNFTDropsId;
    uint16 public FNFTsId;

    bytes32 public merkleRoot;
    bool public merkleEnabled = true;

    bool public saleStarted = true;
    uint256 public constant maxMint = 6000;
    
    constructor() ERC721 ("Fantasy", "FNFT") {
 
    reserveFNFTDropsId = 4000;
    FNFTsId = 4001;
    }

    function addCurrency(
        IERC20 _paytoken,
        uint256 _costvalue
    ) public onlyOwner {
        AllowedCrypto.push(
            TokenInfo({
                paytoken: _paytoken,
                costvalue: _costvalue
            })
        );
    }
  
    function _baseURI() internal view virtual override returns (string memory) {
    return "https://bafybeia3io3ricswfzclgeqjlkcwqjj5aadl66tegfpvf6gcgygzjuacfi.ipfs.nftstorage.link/Fantasy%20%234019.json";

    }
    
    function setPrice(uint256 _newPrice) public onlyOwner {
      price = _newPrice;
    }

    function mint(address _to, uint256 _mintAmount) public payable {
                  uint256 supply = reserveFNFTDropsId + totalSupply();
            require(!paused);
            require(FNFTsId <= maxMint, "Mint limit reached");
            require(reserveFNFTDropsId + _mintAmount <= 6000, "Out of stock");
            require(_mintAmount > 0);
            require(_mintAmount <= maxMintAmount);
            require(supply + _mintAmount <= maxSupply);
            
            if (msg.sender != owner()) {
            require(msg.value >= price * _mintAmount, "Not enough balance to complete transaction.");
            }

            for (uint256 i = 1; i <= _mintAmount; i++) {
                _safeMint(_to, supply + i);
            }
    }

    function mintpid(address _to, uint256 _mintAmount, uint256 _pid) public payable {
        TokenInfo storage tokens = AllowedCrypto[_pid];
        IERC20 paytoken;
        paytoken = tokens.paytoken;
        uint256 costval;
        costval = tokens.costvalue;
        uint256 supply = reserveFNFTDropsId + totalSupply();
        require(!paused);
        require(FNFTsId <= maxMint, "Mint limit reached");
        require(reserveFNFTDropsId + _mintAmount <= 6000, "Out of stock");
        require(_mintAmount > 0);
        require(_mintAmount <= maxMintAmount);
        require(supply + _mintAmount <= maxSupply);
            
            for (uint256 i = 1; i <= _mintAmount; i++) {
                require(paytoken.transferFrom(msg.sender, address(this), costval));
                _safeMint(_to, supply + i);
            }
        }
     
        function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
        {
            uint256 ownerTokenCount = balanceOf(_owner);
            uint256[] memory tokenIds = new uint256[](ownerTokenCount);
            for (uint256 i; i < ownerTokenCount; i++) {
                tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
            }
            return tokenIds;
        }
    
        
        function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory) {
            require(
                _exists(tokenId),
                "ERC721Metadata: URI query for nonexistent token"
                );
                
                string memory currentBaseURI = _baseURI();
                return
                bytes(currentBaseURI).length > 0 
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
                : "";
        }
        // only owner
        
        function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner() {
            maxMintAmount = _newmaxMintAmount;
        }
        
        // Base URI
                
        function setBaseURI(string memory _newBaseURI) public onlyOwner() {
            baseURI = _newBaseURI;
        }
        
        function setBaseExtension(string memory _newBaseExtension) public onlyOwner() {
            baseExtension = _newBaseExtension;
        }
        
        function pause(bool _state) public onlyOwner() {
            paused = _state;
        }

        function getNFTCost(uint256 _pid) public view virtual returns(uint256) {
            TokenInfo storage tokens = AllowedCrypto[_pid];
            uint256 costval;
            costval = tokens.costvalue;
            return costval;
        }

        function getCryptotoken(uint256 _pid) public view virtual returns(IERC20) {
            TokenInfo storage tokens = AllowedCrypto[_pid];
            IERC20 paytoken;
            paytoken = tokens.paytoken;
            return paytoken;
        }
        
        function withdrawcustom(uint256 _pid) public payable onlyOwner() {
            TokenInfo storage tokens = AllowedCrypto[_pid];
            IERC20 paytoken;
            paytoken = tokens.paytoken;
            paytoken.transfer(msg.sender, paytoken.balanceOf(address(this)));
        }
        
        function withdraw() public payable onlyOwner() {
            require(payable(msg.sender).send(address(this).balance));
        }
}