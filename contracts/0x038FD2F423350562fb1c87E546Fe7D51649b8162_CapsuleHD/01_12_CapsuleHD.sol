// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "erc721a/contracts/ERC721A.sol";

contract CapsuleHD is ERC721A, Ownable, Pausable, PaymentSplitter {
    /* ----------------------------- ENUMS ----------------------------- */
    enum Phase {
        PreSale,
        PublicSale
    }

    enum CapsuleCategory {
        Onyx,
        Gold,
        Diamond
    }

    /* ----------------------------- STRUCTS ----------------------------- */
    struct MaxSupplyPerCategory {
        uint256 Onyx;
        uint256 Gold;
        uint256 Diamond;
    }

    struct PricePerCategory {
        uint256 Onyx;
        uint256 Gold;
        uint256 Diamond;
    }

    struct MaxCapsulesPerAddress {
        uint256 Onyx;
        uint256 Gold;
        uint256 Diamond;
    }

    struct Params {
        uint256 startTime;
        uint256 endTime;
        bytes32 merkleRootForWhitelist;
        bytes32 merkleRootForFreeMint;
        MaxCapsulesPerAddress maxCapsulesPerAddress;
        PricePerCategory pricePerCategory;
        Phase phase;
    }

    struct AmountOfCapsulesMintedPerCategory{
        uint256 Onyx;
        uint256 Gold;
        uint256 Diamond;
    }

    /* ----------------------------- VARIABLES ----------------------------- */
    /// @dev Param of the sale.
    Params public params;
    /// @dev Max supply of each category.
    MaxSupplyPerCategory public maxSupplyPerCategory;
    /// @dev Amount of capsules minted per category.
    AmountOfCapsulesMintedPerCategory public amountOfCapsulesMintedPerCategory;
    uint256 public maxSupply;
    uint256[] public teamShares;
    address[] public team;
    string public baseURI;


    mapping(address => bool) public freeMintClaimed;
    mapping(address => AmountOfCapsulesMintedPerCategory) public capsulesMintedPerAddress;

    event SetBaseURI(string _baseURI);
    event SetMintParams(Params _params);
    event Mint(
        address indexed _to,
        uint256 _amountOnyx,
        uint256 _amountGold,
        uint256 _amountDiamond,
        uint256 _firstTokenId
    );
    event FreeMintDiamond(
        address indexed _to,
        uint256 _tokenId
    );

    /* ----------------------------- MODIFIERS ----------------------------- */
    modifier checkSupplies(
        address _to,
        uint256 _amountOnyx,
        uint256 _amountGold,
        uint256 _amountDiamond
    ) {
        require(
            amountOfCapsulesMintedPerCategory.Onyx + _amountOnyx 
                <= maxSupplyPerCategory.Onyx,
            "HD: Onyx count per mint limit"
        );
        require(
            amountOfCapsulesMintedPerCategory.Gold + _amountGold 
                <= maxSupplyPerCategory.Gold,
            "HD: Gold count per mint limit"
        );
        require(
            amountOfCapsulesMintedPerCategory.Diamond + _amountDiamond 
                <= maxSupplyPerCategory.Diamond,
            "HD: Diamond count per mint limit"
        );

        require(
            _amountOnyx + capsulesMintedPerAddress[_to].Onyx <=
                params.maxCapsulesPerAddress.Onyx,
            "HD: max count per address Onyx limit"
        );
        require(
            _amountGold + capsulesMintedPerAddress[_to].Gold <=
                params.maxCapsulesPerAddress.Gold,
            "HD: max count per address Gold limit"
        );
        require(
            _amountDiamond + capsulesMintedPerAddress[_to].Diamond <=
                params.maxCapsulesPerAddress.Diamond,
            "HD: max count per address Diamond limit"
        );
        _;
    }
   
    constructor(
        uint256 _maxSupply,
        uint256 _maxSupplyOnyx,
        uint256 _maxSupplyGold,
        uint256 _maxSupplyDiamond,
        address[] memory _team,
        uint256[] memory _teamShares
    )
        ERC721A("CapsuleHD", "CAPSHD")
        PaymentSplitter(_team, _teamShares)
    {
        maxSupply = _maxSupply;
        maxSupplyPerCategory = MaxSupplyPerCategory(
            _maxSupplyOnyx,
            _maxSupplyGold,
            _maxSupplyDiamond
        );
        team = _team;
        teamShares = _teamShares;
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
        emit SetBaseURI(baseURI_);
    }

    function setMintParams(Params memory _params) external onlyOwner {
        require(
            _params.maxCapsulesPerAddress.Onyx > 0 &&
            _params.maxCapsulesPerAddress.Gold > 0 &&
            _params.maxCapsulesPerAddress.Diamond > 0,
            "HD: max Count per address is zero");
        require(
            _params.merkleRootForFreeMint != bytes32(0),
            "HD: merkleRootForFreeMint is zero"
        );
        params = _params;
        emit SetMintParams(_params);
    }

    function mint(
        address _to,
        bytes32[] calldata _merkleProofWhitelist,
        uint256 _amountOnyx,
        uint256 _amountGold,
        uint256 _amountDiamond,
        bytes32[] calldata _merkleProofFreeMint
    ) external whenNotPaused payable checkSupplies(_to, _amountOnyx, _amountGold, _amountDiamond) {
        require( _to != address(0), "HD: zero address");
        require(
            (block.timestamp >= params.startTime) &&
            (block.timestamp < params.endTime),
            "HD: time is out of range"
        );
        uint256 _totalSupply = totalSupply();
        require(
            _totalSupply + _amountOnyx + _amountGold + _amountDiamond <= maxSupply,
            "HD: total supply limit"
        );
        require(checkValidity(_merkleProofWhitelist, params.merkleRootForWhitelist), "HD: address not whitelisted");

        capsulesMintedPerAddress[_to].Onyx += _amountOnyx;
        capsulesMintedPerAddress[_to].Gold += _amountGold;
        capsulesMintedPerAddress[_to].Diamond += _amountDiamond;

        amountOfCapsulesMintedPerCategory.Onyx += _amountOnyx;
        amountOfCapsulesMintedPerCategory.Gold += _amountGold;
        amountOfCapsulesMintedPerCategory.Diamond += _amountDiamond;

        _checkPayment(_to, _amountOnyx, _amountGold, _amountDiamond, _merkleProofFreeMint);

        _safeMint(_to, _amountOnyx + _amountGold + _amountDiamond);
        emit Mint(_to, _amountOnyx, _amountGold, _amountDiamond, _totalSupply);
    }

    function _checkPayment(
        address _to,
        uint256 _amountOnyx,
        uint256 _amountGold,
        uint256 _amountDiamond,
        bytes32[] calldata _merkleProofFreeMint
    ) internal {

        uint256 _amountDiamondToPay = _amountDiamond;

        if (checkValidity(_merkleProofFreeMint, params.merkleRootForFreeMint) &&
            _amountDiamond > 0 &&
            !freeMintClaimed[_to]
        ) {
            _amountDiamondToPay = _amountDiamond - 1;
            freeMintClaimed[_to] = true;
        }

        require(msg.value == getPrice(_amountOnyx, _amountGold, _amountDiamondToPay),
            "HD: incorrect ether value");
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function checkValidity(bytes32[] calldata _merkleProof, bytes32 _merkleRoot) public view  returns (bool){
       if (_merkleRoot ==  bytes32(0)) {
            return true;
        } else {
            bytes32 _leafToCheck = keccak256(abi.encodePacked(msg.sender));
            return MerkleProof.verify(_merkleProof, _merkleRoot, _leafToCheck);
        }
    }

    function getPrice(
        uint256 _amountOnyx,
        uint256 _amountGold,
        uint256 _amountDiamond
    ) public view returns (uint256) {
        return
            _amountOnyx * params.pricePerCategory.Onyx + _amountGold 
            * params.pricePerCategory.Gold + _amountDiamond * params.pricePerCategory.Diamond;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
    
}