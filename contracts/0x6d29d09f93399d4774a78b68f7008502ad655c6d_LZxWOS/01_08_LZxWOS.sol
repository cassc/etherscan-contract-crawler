// SPDX-License-Identifier: LGPL-3.0-or-later 

pragma solidity ^0.8.4;

/**
*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
*:::::::::::::::::           :::::::::::::::::::                         ::::::::::::::::::
*:::::::::::::::.              .:::::::::::::.                             .:::::::::::::::
*::::::::::::::.                .::::::::::::                               :::::::::::::::
*::::::::::::::                  ::::::::::::                               :::::::::::::::
*:::::::::::::.                 .::::::::::::                               :::::::::::::::
*:::::::::::::.                 .::::::::::::.                             .:::::::::::::::
*:::::::::::::                 .::::::::::::::.                           .::::::::::::::::
*:::::::::::::                .::::::::::::::::... .....::.              ::::::::::::::::::
*:::::::::::::                :::::::::::::::::::::::::.               .:::::::::::::::::::
*:::::::::::::               .:::::::::::::::::::::::.              .::::::::::::::::::::::
*:::::::::::::               :::::..    .:::::::::.               .::::::::::::::::::::::::
*:::::::::::::.               .          .::::::.               ....      .::::::::::::::::
*:::::::::::::.                           .::::.                            :::::::::::::::
*::::::::::::::                           .::.                              .::::::::::::::
*::::::::::::::.                          .::                                ::::::::::::::
*:::::::::::::::                          ::.                                ::::::::::::::
*::::::::::::::::                       .::::                               .::::::::::::::
*:::::::::::::::::.                 ...::::::.                             .:::::::::::::::
*:::::::::::::::::::::..........:::::::::::::::::::....................::::::::::::::::::::
*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
*::::::::::::::::::::::::::::::::::::::::::.:::::::.:::::::::::::::::::::::::::::::::::::::
*::::::::::::::::::::::::::::::::::::::::::  .:::.  .::::::::::::::::::::::::::::::::::::::
*:::::::::::::::::::::::::::::::::::::::::::.  .. .::::::::::::::::::::::::::::::::::::::::
*:::::::::::::::::::::::::::::::::::::::::::::   .:::::::::::::::::::::::::::::::::::::::::
*::::::::::::::::::::::::::::::::::::::::::::  .  .::::::::::::::::::::::::::::::::::::::::
*::::::::::::::::::::::::::::::::::::::::::. .:::. .:::::::::::::::::::::::::::::::::::::::
*::::::::::::::::::::::::::::::::::::::::::..:::::..:::::::::::::::::::::::::::::::::::::::
*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
*::::..:::::::::::::...:::::::::::::..::::::::::::.......:::::::::::::::::::......:::::::::
*:::    :::::::::::.   .:::::::::::   .:::::::.             .   ::::::::.            .:::::
*:::.   .:::::::::.     ::::::::::.   ::::::.     ..:::...     .:::::::.   ..:::...    ::::
*::::.   .::::::::       :::::::::   .:::::    .:::::::::.      .:::::.   :::::::::::.:::::
*:::::    :::::::.   :   .:::::::   .:::::    ::::::::::.  .:.   .::::.   :::::::::::::::::
*:::::.   .::::::   .:.   ::::::.   :::::.   :::::::::.   .:::    :::::     ..:::::::::::::
*::::::.   .::::   .:::    ::::.   .:::::.   ::::::::   .:::::.   ::::::.          ..::::::
*:::::::.   :::.   :::::   .:::   .::::::.   ::::::.   .::::::.   ::::::::::...       .::::
*::::::::   .::   .:::::.   .:.   :::::::.   .:::.   .::::::::   .:::::::::::::::::.   .:::
*::::::::.   .   .:::::::.   .   :::::::::.   .:.   ::::::::.    :::::::::::::::::::.   :::
*:::::::::.      :::::::::      .::::::::::.      .:::::::.    .::::::   ..::::::::.   .:::
*::::::::::     .:::::::::.    .:::::::::::::                ..:::::::.        ..     .::::
*:::::::::::   .:::::::::::.  .:::::::::::::.  ..         ..:::::::::::::..        ..::::::
* in collaboration with Purebase Studio https://purebase.co/
*/

