// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.10;


//  ___  _  _  ____  ____  ___  _   _  _  _    __  __  ____  ____  ____  ___
// / __)( )/ )( ___)(_  _)/ __)( )_( )( \/ )  (  \/  )( ___)( ___)(  _ \/ __)
// \__ \ )  (  )__)   )( ( (__  ) _ (  \  /    )    (  )__)  )__)  )   /\__ \
// (___/(_)\_)(____) (__) \___)(_) (_) (__)   (_/\/\_)(__)  (____)(_)\_)(___/

// author: zhoug.eth


import "@rari-capital/solmate/src/tokens/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract SketchyMfers is ERC721, Ownable {
    using Strings for uint256;

    // ---------------------------------------------------------------------------------- state
    address public withdrawAddress;

    uint256 public constant MAX_SUPPLY = 2000;
    uint256 public totalSupply;
    uint256 public maxMintPerTx = 10;
    uint256 public cost = 0.0420 ether;

    string public uriPrefix;
    string public uriSuffix = ".json";
    string public hiddenURI = "HIDDEN";
    string public provenanceHash;

    bool public mintIsActive = false;
    bool public collectionIsHidden = true;

    // ---------------------------------------------------------------------------------- constructor
    constructor() ERC721("sketchy mfers", "SMFER") {
        setWithdrawAddress(msg.sender);
    }

    // ---------------------------------------------------------------------------------- error handling
    error Unauthorized();
    error NoTokenExists();
    error MintNotActive();
    error InvalidAmount();
    error InvalidPayment();
    error InvalidReveal();
    error InsufficientBalance();

    modifier validMintInput(uint256 _amount) {
        if (_amount == 0) revert InvalidAmount();
        if (totalSupply + _amount > MAX_SUPPLY) revert InvalidAmount();
        _;
    }

    // ---------------------------------------------------------------------------------- views
    function tokenURI(uint256 _id)
        public
        view
        override
        returns (string memory)
    {
        if (collectionIsHidden) {
            return hiddenURI;
        }
        if (ownerOf[_id] == address(0)) revert NoTokenExists();
        return
            bytes(uriPrefix).length > 0
                ? string(abi.encodePacked(uriPrefix, _id.toString(), uriSuffix))
                : "";
    }

    function getTokenIdsByAddress(address _address)
        public
        view
        returns (uint256[] memory ownedIds)
    {
        uint256 balance = balanceOf[_address];
        uint256 idCounter = 1;
        uint256 ownedCounter = 0;
        ownedIds = new uint256[](balance);

        while (ownedCounter < balance && idCounter < MAX_SUPPLY + 1) {
            address ownerAddress = ownerOf[idCounter];
            if (ownerAddress == _address) {
                ownedIds[ownedCounter] = idCounter;
                unchecked {
                    ++ownedCounter;
                }
            }
            unchecked {
                ++idCounter;
            }
        }
    }

    // ---------------------------------------------------------------------------------- mint
    function batchMint(address _recipient, uint256 _amount) private {
        unchecked {
            for (uint256 i = 1; i < _amount + 1; ++i) {
                _safeMint(_recipient, totalSupply + i);
            }
            totalSupply += _amount;
        }
    }

    function adminMint(address _address, uint256 _amount)
        external
        onlyOwner
        validMintInput(_amount)
    {
        batchMint(_address, _amount);
    }

    function mint(uint256 _amount) external payable validMintInput(_amount) {
        if (!mintIsActive) revert MintNotActive();
        if (_amount > maxMintPerTx) revert InvalidAmount();
        if (msg.value != cost * _amount) revert InvalidPayment();
        batchMint(msg.sender, _amount);
    }

    // ---------------------------------------------------------------------------------- admin
    function withdraw() external payable {
        if (msg.sender != withdrawAddress) revert Unauthorized();
        if (address(this).balance == 0) revert InsufficientBalance();
        (bool os, ) = payable(withdrawAddress).call{
            value: address(this).balance
        }("");
        require(os);
    }

    function setWithdrawAddress(address _withdrawAddress) public onlyOwner {
        withdrawAddress = _withdrawAddress;
    }

    function setMaxMintPerTx(uint256 _newMax) public onlyOwner {
        maxMintPerTx = _newMax;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setURIPrefix(string calldata _uriPrefix) public onlyOwner {
        if (collectionIsHidden) revert InvalidReveal();
        uriPrefix = _uriPrefix;
    }

    function setURISuffix(string calldata _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setHiddenURI(string calldata _hiddenURI) public onlyOwner {
        hiddenURI = _hiddenURI;
    }

    function setProvenanceHash(string calldata _newHash) public onlyOwner {
        provenanceHash = _newHash;
    }

    function setMintIsActive(bool _state) public onlyOwner {
        mintIsActive = _state;
    }

    // One-way function that reveals the collection and sets the content URI
    function revealCollection(string calldata _uriPrefix) external onlyOwner {
        if (!collectionIsHidden || mintIsActive) revert InvalidReveal();
        collectionIsHidden = false;
        setURIPrefix(_uriPrefix);
    }
}