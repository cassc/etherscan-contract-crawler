// SPDX-License-Identifier: MIT
/*
- - | - | - | - | - | - | - | - | - - - - - - - - - - - - - - - - - - - ( ) - ( ) - ( ) - - - - -
-                                                                                               -
-------------o            ..- ~~ " ~~ -..                                                       -
------o                -="               "=-                       o-----------------------------
-                   ++     _. - ~"~ - ._     ++                                o-----------------
-                 +.    ./'             '\.    +.                                               -
-               .:    -'                   '-    :.                                             -
-              :+   .>                       \.   +.                                            -
-             .+   -        :::      ::: :::  >   '+       :::                                  -
-             +"  ./        :::      ::: :::               :::                                  -
-            ':   -         :::      ::: :::  .::::::::::. :::::::::::. .:::::::::::            -
-            ':  '.         :::::::::::: :::  :::::::::::: :::::::::::: :::"""""""""            -
-            ':  '.         "::::::::::: :::  :::      ::: :::      ::: :::::::::::.            -
-            ':  '.                  ::: :::. :::  ::: ::: :::      :::  """""""":::            -
-             +.  -.        :::::::::::: +::: +::::::: ::: :::::::::::: ::::::::::::            -
O             ':   -.       """""""""""   """  """"""  """  """"""""""  """""""""""             -
O              ':   \.                       ./   :'                                            -
O               '+    -.                   .-    +'                                             -
O                 +.    -.               .-    .+                                               -
o                    +.    " ~ - . - ~ "    .+                                                  -
o                      "+:_             _:+"                                                    -
-                           " ~ - - ~ "                                                         -
-     _____                             __                ____   _       __     __       _____  -
-    / ___/___  ______   ______ _____  / /______   ____  / __/  | |     / /__  / /_     |__  /  -
-    \__ \/ _ \/ ___/ | / / __ `/ __ \/ __/ ___/  / __ \/ /_    | | /| / / _ \/ __ \     /_ <   -
-   ___/ /  __/ /   | |/ / /_/ / / / / /_(__  )  / /_/ / __/    | |/ |/ /  __/ /_/ /   ___/ /   -
-  /____/\___/_/    |___/\__,_/_/ /_/\__/____/   \____/_/       |__/|__/\___/_.___/   /____/    -
-                                                                                               -
-                                                                           >/. Ylabs.one </.   -
-                                                         o--------------------------------------
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
*/
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721Y.sol";


contract YuaVerse is ERC721Y, Ownable {

    uint256 public constant YUA_SUPPLY = 7777;
    uint256 public constant RESERVE = 777;
    uint256 public YUA_PRICE;

    string public baseURI;
    bytes32 public merkleRoot;
    
    bool public giftState;
    bool public isPhaseTwoActive;
    uint8 public lockState;
    address public proxyRegistryAddress;

    mapping(address => bool) public projectProxy;
    mapping(address => bool) public isMintedPhaseOne;
    mapping(address => bool) public isMintedPhaseTwo;
    mapping(address => uint256) public mintedSoFar;

    constructor(address _proxyRegistryAddress, string memory _baseURI) ERC721Y("YuaVerse", "YUAVERSE") {
        proxyRegistryAddress = _proxyRegistryAddress; 
        baseURI = _baseURI;
        lockState = 0;
        isPhaseTwoActive = false;
        giftState = false;
        YUA_PRICE = 0;
    } 

    function setProxyRegistryAddress(address _proxyRegistryAddress) external onlyOwner {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function flipProxyState(address proxyAddress) public onlyOwner {
        projectProxy[proxyAddress] = !projectProxy[proxyAddress];
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        require(lockState == 0);
        merkleRoot = _merkleRoot;
    }

     function lockTheDoorForEverAndEver() external onlyOwner {
         require(lockState == 0);
         lockState = 1;
    }

    function setPrice(uint256 _price) external onlyOwner {
        require(lockState == 0);
         YUA_PRICE = _price;
    }

    function toggleIntoPhaseTwo() external onlyOwner {
        isPhaseTwoActive = !isPhaseTwoActive;
    }

    function _leaf(string memory allowance, string memory payload) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(payload, allowance));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof) internal view returns (bool) {
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    modifier isActive() {
            require(isPhaseTwoActive == true, "The phase two minting is not active!");
            _;
    }

    function mintFreePhaseOne(uint256 allowance, bytes32[] calldata proof) external {

        uint256 totalSupply = _owners.length;
        require(totalSupply + allowance < YUA_SUPPLY, "Uh-oh there is no more YUA!");
        string memory payload = string(abi.encodePacked(msg.sender));
        require(_verify(_leaf(Strings.toString(allowance), payload), proof), "Wrong proof or the contract is locked for ever!");
        require(!isMintedPhaseOne[msg.sender], "You already minted your allowance!");

        for(uint i; i < allowance; i++) { 
            _mint(_msgSender(), totalSupply + i);
        }
        isMintedPhaseOne[msg.sender] = true;
    }
    function mintFreePhaseTwo(uint256 allowance, bytes32[] calldata proof) external isActive {
        
        uint256 totalSupply = _owners.length;
        require(totalSupply + allowance < YUA_SUPPLY, "Uh-oh there is no more YUA!");
        string memory payload = string(abi.encodePacked(msg.sender));
        require(_verify(_leaf(Strings.toString(allowance), payload), proof), "Wrong proof or the contract is locked for ever!");
        require(!isMintedPhaseTwo[msg.sender], "You already minted your allowance!");

        for(uint i; i < allowance; i++) { 
            _mint(_msgSender(), totalSupply + i);
        }
        isMintedPhaseTwo[msg.sender] = true;
    }

    function mintPrivate(uint256 num_tokens, uint256 allowance, bytes32[] calldata proof) external payable {

        require(YUA_PRICE != 0);
        uint256 totalSupply = _owners.length;
        require(totalSupply + allowance < YUA_SUPPLY, "Uh-oh there is no more YUA!");
        string memory payload = string(abi.encodePacked(msg.sender));
        require(_verify(_leaf(Strings.toString(allowance), payload), proof), "Wrong proof or the contract is locked for ever!");
        require(mintedSoFar[msg.sender] + num_tokens <= allowance, "More than your Allowance!");
        require(YUA_PRICE * num_tokens <= msg.value, "Insufficient fund!");
 
        mintedSoFar[msg.sender] += num_tokens;
        for(uint i; i < num_tokens; i++) { 
            _mint(_msgSender(), totalSupply + i);
        }
    }

    function giftThem(address[] calldata _first25) public onlyOwner { 
        require(giftState == false);
        for(uint256 i; i < _first25.length; i++) {
            _mint(_first25[i], i);
        }
        giftState = true;
    }

    function teamReserve() public onlyOwner {

        uint256 totalSupply = _owners.length;
        require(lockState == 0);
        require(totalSupply + RESERVE < YUA_SUPPLY, "Dman!");
        for(uint256 i; i < RESERVE; i++)
            _mint(_msgSender(), totalSupply + i);
    }

    function _mint(address to, uint256 tokenId) internal virtual override {
        _owners.push(to);
        emit Transfer(address(0), to, tokenId);
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }

    function setBaseURI(string memory _baseURI) external onlyOwner() {
        baseURI = _baseURI;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);

    }

    function isApprovedForAll(address _owner, address operator) public view override returns (bool) {
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == operator || projectProxy[operator]) return true;
        return super.isApprovedForAll(_owner, operator);
    }

}

contract OwnableDelegateProxy { }
contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}