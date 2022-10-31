//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

error MintingClosed();
error AmountNotAvailable();
error WouldExceedMaxPerWallet();
error OnlyUserMint();
error NotWhiteListed();
error ValueNotEqualToPrice();
error NotEnoughBalance();
error AlreadyMintedMaxInPhase();
error NotAllowListed();
error WrongMintFunction();

contract NotMafia is ERC721A, Ownable {
    // The different options of the status of the contract, governs which mint function can be called
    enum Status {
        CLOSED, // 0
        WHITELIST, // 1
        PUBLIC // 2
    }

    Status public status;
    uint256 public price;

    string public baseURI;

    bytes32 public whiteListRoot;

    /**
     * Token id allocation:
     *
     * |  WHITELIST  |  |     FREE      |  |     PAID      |
     * |    1 pw     |  |     1 pw      |  |     3 pw      |
     * [1, ..., 1700 ]  [1701, ..., 2222]  [2223, ..., 4444]
     */
    uint256 private tokenId;
    uint256 private constant TOTAL_WHITELIST_SUPPLY = 1700;
    uint256 private constant TOTAL_FREE_SUPPLY = 2222;
    uint256 private TOTAL_SUPPLY = 4444;
    uint256 private constant MAX_PER_WALLET_PUBLIC = 5;

    mapping(address => bool) private hasMintedWhiteList;
    mapping(address => bool) private hasMintedFree;
    mapping(address => uint256) private hasMintedSale;

    event ChangedStatus(uint256 newStatus);

    // Constructor
    constructor() ERC721A("notmafia", "NTMF") {
        status = Status.CLOSED;
        price = 0.00869 ether;
        tokenId = 1;
    }

    /**
     *  ############## PUBLIC FUNCTIONS ##############
     */

    function ownerMint(uint256 __amount) external onlyOwner {
        // Order should not exceed the total supply
        if (totalSupply() + __amount > TOTAL_SUPPLY) revert AmountNotAvailable();

        // Increment counter
        unchecked {
            tokenId += __amount;
        }

        // Do the magic
        _safeMint(msg.sender, __amount);
    }

    function whiteListMint(bytes32[] calldata __proof) external {
        // Caller cannot be a contract
        if (tx.origin != msg.sender) revert OnlyUserMint();

        // Status should be WHITELIST
        if (status != Status.WHITELIST) revert WrongMintFunction();

        // There should still be WHITELIST supply left to fulfill order
        if (tokenId > TOTAL_WHITELIST_SUPPLY) revert AmountNotAvailable();

        // Caller should be on the WHITELIST
        if (!verifyWhiteList(__proof, whiteListRoot)) revert NotWhiteListed();

        // Caller cannot mint more than one during the WHITELIST phase
        if (hasMintedWhiteList[msg.sender]) revert AlreadyMintedMaxInPhase();

        // Increment counter
        unchecked {
            tokenId += 1;
        }

        // Update: the caller minted during WHITELIST
        hasMintedWhiteList[msg.sender] = true;

        // Do the magic
        _safeMint(msg.sender, 1);
    }

    function publicMint(uint256 __amount) external payable {
        // Caller cannot be a contract
        if (tx.origin != msg.sender) revert OnlyUserMint();

        // Status must be PUBLIC
        if (status != Status.PUBLIC) revert WrongMintFunction();

        // Send the call to the right mint function
        if (tokenId > TOTAL_FREE_SUPPLY) {
            paidMint(__amount);
        } else {
            freeMint();
        }
    }

    /**
     *  ############## OVERRIDING FUNCTIONS ##############
     */

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        // The first token that is minted has number #1
        return 1;
    }

    function tokenURI(uint256 __tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(__tokenId)) revert URIQueryForNonexistentToken();

        string memory __baseURI = baseURI;
        return
            bytes(__baseURI).length != 0
                ? string(
                    abi.encodePacked(__baseURI, _toString(__tokenId), ".json")
                )
                : "";
    }

    /**
     *  ############## INTERNAL FUNCTIONS ##############
     */

    function freeMint() internal {
        // Cannot send eth when minting free
        if (msg.value != 0) revert ValueNotEqualToPrice();

        // Caller is not allowed to mint more than one during the FREE phase
        if (hasMintedFree[msg.sender]) revert AlreadyMintedMaxInPhase();

        // Increment counter
        unchecked {
            tokenId += 1;
        }

        // Update: the caller minted during the FREE phase
        hasMintedFree[msg.sender] = true;

        // Do the magic.
        _safeMint(msg.sender, 1);
    }

    function paidMint(uint256 __amount) internal {
        // Msg value must be equal to the cost of the amount of NFT's
        if (msg.value != __amount * price) revert ValueNotEqualToPrice();

        // Cannot mint more than allowed per wallet
        uint256 amountMinted = hasMintedSale[msg.sender];
        if (amountMinted + __amount > MAX_PER_WALLET_PUBLIC)
            revert WouldExceedMaxPerWallet();

        // There must be supply left to fulfill the order
        if (tokenId + __amount > TOTAL_SUPPLY) revert AmountNotAvailable();

        // Increment counter
        unchecked {
            tokenId += __amount;
        }

        // update the amount minted by user
        hasMintedSale[msg.sender] = amountMinted + __amount;

        // Do the magic
        _safeMint(msg.sender, __amount);
    }

    function verifyWhiteList(bytes32[] calldata __proof, bytes32 __root)
        internal
        view
        returns (bool)
    {
        return
            MerkleProof.verify(
                __proof,
                __root,
                keccak256(abi.encodePacked(msg.sender))
            );
    }

    /**
     *  ############## GETTERS -> EXTERNAL ##############
     */

    function getCurrentTokenId() external view returns (uint256) {
        return tokenId;
    }

    function getHasMintedFree(address __address) external view returns (bool) {
        return hasMintedFree[__address];
    }

    function getHasMintedWhiteList(address __address)
        external
        view
        returns (bool)
    {
        return hasMintedWhiteList[__address];
    }

    function getHasMintedSale(address __address)
        external
        view
        returns (uint256)
    {
        return hasMintedSale[__address];
    }

    /**
     *  ############## SETTERS -> ONLY OWNER ##############
     */

    function setStatus(uint256 __status) external onlyOwner {
        status = Status(__status);
        emit ChangedStatus(__status);
    }

    function setBaseURI(string memory __newURI) external onlyOwner {
        baseURI = __newURI;
    }

    function setWhiteListRoot(bytes32 __root) external onlyOwner {
        whiteListRoot = __root;
    }

    function setPrice(uint256 __price) external onlyOwner {
        price = __price;
    }

    function setTotalSupply(uint256 __newTotalSupply) external onlyOwner {
        TOTAL_SUPPLY = __newTotalSupply;
    }

    /**
     *  ############## FUNCTIONS -> ONLY OWNER ##############
     */

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}