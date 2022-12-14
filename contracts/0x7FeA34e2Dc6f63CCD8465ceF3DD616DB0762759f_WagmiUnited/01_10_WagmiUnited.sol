// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721A.sol";
import {OperatorFilterer} from "./OperatorFilterer.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

interface IERC1155 {
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) external;

    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);
}

interface SanctionsList {
    function isSanctioned(address addr) external view returns (bool);
}

contract WagmiUnited is
    ERC721A,
    ERC2981,
    Ownable,
    OperatorFilterer
{
    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Token symbol
    uint256 private _maxSupply;

    // Minting status
    bool private _mintEnabled = false;

    // Token reveal
    bool private _reveal = false;

    // Base uri
    string public baseUri = "";

    // Chainalysis sanctions contract
    address constant SANCTIONS_CONTRACT = 0x40C57923924B5c5c5455c48D93317139ADDaC8fb;
    SanctionsList constant SANCTIONSLIST = SanctionsList(SANCTIONS_CONTRACT);
    bool private _checkSanctions = true;

    // 1155 Capsule contract
    IERC1155 private _src;

    // Decay seedSalt value
    uint256 private _seed = 4254618;
    uint256 constant MODEVALUE = 100;

    // Decaying state
    bool private _decayEnabled = false;

    // The minimum decay value
    uint256 private _decayLimit = 1;

    // Decay probability
    uint256 private _decayProbability = 20;

    // Mapping tokenId to decay amount
    mapping(uint256 => uint256) private _decay;

    // Mapping tokenId to message
    mapping(uint256 => string) private _message;

    // Message state
    bool private _messagesEnabled = false;

    // Mapping tokenId to score
    mapping(uint256 => uint256) private _score;
    mapping(address => bool) private _scoreAdmins;

    // Score state
    bool private _scoreEnabled = false;

    // Emitted events
    event TokenDecayed(uint256 tokenId);

    bool public operatorFilteringEnabled;

    constructor(
        string memory __name,
        string memory __symbol,
        string memory _baseUri,
        uint256 __maxSupply,
        address recipient, 
        uint96 value,
        address erc1155
    ) ERC721A(__name, __symbol) {
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;

        _name = __name;
        _symbol = __symbol;
        _src = IERC1155(erc1155);
        _maxSupply = __maxSupply;
        baseUri = _baseUri;
        _setDefaultRoyalty(recipient, value);
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    function setNameAndSymbol(string calldata __name, string calldata __symbol)
        public
        onlyOwner
    {
        _name = __name;
        _symbol = __symbol;
    }

    /** Tests balanceOf function of 1155 contract pre launch
     * @param user address of user
     * @param id tokenId for 1155 contract
     */
    function balanceOf1155(address user, uint256 id)
        public
        view
        returns (uint256)
    {
        return _src.balanceOf(user, id);
    }

    /**
     * @param enableMessages sets whether token messages is enabled
     */
    function setMessagesEnabled(bool enableMessages) public onlyOwner {
        _messagesEnabled = enableMessages;
    }

    /**
     * @param tokenId sets whether token messages is enabled
     * @param message sets whether token messages is enabled
     */
    function addTokenMessage(uint256 tokenId, string calldata message) public {
        require(_messagesEnabled, "Token messages are not enabled");
        if (owner() == msg.sender || msg.sender == ownerOf(tokenId)) {
            _message[tokenId] = message;
        } else {
            revert("Not authorized");
        }
    }

    /**
     * @param tokenId sets whether token messages is enabled
     */
    function tokenMessage(uint256 tokenId) public view returns (string memory) {
        require(_messagesEnabled, "Token messages are not enabled");
        return _message[tokenId];
    }

    /**
     * @param scoreEnabled sets whether token score setting is enabled
     */
    function setScoreTrackingStatus(bool scoreEnabled) public onlyOwner {
        _scoreEnabled = scoreEnabled;
    }

    /**
     * @param admin new admin account address
     * @param isAdmin sets whether account is score admin
     */
    function setScoreAdmin(address admin, bool isAdmin) public onlyOwner {
        _scoreAdmins[admin] = isAdmin;
    }

    /**
     * @param reveal sets reveal state
     * @param _baseUri sets baseUri string
     */
    function setReveal(bool reveal, string calldata _baseUri) public onlyOwner {
        _reveal = reveal;
        baseUri = _baseUri;
    }

    /**
     * @param tokenId to have score value changed.
     * @param value sets the new score value
     */
    function setTokenScore(uint256 tokenId, uint256 value) public {
        require(_scoreEnabled, "Setting score is not enabled");
        require(_exists(tokenId), "Token doesn't exist");
        if (owner() == msg.sender || _scoreAdmins[msg.sender]) {
            _score[tokenId] = value;
        } else {
            revert("Not authorized");
        }
    }

    /**
     * @param tokenIds[] array of tokenid to have score value changed.
     * @param values[] array of score values
     */
    function setBatchTokenScore(
        uint256[] calldata tokenIds,
        uint256[] calldata values
    ) public {
        require(_scoreEnabled, "Setting score is not enabled");
        if (owner() == msg.sender || _scoreAdmins[msg.sender]) {
            require(tokenIds.length == values.length, "Mismatched lengths");
            uint256 count = tokenIds.length;
            unchecked {
                for (uint256 i = 0; i < count; ) {
                    require(_exists(tokenIds[i]), "Token doesn't exist");
                    _score[tokenIds[i]] = values[i];
                    i++;
                }
            }
        } else {
            revert("Not authorized");
        }
    }
    
    /**
     * @param seed reset seed value.
     */
    function resetSeed(uint256 seed) public onlyOwner {
        _seed = seed;
    }

    /**
     * @param tokenId of score to be returned.
     */
    function getTokenScore(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Token doesn't exist");
        return _score[tokenId];
    }

    /**
     * @param checkSanctions sets whether account sanction checking is enabled
     */
    function setSanctionChecking(bool checkSanctions) public onlyOwner {
        _checkSanctions = checkSanctions;
    }

    /**
     * @param decayLimit sets the decay limit of contract, default is 20
     */
    function setDecayLimit(uint256 decayLimit) public onlyOwner {
        require(decayLimit <= 10, "decayLimit to high");
        require(decayLimit > 0, "decayLimit to low");
        _decayLimit = decayLimit;
    }

    /**
     * @param decayEnabled sets the decay status of contract
     */
    function setDecayEnabled(bool decayEnabled) public onlyOwner {
        _decayEnabled = decayEnabled;
    }

    /**
     * @param decayProbability sets the decay probability during any tranfer function
     */
    function setDecayProbability(uint256 decayProbability) public onlyOwner {
        require(decayProbability <= 100, "Probability too high");
        require(decayProbability > 0, "Probability too low");
        _decayProbability = decayProbability;
    }

    /**
     * @param enabled sets the minting status of contract
     */
    function setMintStatus(bool enabled) public onlyOwner {
        _mintEnabled = enabled;
    }

    // URI
    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }

    function setBaseUri(string calldata _baseUri) public onlyOwner {
        baseUri = _baseUri;
    }

    /**
     * @param id 1155 Token id WAGMIUnited contract has a single Id = 1
     * @param value the amount of tokens to burn and minted
     */
    function burnAndMint(uint256 id, uint256 value) external {
        require(_mintEnabled == true, "Minting not enabled yet");

        uint256 newMax = _totalMinted() + value;
        require(_maxSupply >= newMax, "Max Supply limit reached");

        if (_checkSanctions) {
            //Check if msg.sender is sanctioned
            bool isToSanctioned = SANCTIONSLIST.isSanctioned(msg.sender);
            require(!isToSanctioned, "Transfer to sanctioned address");
        }

        uint256 quantity = _src.balanceOf(msg.sender, id);
        require(quantity >= value, "Insufficient tokens");

        // 1155 Burn value of Token id
        _src.burn(msg.sender, id, value);

        // mint's to msg.sender 721 of value amount
        _mint(msg.sender, value);
    }

    /**
     * @param to array of destination addresses
     * @param value the amount of tokens to minted
     */
    function mintMany(address[] calldata to, uint256[] calldata value)
        external
        onlyOwner
    {
        require(to.length == value.length, "Mismatched lengths");
        uint256 count = to.length;
        unchecked {
            for (uint256 i = 0; i < count; ) {
                // mint value amount for to address
                uint256 newMax = _totalMinted() + value[i];
                require(_maxSupply >= newMax, "Max Supply limit reached");

                _mint(to[i], value[i]);
                i++;
            }
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        string memory base = _baseURI();
        if(_reveal == true) {
            uint256 decay = _decay[tokenId] == 0 ? 10 : _decay[tokenId];
            string memory suffix = ".json";
            string memory slash = "/";

            // Concatenate the baseURI, tokenId, and decay (via abi.encodePacked).
            return
                string(
                    abi.encodePacked(
                        base,
                        _toString(tokenId),
                        slash,
                        _toString(decay),
                        suffix
                    )
                );
        } else {
            return base;
        }
    }

    /**
     * As tokens are transferred from wallet to wallet there is a chance of token decay.
     * @param tokenId is the token Id
     */
    function _decayToken(
        uint256 tokenId
    ) private {
        if (_decayEnabled) {
            uint256 probability = randomNum(tokenId);
            if (probability < _decayProbability) {
                if (_decay[tokenId] == 0) {
                    _decay[tokenId] = 9;
                } else if (
                    _decay[tokenId] > _decayLimit
                ) {
                    _decay[tokenId] = _decay[tokenId] - 1;
                }
                emit TokenDecayed(tokenId);
            }
        }
    }

    /**
     * @notice Updates the source of randomness. Uses block.difficulty in pre-merge chains, this is substituted
     * to block.prevrandao in post merge chains.
     * @param tokenId is the token Id
     */
    function randomNum(
        uint256 tokenId
    ) private returns (uint256) {
        uint256 seed = uint256(keccak256(abi.encode(block.difficulty,block.timestamp,block.number,msg.sender,_seed,tokenId)));
        _seed = seed;
        uint256 output = _seed % MODEVALUE;
        return output;
    }

    // Royalities
    function setRoyalties(address recipient, uint96 value) public onlyOwner {
        _setDefaultRoyalty(recipient, value);
    }

    // Interface Support
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981)
        returns (bool)
    {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override (ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override (ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override (ERC721A)
        onlyAllowedOperator(from)
    {
        _decayToken(tokenId);
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override (ERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override (ERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(address operator) internal pure override returns (bool) {
         return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
     }
}