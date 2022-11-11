// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


//tokenURI interface
interface iTokenURI {
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

contract JUNKeeeeS is Ownable, AccessControl , ERC721A{

    constructor(
    ) ERC721A("JUNK FOOD PARTY", "JFP") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE       , msg.sender);
        _setupRole(AIRDROP_ROLE      , msg.sender);
        setBaseURI("ipfs://bafybeihonzeenefx66rs7elq5vlaswpw7auhpbydagshjxymksvsd42ble/");
        _safeMint(0x2f624Bde8eE37793F0677E6b9eE97bf68AAC6172, 1);
    }


    //
    //withdraw section
    //

    address public constant withdrawAddress = 0x2f624Bde8eE37793F0677E6b9eE97bf68AAC6172;

    function withdraw() public onlyOwner {
        (bool os, ) = payable(withdrawAddress).call{value: address(this).balance}('');
        require(os);
    }


    //
    //mint section
    //

    uint256 public cost = 0;
    uint256 public maxSupply = 1111;
    uint256 public maxMintAmountPerTransaction = 10;
    uint256 public publicSaleMaxMintAmountPerAddress = 300;
    bool public paused = true;
    bool public onlyWhitelisted = true;
    bool public mintCount = true;
    mapping(address => uint256) public whitelistMintedAmount;
    mapping(address => uint256) public publicSaleMintedAmount;
    bytes32 public constant AIRDROP_ROLE = keccak256("AIRDROP_ROLE");

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract.");
        _;
    }
 
 


    //mint with mapping
    mapping(address => uint256) public whitelistUserAmount;
    function mint(uint256 _mintAmount ) public payable callerIsUser{
        require(!paused, "the contract is paused");
        require(0 < _mintAmount, "need to mint at least 1 NFT");
        require(_mintAmount <= maxMintAmountPerTransaction, "max mint amount per session exceeded");
        require(totalSupply() + _mintAmount <= maxSupply, "max NFT limit exceeded");
        require(cost * _mintAmount <= msg.value, "insufficient funds");
        if(onlyWhitelisted == true) {
            require( whitelistUserAmount[msg.sender] != 0 , "user is not whitelisted");
            if(mintCount == true){
                require(_mintAmount <= whitelistUserAmount[msg.sender] - whitelistMintedAmount[msg.sender] , "max NFT per address exceeded");
                whitelistMintedAmount[msg.sender] += _mintAmount;
            }
        }else{
            if(mintCount == true){
                require(_mintAmount <= publicSaleMaxMintAmountPerAddress - publicSaleMintedAmount[msg.sender] , "max NFT per address exceeded");
                publicSaleMintedAmount[msg.sender] += _mintAmount;
            }
        }
        _safeMint(msg.sender, _mintAmount);
    }

    function setWhitelist(address[] memory addresses, uint256[] memory saleSupplies) public onlyOwner {
        require(addresses.length == saleSupplies.length);
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelistUserAmount[addresses[i]] = saleSupplies[i];
        }
    }    





    function airdropMint(address[] calldata _airdropAddresses , uint256[] memory _UserMintAmount) public {
        require(hasRole(AIRDROP_ROLE, msg.sender), "Caller is not a air dropper");
        uint256 _mintAmount = 0;
        for (uint256 i = 0; i < _UserMintAmount.length; i++) {
            _mintAmount += _UserMintAmount[i];
        }
        require(0 < _mintAmount , "need to mint at least 1 NFT");
        require(totalSupply() + _mintAmount <= maxSupply, "max NFT limit exceeded");
        for (uint256 i = 0; i < _UserMintAmount.length; i++) {
            _safeMint(_airdropAddresses[i], _UserMintAmount[i] );
        }
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner() {
        maxSupply = _maxSupply;
    }

    function setPublicSaleMaxMintAmountPerAddress(uint256 _publicSaleMaxMintAmountPerAddress) public onlyOwner() {
        publicSaleMaxMintAmountPerAddress = _publicSaleMaxMintAmountPerAddress;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setOnlyWhitelisted(bool _state) public onlyOwner {
        onlyWhitelisted = _state;
    }

    function setMaxMintAmountPerTransaction(uint256 _maxMintAmountPerTransaction) public onlyOwner {
        maxMintAmountPerTransaction = _maxMintAmountPerTransaction;
    }
  
    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function setMintCount(bool _state) public onlyOwner {
        mintCount = _state;
    }
 


    //
    //URI section
    //

    string public baseURI;
    string public baseExtension = ".json";

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;        
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }



    //
    //interface metadata
    //

    iTokenURI public interfaceOfTokenURI;
    bool public useInterfaceMetadata = false;

    function setInterfaceOfTokenURI(address _address) public onlyOwner() {
        interfaceOfTokenURI = iTokenURI(_address);
    }

    function setUseInterfaceMetadata(bool _useInterfaceMetadata) public onlyOwner() {
        useInterfaceMetadata = _useInterfaceMetadata;
    }


    //
    //token URI
    //

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (useInterfaceMetadata == true) {
            return interfaceOfTokenURI.tokenURI(tokenId);
        }
        return string(abi.encodePacked(ERC721A.tokenURI(tokenId), baseExtension));
    }


    //
    //burnin' section
    //

    bytes32 public constant MINTER_ROLE  = keccak256("MINTER_ROLE");    
    function externalMint(address _address , uint256 _amount ) external payable {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        require( _nextTokenId() -1 + _amount <= maxSupply , "max NFT limit exceeded");
        _safeMint( _address, _amount );
    }



    //
    //viewer section
    //

    function tokensOfOwner(address owner) public view returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            TokenOwnership memory ownership;
            for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
    }




    //
    //override
    //

    function supportsInterface(bytes4 interfaceId) public view override(ERC721A , AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }


}