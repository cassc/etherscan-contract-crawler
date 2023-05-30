//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// @title:  RECESSCaps
// @desc:   Membership NFT for RECESS
// @url:    https://www.recessdao.com/

import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import './ERC721BaseTokenURI.sol';

contract RECESSCaps is ERC721BaseTokenURI {
    uint256 public TOKEN_PRICE;
    uint256 public constant MAX_SUPPLY = 1000;

    enum State {
        Paused,
        Ended,
        RecessMint,
        PrivateMint
    }

    event TokenMinted(address indexed purchaser, uint256 indexed tokenId);

    mapping(address => bool) public hasMintedRecess;
    mapping(string => bool) public referralCodeUsed;

    uint256 public currentTokenId;

    bytes32 public whitelistMerkleRoot;
    State public state = State.Paused;

    constructor(string memory baseTokenURI)
        ERC721BaseTokenURI('RECESSCaps', 'CAPS', baseTokenURI)
    {}

    modifier isRightState(State _state) {
        require(_state <= state, 'Wrong state for this action.');
        _;
    }

    modifier sentCorrectValue() {
        require(msg.value >= TOKEN_PRICE, 'Not enough ETH sent.');
        _;
    }

    modifier hasntClaimed(address addr) {
        require(!hasMintedRecess[addr], 'Already claimed your RECESS Cap!');
        _;
    }

    modifier referralUnused(string memory referralCode) {
        require(!referralCodeUsed[referralCode], 'Referral code has already been used.');
        _;
    }

    modifier validMerkleProof(bytes32[] calldata merkleProof) {
        bytes32 leafNode = keccak256(abi.encodePacked(_msgSender()));
        require(
            MerkleProof.verify(merkleProof, whitelistMerkleRoot, leafNode),
            'Invalid merkleProof.'
        );
        _;
    }

    modifier validReferralMerkleProof(
        bytes32[] calldata merkleProof,
        address referrerAddress,
        string memory referralCode
    ) {
        bytes32 leafNode = keccak256(abi.encodePacked(referrerAddress, referralCode));
        require(
            MerkleProof.verify(merkleProof, whitelistMerkleRoot, leafNode),
            'Invalid merkleProof.'
        );
        _;
    }

    modifier checkBelowMax() {
        require(currentTokenId < MAX_SUPPLY, 'No more RECESS Membership Caps left!');
        _;
    }

    // NB: Setting State.Ended *permanently* ends the sale, which has the effect of "burning" what's left of the supply
    function setState(State _state) external onlyOwner {
        require(state != State.Ended, "The sale has ended and can't be restarted.");
        state = _state;
    }

    function recessMint(bytes32[] calldata merkleProof)
        external
        isRightState(State.RecessMint)
        hasntClaimed(_msgSender())
        checkBelowMax
        validMerkleProof(merkleProof)
    {
        hasMintedRecess[_msgSender()] = true;
        _mintCap(_msgSender());
    }

    function referredMint(
        bytes32[] calldata merkleProof,
        address referrerAddress,
        string calldata referralCode
    )
        external
        payable
        isRightState(State.PrivateMint)
        referralUnused(referralCode)
        checkBelowMax
        validReferralMerkleProof(merkleProof, referrerAddress, referralCode)
        sentCorrectValue
    {
        referralCodeUsed[referralCode] = true;
        _mintCap(_msgSender());
    }

    function _mintCap(address recipient) private {
        _mint(recipient, currentTokenId);
        emit TokenMinted(_msgSender(), currentTokenId);
        currentTokenId++;
    }

    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = owner().call{value: balance}('');
        require(success, 'Withdraw failed.');
    }

    // set merkle root functions
    function setWhitelistMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        whitelistMerkleRoot = _merkleRoot;
    }

    function setTokenPrice(uint256 _tokenPrice) external onlyOwner {
        TOKEN_PRICE = _tokenPrice;
    }
}