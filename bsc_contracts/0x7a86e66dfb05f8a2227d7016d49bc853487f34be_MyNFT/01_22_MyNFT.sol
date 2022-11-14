// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MyNFT is Initializable, ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721BurnableUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    // base uri for nfts
    string private _buri;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __ERC721_init("MyNFT", "NFT");
        __ERC721Enumerable_init();
        __ERC721Burnable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _buri;
    }

    function setBaseURI(string memory buri) public onlyOwner {
        require(bytes(buri).length > 0, "wrong base uri");
        _buri = buri;
    }

    function mint(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // from ActivityTimeStart to ActivityTimeEnd, users have mint quota can mint
    uint256 public activityTimeStart;
    uint256 public activityTimeEnd;

    bytes32 public mintMerkleRoot;

    mapping(address => uint256[]) public mintRecord;
    address[] public mintAddresses; // mark the mint addresses for iterating

    // fm/wl mint for free
    uint256 public cost;

    // open mint amount
    uint256 public remainingMintAmount;

    // fm/wl mint start from 1
    uint256 public mintIndex;

    uint256 public maxMintAmount;

    function setMaxMintAmount(uint256 _amount) public onlyOwner {
        maxMintAmount = _amount;
    }

    function setMintIndex(uint256 _index) public onlyOwner {
        mintIndex = _index;
    }

    function getTokenID() private view returns (uint256) {
        return mintIndex;
    }

    function increaseMintIndex() private {
        mintIndex++;
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setRemainingMintAmount(uint256 _amount) public onlyOwner {
        remainingMintAmount = _amount;
    }

    function decreaseRemainingMintAmount() private {
        remainingMintAmount--;
    }

    // set merklt root
    function setMintMerkleRoot(bytes32 _merkle) public onlyOwner {
        mintMerkleRoot = _merkle;
    }

    function updateMintRecord(address _to) private {
        mintRecord[_to].push(block.timestamp);
        mintAddresses.push(_to); // mark the mint address
    }

    function resetMintRecord() public onlyOwner {
        for (uint i=0; i< mintAddresses.length ; i++) {
            delete mintRecord[mintAddresses[i]];
        }
    }

    // set free mint activity time
    function setActivityTime(
        uint256 _activityTimeStart,
        uint256 _activityTimeEnd
        ) public onlyOwner {
            activityTimeStart = _activityTimeStart;
            activityTimeEnd = _activityTimeEnd;
    }

    function checkAddressAvailable(
        address _address,
        uint256 _amount,
        bytes32 _merkleRoot,
        bytes32[] calldata _proof
        ) private pure returns (bool) {
            //bytes32 leaf = keccak256(abi.encodePacked(_address));
            bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(_address, _amount))));
            return MerkleProof.verify(_proof, _merkleRoot, leaf);
    }

    function getQuota(
        address _address,
        uint256 _proofAmount,
        bytes32[] calldata _proof
        ) public view returns (uint256) {
            uint256 originalQuota;
            uint256 usedQuota;
            uint256 currentQuota;

            if (checkAddressAvailable(_address, _proofAmount, mintMerkleRoot, _proof)) {
                originalQuota = _proofAmount;
            } else {
                originalQuota = maxMintAmount;
            }

            usedQuota = mintRecord[_address].length;
            currentQuota = originalQuota - usedQuota;

            return currentQuota;
    }

    function mintToSender(bytes32[] calldata _proof, uint256 _proofAmount, uint256 _mintAmount) public payable {
        uint256 currentQuota = getQuota(msg.sender, _proofAmount, _proof);

        // check if current time is available
        require(
            block.timestamp > activityTimeStart &&
            block.timestamp < activityTimeEnd,
            "out of available time"
        );

        // check if still have mint quota
        require(currentQuota - _mintAmount >= 0, "not enough quota");

        // check if there is enough mint quota
        require(remainingMintAmount - _mintAmount >= 0, "there is no mint quota for fm/wl");

        // check if you have enough money
        require(msg.value - cost * _mintAmount >= 0, "insufficient funds");

        // mint
        for (uint256 i = 0; i < _mintAmount; i++) {
            _safeMint(msg.sender, getTokenID());
            // increase mint index
            increaseMintIndex();
            // decrease remaining mint amount
            decreaseRemainingMintAmount();
            // update mint record
            updateMintRecord(msg.sender);
        }
    }
}