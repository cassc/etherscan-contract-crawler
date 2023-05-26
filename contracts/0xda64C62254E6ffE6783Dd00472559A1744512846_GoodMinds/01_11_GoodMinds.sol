//SPDX-License-Identifier: MIT

//                                                       *,                                 @@@@@@@@
//                                                   @@@@  *@.     @@@@@@@@     @@@@@@@@@   (@@    @@@@
//                                                 @@@           @@@      @@@ @@@      @@@  %@@      @@@
//                                                @@@    ,@@@&   @@       @@@ @@       %@@  /@@       @@
//                                                @@@    .   @@@ @@.      @@@ @@@      @@@  ,@@      @@@
//                                                 @@@       @@@  @@@. #@@@&   @@@@@@@@@*    @@ *@@@@@
//               &@@         @@@                    [email protected]@@@@@@@@      [email protected]@@#                    @@@@
//               @@@        @@@
//  @@%          @@@      [email protected]@@         (@@@      @@       @@@     @@   @@@      @@&  @@@@@@@      @@@@@@@@%
//  @@@          @@@      @@@        @@@@       @@@@@   @@@@@#    @@   @@@@@    @@   @@   ,@@@   @@/
//   @@@                           @@@@        ,@@ %@@@@@@ @@@    @@&  @@&@@@# @@@   @@     @@@  @@@@@@%
//    @@@                           (          @@@   @@@    @@@   @@@  @@/  @@@@@@   @@*    @@@       *@@@@.
//              @@@@@@@@@@@@@@@                @@&          #@@   @@@  @@.   /@@@    @@&  @@@@           ,@@
//         &@@@@              @@@@             @@            @@@   @@  @@            @@@@@@.     @@@@@@@@@@&
//      [email protected]@@                     @@@@                                                                .(/
//     @@.                         @@@@
//                                   @@@%   @@@@@@@@@@@@@@@@@@@@@@(           @@@@@@@@@@@@@@@@@@@@@@@@@@@@@&
//             [email protected]@@@@@@@@@@@           @@@                      @@#          @@@
//                         @@@@          @@@                   @@@         @@@*
//                           @@@           @@@@                @@&        @@@
//                    @@      @@@           @@@@              @@@       @@@@
//          @@@@*,%@@@(      &@@        @@@@@(               @@@      (@@@
//                         @@@@         @@,                 @@@     @@@@
//                    *@@@@@            @@@@@@@@@@@@      @@@.  *@@@@/
//             @@@@@@@@&                        @@@@     @@@@@@@@@
//       (@@@@@@                             @@@@@/
//     @@@@                                 @@@@&@@@@@@
//    @@@                                           @@@
//    @@%            @@@@@@@@@@@@@@@@           @@@@@%
//    /@@(      @@@@@@             @@@     @@@@@@
//      @@@@%@@@@               @@@@%       @@@
//         %@@@@@@@@@@@@@@@@@@@@@           ,@@
//         @@                                @@@
//        @@@                                (@@
//        /@@                                 @@@
//         #@@@                               @@@
//           @@@@&                           @@@
//              [email protected]@@@@@&                @@@@@@*
//                     @@@@@@@@@@@@@@@@@@(

pragma solidity ^0.8.13;

/// @author: Good Minds
/// @title: Good Minds

// Audited by: @backseats_eth

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

error AllowlistClosed();
error BadProof();
error ExceedsMaxMintsAllowlist(uint256 currentBalance, uint256 maxLimit);
error ExceedsMaxMintsPerTx(uint256 maxMintsPerTx);
error ExceedsMaxSupply(uint256 maxSupply);
error ExceedsTeamSupply(uint256 teamSupply);
error NoContracts();
error PublicClosed();
error WrongAmount(uint256 sent, uint256 required);