import '@ERC721A/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

contract LZxWOS is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;
    bool public paused;
    bool public minting;
    bool public whitelistminting;
    bytes32 public whitelistMerkleRoot;
    mapping(uint256 => mapping(address => uint256)) public whitelistClaimed;
    mapping(address => uint256) public whitelistClaimedTotal;
    uint256 public constant maxBatchSize = 10;
    uint256 public maxPublicPerWallet = 5;
    uint256 public maxMintAmountPerTx = 10;
    uint256 public cost = 0.05 ether;
    uint256 public constant maxSupply = 3333;
    uint256 public constant maxSupplyPerPhase = 1111;
    uint256 public currentPhase = 1;
    string private _baseTokenURI = 'https://luckyzeros.io/api/wos/nft/';
    string public provenance;

    constructor() ERC721A("LZxWOS", "LZxWOS") {
        paused = true;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }
    function flipPause() public onlyOwner {
        paused = !paused;
    }
    function flipMint() public onlyOwner {
        minting = !minting;
    }
    function flipPresaleMint() public onlyOwner {
        whitelistminting = !whitelistminting;
    }
    function setItemPrice(uint256 _price) public onlyOwner {
        cost = _price;
    }
    function setNumPerMint(uint256 _max) public onlyOwner {
        maxMintAmountPerTx = _max;
    }
    function setNumPerWallet(uint256 _max) public onlyOwner {
        maxPublicPerWallet = _max;
    }
    function _leaf(string memory allowance, string memory payload) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(payload, allowance));
    }
    function _verify(bytes32 leaf, bytes32[] memory proof) internal view returns (bool) {
        return MerkleProof.verify(proof, whitelistMerkleRoot, leaf);
    }
    function setPhase(uint256 _phase) public onlyOwner {
        currentPhase = _phase;
    }

    function mintReserves(uint256 quantity) public onlyOwner {
        require(quantity % maxBatchSize == 0, "can only mint a multiple of the maxBatchSize");
        uint256 numChunks = quantity / maxBatchSize;
        for (uint256 i = 0; i < numChunks; i++) {
            _mint(msg.sender, maxBatchSize);
        }
    }

    function presaleMint(uint256 _mintAmount, uint256 _allowance, bytes32[] calldata _merkleProof) public payable callerIsUser {
        string memory payload = string(abi.encodePacked(_msgSender()));
        require(!paused, 'The contract is paused!');
        require(whitelistminting, "Whitelist Mint closed");
        require(whitelistClaimed[currentPhase][msg.sender] + _mintAmount <= _allowance, 'More than allowed during WL');
        require(totalSupply() + _mintAmount <= maxSupplyPerPhase * currentPhase, 'More than max supply for this phase');
        require(totalSupply() + _mintAmount <= maxSupply, 'More than max supply');
        require(msg.value >= cost * _mintAmount, 'Not enough ETH');
        require(_verify(_leaf(Strings.toString(_allowance), payload), _merkleProof),'Invalid proof');
        
        whitelistClaimed[currentPhase][msg.sender] += _mintAmount;
        whitelistClaimedTotal[msg.sender] += _mintAmount;
        _mint(msg.sender, _mintAmount);
    }

    function mint(uint256 _mintAmount) public payable callerIsUser {
        require(!paused, 'The contract is paused!');
        require(minting, "Mint closed");
        require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount');
        require(totalSupply() + _mintAmount <= maxSupplyPerPhase * currentPhase, 'More than max supply for this phase');
        require(totalSupply() + _mintAmount <= maxSupply, 'More than max supply');
        require(msg.value >= cost * _mintAmount, 'Not enough ETH');
        require(numberMinted(msg.sender) + _mintAmount <= maxPublicPerWallet * currentPhase + whitelistClaimedTotal[msg.sender], 'More than allowed per wallet');
        
        _mint(msg.sender, _mintAmount);
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        whitelistMerkleRoot = _merkleRoot;
    }
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }
    function setProvenance(string memory hash) public onlyOwner {
        provenance = hash;
    }
    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}