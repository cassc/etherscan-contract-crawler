// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IOperatorFilterRegistry} from "./IOperatorFilterRegistry.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFTcontract is ERC721Enumerable, ReentrancyGuard {
    address constant DEFAULT_SUBSCRIPTION = address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);
    IOperatorFilterRegistry public constant OPERATOR_FILTER_REGISTRY =
        IOperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);
    mapping(uint256 => string) private arrBaseURIs;
    mapping(uint256 => uint256) private stageTime;

    uint256 private publicMintId;
    uint256 private smallestCnt;
    uint256 public totalCntOfContent;
    uint256 public maxPublicMint;
    uint256 private transferOwnerTime;
    uint256 private updateValidTime;
    string private validKey;
    bool public revealStatus;
    bool public putCap;
    address public collectAddress;
    address public owner;

    error OperatorNotAllowed(address operator);
    error CallNotAllowed(uint times);
    error MintTimeNotYet(uint256 privateMintTime, uint256 publicMintTime, uint256 currentTime);
    error MintOver(uint256 realNum);
    error InputInvalidData();
    error TransferETHFailed();
    error InvalidKey();
    error Unauthorized(address caller);
    error NotExistedToken(uint256 tokenid);

    constructor(
        address _owner,
        address _collectAddress,
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _maxPublicMint
    ) ERC721(_tokenName, _tokenSymbol) {
        OPERATOR_FILTER_REGISTRY.registerAndSubscribe(address(this), DEFAULT_SUBSCRIPTION);
        maxPublicMint = _maxPublicMint;
        collectAddress = _collectAddress;
        owner = _owner;
        smallestCnt = _maxPublicMint;
        publicMintId = 1;
    }

    modifier isCorrectPayment(string calldata _valid, uint256 _stage) {
        if (keccak256(abi.encodePacked(_valid)) != keccak256(abi.encodePacked(validKey))) {
            revert InvalidKey();
        }
        uint256 currTime = block.timestamp;
        if (_stage == 1) {
            if (stageTime[_stage] > currTime) {
                revert MintTimeNotYet(stageTime[0], stageTime[1], currTime);
            }
        }
        if (_stage == 0) {
            if (stageTime[_stage] > currTime) {
                revert MintTimeNotYet(stageTime[0], stageTime[1], currTime);
            }
        }
        _;
    }

    modifier canMint(uint256 numberOfTokens) {
        _canMint(numberOfTokens);
        _;
    }

    modifier onlyAllowedOperator(address from) virtual {
        if (from != msg.sender) {
            _checkFilterOperator(msg.sender);
        }
        _;
    }

    modifier onlyAllowedOperatorApproval(address operator) virtual {
        _checkFilterOperator(operator);
        _;
    }

    modifier onlyOwner() {
		_checkOwner();
		_;
    }

    function _checkOwner() internal view virtual {
        if (msg.sender != owner) {
            revert Unauthorized(msg.sender);
        }
    }

    function _canMint(uint256 _numberOfTokens) internal view virtual {
        uint256 temp = publicMintId + _numberOfTokens;
        if (temp > maxPublicMint + 1) {
            revert MintOver(temp);
        }
    }

    function _checkFilterOperator(address operator) internal view virtual {
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            if (!OPERATOR_FILTER_REGISTRY.isOperatorAllowed(address(this), operator)) {
                revert OperatorNotAllowed(operator);
            }
        }
    }

    function transferFrom(address from, address to, uint256 tokenId) public override(IERC721, ERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override(IERC721, ERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override(IERC721, ERC721)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function updateOperatorsFilter(address[] calldata _operators, bool[] calldata _allowed) external onlyOwner {
        uint256 lengthAllowed = _allowed.length;
        if (_operators.length != lengthAllowed) {
            revert InputInvalidData();
        }

        for (uint256 i; i < lengthAllowed; i++) {
            if (_allowed[i] == OPERATOR_FILTER_REGISTRY.isOperatorFiltered(address(this), _operators[i])) {
                OPERATOR_FILTER_REGISTRY.updateOperator(address(this), _operators[i], !_allowed[i]);
            }
        }
    }
    
    // ============ PUBLIC MINT FUNCTION FOR NORMAL USERS ============
    function publicMint(string calldata _valid, uint256 _numberOfTokens, uint256 _stage)
        public
        payable
        isCorrectPayment(_valid, _stage)
        canMint(_numberOfTokens)
        nonReentrant
    {
        uint256 temp = publicMintId;
        for (uint256 i; i < _numberOfTokens; i++) {
            _mint(msg.sender, temp);
            temp++;
        }
        publicMintId = temp;
        // ============ WITHDRAW ETH TO THE COLLECT ADDRESS ============
        (bool success, ) = payable(collectAddress).call{
            value: msg.value
        }("");
        if (success ==  false) {
            revert TransferETHFailed();
        }
    }

    // ============ MINT FUNCTION FOR ONLY OWNER ============
    function privateMint(uint256 _numberOfTokens)
        public
        payable
        canMint(_numberOfTokens)
        nonReentrant
        onlyOwner
    {
        uint256 temp = publicMintId;
        for (uint256 i; i < _numberOfTokens; i++) {
            _mint(msg.sender, temp);
            temp++;
        }
        publicMintId = temp;
    }

    // ============ FUNTION TO READ TOKENRUI ============
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (_exists(_tokenId) == false) {
            revert NotExistedToken(_tokenId);
        }
        if (!revealStatus) {
            return
                string(
                    abi.encodePacked(
                        arrBaseURIs[maxPublicMint],
                        Strings.toString(maxPublicMint),
                        ".json"
                    )
                ); 
        }
        uint256 index;
        if (_tokenId < smallestCnt) {
            index = smallestCnt;
        } else {
            for (index = _tokenId; index <= maxPublicMint;) {
                index++;
                if (keccak256(abi.encodePacked(arrBaseURIs[index])) != keccak256(abi.encodePacked(""))) {
                    break;
                }
            }
        }
        return
            string(
                abi.encodePacked(
                    arrBaseURIs[index],
                    Strings.toString(_tokenId),
                    ".json"
                )
            );
    }

    // ============ FUNCTION TO UPDATE ETH COLLECTADDRESS ============
    function setCollectAddress(address _collectAddress) external onlyOwner {
        collectAddress = _collectAddress;
    }

    // ============ FUNCTION TO UPDATE BASEURIS ============
    function updateBaseURI(
        uint256 _numOfTokens,
        string calldata _baseURI
    ) external onlyOwner {
        uint256 temp = totalCntOfContent + _numOfTokens;
        if (temp > maxPublicMint || putCap == true) {
            revert InputInvalidData();
        }
        totalCntOfContent = temp;
        if (smallestCnt > totalCntOfContent) {
            smallestCnt = totalCntOfContent;
        }
        arrBaseURIs[totalCntOfContent] = _baseURI;
    }

    // ============ FUNCTION TO UPDATE STAGE SCHEDULED TIME ============
    function updateScheduledTime(uint256[] calldata _stageTimes)
        external
        onlyOwner
    {
        uint256 lengthStages = _stageTimes.length;
        if (lengthStages > 2) {
            revert InputInvalidData();
        }
        for (uint256 i; i < lengthStages; i++) {
            stageTime[i] = _stageTimes[i];
        }
    }

    // ============ FUNCTION TO SET BASEURI BEFORE REVEAL ============
    function setBaseURIBeforeReveal(string calldata _baseuri) external onlyOwner {
        arrBaseURIs[maxPublicMint] = _baseuri;
    }

    // ============ FUNCTION TO UPDATE REVEAL STATUS ============
    function updateReveal(bool _reveal) external onlyOwner {
        revealStatus = _reveal;
    }

    // ============ FUNCTION TO TRIGGER TO CAP THE SUPPLY ============
    function capTrigger(bool _putCap) external onlyOwner {
        putCap = _putCap;
    }

    //============ FUNCTION TO UPDATE VALID KEY ============
    function updateValidation(string calldata _valid) external onlyOwner {
        if (updateValidTime != 0) {
            revert CallNotAllowed(updateValidTime);
        }
        validKey = _valid;
        updateValidTime = 1;
    }

    //============ FUNCTION TO TRANSFER OWNERSHIP ============
    function transferOwnership(address _newOwner) external onlyOwner {
        if (transferOwnerTime != 0) {
            revert CallNotAllowed(transferOwnerTime);
        }
        owner = _newOwner;
        transferOwnerTime = 1;
    }
}