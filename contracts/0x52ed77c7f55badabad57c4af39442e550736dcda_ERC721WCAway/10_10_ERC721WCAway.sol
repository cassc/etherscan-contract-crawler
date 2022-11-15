// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IERC165} from "openzeppelin-contracts/interfaces/IERC165.sol";
import {IERC721} from "openzeppelin-contracts/interfaces/IERC721.sol";
import {IERC721Metadata} from "openzeppelin-contracts/interfaces/IERC721Metadata.sol";
import {ERC721} from "solmate/tokens/ERC721.sol";
import {Strings} from "openzeppelin-contracts/utils/Strings.sol";

contract ERC721WCAway is ERC721 {
    address payable public owner;

    string public BASE_URI;

    uint256 public immutable mintCost; // in wei
    uint256 public immutable maxSupply;  // total number of NFTs
    uint256 public immutable numInitialTeams;  // 32 for WC
    uint256 public immutable maxMintPerAddress;  // max amount each wallet can mint

    uint256 public numMinted;  // number of items already minted
    uint256 public numQualifiedWithdraw;  // current number of qualified items to withdraw
    mapping (address => uint256) public addressNumMinted;  // amount already minted in each wallet
    bool[] public qualifiedTeams;  // which teams are still qualified
    uint256[] public numTradableItems;  // number of qualified items in each team

    bool public mintStarted;  // cannot mint before start time
    bool public mintEnded;  // cannot mint after teams are assigned
    bool public locked;  // contract locked (can not withdraw) during game
    bool public finalized;  // contract finalized (can not change qualification) end of the championship

    event OwnerChanged(address indexed newOwner);
    event BaseURIUpdated();
    event ContractLocked();
    event ContractUnlocked();
    event ContractFinalized();
    event MintStarted();
    event MintEnded();
    event QualificationUpdated(uint256 teamId, bool qualified);
    event Withdrawn(address indexed holder, uint256 tokenId, uint256 teamId);

    error NotOwner();
    error NotHolder();
    error WrongSize();
    error IncorrectPayment(uint256 expected, uint256 amount);
    error InsufficientBalance(uint256 amount);
    error TransferFailed();
    error MintingNotStarted();
    error MintingStarted();
    error MintingNotEnded();
    error MintingEnded();
    error Unqualified();
    error AlreadyLocked();
    error AlreadyUnlocked();
    error AlreadyFinalized();
    error MaxSupplyReached();
    error MaxMintAmountReached();

    constructor(
        uint256 _mintCost,
        uint256 _numInitialTeams,
        uint256 _maxSupply,
        uint256 _maxMintPerAddress,
        string memory _baseUri
    ) ERC721(name, symbol) {
        owner = payable(msg.sender);

        BASE_URI = _baseUri;

        name = string("Hologram WC 2022 Away Jersey");
        symbol = string("HWCA");

        mintCost = _mintCost;
        maxSupply = _maxSupply;
        numInitialTeams = _numInitialTeams;
        maxMintPerAddress = _maxMintPerAddress;

        numMinted = 0;
        numQualifiedWithdraw = 0;

        qualifiedTeams = new bool[](numInitialTeams);
        numTradableItems = new uint256[](numInitialTeams);

        for (uint256 i = 0; i < numInitialTeams; i++) {
            qualifiedTeams[i] = true;  // initially all teams are qualified
            numTradableItems[i] = 0;  // no items in the market before minting
        }

        mintStarted = false;
        mintEnded = false;
        locked = false;
        finalized = false;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    function setOwner(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
        emit OwnerChanged(_newOwner);
    }

    function updateBaseURI(string memory _baseUri) public onlyOwner {
        BASE_URI = _baseUri;
        emit BaseURIUpdated();
    }

    function lockContract() public onlyOwner {
        if (finalized) revert AlreadyFinalized();
        if (!mintEnded) revert MintingNotEnded();
        locked = true;
        emit ContractLocked();
    }

    function unlockContract() public onlyOwner {
        if (finalized) revert AlreadyFinalized();
        locked = false;
        emit ContractUnlocked();
    }

    function finalizeContract() public onlyOwner {
        if (finalized) revert AlreadyFinalized();
        finalized = true;
        emit ContractFinalized();
    }

    function startMinting() public onlyOwner {
        if (mintStarted) revert MintingStarted();
        mintStarted = true;
        emit MintStarted();
    }

    function endMinting() public onlyOwner {
        if (mintEnded) revert MintingEnded();
        mintEnded = true;
        emit MintEnded();
    }

    function updateQualification(uint256 _teamId, bool _qualified) public onlyOwner {
        if (finalized) revert AlreadyFinalized();
        if (!locked) revert AlreadyUnlocked();

        if (qualifiedTeams[_teamId] == true && _qualified == false) {
            // normal advance of tournament
            numQualifiedWithdraw -= numTradableItems[_teamId];
            qualifiedTeams[_teamId] = false;
            emit QualificationUpdated(_teamId, false);
        } else if (qualifiedTeams[_teamId] == false && _qualified == true) {
            // in case admin messes up
            numQualifiedWithdraw += numTradableItems[_teamId];
            qualifiedTeams[_teamId] = true;
            emit QualificationUpdated(_teamId, true);
        }
    }

    function updateQualifications(uint256[] memory _teamIds, bool[] memory _qualified) public onlyOwner {
        if (_teamIds.length != _qualified.length) revert WrongSize();

        for (uint256 i = 0; i < _teamIds.length; i ++) {
            updateQualification(_teamIds[i], _qualified[i]);
        }
    }

    function withdraw(uint256 _tokenId) public {
        if (locked) revert AlreadyLocked();  // cannot withdraw during game

        if (msg.sender != _ownerOf[_tokenId]) revert NotHolder();

        uint256 teamId = _tokenId % numInitialTeams;
        if (!qualifiedTeams[teamId]) revert Unqualified();

        uint256 amount = address(this).balance / numQualifiedWithdraw;  // built in floor operation on floats
        if (address(this).balance < amount) revert InsufficientBalance(amount);

        (bool success, ) = _ownerOf[_tokenId].call{value: amount}("");
        if (!success) revert TransferFailed();

        numQualifiedWithdraw -= 1;
        numTradableItems[teamId] -= 1;

        // burn the actual token
        _burn(_tokenId);

        emit Withdrawn(msg.sender, _tokenId, teamId);
    }

    function batchWithdraw(uint256[] memory _tokenIds) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            withdraw(_tokenIds[i]);
        }
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        return string.concat(BASE_URI, Strings.toString(_tokenId));
    }

    function getMintedAmount(address _addr) public view returns(uint256) {
        return addressNumMinted[_addr];
    }

    function getQualifiedTeams() public view returns (bool[] memory) {
        return qualifiedTeams;
    }

    function getNumTradableItems() public view returns (uint256[] memory) {
        return numTradableItems;
    }

    function mint() public payable {
        if (!mintStarted) revert MintingNotStarted();
        if (mintEnded) revert MintingEnded();
        if (numMinted == maxSupply) revert MaxSupplyReached();
        if (msg.value != mintCost) revert IncorrectPayment(mintCost, msg.value);

        address to = msg.sender;
        if (addressNumMinted[to] == maxMintPerAddress) revert MaxMintAmountReached();
        
        _mint(to, numMinted);
        
        uint256 teamId = numMinted % numInitialTeams;
        numQualifiedWithdraw += 1;
        numTradableItems[teamId] += 1;

        addressNumMinted[to] += 1;
        numMinted += 1;
    }

    function batchMint(uint256 numToMint) public payable {
        if (!mintStarted) revert MintingNotStarted();
        if (mintEnded) revert MintingEnded();
        if (numMinted + numToMint > maxSupply) revert MaxSupplyReached();
        if (msg.value != mintCost * numToMint) revert IncorrectPayment(mintCost, msg.value);

        address to = msg.sender;
        if (addressNumMinted[to] + numToMint > maxMintPerAddress) revert MaxMintAmountReached();

        for (uint256 i = numMinted; i < numMinted + numToMint; i ++) {
            _mint(to, i);
            uint256 teamId = i % numInitialTeams;
            numTradableItems[teamId] += 1;
        }

        numQualifiedWithdraw += numToMint;
        addressNumMinted[to] += numToMint;
        numMinted += numToMint;
    }
}