// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract BAC2Implementation is ERC721A, AccessControl, VRFConsumerBaseV2 {
    enum State {
        InitMint,
        BulkMint,
        ComboMint,
        PublicMint,
        Paused,
        Complete
    }

    VRFCoordinatorV2Interface COORDINATOR;

    uint64 s_subscriptionId;

    bytes32 keyHash;

    uint32 callbackGasLimit = 100000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;


    uint256[] public s_randomWords;
    uint256 public s_requestId;

    State public STATE;

    //Roles
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant WITHDRAWER_ROLE = keccak256("WITHDRAWER_ROLE");

    uint256 constant public MAX_SUPPLY = 10000;
    uint256 constant public TOKENS_PER_TX = 25;

    address public BACV1_CONTRACT;
    uint256 public MINT_PRICE = 0.04 ether;


    //Rarities
    string public rarityListHash;
    string public reorderedListHash;
    string public fileKey;

    //ERRORS
    error StateError(State actual, State expected);
    error ContractError();
    error NumberTokensError();
    error ValueBelowPriceError();
    error MaxSupplyError();
    error NotOwnerError();
    error SameTokenError();
    error AlreadyUsedTokenError();

    error TokenCountError();
    error MaxPerWalletError();
    error MaxPerTransactionError();

    error ArraySizeError();

    error RarityListHashError();
    error ReorderedListHashError();
    error FileKeyError();

    //Metadata
    string private baseTokenURI;
    string private _contractURI;

    mapping(uint256 => address) usedTokens;

    //Events
    event PresaleMint(
        uint256 token1,
        uint256 token2,
        uint256 newToken
    );

    event RandomWordsGenerated(
        uint256[] randomWords
    );

    event RarityListChanged(string value);
    event RarityOrderedListChanged(string value);
    event KeyChanged(string value);

    event StateChanged(State value);


    constructor(address contractAddress, address vrfCoordinator) ERC721A("Bored Ape Comic #2", "BAC2") VRFConsumerBaseV2(vrfCoordinator) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(WITHDRAWER_ROLE, msg.sender);

        BACV1_CONTRACT = contractAddress;
        STATE = State.BulkMint;

        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    }

    //OpenSea
    function setContractURI(string memory newContractURI)
    external
    onlyRole(OPERATOR_ROLE)
    {
        _contractURI = newContractURI;
    }

    ///Returns the contract URI for OpenSea
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setSubscriptionId(uint64 subscriptionId) external onlyRole(OPERATOR_ROLE) {
        s_subscriptionId = subscriptionId;
    }

    function setKeyHash(bytes32 _keyHash) external onlyRole(OPERATOR_ROLE) {
        keyHash = _keyHash;
    }

    function getCoordinator() external view returns (address) {
        return address(COORDINATOR);
    }


    function getKeyHash() external view returns (bytes32) {
        return keyHash;
    }

    function setGasLimit(uint32 _callbackGasLimit) external onlyRole(OPERATOR_ROLE) {
        callbackGasLimit = _callbackGasLimit;
    }

    function getGasLimit() external view returns (uint32) {
        return callbackGasLimit;
    }

    function setRequestConfirmations(uint16 _requestConfirmations) external onlyRole(OPERATOR_ROLE) {
        requestConfirmations = _requestConfirmations;
    }

    function getRequestConfirmations() external view returns (uint16) {
        return requestConfirmations;
    }

    function setNumWords(uint32 _numWords) external onlyRole(OPERATOR_ROLE) {
        numWords = _numWords;
    }

    function getNumWords() external view returns (uint32) {
        return numWords;
    }


    function getRandomNumber() external view returns (uint256) {
        if (s_randomWords.length > 0) {
            return s_randomWords[0] % 9999;
        }

        return 0;
    }

    function setOriginalRarityListHash(string memory _hash)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
    {
        rarityListHash = _hash;
        emit RarityListChanged(_hash);
    }

    function setReorderedRarityListHash(string memory _hash)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
    {
        reorderedListHash = _hash;
        emit RarityOrderedListChanged(_hash);
    }

    function setFileKey(string memory _fileKey)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
    {
        fileKey = _fileKey;
        emit KeyChanged(_fileKey);
    }


    function requestRandomWords() external onlyRole(OPERATOR_ROLE) {
        s_requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
    }

    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory randomWords
    ) internal override {
        s_randomWords = randomWords;
    }

    function safeMint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        if (STATE != State.BulkMint) {
            revert StateError(STATE, State.BulkMint);
        }
        _safeMint(to, amount, "");
    }

    function safeMintArray(address[] calldata to, uint256[] calldata amount) external onlyRole(MINTER_ROLE) {
        if (STATE != State.BulkMint) {
            revert StateError(STATE, State.BulkMint);
        }

        if (to.length != amount.length) {
            revert ArraySizeError();
        }

        for (uint256 i = 0; i < to.length; i++) {
            _safeMint(to[i], amount[i], "");
        }
    }


    function presaleMint(uint256[] memory tokens) external payable {
        if (STATE != State.ComboMint) {
            revert StateError(STATE, State.ComboMint);
        }
        if (BACV1_CONTRACT == address(0)) {
            revert ContractError();
        }

        if (tokens.length == 0 || tokens.length % 2 != 0) {
            revert NumberTokensError();
        }

        uint256 tokensToMint = tokens.length / 2;

        if (msg.value < (MINT_PRICE * tokensToMint)) {
            revert ValueBelowPriceError();
        }

        uint256 currentSupply = totalSupply();

        if ((currentSupply + tokensToMint) > MAX_SUPPLY) {
            revert MaxSupplyError();
        }

        for (uint256 index = 0; index < tokens.length; index += 2) {
            if (tokens[index] == tokens[index + 1]) {
                revert SameTokenError();
            }

            if (
                IERC721(BACV1_CONTRACT).ownerOf(tokens[index]) != msg.sender ||
                IERC721(BACV1_CONTRACT).ownerOf(tokens[index + 1]) != msg.sender
            ) {
                revert NotOwnerError();
            }

            if (
                usedTokens[tokens[index]] != address(0) ||
                usedTokens[tokens[index + 1]] != address(0)
            ) {
                revert AlreadyUsedTokenError();
            }

            usedTokens[tokens[index]] = msg.sender;
            usedTokens[tokens[index + 1]] = msg.sender;
            currentSupply++;
            emit PresaleMint(
                tokens[index],
                tokens[index + 1],
                currentSupply
            );
        }
        _safeMint(msg.sender, tokensToMint);
    }

    function publicMint(uint256 count) external payable {
        if (STATE != State.PublicMint) {
            revert StateError(STATE, State.PublicMint);
        }

        if (count == 0) {
            revert TokenCountError();
        }

        if (count > TOKENS_PER_TX) {
            revert MaxPerTransactionError();
        }

        if (msg.value < (MINT_PRICE * count)) {
            revert ValueBelowPriceError();
        }

        uint256 currentSupply = totalSupply();

        if ((currentSupply + count) > MAX_SUPPLY) {
            revert MaxSupplyError();
        }

        _safeMint(_msgSender(), count);
    }

    function setPrice(uint256 price) external onlyRole(OPERATOR_ROLE) {
        MINT_PRICE = price;
    }


    function getPrice() external view returns (uint256) {
        return MINT_PRICE;
    }

    function setState(State _state) external onlyRole(OPERATOR_ROLE) {
        STATE = _state;
        emit StateChanged(_state);
    }

    function getState() external view returns (State) {
        return STATE;
    }

    function setContractAddress(address contractAddress)
    external
    onlyRole(OPERATOR_ROLE)
    {
        BACV1_CONTRACT = contractAddress;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyRole(OPERATOR_ROLE) {
        baseTokenURI = baseURI;
    }

    function usedTokensFromList(uint256[] memory _tokens)
    external
    view
    returns (uint256[] memory)
    {
        uint256[] memory _usedTokens = new uint256[](_tokens.length);
        uint256 usedTokensIndex = 0;

        for (uint256 index = 0; index < _tokens.length; index++) {
            if (usedTokens[_tokens[index]] != address(0)) {
                _usedTokens[usedTokensIndex] = _tokens[index];
                usedTokensIndex++;
            }
        }

        return _usedTokens;
    }

    function isTokenUsed(uint256 _token) external view returns (bool) {
        return usedTokens[_token] != address(0);
    }

    function withdrawAll() public payable onlyRole(WITHDRAWER_ROLE) {
        uint256 balance = address(this).balance;

        (bool sent,) = payable(msg.sender).call{value : balance}("");
        require(sent, "WITHDRAW_FAILED");
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721A, AccessControl)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function burn(uint256 tokenId) external {
        super._burn(tokenId, true);
    }
}