contract GoodMinds is ERC721A, Ownable, ReentrancyGuard, VRFConsumerBaseV2 {
    using ECDSA for bytes32;
    using Strings for uint256;

    VRFCoordinatorV2Interface COORDINATOR;

    struct ShuffleData {
        uint256 seed;
        uint256 until;
    }

    ShuffleData[] shuffleData;

    enum SaleState {
        CLOSED,
        ALLOWLIST,
        PUBLIC
    }

    SaleState public saleState;

    mapping(address => uint256) public allowlist;

    string private _defaultURI;
    string private _tokenBaseURI;
    string public contractURI;

    bytes32 public merkleRoot;
    bool isShuffled = true;

    uint64 public s_subscriptionId;
    uint256 public s_requestId;
    uint256 public maxSupply = 6000;
    uint256 public constant maxMintPerTx = 10;
    uint256 private constant _teamSupply = 300;
    uint256 private constant _availableForAllowlist = 876;
    uint256 private constant _allowlistWalletLimit = 2;
    uint256 public mintPrice = 30000000000000000; // 0.03 ETH

    address private _withdrawalAddress;

    event SetDefaultURI(string indexed collectionDefaultURI);
    event SetTokenBaseURI(string indexed tokenBaseURI);
    event SetContractURI(string indexed contractURI);

    modifier mintCompliance(uint256 _quantity) {
        if (tx.origin != msg.sender) revert NoContracts();
        if (totalSupply() + _quantity > maxSupply)
            revert ExceedsMaxSupply(maxSupply);
        if (_quantity > maxMintPerTx) revert ExceedsMaxMintsPerTx(maxMintPerTx);
        if (msg.value != _quantity * mintPrice)
            revert WrongAmount(msg.value, _quantity * mintPrice);
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        uint64 _subscriptionId,
        address _vrfCoordinator
    ) payable ERC721A(_name, _symbol) VRFConsumerBaseV2(_vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        s_subscriptionId = _subscriptionId;
    }

    function setDefaultURI(string memory defaultURI_) external onlyOwner {
        _defaultURI = defaultURI_;
        emit SetDefaultURI(_defaultURI);
    }

    function setTokenBaseURI(string memory tokenBaseURI_) external onlyOwner {
        _tokenBaseURI = tokenBaseURI_;
        emit SetTokenBaseURI(_tokenBaseURI);
    }

    function setContractURI(string memory _contractURI) external onlyOwner {
        contractURI = _contractURI;
        emit SetContractURI(contractURI);
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setSaleState(uint256 _state) external onlyOwner {
        require(_state <= uint256(SaleState.PUBLIC), "Bad state");
        saleState = SaleState(_state);
    }

    /// @notice Set the maxSupply
    /// @dev maxSupply can only be deflationary
    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        require(_maxSupply < maxSupply, "Too high");
        maxSupply = _maxSupply;
    }

    function setWithdrawalAddress(address withdrawalAddress_)
        external
        onlyOwner
    {
        require(withdrawalAddress_ != address(0), "Reject zero-account");
        _withdrawalAddress = withdrawalAddress_;
    }

    /// Allows the team to mint the allotted amount
    function teamMint(uint256 _quantity) external onlyOwner {
        if (totalSupply() + _quantity > _teamSupply)
            revert ExceedsTeamSupply(_teamSupply);
        _mint(msg.sender, _quantity);
    }

    /// Mint via the allowlist
    function allowlistMint(bytes32[] calldata _merkleProof, uint256 _quantity)
        external
        payable
        nonReentrant
        mintCompliance(_quantity)
    {
        if (saleState != SaleState.ALLOWLIST) revert AllowlistClosed();
        if (allowlist[msg.sender] + _quantity > _allowlistWalletLimit)
            revert ExceedsMaxMintsAllowlist(
                allowlist[msg.sender],
                _allowlistWalletLimit
            );

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if (!MerkleProof.verify(_merkleProof, merkleRoot, leaf))
            revert BadProof();

        _mint(msg.sender, _quantity);
        allowlist[msg.sender] += _quantity;
    }

    function publicMint(uint256 _quantity)
        external
        payable
        mintCompliance(_quantity)
    {
        if (saleState != SaleState.PUBLIC) revert PublicClosed();
        _mint(msg.sender, _quantity);
    }

    /// "Unshuffle" the metadata so that the URI matches tokenId
    function unshuffle(string memory tokenBaseURI_) external onlyOwner {
        isShuffled = false;
        _tokenBaseURI = tokenBaseURI_;
        emit SetTokenBaseURI(_tokenBaseURI);
    }

    /// Set the new Merkle Root
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /// Withdraw funds from the contract
    function withdrawFunds() external onlyOwner {
        (bool sent, ) = payable(_withdrawalAddress).call{
            value: address(this).balance
        }("");
        require(sent, "Withdraw failed");
    }

    /// @notice Request random number through Chainlink VRF
    /// @param _keyHash Chainlink-provided Key Hash
    /// @param _requestConfirmations Variable number of confirmations
    /// @param _callbackGasLimit Callback function gas limit
    /// @param _numWords Total number of random numbers to request
    function requestRandomWords(
        bytes32 _keyHash,
        uint16 _requestConfirmations,
        uint32 _callbackGasLimit,
        uint32 _numWords
    ) external onlyOwner {
        require(totalSupply() > 0, "No tokens minted");
        if (shuffleData.length > 0) {
            require(totalSupply() > _getLastRevealed(), "None to reveal");
        }
        s_requestId = COORDINATOR.requestRandomWords(
            _keyHash,
            s_subscriptionId,
            _requestConfirmations,
            _callbackGasLimit,
            _numWords
        );
    }

    function fulfillRandomWords(uint256, uint256[] memory randomWords)
        internal
        override
    {
        /*
         * Instead of setting randomWords to an existing var, we
         * push each call to an array so that we can keep track
         * of the seed for each batch.
         */
        shuffleData.push(ShuffleData(randomWords[0], totalSupply() - 1));
    }

    /// Custom tokenURI that uses a custom _getMetadata function for batch reveals
    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        require(_exists(_tokenId), "Query for nonexistent token");
        require(bytes(_tokenBaseURI).length > 0, "tokenBaseURI not set");

        return _getMetadata(_tokenId);
    }

    /// Generates the metadata for various cases
    function _getMetadata(uint256 _tokenId)
        private
        view
        returns (string memory)
    {
        // If true, the token has not revealed yet
        if (_tokenId > _getLastRevealed() || (shuffleData.length == 0)) {
            return _defaultURI;
        }
        // This will return once the metadata is "unshuffled"
        if (!isShuffled) {
            return string.concat(_tokenBaseURI, _tokenId.toString());
        }

        uint256 lowestToken;
        uint256 metadataForTokenId;

        for (uint256 i; i < shuffleData.length; i++) {
            ShuffleData memory batch = shuffleData[i];

            /*
             * This will keep looping through batches until the tokenId
             * requested is in the current batch
             */
            if (_tokenId > batch.until) {
                continue;
            }

            // Gets the lowest token in the current batch to reveal
            lowestToken = i > 0 ? shuffleData[i - 1].until + 1 : 0;

            uint256 batchSize = batch.until - lowestToken + 1;

            uint256[] memory metadata = new uint256[](batchSize);

            // Initializes the metadata array with the base values
            for (i = lowestToken; i <= batch.until; i++) {
                metadata[i - lowestToken] = i;
            }

            /*
             * Attempts to swap every value in the metadata with another. This
             * method uses Chainlink VRF to generate a random seed to randomly swap
             * the base value with another. Though rare, it is possible for a base
             * value not to be swapped.
             */
            for (i = lowestToken; i < batch.until; i++) {
                uint256 swap = (uint256(keccak256(abi.encode(batch.seed, i))) %
                    (batchSize));
                (metadata[i - lowestToken], metadata[swap]) = (
                    metadata[swap],
                    metadata[i - lowestToken]
                );
            }
            // Updates metadataForTokenId for the following return statement
            metadataForTokenId = metadata[_tokenId - lowestToken];
        }
        return string.concat(_tokenBaseURI, metadataForTokenId.toString());
    }

    /// Gets the last tokenId of the last batch to be revealed
    function _getLastRevealed() private view returns (uint256) {
        return
            shuffleData.length > 0
                ? shuffleData[shuffleData.length - 1].until
                : 0;
    }
}