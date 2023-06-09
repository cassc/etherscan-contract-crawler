// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "hardhat/console.sol";
    interface iBattleRoyale {
    function pickWinner(uint256[] calldata doomed)
        external 
        returns (uint256);
}
   interface iAllowList {
    function isAllowed(address address_, uint8 amount, bytes32[] memory proof_)
        external
        view
        returns (bool);
}

contract CrankyCritters is ERC721, Ownable, VRFConsumerBase {
    using SafeMath for uint256;
    using Strings for uint256;

    //CONST
    uint256 public constant CC_ENRAGED = 100;
    uint256 public constant CC_MAX = 6000;
    uint256 public constant CC_MAX_ENRAGED = 100;
    uint256 public constant PURCHASE_LIMIT = 6;
    string public constant PROVENANCE_HASH = "72a30f3d9be178d32c24f16833898e96e46910d04c3c4a822f0075fbfe4af729";
    uint256 public constant NUMBEROFDOOMED = 3;

    mapping(address => uint8) private _nrMinted;
    

    bool public isPreSaleActive;
    bool public isPublicSaleActive;
    uint256 public totalEnragedSupply;
    uint256 public offsetIndex;
    bytes32 internal keyHash;
    uint256 internal fee;
    string private _baseTokenURI;
    string private _ultraCrankyTokenURI;
    string private _placeholderURI;
    uint256 public totalSupply;
    
    // External Contracts
    address public _brAdress;
    iAllowList allowList;
    uint256 private _price = 0.06 ether;



    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenUri,
        address _VRFCoordinator,
        address _LinkToken,
        bytes32 _keyhash,
        address _allowListContract
    ) ERC721(name, symbol) VRFConsumerBase(_VRFCoordinator, _LinkToken) {
        _placeholderURI = baseTokenUri;
        _ultraCrankyTokenURI = baseTokenUri;
        keyHash = _keyhash;
        fee = 2 * 10**18; 
        allowList = iAllowList(_allowListContract); 
    }

    function getRandomNumber() internal returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");
        return requestRandomness(keyHash, fee);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
       offsetIndex = randomness.mod(CC_MAX) +1;
    }

    function setBrAddress(address brAdress) public onlyOwner {
        _brAdress = brAdress;
    }

    function getPrice(uint256 quantity) public view returns (uint256) {
        return _price * quantity;
    }

    //mint
   function mintTokens(uint8 quantity) private {
        for (uint256 i = 0; i < quantity; i++) {
            uint256 newTokenId = totalSupply + 1;
            _safeMint(msg.sender, newTokenId);
           totalSupply++; 
        }
        _nrMinted[msg.sender] += quantity;
    }

    function generalMintingRules(uint256 value, uint256 quantity) private view {
        require(msg.sender == tx.origin, "contracts can't mint");
        require(totalSupply < CC_MAX, "Sold Out, Gaaaah");
        require(totalSupply + quantity <= CC_MAX, "this exceed the public amount");
        require(value == getPrice(quantity), "wrong eth value");
    }

    function presalemint(uint8 numberOfTokens, bytes32[] calldata proof) external payable {
        require(isPreSaleActive, "PreSale is not active");
        require(_nrMinted[msg.sender] == 0, "You had your chance,good day sir");
        require(allowList.isAllowed(msg.sender, (numberOfTokens), proof), "Not on Presale with this amount");
        generalMintingRules(msg.value, numberOfTokens);
        mintTokens(numberOfTokens);
    }

    function mint(uint8 numberOfTokens) external payable {
        require(isPublicSaleActive, "Public Sale is not active");
        require(numberOfTokens <= PURCHASE_LIMIT,"Would exceed purchase limit");
        generalMintingRules(msg.value, numberOfTokens);
        mintTokens(numberOfTokens);
    }

    function reserveTokens(uint8 quantity) public onlyOwner {
         require(totalSupply + quantity <= CC_MAX, "this exceed the public amount");
        mintTokens(quantity);
    }

    //battleRoyale

    function battleRoyale(uint256[] calldata doomed) external {
        require(totalEnragedSupply < CC_MAX_ENRAGED);
        require(_brAdress != address(0), "Battle royale is not active");
        require(doomed.length == NUMBEROFDOOMED, "number of doomed is wrong");
        require(
            ownsAllDoomed(msg.sender, doomed),
            "not all ids belong to sender"
        );
        require(msg.sender == tx.origin, "contracts can't play");
        uint256 tokenId = iBattleRoyale(_brAdress).pickWinner(doomed) + totalEnragedSupply + 1;
        for (uint256 i; i < doomed.length; i++) {
            _burn(doomed[i]);
        }
          totalEnragedSupply += 1;
        _safeMint(msg.sender, tokenId);
    }


    function ownsAllDoomed(address account, uint256[] calldata doomed)
        internal
        view
        returns (bool)
    {
        for (uint256 i = 0; i < doomed.length; i++) {
            if (ownerOf(doomed[i]) != account) {
                return false;
            }
        }
        return true;
    }

      function getWalletMintCount(address addr) public view returns (uint256) {
        return _nrMinted[addr];
    }

   function walletOfOwner(address address_)
        public
        view
        returns (uint256[] memory)
    {
        uint256 _balance = balanceOf(address_);
        uint256[] memory _tokens = new uint256[](_balance);
        uint256 _index;

        for (uint256 i = 1; i < (CC_MAX + 600); i++) {
            if (_exists(i)){
            if (address_ == ownerOf(i)) {
                _tokens[_index] = i;
                _index++;
            }}
        }

        return _tokens;
    }

    //owner functions
    function toggleIsActive() external onlyOwner {
        isPublicSaleActive = !isPublicSaleActive;
    }

    function togglePresaleActive() external onlyOwner {
        isPreSaleActive = !isPreSaleActive;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

     function setPrice(uint256 _newPrice) public onlyOwner {
          _price = _newPrice;
      }

    //metaData
    function setBaseURI(string calldata URI) external onlyOwner {
        //When we upload the metadata the first time, offsetindex will be set, ensuring no one knows the offset before data is uploaded
        if (offsetIndex == 0) {
            getRandomNumber();
        }
        _baseTokenURI = URI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setultraCrankyURI(string calldata URI) external onlyOwner {
        _ultraCrankyTokenURI = URI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(_exists(tokenId), "Token does not exist");
        if(offsetIndex == 0){
            return _placeholderURI;
        }
        if (tokenId <= CC_MAX){
            uint256 offsetId = tokenId.add(CC_MAX.sub(offsetIndex)).mod(CC_MAX) +1;
            return string(abi.encodePacked(_baseURI(), offsetId.toString()));
        } else {
            return
                string(abi.encodePacked(_ultraCrankyTokenURI, tokenId.toString()));
        }
    }
}