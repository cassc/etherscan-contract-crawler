// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "./SaleManager.sol";
import "./VRFManager.sol";
import "./ProbabilityMap.sol";
import "./Tag.sol";
import "./TermsAndConditions.sol";

//  ________  ___  ___  _________  ________
// |\   __  \|\  \|\  \|\___   ___\\   __  \
// \ \  \|\  \ \  \\\  \|___ \  \_\ \  \|\  \
//  \ \   ____\ \   __  \   \ \  \ \ \  \\\  \
//   \ \  \___|\ \  \ \  \   \ \  \ \ \  \\\  \
//    \ \__\    \ \__\ \__\   \ \__\ \ \_______\
//     \|__|     \|__|\|__|    \|__|  \|_______|

/// @title Phto Innovation of Influence
/// @author Atlas C.O.R.P.
contract PhtoInnovationOfInfluence is
    ERC1155Supply,
    SaleManager,
    VRFManager,
    ProbabilityMap,
    Ownable,
    PaymentSplitter
{
    using MerkleProof for bytes32[];

    mapping(uint256 => uint256) public deckCache;

    bytes32 public merkleroot;

    string public name = "Phto Innovation of Influence";

    string public COAdocuments;

    modifier whenAddressOnWhitelist(
        bytes32[] calldata _merkleproof,
        uint256 _maxItems
    ) {
        require(
            MerkleProof.verify(
                _merkleproof,
                merkleroot,
                keccak256(abi.encodePacked(msg.sender, _maxItems))
            ),
            "whenAddressOnWhitelist: invalid merkle verfication"
        );
        _;
    }

    constructor(
        string memory _URI,
        string memory _coaDocuments,
        uint256[] memory reserveTokenIds,
        uint256[] memory reserveTokenAmounts,
        SaleManagerConstructorArgs memory _saleManagerConstructorArgs,
        VRFManagerConstructorArgs memory _VRFManagerConstructorArgs,
        address[] memory _payees,
        uint256[] memory _shares
    )
        ERC1155(_URI)
        SaleManager(_saleManagerConstructorArgs)
        VRFManager(_VRFManagerConstructorArgs)
        PaymentSplitter(_payees, _shares)
    {
        _mintBatch(msg.sender, reserveTokenIds, reserveTokenAmounts, "");
        counter = 55;
        supply = 55;

        COAdocuments = _coaDocuments;
    }

    /// @param _numTokens is the number of tokens caller wants to purchase
    function purchase(uint32 _numTokens) external payable {
        require(
            saleState == SaleState.ACTIVE,
            "mint: sale state must be active"
        );

        require(_numTokens > 0, "claim: Must input a number greater than 0");

        require(
            msg.value >= _numTokens * PRICE,
            "mint: caller sent incorrect value"
        );
        require(
            _numTokens + counter <= MAX_TOKENS_IN_SALE,
            "mint: insufficient supply remaining for purchase"
        );
        require(
            _numTokens <= MAX_PER_TRANSACTION,
            "mint: caller cannot mint more than xxxx per transactions"
        );

        uint256 requestId = requestRandomWords(_numTokens);
        callerByRequestId[requestId] = msg.sender;

        unchecked {
            counter += _numTokens;
        }
    }

    /// @param _numTokens is the number of tokens caller wants to purchase
    /// @param _maxItems is the max amount of items you can claim
    /// @param _merkleproof is the value to prove you are on whitelist
    function claim(
        uint32 _numTokens,
        uint256 _maxItems,
        bytes32[] calldata _merkleproof
    ) external whenAddressOnWhitelist(_merkleproof, _maxItems) {
        require(
            saleState == SaleState.CLAIM,
            "claim: sale state must be active"
        );

        require(_numTokens > 0, "claim: Must input a number greater than 0");

        // Is it possible to hit this condition given amount allowed in whitelist
        require(
            _numTokens + counter <= MAX_TOKENS_IN_SALE,
            "claim: insufficient supply remaining for purchase"
        );

        require(
            _numTokens + tokensClaimedByAddress[msg.sender] <= _maxItems,
            "claim: insufficient supply remaining for purchase"
        );

        require(
            _numTokens <= MAX_PER_TRANSACTION,
            "claim: caller cannot mint more than xxxx per transactions"
        );

        uint256 requestId = requestRandomWords(_numTokens);
        callerByRequestId[requestId] = msg.sender;

        unchecked {
            counter += _numTokens;
            tokensClaimedByAddress[msg.sender] += _numTokens;
        }
    }

    /// @param _numTokens is the number of tokens caller wants to purchase
    function requestRandomWords(uint32 _numTokens) private returns (uint256) {
        return
            COORDINATOR.requestRandomWords(
                keyHash,
                subscriptionId,
                requestConfirmations,
                (callbackGasLimitMultiplier * _numTokens) +
                    callbackGasLimitBase,
                _numTokens
            );
    }

    /// @param requestId the Id matching contract call to chainlink
    /// @param randomWords is the random numbers from VRF
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        // deck deal for serial numbers
        uint256[] memory serialNumbers = dealTokens(randomWords);
        // identify collections based on serial numbers using probability map
        uint256 i;
        for (; i < randomWords.length; ) {
            _mint(callerByRequestId[requestId], serialNumbers[i], 1, "");
            unchecked {
                ++i;
                ++supply;
            }
        }
    }

    /// @param _saleState is the state in which the contract is in
    function setSaleState(SaleState _saleState) public override onlyOwner {
        super.setSaleState(_saleState);
    }

    /// @param _subscriptionId is the Id from the Chainlink subscription manager
    function updateSubscriptionId(uint64 _subscriptionId)
        public
        override
        onlyOwner
    {
        super.updateSubscriptionId(_subscriptionId);
    }

    /// @param _keyHash is the keyhash from the Chainlink subscription manager
    function updateKeyHash(bytes32 _keyHash) public override onlyOwner {
        super.updateKeyHash(_keyHash);
    }

    /// @param _callbackGasLimitMultiplier is the maximum gas for a callback function
    function updateCallbackGasLimits(
        uint32 _callbackGasLimitMultiplier,
        uint32 _callbackGasLimitBase
    ) public override onlyOwner {
        super.updateCallbackGasLimits(
            _callbackGasLimitMultiplier,
            _callbackGasLimitBase
        );
    }

    /// @param _requestConfirmations the confirmation number from the request
    function updateRequestConfirmations(uint16 _requestConfirmations)
        public
        override
        onlyOwner
    {
        super.updateRequestConfirmations(_requestConfirmations);
    }

    /// @notice used to randomly assign tokenId's to the NFT mint
    /// @param _randomWords is assigning a random number to a tokenId from Chainlink
    /// @return tokenIds returns an array of random tokenId's
    function dealTokens(uint256[] memory _randomWords)
        private
        returns (uint256[] memory)
    {
        uint256 tokensRemaining = MAX_TOKENS_IN_SALE - supply;

        uint256 numberOfTokens = _randomWords.length;
        uint256[] memory tokenIds = new uint256[](numberOfTokens);

        uint256 i;
        for (; i < numberOfTokens; ) {
            uint256 randomNum = _randomWords[i] % tokensRemaining;

            uint256 index = deckCache[randomNum] == 0
                ? randomNum
                : deckCache[randomNum];

            deckCache[randomNum] = deckCache[tokensRemaining] == 0
                ? --tokensRemaining
                : deckCache[--tokensRemaining];

            tokenIds[i] = _mapCollectionId(index);

            unchecked {
                ++i;
            }
        }

        return tokenIds;
    }

    /// @param _merkleRoot is the whitelist
    function setMerkleroot(bytes32 _merkleRoot) external onlyOwner {
        merkleroot = _merkleRoot;
    }

    /// @param _baseURI is an IPFS link
    function setBaseURI(string memory _baseURI) external onlyOwner {
        _setURI(_baseURI);
    }

    /// @param _coaDocuments is an IPFS link
    function setCOADocuments(string memory _coaDocuments) external onlyOwner {
        COAdocuments = _coaDocuments;
    }

    /// @dev used for convenience
    function getTotalBalance(address _address) public view returns (uint256) {
        uint256 i = 1;
        uint256 total;
        for (; i < 103; ) {
            total += balanceOf(_address, i);
            unchecked {
                ++i;
            }
        }
        return total;
    }
}