pragma solidity 0.8.13;
import "openzeppelin-contracts/utils/cryptography/MerkleProof.sol";
import "../src/SkySwan.sol";
import "../src/Timer.sol";
import "../src/Percentage.sol";

error TimerNotYetExpired();
error InvalidEtherAmount();
error InvalidMerkleProof();
error MustBeGraterThenZero();
error CanOnlyRevealOnce();
error QuotaReached();
error NotTeamMember();
error NothingToWithdraw();
error NotEnabled();

contract Swantract is SkySwan { 

    bool _whitelistEnabled = true;

    bytes32 public _merkleRoot;
    uint256 public _whitelistPrice = 0.05 ether;
    uint256 public _regularPrice = 0.0577 ether;
    uint256 public _released = 0;
    
    address payable public _skydasAddr;
    address payable _partnerAddr;

    using Timerlib for Timer;
    Timer timer;

    bytes32 public constant _geneRoot = 0x453188df50584551ef41dcae470e997eb7d826ec0adc6d4baa1bc5269c22e1ae;

    constructor(
        string memory _name,
        string memory _symbol,
        address payable skydasAddr,
        address payable partnerAddr,
        bytes32 merkleRoot
    ) SkySwan(_name, _symbol) {
        _skydasAddr = skydasAddr;
        _partnerAddr = partnerAddr;
        _merkleRoot = merkleRoot;

	_airdrop();
    }

    function _airdrop() internal {
        // team swans: https://opensea.io/collection/theskyswans
        _safeMint(0x38603A0DfB2D27A2E3bd44d7b730f0aF13Fe40C6, 1);
        _safeMint(0xa5cc7836b62FA10Fc7955cC6cc8A0100b5351335, 1);
        _safeMint(0x9c45F9e2E9477C1Af8CEc86bC43531Cfa9AF8fB3, 1);
        _safeMint(0xC338D50eaD8872175f881850eF77Cb9A8BA112Ed, 1);
        _safeMint(0xf238BB36cF63157F3EC4206F7cbc2940533e7099, 1);
	_safeMint(0xA48D662Fb0b040228d91218E805e2837b645D51c, 1);
        _safeMint(0xfb98894FC02D065c971611e8927Cae95eC0e203d, 1);
        _safeMint(0x4A441774C8cCdc4b92726cc45fA17BA438864671, 1);
        _safeMint(0x38603A0DfB2D27A2E3bd44d7b730f0aF13Fe40C6, 1);  // to Mr. Swan
        _safeMint(0x2131C8d59D9b1F50C59596C61dD85f9b92a8C30e, 1);

        // for the egg holders (https://opensea.io/collection/sky-swan-eggs): 7 gold + 17 silver + 77 bronze
        // total:  7*7 + 17*3 + 77 = 177
        _safeMint(0x791889F51cd7E8a37A9b08699eA99e45ae78Adb7, 177);
    }

    // nonReentrant not needed reentry handled in _safemint
    function buy(uint256 count) external payable {
        if (_whitelistEnabled) revert NotEnabled();
        if (count <= 0) revert MustBeGraterThenZero();
        if (_totalMinted() + count > _released) revert MaxSupplyReached();
        if (msg.value != _regularPrice * count) revert InvalidEtherAmount();
        safeMint(count);
    }

    function whitelistBuy(
        uint256 count,
        bytes32[] calldata merkleProof
    ) external payable {
        if (count <= 0) revert MustBeGraterThenZero();
        if (_totalMinted() + count > _released) revert MaxSupplyReached();
        if (
            !MerkleProof.verify(
                merkleProof,
                _merkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            )
        ) revert InvalidMerkleProof();
        if (_numberMinted(msg.sender) + count > 2) revert QuotaReached();
        if (msg.value != _whitelistPrice * count) revert InvalidEtherAmount();
        safeMint(count);
    }

    function withdraw() external onlyTeam {
        uint256 balance = address(this).balance;
        if (balance == 0) revert NothingToWithdraw();
	uint256 toPartner = Precentage.percentageOf(225e17, balance);
        _partnerAddr.transfer(toPartner);
        _skydasAddr.transfer(address(this).balance);
    }

    function setSkydasAddr(
        address payable skydas
    ) external onlyOwner {
        _skydasAddr = skydas;
    }

    function setPartnerAddr(
        address payable partner
    ) external onlyTeam {
        if (msg.sender == _partnerAddr) {
            _partnerAddr = partner;
            return;
        }
        if (timer.hasExpired()) {
            _partnerAddr = partner;
        } else {
            revert TimerNotYetExpired();
        }
    }

    function setPrices(uint256 whitelist, uint256 regular) external onlyOwner {
        _whitelistPrice = whitelist;
        _regularPrice = regular;
    }

     function setReleaseNum(uint256 num) external onlyOwner {
        _released = num;
    }

    function toggleWhitelist() external onlyOwner {
        _whitelistEnabled = !_whitelistEnabled;
    }

    function Reveal(string memory uri) external onlyOwner {
	if (_reveal) revert CanOnlyRevealOnce();
        timer.setTimer(block.timestamp + 5259492);
        _reveal = !_reveal;
        _base = uri;
    }

    function setRoyalties(address newRecipient) external afterTimer onlyOwner {
        _royaltyRecipient = newRecipient;
    }

    modifier afterTimer() {
        if (!timer.hasExpired()) revert TimerNotYetExpired();
        _;
    }

    modifier onlyTeam() {
        if (!(
            msg.sender == owner() ||
            msg.sender == _skydasAddr ||
            msg.sender == _partnerAddr
        )) revert NotTeamMember();
        _;
    }
}