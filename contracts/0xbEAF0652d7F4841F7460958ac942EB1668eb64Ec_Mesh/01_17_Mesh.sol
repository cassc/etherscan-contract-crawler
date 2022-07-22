// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./ERC721.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

struct Meshie {
    uint256 startTimestamp;
    uint256 endTimestamp;
    uint256 probationSeconds;
    bool isSudo;
}

contract Mesh is 
    ERC721Upgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    uint256 constant private THREE_MONTHS = 7776000;
    string constant private _baseuri = "https://nft.dltx.io/metadata/";
    mapping (uint256 => uint256) private _upgrades;
    mapping (address => uint256) private _nftHodlers;

    uint256 public totalSupply;
    mapping (uint256 => Meshie) public mesh;
    
    event RequestingSudoUpgrade(address indexed who, uint256 index);
    event Upgraded(address indexed who, uint256 index);
    event WelcomeToTheMesh(address indexed who, uint256 index);
    
    modifier onlySudo() {
        uint256 index = _nftHodlers[msg.sender];
        require(mesh[index].isSudo = true, "su != true");
        _;
    }

    function initialize() public initializer {
        __Ownable_init();
        __ERC721_init("DLTx Mesh", "Mesh");
    }

    function mint(
        address to,
        uint256 startTimestamp
    ) public onlyOwner() {
        require(to != address(0), "Invalid address");
        if (startTimestamp == 0) startTimestamp = block.timestamp;

        if (totalSupply == 0)
            mesh[totalSupply] = Meshie(startTimestamp, 0, THREE_MONTHS, true);

        if (totalSupply > 0)
            mesh[totalSupply] = Meshie(startTimestamp, 0, THREE_MONTHS, false);
        
        _safeMint(to, totalSupply);
        _nftHodlers[to] = totalSupply;
        totalSupply++;
    }

    function terminateNow(uint256 index) external onlyOwner() {
        terminate(index, block.timestamp);
    }

    function terminate(uint256 index, uint256 endTimestamp) public onlyOwner() {
        require(index < totalSupply, "Invalid index");
        require(mesh[index].endTimestamp == 0, "Already terminated");
        mesh[index].endTimestamp = endTimestamp;
    }

    function setProbation(uint256 index, uint256 value) external onlyOwner() {
        require(value > 0);
        require(index < totalSupply, "No such Meshie");
        mesh[index].probationSeconds = value;
    }

    function setStartTimestamp(uint256 index, uint256 value) external onlyOwner {
        require(
            mesh[index].endTimestamp == 0 ||
                mesh[index].startTimestamp < mesh[index].endTimestamp,
            "Start date not lower than end"
        );
        mesh[index].startTimestamp = value;
    }
    
    function employed(uint256 index) external view returns (bool) {
        return mesh[index].endTimestamp == 0;
    }

    function onProbation(uint256 index) external view returns (bool) {
        return block.timestamp <= mesh[index].startTimestamp + mesh[index].probationSeconds;
    }

    function approveUpgrade(uint256 index) external onlySudo {
        require(mesh[index].isSudo == false, "Already one!");

        _upgrades[index]++;

        if (_upgrades[index] > 1) {
            mesh[index].isSudo = true;
            address who = ownerOf(index);
            emit Upgraded(who, index);
        }
    }
    
    function tokenURI(uint256 tokenId)
        public view override returns (string memory)
    {
        string memory superUri = super.tokenURI(tokenId);
        return string(abi.encodePacked(superUri, ".json"));
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseuri;
    }

    // The Mesh NFT is not transferable.
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        revert("Not so fast");
    }

    /** @dev Protected UUPS upgrade authorization function */
    function _authorizeUpgrade(address) internal override onlyOwner {}
}