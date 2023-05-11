//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./PaymentSplitter.sol";
import "./MerkleProof.sol";


// __  __ _                 _   ____            _     _    ____ _       _     
//|  \/  (_) __ _ _ __ ___ (_) / ___| _   _ ___| |__ (_)  / ___| |_   _| |__  
//| |\/| | |/ _` | '_ ` _ \| | \___ \| | | / __| '_ \| | | |   | | | | | '_ \ 
//| |  | | | (_| | | | | | | |  ___) | |_| \__ \ | | | | | |___| | |_| | |_) |
//|_|  |_|_|\__,_|_| |_| |_|_| |____/ \__,_|___/_| |_|_|  \____|_|\__,_|_.__/ 

// Miami Sushi Club: Omakase Warriors 

contract OmakaseWarriorsMSC is ERC721, PaymentSplitter, Ownable {

    // Setup

    using Counters for Counters.Counter;
    Counters.Counter private _tokenSupply;

    // Public Properties

    bool public mintEnabled;
    bool public allowListMintEnabled;

    mapping(address => uint) public allowListMintCount;

    bytes32 public merkleRoot;

    // Private Properties

    string private _baseTokenURI;

    uint private price = 1.53 ether;

    address private teamWallet = 0x24Fcf1edcD259e0e028518948DFC4558A082f748;

    // Modifiers

    modifier isNotPaused(bool _enabled) {
        require(_enabled, "Mint paused");
        _;
    }

    // Constructor

    constructor(address[] memory _payees, uint256[] memory _shares) ERC721("MSC: OMAKASE WARRIORS", "OW") PaymentSplitter(_payees, _shares) {
        _mintOW(teamWallet, 50);
    }

    // Mint Functions

    // Function requires a Merkle proof and will only work if called from the minting site.
    // Allows the allowList minter to come back and mint again if they mint under 3 max mints in the first transaction(s).
    function allowListMint(bytes32[] calldata _merkleProof, uint _amount) external payable isNotPaused(allowListMintEnabled) {
        require((_amount > 0 && _amount < 3), "Wrong amount");
        require(totalSupply() + _amount < 1_001, 'Exceeds max supply');
        require(allowListMintCount[msg.sender] + _amount < 3, "Can only mint 2");
        require(price * _amount == msg.value, "Wrong ETH amount");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Not on the list');

        allowListMintCount[msg.sender] = allowListMintCount[msg.sender] + _amount;

        _mintOW(msg.sender, _amount);
    }

    function mint(uint _amount) external payable isNotPaused(mintEnabled) {
        require((_amount > 0 && _amount < 21), "Wrong amount");
        require(totalSupply() + _amount < 1_001, 'Exceeds max supply');
        require(price * _amount == msg.value, "Wrong ETH amount");

        _mintOW(msg.sender, _amount);
    }

    // Allows the team to mint OW to a destination address
    function promoMint(address _to, uint _amount) external onlyOwner {
        require(_amount > 0, "Mint 1");
        require(totalSupply() + _amount < 1_001, 'Exceeds max supply');
        _mintOW(_to, _amount);
    }

    function _mintOW(address _to, uint _amount) internal {
        for(uint i = 0; i < _amount; i++) {
            _tokenSupply.increment();
            _safeMint(_to, totalSupply());
        }
    }

    function totalSupply() public view returns (uint) {
        return _tokenSupply.current();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    // Ownable Functions

    function setMerkleRoot(bytes32 _root) external onlyOwner {
        merkleRoot = _root;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setAllowListMintEnabled(bool _val) external onlyOwner {
        allowListMintEnabled = _val;
    }

    function setMintEnabled(bool _val) external onlyOwner {
        mintEnabled = _val;
    }

    // Important: Set new price in wei (i.e. 50000000000000000 for 0.05 ETH)
    function setPrice(uint _newPrice) external onlyOwner {
        price = _newPrice;
    }

}