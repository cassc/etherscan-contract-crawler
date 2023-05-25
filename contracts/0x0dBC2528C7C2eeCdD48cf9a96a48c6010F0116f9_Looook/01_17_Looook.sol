// SPDX-License-Identifier: MIT

/**
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░▓▓▓▓▓▓░░░░▓▓▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░▓░░░░░░▓░░▓░░░░░░▓░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░▓▓▓▓░░░░░▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░▓░░░░░░▓░▓░░░░░░▓░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░▓░░░░░░░░▓░░░░░░░░▓░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░▓░░░░░░░░░░▓░░░░░░░░▓░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░▓░░░░░░▓░░░▓░░░▓░░░░▓░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░▓░░░░░▓▓▓░░▓░░▓▓▓░░░▓░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░▓░░░░░▓░░▓░░░░▓░░░▓░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░▓░░░░░░▓░▓░░░░░░▓░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░▓▓▓▓░░░░░▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

LOOK AGAIN
Website: https://lookaga.in
Author: CTHDRL
**/

pragma solidity ^0.8.6;

import {SafeMath} from '@openzeppelin/contracts/utils/math/SafeMath.sol';
import {Address} from '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/interfaces/IERC2981.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import './libs/ReentrancyGuard.sol';

contract Looook is Ownable, ERC721, ReentrancyGuard {
    using Counters for Counters.Counter;

    event PuzzleCreated(uint256 puzzleId);
    event PuzzleUpdated(uint256 puzzleId);

    struct Puzzle {
        // address of the
        // solution signer
        address solution;
        // wallet address of
        // the curator
        address curator;
        // the number of tokens currently
        // minted for this puzzle
        Counters.Counter counter;
        // string to represent
        // the puzzle/challenge
        string challenge;
    }

    struct Token {
        // ID of the puzzle
        // this token belongs to
        uint256 puzzleId;
        // the value of the puzzle
        // counter when this
        // token was minted
        uint256 number;
    }

    // ID counters
    Counters.Counter public currentQueuedPuzzleId;
    Counters.Counter public currentTokenId;

    // Keeps track of the last known
    // puzzle ID each time the interval
    // or startTime are changed
    uint256 public puzzleAnchorId = 1;
    uint256 public puzzleInterval = 86400;
    uint256 public startTime = 0;

    // metadata
    string public description;

    // Base token and contract URI
    string private _baseTokenURI;
    string private _baseContractURI;

    // Who to pay when no curator
    address public defaultCurator = address(0x0);

    // addess => Puzzle ID => true/false
    // Determine whether a particular looker has
    // already minted a particular puzzle.
    mapping(address => mapping(uint256 => bool)) public mintedPuzzle;

    // Map IDs to structs
    mapping(uint256 => Puzzle) public puzzles;
    mapping(uint256 => Token) public tokens;

    // Kill switch for end times
    bool public frozen = false;

    // EIP-721
    // https://eips.ethereum.org/EIPS/eip-721

    constructor() ERC721('lookaga.in', 'LOOOOK') {}

    // EIP-2981
    // https://eips.ethereum.org/EIPS/eip-2981

    /**
        @dev Get royalty information for token
        @param _price Sale price for the token
    */
    function royaltyInfo(
        uint256 _id,
        uint256 _price
    ) external view returns (address receiver, uint256 royaltyAmount) {
        uint256 _puzzleId = tokens[_id].puzzleId;
        receiver = curatorOf(_puzzleId);
        royaltyAmount = (_price * 5) / 100;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721) returns (bool) {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
      @dev Allow the contract to receive ETH
     */
    receive() external payable {}

    /**
      @dev Read the contract meta URI
     */
    function contractURI() public view returns (string memory) {
        return _baseContractURI;
    }

    /**
      @dev Owner function to set the contract meta URI
     */
    function setContractURI(string memory baseContractURI_) public onlyOwner {
        require(!frozen, 'Contract is frozen');
        require(bytes(baseContractURI_).length > 0, 'Invalid baseContractUrl');
        _baseContractURI = baseContractURI_;
    }

    /**
      @dev Read the baseURI
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
      @dev Owner function to set the token baseURI
     */
    function setBaseURI(string memory baseURI_) public onlyOwner {
        require(!frozen, 'Contract is frozen');
        require(bytes(baseURI_).length > 0, 'Invalid baseUrl');
        _baseTokenURI = baseURI_;
    }

    /**
      @dev Owner function to set the description
     */
    function setDescription(string memory _description) public onlyOwner {
        require(!frozen, 'Contract is frozen');
        require(bytes(_description).length > 0, 'Invalid description');
        description = _description;
    }

    /**
      @dev Owner function to set default curator. Can only happen once.
     */
    function setDefaultCurator(address _curator) public onlyOwner {
        require(!frozen, 'Contract is frozen');
        require(
            defaultCurator == address(0x0),
            'The default curator has already been set'
        );
        defaultCurator = _curator;
    }

    /**
      @dev Kill switch, it can only be triggered once.
     */
    function freeze() public onlyOwner {
        require(!frozen, 'Contract is frozen');
        frozen = true;
    }

    // Puzzle that is currently minting
    function puzzleActive() public view returns (uint256) {
        if (startTime == 0 || startTime > block.timestamp || frozen) {
            return 0;
        }
        uint256 diff = SafeMath.div(
            SafeMath.sub(block.timestamp, startTime),
            puzzleInterval
        );
        return puzzleAnchorId + diff;
    }

    function setStartAndInterval(
        uint256 _startTime,
        uint256 _interval
    ) public onlyOwner {
        require(!frozen, 'Contract is frozen');
        require(_interval > 60, 'Minimum interval is 1 minute');
        require(puzzleInterval > 0, 'Contract must be initialized first');
        require(
            _startTime > block.timestamp,
            'Start time must be in the future'
        );

        // Set anchor if this is not
        // initialization
        if (startTime > 0) {
            uint256 diff = SafeMath.div(
                SafeMath.sub(block.timestamp, startTime),
                puzzleInterval
            );
            puzzleAnchorId = puzzleAnchorId + diff + 1;
        }

        // Set values
        startTime = _startTime;
        puzzleInterval = _interval;
    }

    /**
      @param _challenges - the IPFS hash where the challenge can be found
      @param _solutions - the public address of the solution wallet
      @param _curators - the address of the wallet who curated this puzzle
      @dev This allows the owner to create/queue one or many new puzzles
     */
    function createPuzzles(
        string[] calldata _challenges,
        address[] calldata _solutions,
        address[] memory _curators
    ) public onlyOwner returns (bool) {
        require(!frozen, 'Contract is frozen');

        for (uint256 i = 0; i < _challenges.length; i++) {
            // Default curator is owner
            if (_curators[i] == address(0x0)) {
                _curators[i] = owner();
            }

            currentQueuedPuzzleId.increment();
            uint256 _puzzleId = currentQueuedPuzzleId.current();

            puzzles[_puzzleId] = Puzzle(
                _solutions[i],
                _curators[i],
                Counters.Counter(0),
                _challenges[i]
            );
            emit PuzzleCreated(_puzzleId);
        }

        return true;
    }

    /**
      @param _puzzleId is the puzzle that is being updated. Must be 
      @param _challenge is the IPFS hash where the challenge can be found
      @param _solution is the public address of the solution wallet
      @param _curator is the address of the wallet who curated this puzzle
      @dev This allows the owner to update an existing queued puzzle
     */
    function updatePuzzle(
        uint256 _puzzleId,
        string memory _challenge,
        address _solution,
        address _curator
    ) public onlyOwner returns (uint256) {
        require(!frozen, 'Contract is frozen');
        require(
            puzzles[_puzzleId].solution != address(0x0),
            'Puzzle does not exist'
        );
        require(_puzzleId > puzzleActive(), 'Must be a queued future puzzle');

        // Default curator is owner
        if (_curator == address(0x0)) {
            _curator = owner();
        }

        puzzles[_puzzleId] = Puzzle(
            _solution,
            _curator,
            Counters.Counter(0),
            _challenge
        );
        emit PuzzleUpdated(_puzzleId);

        return _puzzleId;
    }

    /**
      @param signature is the signature proving that the looker found the solution
      @dev This allows anyone to mint an puzzle, given that they can prove that
            they have discovered the correct solution.
     */
    function mint(bytes calldata signature) external payable returns (uint256) {
        require(!frozen, 'Contract is frozen');

        // Ensure the curator is not minting
        address curator = curatorOf(puzzleActive());
        require(curator != _msgSender(), 'The curator cannot mint');

        // Verify that looker has found the solution
        Puzzle storage _puzzle = puzzles[puzzleActive()];
        address solutionSigner = _puzzle.solution;

        // Make sure there is a valid puzzle minting
        require(solutionSigner != address(0x0), 'There is no active puzzle');

        // Check solution
        require(
            _verify(solutionSigner, _hash(_msgSender()), signature),
            'Invalid signature provided'
        );

        // Ensure looker has not minted this puzzle already
        require(
            mintedPuzzle[_msgSender()][puzzleActive()] == false,
            'You`ve already minted this puzzle'
        );

        // Clear to mint

        // Increment token ID & puzzle counter
        currentTokenId.increment();
        uint256 _tokenId = currentTokenId.current();
        _puzzle.counter.increment();

        // Track that this looker has now minted this puzzle
        mintedPuzzle[_msgSender()][puzzleActive()] = true;

        // Track what puzzle this token is for, and its place within the puzzle
        tokens[_tokenId] = Token(puzzleActive(), _puzzle.counter.current());

        // First minter? Run payout.
        if (
            _puzzle.counter.current() == 1 &&
            address(this).balance > tx.gasprice
        ) {
            address beneficiaryCurator = curatorOf(puzzleActive() - 1);
            uint256 halfBal = SafeMath.div(address(this).balance, 2);
            Address.sendValue(payable(_msgSender()), halfBal);
            Address.sendValue(payable(beneficiaryCurator), halfBal);
        }

        // mint & return
        _safeMint(_msgSender(), _tokenId);
        return _tokenId;
    }

    /**
        @dev Convenience function to get the curator of any given puzzle
        @param _puzzleId token id
        @return address of curator
    */
    function curatorOf(uint256 _puzzleId) public view returns (address) {
        address _curator = puzzles[_puzzleId].curator;
        if (_curator == address(0x0)) {
            _curator = defaultCurator;
        }
        return _curator;
    }

    /**
        @dev Convenience function to get the public solution key of an puzzle
        @param _puzzleId token id
        @return address of solution
    */
    function solutionOf(uint256 _puzzleId) public view returns (address) {
        return puzzles[_puzzleId].solution;
    }

    /**
        @dev Convenience function to get the Puzzle ID of a given token
        @param _tokenId token id
        @return uint256 ID of corresponding puzzle
    */
    function puzzleOf(uint256 _tokenId) public view returns (uint256) {
        return tokens[_tokenId].puzzleId;
    }

    /**
        @param tokenId Token ID to burn
        User burn function for token id
     */
    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), 'Not approved');
        _burn(tokenId);
    }

    function _verify(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) private pure returns (bool) {
        return signer == ECDSA.recover(hash, signature);
    }

    function _hash(address account) private pure returns (bytes32) {
        return
            ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(account)));
    }

    function totalSupply() external view returns (uint256) {
        return currentTokenId.current();
    }
}