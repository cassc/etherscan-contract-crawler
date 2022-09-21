// SPDX-License-Identifier: MIT
// solhint-disable-next-line
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NftMinter is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using SafeMath for uint256;

    bool public emergencyStop = false;
    uint256 internal maxAmount = 1;
    uint256 internal maxSupply = 5000;
    string internal baseExtension = ".json";
    string internal baseURI;
    bool public revealed = false;
    string public notRevealedUri;
    uint256 public mintIndex = 300;
    uint256 public reserveMintIndex = 0;
    uint256 public reservedNftMintCount = 0;
    uint256 public publicNftMintCount = 0;
    uint256 public whitelistMintPeriod;
    bytes32 public root;
    address[] public airdropAddresses;

    mapping(address => uint) internal reserveList;
    mapping(address => uint) internal airdropList;
    mapping(address => uint) internal publicMinted;
    mapping(address => uint) internal whitelistedMinted;

    event Mint(address minter, uint256 _tokenAmount, uint256 _tokenPrice);
    event SetMaxAmount(uint256 _maxAmount);
    event SetMaxSupply(uint256 _maxSupply);
    event SetBaseURI(string _uri);
    event SetBaseExtension(string _baseExtension);
    event Withdraw(uint256 amount);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _initNotRevealedUri,
        bytes32 _root
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
        root = _root;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");

        if(revealed == false) {
            return bytes(notRevealedUri).length > 0
            ? string(abi.encodePacked(notRevealedUri, tokenId.toString(), baseExtension))
            : "";
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
            : "";
    }

    function airdropMint() external onlyOwner {
        require(!emergencyStop, "Contract is paused");
        uint256 supply = totalSupply();
        for(uint256 i = 0; i < airdropAddresses.length; i++){
            require(airdropList[airdropAddresses[i]].add(supply) <= 4500, "Exceeded max supply");
            for(uint256 j = 0; j < airdropList[airdropAddresses[i]]; j++){
                if((mintIndex.add(1) > 3000 && mintIndex.add(1) < 3100) || (mintIndex.add(1) > 4000 && mintIndex.add(1) < 4100)){
                    mintIndex = mintIndex.add(100);
                }
                _safeMint(airdropAddresses[i], mintIndex.add(1));
                mintIndex = mintIndex.add(1);
            }
            emit Mint(airdropAddresses[i], airdropList[airdropAddresses[i]], 0);
        }
    }

    function publicMint(uint256 _amount) external nonReentrant{
        require(block.timestamp > whitelistMintPeriod,"public mint not started");
        require(!emergencyStop, "Contract is paused");
        require(_amount > 0, "Value less than 0");
        uint256 supply = totalSupply();
        require(_amount.add(supply) <= 4500, "Exceeded max supply");
        if (msg.sender != owner()) {
            require(publicMinted[msg.sender] <= 1, "Limit Exceeded");
            require(_amount <= maxAmount, "Exceeded max amount");
            require(publicNftMintCount <= 1000,"Public nft Minted");
        }
        publicMinted[msg.sender]  = publicMinted[msg.sender].add(_amount);
        publicNftMintCount = publicNftMintCount.add(_amount);
        for (uint256 i = 1; i <= _amount; i++) {
            if((mintIndex.add(1) > 3000 && mintIndex.add(1) < 3100) || (mintIndex.add(1) > 4000 && mintIndex.add(1) < 4100)){
                mintIndex = mintIndex.add(100);
            }
            _safeMint(msg.sender, mintIndex.add(1));
            mintIndex = mintIndex.add(1);
        }
        emit Mint(msg.sender, _amount, 0);
    }


    function whitelistMint(bytes32[] calldata proof,uint _level, uint _amount) external nonReentrant{
        require(block.timestamp <= whitelistMintPeriod,"Minting period over");
        require(_amount > 0, "Value less than 0");
        require(!emergencyStop, "Contract is paused");
        require(whitelistedMinted[msg.sender].add(_amount) <= _level, "Limit Exceeded");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender,_level));
        require(isValid(proof,leaf), "Invalid Proof");
        uint256 supply = totalSupply();
        require(_amount.add(supply) <= 4500, "Exceeded max supply");
        whitelistedMinted[msg.sender] = whitelistedMinted[msg.sender].add(_amount);
        for (uint256 i = 1; i <= _amount; i++) {
            if((mintIndex.add(1) > 3000 && mintIndex.add(1) < 3100) || (mintIndex.add(1) > 4000 && mintIndex.add(1) < 4100)){
                mintIndex = mintIndex.add(100);
            }
            _safeMint(msg.sender, mintIndex.add(1));
            mintIndex = mintIndex.add(1);
        }
        emit Mint(msg.sender, _amount, 0);
    }

    function reserveMint(uint _amount) external {
        require(reserveList[msg.sender] > 0, "Not a part of Allowlist");
        require(!emergencyStop, "Contract is paused");
        require(_amount > 0, "Value less than 0");
        require(reservedNftMintCount.add(_amount) <= 500,"Reserved nft minted");
        require(_amount <= reserveList[msg.sender], "Exceeded max amount");
        uint256 supply = totalSupply();
        require(_amount + supply <= maxSupply, "Exceeded max supply");
        reserveList[msg.sender] = reserveList[msg.sender].sub(_amount);
        reservedNftMintCount = reservedNftMintCount.add(_amount);
        for (uint256 i = 1; i <= _amount; i++) {
            if(reserveMintIndex.add(1) > 300 && reserveMintIndex.add(1) <= 3000){
                reserveMintIndex = 3000;
            }else if(reserveMintIndex.add(1) > 3100 && reserveMintIndex.add(1) <= 4000){
                reserveMintIndex = 4000;
            }
            _safeMint(msg.sender, reserveMintIndex.add(1));
            reserveMintIndex = reserveMintIndex.add(1);
        }
        emit Mint(msg.sender, _amount, 0);
    }

    function isValid(bytes32[] memory proof, bytes32 leaf) public view returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }

    function ownerOfTokens(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 balance = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](balance);
        for (uint256 i; i < balance; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }


    function setMaxAmount(uint256 _maxAmount) public onlyOwner {
        require(_maxAmount > 0, "Value less than 0");
        maxAmount = _maxAmount;
        emit SetMaxAmount(maxAmount);
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        require(_maxSupply > 0, "Value less than 0");
        maxSupply = _maxSupply;
        emit SetMaxSupply(maxSupply);
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        baseURI = _uri;
        emit SetBaseURI(baseURI);
    }

    function setBaseExtension(string memory _baseExtension) public onlyOwner {
        baseExtension = _baseExtension;
        emit SetBaseExtension(baseExtension);
    }

    function setReserveList(address[] memory addresses, uint256[] memory numSlots) external onlyOwner {
        (
            addresses.length == numSlots.length,
            "addresses does not match numSlots length"
        );
        for (uint256 i = 0; i < addresses.length; i++) {
            reserveList[addresses[i]] = numSlots[i];
        }
    }

    function setRootHash(bytes32 _newRoot) external onlyOwner {
        root = _newRoot;
    }

    function setAirdropList(address[] memory addresses, uint256[] memory numSlots) external onlyOwner {
        (
            addresses.length == numSlots.length,
            "addresses does not match numSlots length"
        );
        for (uint256 i = 0; i < addresses.length; i++) {
            airdropList[addresses[i]] = numSlots[i];
        }
        airdropAddresses = addresses;
    }

    function reveal() public onlyOwner {
      revealed = true;
  }

    function getMaxAmount() public view returns (uint256) {
        return maxAmount;
    }

    function getMaxSupply() public view returns (uint256) {
        return maxSupply;
    }

    function getBaseURI() public view returns (string memory) {
        return baseURI;
    }

    function getBaseExtension() public view returns (string memory) {
        return baseExtension;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function stopContract() public onlyOwner {
        emergencyStop = true;
    }

    function startContract() public onlyOwner {
        emergencyStop = false;
    }

    function setWhitelistMintPeriod(uint _timePeriod) public onlyOwner {
        whitelistMintPeriod = block.timestamp.add(_timePeriod);
    }


    function transferOwnership(address newOwner)
        public
        virtual
        override
        onlyOwner
    {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }
}