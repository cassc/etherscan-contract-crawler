pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721Enumerable.sol";

contract apemfers is ERC721Enumerable, Ownable {
    string public baseURI;

    address public sartoshi = 0xF7DcF798971452737f1E6196D36Dd215b43b428D;
    address public kingBlackBored = 0x6Cd2D84298F731fa443061255a9a84a09dbCA769;
    address public tropoFarmer = 0xA442dDf27063320789B59A8fdcA5b849Cd2CDeAC;
    address public franklin = 0x72FAe93d08A060A7f0A8919708c0Db74Ca46cbB6;
    address public deezeFi = 0xC46Db2d89327D4C41Eb81c43ED5e3dfF111f9A8f;
    address public seraStarGirl = 0xCb96594AbA4627e6064731b0098Dc97547b397BE;
    address public storm = 0x4385FF4B76d8A7fa8075Ed1ee27c82fFE0951456;
    address public joshOng = 0xaf469C4a0914938e6149CF621c54FB4b1EC0c202;
    address public danielgothits =  0xe9F1E4dC4D1F3F62d54d70Ea73A8c9B4Cd2BDE2D;
    address public keyboardmonkey = 0xe1D29d0a39962a9a8d2A297ebe82e166F8b8EC18;
    address public beanieMaxie = 0xaBF107de3E01c7c257e64E0a18d60A733Aad395d;
    address public j1mmy =  0x442DCCEe68425828C106A3662014B4F131e3BD9b;
    address public pranksy = 0xD387A6E4e84a6C86bd90C158C6028A58CC8Ac459;
    address public dfarmer =  0x7500935C3C34D0d48e9c388b3dFFa0AbBda52633;
    address public shamdoo = 0x11360F0c5552443b33720a44408aba01a809905e;
    address public farokh = 0xc5F59709974262c4AFacc5386287820bDBC7eB3A;

    address public withdrawAddress;

    bool    public publicSaleState = false;
    bool    public preSaleState = false;
    bytes32 public allowListMerkleRoot = 0x0;
    uint256 public MAX_SUPPLY = 8889;

    uint256 public constant MAX_PER_TX = 8;
    uint256 public constant RESERVES = 25;
    uint256 private price = 0.03333 ether;

    mapping(address => bool) public projectProxy;
    mapping(address => uint) public addressToMinted;

    constructor(
        string memory _baseURI,
        address _withdrawAddress
    ) ERC721("ape mfer", "apemfer")

    {
        baseURI = _baseURI;
        withdrawAddress = _withdrawAddress;

        // reserves
        _mint( sartoshi, 0);
        _mint( deezeFi, 1);
        _mint( dfarmer, 2);
        _mint( farokh, 3);
        _mint( franklin, 4);
        _mint( j1mmy, 5);
        _mint( joshOng, 6);
        _mint( keyboardmonkey, 7);
        _mint( kingBlackBored, 8);
        _mint( pranksy, 9);
        _mint( seraStarGirl, 10);
        _mint( shamdoo, 11);
        _mint( storm, 12);
        _mint( tropoFarmer, 13);
        _mint( beanieMaxie, 14);
        _mint( danielgothits, 15);

        for (uint256 i = 16; i <= 16+RESERVES; i++) {
            _mint( withdrawAddress, i);
        }
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }


    function flipProxyState(address proxyAddress) public onlyOwner {
        projectProxy[proxyAddress] = !projectProxy[proxyAddress];
    }

    function togglePublicSale() external onlyOwner {
        publicSaleState = true;
        preSaleState = false;
        delete allowListMerkleRoot;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }

    // This also starts the presale
    function setAllowlistMerkleRoot(bytes32 _allowListMerkleRoot) external onlyOwner {
        preSaleState = true;
        allowListMerkleRoot = _allowListMerkleRoot;
    }

    function allowListMint(uint256 count, bytes32[] calldata proof) public payable {
        uint256 totalSupply = _owners.length;
        require(totalSupply + count < MAX_SUPPLY, "Exceeds max supply.");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify( proof, allowListMerkleRoot, leaf), "wrong proof");
        require(count <= MAX_PER_TX, "exceeds tx max"); 
        require(count * price == msg.value, "invalid funds");

        addressToMinted[_msgSender()] += count;
        for(uint i = 0; i < count; i++) { 
            _mint(_msgSender(), totalSupply+i);
        }
    }

    function publicMint(uint256 count) public payable {
        uint256 totalSupply = _owners.length;
        require(publicSaleState == true, "public sale not started");
        require(totalSupply + count < MAX_SUPPLY, "Excedes max supply.");
        require(count <= MAX_PER_TX, "Exceeds max per transaction.");
        require(count * price == msg.value, "Invalid funds provided.");
    
        for(uint i = 0; i < count; i++) { 
            _mint(_msgSender(), totalSupply+i );
        }
    }

    function burn(uint256 tokenId) public { 
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not approved to burn.");
        _burn(tokenId);
    }

    function withdraw() external onlyOwner  {
        (bool success, ) = withdrawAddress.call{value: address(this).balance}("");
        require(success, "Failed to send to apetoshi.");
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) return new uint256[](0);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }


    function batchTransferFrom(address _from, address _to, uint256[] memory _tokenIds) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            transferFrom(_from, _to, _tokenIds[i]);
        }
    }

    function batchSafeTransferFrom(address _from, address _to, uint256[] memory _tokenIds, bytes memory data_) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            safeTransferFrom(_from, _to, _tokenIds[i], data_);
        }
    }

    function isOwnerOf(address account, uint256[] calldata _tokenIds) external view returns (bool){
        for(uint256 i; i < _tokenIds.length; ++i ){
            if(_owners[_tokenIds[i]] != account)
                return false;
        }

        return true;
    }

    function _mint(address to, uint256 tokenId) internal virtual override {
        _owners.push(to);
        emit Transfer(address(0), to, tokenId);
    }

    function setMintPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

}

 

contract OwnableDelegateProxy { }
contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}