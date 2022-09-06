// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract ERC1155Claim is Ownable, ERC1155, ReentrancyGuard {
    using Strings for uint256;
    using ECDSA for bytes32;

    uint256 public initWhiteTokenId;
    uint256 public initGeneralTokenId;
    uint256 public currentWhiteTokenId;
    uint256 public currentGeneralTokenId;
    uint256 public currentPeriodAmount;
    uint256 public totalSupply;

    uint256 public maxClaimAmount;
    string public name;
    string public symbol;
    string public templateURI;
    address public claimSigner;

    //    mapping(uint256 => string) internal tokenURI;
    mapping(uint256 => uint256) public currentSupply;
    mapping(address => uint256) public whiteClaimedAmount;
    mapping(address => uint256) public userClaimedAmount;
    mapping(address => uint256) public userLastSignTime;

    uint256 public tokenPrice = 0.06 ether;
    address public feeRecipient;

    event Minted(address indexed to, uint256 indexed tokenId);
    event PeriodAmountChanged(uint256 indexed newAmount);
    // for migration
    event TemplateURIChanged(string indexed newURI);

    modifier onlyEOA() {
        require(
            msg.sender == tx.origin,
            "ERC1155Claim#onlyEOA: only the EOA address"
        );
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _templateURI,
        address _feeRecipient,
        address _signer
    ) ERC1155(_templateURI) {
        name = _name;
        symbol = _symbol;
        templateURI = _templateURI;
        feeRecipient = _feeRecipient;
        claimSigner = _signer;
        maxClaimAmount = 10;

        initWhiteTokenId = 11; // 11 - 106
        initGeneralTokenId = 106; // 106 - 300
        currentPeriodAmount = 300; // 301 - 999
        totalSupply = 999;
        currentWhiteTokenId = initWhiteTokenId;
        currentGeneralTokenId = initGeneralTokenId;

        uint256 holderAmount = initWhiteTokenId - 1;
        uint256[] memory holderTokenIds = new uint256[](holderAmount);
        uint256[] memory tokenAmounts = new uint256[](holderAmount);
        for (uint256 i = 0; i < holderAmount; i++) {
            holderTokenIds[i] = i + 1;
            tokenAmounts[i] = 1;
            currentSupply[i + 1] = 1;
        }

        _mintBatch(feeRecipient, holderTokenIds, tokenAmounts, new bytes(0));
    }

    function setSigner(address _signer) public onlyOwner {
        require(_signer != address(0), "signer address is invalid");
        claimSigner = _signer;
    }

    function setFeeRecipient(address _feeRecipient) public onlyOwner {
        require(
            _feeRecipient != address(0),
            "feeRecipient cannot be the zero address"
        );
        feeRecipient = _feeRecipient;
    }

    function setMaxClaimAmount(uint256 _maxClaimAmount) public onlyOwner {
        maxClaimAmount = _maxClaimAmount;
    }

    function setTemplateURI(string memory _templateURI) public onlyOwner {
        templateURI = _templateURI;
        emit TemplateURIChanged(templateURI);
    }

    function setCurrentPeriodAmount(uint256 _currentPeriodAmount)
        public
        onlyOwner
    {
        require(_currentPeriodAmount > currentPeriodAmount, "invalid amount ");
        require(
            _currentPeriodAmount <= totalSupply,
            "total must be greater than currentPeriodAmount"
        );
        currentPeriodAmount = _currentPeriodAmount;
        emit PeriodAmountChanged(currentPeriodAmount);
    }

    function uri(uint256 _id)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(currentSupply[_id] == 1, "ERC1155Token#uri: nonexistent token");
        return string(abi.encodePacked(templateURI, _id.toString()));
    }

    function mint(
        uint256 _whiteAmount,
        uint256 _signTime,
        bool _isWhiteUser,
        bytes memory _signature
    ) external payable onlyEOA nonReentrant returns (uint256 userTokenId) {
        uint256 payAmount = tokenPrice;
        require(
            userClaimedAmount[msg.sender] < maxClaimAmount,
            "ERC1155Token#mint: max claim amount reached"
        );
        verifySignature(
            msg.sender,
            _whiteAmount,
            _signTime,
            _isWhiteUser,
            _signature
        );
        require(
            userLastSignTime[msg.sender] < _signTime,
            "ERC1155Token#mint:signature expired"
        );
        userLastSignTime[msg.sender] = _signTime;
        if ((_isWhiteUser) && (whiteClaimedAmount[msg.sender] < _whiteAmount)) {
            userTokenId = getWhiteTokenId();
            whiteClaimedAmount[msg.sender] += 1;
            userClaimedAmount[msg.sender] += 1;
        } else {
            require(
                msg.value >= payAmount,
                "ERC1155Token#mint: insufficient funds"
            );
            _safeTransferETH(feeRecipient, payAmount);
            userTokenId = getGeneralTokenId();
            userClaimedAmount[msg.sender] += 1;
        }
        require(userTokenId > 0, "ERC1155Token#mint: invalid tokenId");
        currentSupply[userTokenId] = 1;
        _mint(msg.sender, userTokenId, 1, new bytes(0));
        if (msg.value > payAmount) {
            _safeTransferETH(msg.sender, msg.value - payAmount);
        }
        emit Minted(msg.sender, userTokenId);
        return userTokenId;
    }

    function verifySignature(
        address _user,
        uint256 _whiteAmount,
        uint256 _signTime,
        bool _isWhiteUser,
        bytes memory _signature
    ) internal view {
        bytes32 msgHash = keccak256(
            abi.encodePacked(
                _user,
                address(this),
                block.chainid,
                _whiteAmount,
                _signTime,
                _isWhiteUser
            )
        );

        require(
            msgHash.toEthSignedMessageHash().recover(_signature) == claimSigner,
            "ERC1155Token#verifySignature: invalid signature"
        );
    }

    function getGeneralTokenId() internal returns (uint256 generalTokenId) {
        require(
            currentGeneralTokenId <= currentPeriodAmount,
            "ERC1155Token#getGeneralTokenId: no more tokens during this period"
        );
        generalTokenId = currentGeneralTokenId;
        currentGeneralTokenId += 1;
        return generalTokenId;
    }

    function getWhiteTokenId() internal returns (uint256 whiteTokenId) {
        if (currentWhiteTokenId < initGeneralTokenId) {
            whiteTokenId = currentWhiteTokenId;
            currentWhiteTokenId += 1;
            return whiteTokenId;
        } else {
            return getGeneralTokenId();
        }
    }

    function _safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{gas: 2300, value: value}("");
        require(success, "transfer eth failed");
    }
}