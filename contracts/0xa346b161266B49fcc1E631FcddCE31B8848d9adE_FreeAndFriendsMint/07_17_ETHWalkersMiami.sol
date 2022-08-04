// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./ERC721A.sol";

abstract contract ETHWALKERSMINTPASS is IERC721 {}

contract ETHWalkersMiami is ERC721A, Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using Address for address;
    using Strings for uint256;

    uint8 public constant maxMiamiMint = 20;
    uint8 public mintPassMulti = 3;
    uint public totalSupplyMiami = 10000;
    uint private _EWMReserve = 150;
    mapping(address => uint8) numberMinted;
    mapping(address => uint) numberMintedS1Survivor;
    mapping(address => uint) numberMintedS1Player;
    address payable public payoutsAddress = payable(address(0x2Ddaef54e3858F61df46D1cDDc9C3d8e01536878)); // payment splitter
    bool public changePayoutsLocked = false;
    uint public allowListSale = 1657569600; // 7/11 at 1pm PDT
    uint public publicSale = 1657656000; // 7/12 at 1pm PDT
    uint public endSale = 1658779200; // 7/25 at 1pm PDT
    mapping(address => bool) controllers;

    uint256 private _MiamiPrice = 42000000000000000; // 0.042 ETH
    string private baseURI;
    address public whitelistSigner = 0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC;
    address public S1PlayerSigner = 0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC;
    address public S1SurvivorSigner = 0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC;
    address ethWalkersMintPassAddress = 0x7eCa22913103e4a9D92b1FfD892b86d1906093E5;
    ETHWALKERSMINTPASS private ethWalkersMintPass = ETHWALKERSMINTPASS(ethWalkersMintPassAddress);
    mapping(uint256 => bool) mintPassRedeemed;

    constructor() ERC721A("ETH Walkers: Miami", "EWM") { }

    function setPrice(uint256 _newPrice) public onlyOwner {
        _MiamiPrice = _newPrice;
    }

    function setMintPassMulti(uint8 _newMulti) public onlyOwner {
        mintPassMulti = _newMulti;
    }

    function setPayoutsAddress(address newPayoutsAddress) public onlyOwner {
        require(!changePayoutsLocked, "Set payouts cannot be locked");
        payoutsAddress = payable(newPayoutsAddress);
    }

    function setChangePayoutsLocked() public onlyOwner() {
        require(!changePayoutsLocked, "Set payouts can only be locked once");
        changePayoutsLocked = true;
    }

    function getPrice() public view returns (uint256){
        return _MiamiPrice;
    }

    function setSaleTimes(uint[] memory _newTimes) external onlyOwner {
        require(_newTimes.length == 3, "You need to update all times at once");
        allowListSale = _newTimes[0];
        publicSale = _newTimes[1];
        endSale = _newTimes[2];
    }

    function mintReserveETHWalkersMiami(address _to, uint256 _reserveAmount) public onlyOwner {
        require(_reserveAmount > 0 && _reserveAmount <= _EWMReserve, "Reserve limit has been reached");
        require(totalSupply().add(_reserveAmount) <= totalSupplyMiami, "No more tokens left to mint");
        _EWMReserve = _EWMReserve.sub(_reserveAmount);
        _safeMint(_to ,_reserveAmount);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function setWLSignerAddress(address signer) public onlyOwner {
        whitelistSigner = signer;
    }

    function setPlayerSignerAddress(address signer) public onlyOwner {
        S1PlayerSigner = signer;
    }

    function setSurvivorSignerAddress(address signer) public onlyOwner {
        S1SurvivorSigner = signer;
    }

    //Constants for signing whitelist
    bytes32 constant DOMAIN_SEPERATOR = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256("Signer NFT Distributor"),
            keccak256("1"),
            uint256(1),
            address(0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC)
        ));

    bytes32 constant ENTRY_TYPEHASH = keccak256("Entry(uint256 index,address wallet)");

    function allowlistETHWalkersMiami(uint8 numberOfTokens, uint index, bytes memory signature) external payable whenNotPaused {
        require(block.timestamp >= allowListSale && block.timestamp <= endSale, "Allowlist-sale must be started");
        require(numberMinted[_msgSender()] + numberOfTokens <= maxMiamiMint, "Exceeds maximum per wallet");
        require(msg.value >= _MiamiPrice.mul(numberOfTokens), "Ether value is incorrect. Check and try again");
        require(!isContract(_msgSender()), "I fight for the user! No contracts");
        require(totalSupply().add(numberOfTokens) <= totalSupplyMiami, "Purchase exceeds max supply of ETH Walkers");

        // verify signature
        bytes32 digest = getDigest(index);
        address claimSigner = ECDSA.recover(digest, signature);
        require(claimSigner == whitelistSigner, "Invalid Message Signer.");

        _mint(_msgSender(), numberOfTokens);
        numberMinted[_msgSender()] += numberOfTokens;

        (bool sent, ) = payoutsAddress.call{value: address(this).balance}("");
        require(sent, "Something wrong with payoutsAddress");
    }

    function mintETHWalkersMiami(uint numberOfTokens) external payable whenNotPaused {
        require(numberOfTokens > 0 && numberOfTokens <= maxMiamiMint, "Oops - you can only mint 20 at a time");
        require(msg.value >= _MiamiPrice.mul(numberOfTokens), "Ether value is incorrect. Check and try again");
        require(!isContract(_msgSender()), "I fight for the user! No contracts");
        require(totalSupply().add(numberOfTokens) <= totalSupplyMiami, "Purchase exceeds max supply of ETH Walkers");
        require(block.timestamp >= publicSale && block.timestamp <= endSale, "Public sale not started");

        _mint(_msgSender(), numberOfTokens);

        (bool sent, ) = payoutsAddress.call{value: address(this).balance}("");
        require(sent, "Something wrong with payoutsAddress");
    }

    // Method allows for S1 Player free mints if isSurvivor is FALSE and Signer is S1PlayerSigner
    // otherwise, S1 Survivor free mints if isSurvivor is TRUE and Signer is S1SurvivorSigner
    function mintS1PlayerFreeMints(uint freemints, bytes memory signature, bool isSurvivor) external whenNotPaused {
        require(block.timestamp >= allowListSale && block.timestamp <= endSale, "Pre-sale must be started");
        require(!isContract(_msgSender()), "I fight for the user! No contracts");

        // verify signature
        bytes32 digest = getDigest(freemints);
        address claimSigner = ECDSA.recover(digest, signature);
        if(isSurvivor){
            require(numberMintedS1Survivor[_msgSender()] < freemints, "Exceeds maximum per wallet");
            require(claimSigner == S1SurvivorSigner, "Invalid Message Signer.");
            _mint(_msgSender(), freemints);
            numberMintedS1Survivor[_msgSender()] += freemints;
        }
        else {
            require(numberMintedS1Player[_msgSender()] < freemints, "Exceeds maximum per wallet");
            require(claimSigner == S1PlayerSigner, "Invalid Message Signer.");
            _mint(_msgSender(), freemints);
            numberMintedS1Player[_msgSender()] += freemints;
        }
    }

    function mintViaMintPass(uint256[] memory ids) external {
        require(block.timestamp >= allowListSale && block.timestamp <= endSale, "Pre-sale must be started");
        require(!isContract(_msgSender()), "I fight for the user! No contracts");

        for(uint i = 0; i < ids.length; i++) {
            uint id = uint(ids[i]);
            require(ethWalkersMintPass.ownerOf(id) == _msgSender(), "Must own ETH Walkers Mint Pass to mint here");
            require(!mintPassRedeemed[id], "This pass already redeemed");
            mintPassRedeemed[ids[i]] = true;
        }

        _mint(_msgSender(), (ids.length * mintPassMulti));
    }

    function controllerMint(address to, uint256 amount) external {
        require(controllers[msg.sender], "Only controllers can mint");
        require(totalSupply().add(amount) <= totalSupplyMiami, "No more tokens left to mint");
        _mint(to, amount);
    }

    function setNewMaximumETHWalkersCount(uint16 newMaximumCount) public onlyOwner {
        require(newMaximumCount <= totalSupplyMiami, "You can't set the total this high");
        if(newMaximumCount >= totalSupply()){
            totalSupplyMiami = newMaximumCount; // Can only lower cap
        }
    }

    function getDigest(uint index) internal view returns(bytes32){
        bytes32 digest = keccak256(abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPERATOR,
                keccak256(abi.encode(
                    ENTRY_TYPEHASH,
                    index,
                    _msgSender()
                ))
            ));
        return digest;
    }

    function isContract(address _addr) private view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    function setPaused(bool _paused) external onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    function addController(address controller) external onlyOwner {
        controllers[controller] = true;
    }

    function removeController(address controller) external onlyOwner {
        controllers[controller] = false;
    }

    function tokensOfOwner(address _owner) external view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            uint256 current_token = 0;
            for (index = 0; index < totalSupply() && current_token < tokenCount; index++) {
                if (ownerOf(index) == _owner){
                    result[current_token] = index;
                    current_token++;
                }
            }
            return result;
        }
    }

}