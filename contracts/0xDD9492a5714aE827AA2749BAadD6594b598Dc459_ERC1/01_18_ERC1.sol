// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

//       __________  __________
//      /____/  _  \/ ___/_   /
//     /____/  ,  _/ /__  /  / 
//    /____/__/|__|\___/ /__/  
// 
//   L I V I N G   L E G E N D S 
//                      by Examp

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/PullPayment.sol";

contract ERC1 is
    ERC1155,
    Ownable,
    Pausable,
    ERC1155Burnable,
    ERC1155Supply,
    ReentrancyGuard,
    PullPayment
{
    bytes32 public merkleRootForFreeMinters;

    uint256 public singleCardCost;
    uint256 public boosterPackCost;
    uint256 public maxSupply;
    uint256 public currentSupply = 0;
    uint256 public boosterPackSize;

    string public name;

    string public uriPrefix = "https://s3.amazonaws.com/erc1/2/";
    string public uriSuffix = ".json";

    bool public allowlistMintEnabled = false;

    // For royalty payments
    mapping(uint256 => address) private _addressesById;
    
    // denominator of booster pack price distributed to each card creator (besides minter), so 40% total in a 5-card pack.
    // 0 = disabled
    // 10 = 10% to each
    // 20 = 5% to each
    // 100 = 1% to each
    uint256 public creatorDivisor; 

    // for keeping track of mint counts
    mapping(address => uint256) private _mintPackCount;

    // address => mintPackCount => tokenId => bool
    mapping(address => mapping(uint256 => mapping(uint256 => bool)))
        private _randomMintCache;

    // tracking allowlist claimants
    mapping(address => bool) public allowlistClaimed;

    constructor(
        string memory _name,
        uint256 _singleCardCost,
        uint256 _boosterPackCost,
        uint256 _maxSupply,
        uint256 _boosterPackSize,
        uint256 _creatorDivisor
    ) ERC1155("https://s3.amazonaws.com/erc1/2/{id}.json") {
        name = _name;
        maxSupply = _maxSupply;
        setSingleCardCost(_singleCardCost);
        setBoosterPackCost(_boosterPackCost);
        setBoosterPackSize(_boosterPackSize);
        setCreatorDivisor(_creatorDivisor);
    }

    modifier mintSingleCardPriceCompliance() {
        require(
            msg.value >= singleCardCost,
            "Insufficient funds"
        );
        _;
    }

    modifier mintBoosterPackPriceCompliance() {
        require(
            msg.value >= boosterPackCost,
            "Insufficient funds"
        );
        _;
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _mintSingle(
        address account,
        bytes memory data
    ) private {
        require(currentSupply + 1 <= maxSupply, "Max supply exceeded");

        currentSupply = currentSupply + 1;

        // Royalties: Store this address mapped to tokenID
        _addressesById[currentSupply] = account;

        _mint(account, currentSupply, 1, data);
    }

    // If not minted out, mints 1 new card and boosterPackSize-1 random cards from the collection.
    // If minted out, mints boosterPackSize random cards
    function _mintBoosterPack(
        address account,
        bytes memory data
    ) private {
        uint256[] memory ids = new uint256[](1 + boosterPackSize - 1);
        uint256[] memory amounts = new uint256[](1 + boosterPackSize - 1);
        uint256 rand = 0;
        uint256 userMintCount = _mintPackCount[account];
        uint256 startIndex = 0;
        uint256 seedCursor = 1;

        // Not minted out
        if (currentSupply + 1 <= maxSupply) {
            currentSupply = currentSupply + 1;

            ids[0] = currentSupply;
            amounts[0] = 1;
            startIndex++;
            _randomMintCache[account][userMintCount][currentSupply] = true;

            // Royalties: Store this address mapped to tokenID
            _addressesById[currentSupply] = account;
        }

        for (uint256 i = startIndex; i < boosterPackSize; i++) {
            // Keep generating a random number until we get one that hasn't been used yet
            while (
                _randomMintCache[account][userMintCount][rand] ||
                seedCursor == 1
            ) {
                rand = random(currentSupply, seedCursor);
                seedCursor++;
            }

            ids[i] = rand;
            amounts[i] = 1;
            _randomMintCache[account][userMintCount][rand] = true;
            
            // Royalties: Send creatorDivisor of mint price to the other card creators in this booster pack
            if (creatorDivisor > 0 && msg.value > 0) {
                _asyncTransfer(_addressesById[rand], msg.value / creatorDivisor);
            }
        }

        _mintBatch(account, ids, amounts, data);
        _mintPackCount[account] = userMintCount + 1;
    }

    function mintBooster(bytes memory data)
        public
        payable
        mintBoosterPackPriceCompliance()
    {
        _mintBoosterPack(_msgSender(), data);
    }

    function mint(bytes memory data)
        public
        payable
        mintSingleCardPriceCompliance()
    {
        _mintSingle(_msgSender(), data);
    }

    function mintForAddress(
        address account,
        bytes memory data
    ) public onlyOwner {
        _mintSingle(account, data);
    }

    function mintBatch(
        address to,
        uint256[] calldata ids,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyOwner {
        _mintBatch(to, ids, amounts, data);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function freeMint(bytes32[] calldata _freeMerkleProof)
        public
        payable
    {
        require(allowlistMintEnabled, "The VIP mint is not enabled!");
        require(!allowlistClaimed[msg.sender], "Address already claimed!");
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(
            MerkleProof.verify(
                _freeMerkleProof,
                merkleRootForFreeMinters,
                leaf
            ),
            "Invalid proof!"
        );

        allowlistClaimed[_msgSender()] = true;
        _mintBoosterPack(_msgSender(), "");
    }

    function setSingleCardCost(uint256 _singleCardCost) public onlyOwner {
        singleCardCost = _singleCardCost;
    }

    function setBoosterPackCost(uint256 _boosterPackCost) public onlyOwner {
        boosterPackCost = _boosterPackCost;
    }

    function setBoosterPackSize(uint256 _boosterPackSize) public onlyOwner {
        boosterPackSize = _boosterPackSize;
    }

    function setCreatorDivisor(uint256 _creatorDivisor) public onlyOwner {
        creatorDivisor = _creatorDivisor;
    }

    function setMerkleRootForFreeMinters(bytes32 _merkleRoot) public onlyOwner {
        merkleRootForFreeMinters = _merkleRoot;
    }
        
    function setWhitelistMintEnabled(bool _state) public onlyOwner {
        allowlistMintEnabled = _state;
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function uri(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _tokenId <= currentSupply,
            "ERC1155Metadata: URI query for nonexistent token"
        );
        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        Strings.toString(_tokenId),
                        uriSuffix
                    )
                )
                : "";
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function _baseURI() internal view virtual returns (string memory) {
        return uriPrefix;
    }

    function random(uint256 max, uint256 seed) private view returns (uint256) {
        uint256 randomHash = uint256(
            keccak256(
                abi.encodePacked(
                    block.difficulty,
                    block.timestamp,
                    _msgSender(),
                    seed
                )
            )
        );
        uint256 randomNum = randomHash % max;
        return randomNum > 0 ? randomNum : 1;
    }

    function contractURI() pure public returns (string memory) {
        return 'https://s3.amazonaws.com/erc1/2/metadata.json';
    }
}

// Within the shimmering gold lies a secret, a hidden message waiting to be uncovered by those who possess a keen eye and an adventurous spirit.