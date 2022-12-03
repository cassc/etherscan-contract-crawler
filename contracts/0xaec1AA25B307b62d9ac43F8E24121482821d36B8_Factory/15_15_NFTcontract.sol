// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IOperatorFilterRegistry} from "./IOperatorFilterRegistry.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFTcontract is ERC721Enumerable, ReentrancyGuard {
    IOperatorFilterRegistry constant operatorFilterRegistry =
        IOperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);
    mapping(uint256 => string) private arrBaseURIs;
    mapping(uint256 => uint256) private stageTime;
    mapping(uint256 => uint256) public PRE_MINT_PRICES;
    uint256 private premintLength;
    mapping(uint256 => uint256) public PUBLIC_MINT_PRICES;
    uint256 private publicmintLength;
    mapping(uint256 => uint256) private PRE_MINT_IDS;
    mapping(uint256 => uint256) private PUBLIC_MINT_IDS;

    uint256 public maxPublicMint;
    uint256 public publicMintId;
    uint256 public totalCntOfContent;
    uint256 private smallestCnt;

    uint256 private cntOfPreMints;
    uint256 private cntOfPublicMints;
    
    bool public putCap;

    address public collectAddress;
    address public owner;
    modifier onlyOwner() {
        require(owner == msg.sender, "Caller is not the owner.");
        _;
    }

    error OperatorNotAllowed(address operator);

    constructor(
        address _owner,
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _maxPublicMint,
        uint256 _publicMintPrice,
        address _collectAddress
    ) ERC721(_tokenName, _tokenSymbol) {
        maxPublicMint = _maxPublicMint;
        collectAddress = _collectAddress;
        owner = _owner;
        totalCntOfContent = 0;
        smallestCnt = _maxPublicMint;
        cntOfPreMints = 0;
        cntOfPublicMints = 0;
        publicMintId = 1;
        PUBLIC_MINT_PRICES[maxPublicMint] = _publicMintPrice;
        PRE_MINT_PRICES[maxPublicMint] = _publicMintPrice;
        premintLength = 0;
        publicmintLength = 0;
        putCap = false;
    }

    modifier onlyAllowedOperator(address from) virtual {
        if (address(operatorFilterRegistry).code.length > 0) {
            if (from == msg.sender) {
                _;
                return;
            }
            if (
                !(
                    operatorFilterRegistry.isOperatorAllowed(address(this), msg.sender)
                        && operatorFilterRegistry.isOperatorAllowed(address(this), from)
                )
            ) {
                revert OperatorNotAllowed(msg.sender);
            }
        }
        _;
    }

    modifier isCorrectPayment(uint256 stage, uint256 numberOfTokens) {
        uint256 payAmount = 0;
        uint256 index = maxPublicMint;
        uint256 tokenId = 0;
        uint256 i = 0;
        uint256 j = 0;
        if (stage == 0) {
            for (i = 0; i < numberOfTokens; i++) {
                tokenId = publicMintId + i;
                for (j = 0; j < premintLength; j++) {
                    if (tokenId <= PRE_MINT_IDS[j]) {
                        index = PRE_MINT_IDS[j];
                        break;
                    }
                }
                payAmount += PRE_MINT_PRICES[index];
            }
        } else if (stage == 1) {
            for (i = 0; i < numberOfTokens; i++) {
                tokenId = publicMintId + i;
                for (j = 0; j < publicmintLength; j++) {
                    if (tokenId <= PUBLIC_MINT_IDS[j]) {
                        index = PUBLIC_MINT_IDS[j];
                        break;
                    }
                }
                payAmount += PUBLIC_MINT_PRICES[index];
            }
        }
        require(
            payAmount == msg.value,
            "Incorrect ETH value sent. Please input corrent amount of ETH for these tokens."
        );
        require(
            payAmount > 0,
            "Incorrect ETH value sent. Payment amount should be greater than 0."
        );
        _;
    }

    function getETHAmountDynamic(uint256 stage, uint256 numberOfTokens) external view returns (uint256) {
        uint256 payAmount = 0;
        uint256 index = maxPublicMint;
        uint256 tokenId = 0;
        uint256 i = 0;
        uint256 j = 0;
        if (stage == 0) {
            for (i = 0; i < numberOfTokens; i++) {
                tokenId = publicMintId + i;
                for (j = 0; j < premintLength; j++) {
                    if (tokenId <= PRE_MINT_IDS[j]) {
                        index = PRE_MINT_IDS[j];
                        break;
                    }
                }
                payAmount += PRE_MINT_PRICES[index];
            }
        } else if (stage == 1) {
            for (i = 0; i < numberOfTokens; i++) {
                tokenId = publicMintId + i;
                for (j = 0; j < publicmintLength; j++) {
                    if (tokenId <= PUBLIC_MINT_IDS[j]) {
                        index = PUBLIC_MINT_IDS[j];
                        break;
                    }
                }
                payAmount += PUBLIC_MINT_PRICES[index];
            }
        }
        return payAmount;
    }

    modifier canMint(uint256 numberOfTokens) {
        require(
            publicMintId + numberOfTokens <= maxPublicMint,
            "Not enough tokens remaining to mint"
        );
        _;
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

    function registerContract() external onlyOwner {
        operatorFilterRegistry.register(address(this));
    }

    function updateOperatorsFilter(address[] calldata _operators, bool[] calldata _allowed) external onlyOwner {
        require(_operators.length == _allowed.length, "Please confirm that the length of arrays of operators and allowed same.");
        for (uint256 i = 0; i < _allowed.length; i++) {
            if (_allowed[i] == operatorFilterRegistry.isOperatorFiltered(address(this), _operators[i])) {
                operatorFilterRegistry.updateOperator(address(this), _operators[i], !_allowed[i]);
            }
        }
    }
    
    // ============ PUBLIC MINT FUNCTION FOR NORMAL USERS ============
    function publicMint(uint256 numberOfTokens, uint256 stage)
        public
        payable
        isCorrectPayment(stage, numberOfTokens)
        canMint(numberOfTokens)
        nonReentrant
    {
        require(
            stageTime[stage] <= block.timestamp,
            "Not available yet. Please wait for more..."
        );
        if (stage == 0) {
            require(
                stageTime[stage] <= block.timestamp &&
                    stageTime[stage + 1] > block.timestamp,
                "Pre-mint not available now. Please mint with public mint price..."
            );
        }

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _mint(msg.sender, publicMintId);
            publicMintId++;
        }
    }

    // ============ MINT FUNCTION FOR ONLY OWNER ============
    function privateMint(uint256 numberOfTokens)
        public
        payable
        canMint(numberOfTokens)
        nonReentrant
        onlyOwner
    {
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _mint(msg.sender, publicMintId);
            publicMintId++;
        }
    }

    // ============ FUNTION TO READ TOKENRUI ============
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: query for nonexistent token"
        );
        uint256 index;
        if (tokenId < smallestCnt) {
            index = smallestCnt;
        } else {
            for (index = tokenId; index <= maxPublicMint; index++) {
                if (keccak256(abi.encodePacked(arrBaseURIs[index])) != keccak256(abi.encodePacked(""))) {
                    break;
                }
            }
        }
        if (tokenId > 0) {
            return
                string(
                    abi.encodePacked(
                        arrBaseURIs[index],
                        Strings.toString(tokenId),
                        ".json"
                    )
                );
        }
        return "";
    }

    // ============ WITHDRAW FUNCTION TO THE SPECIFIED ADDRESS ============
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "The balance is 0 now.");
        (bool success, ) = payable(collectAddress).call{
            value: balance
        }("");
        require(
            success,
            "Transfer could not be processed. Please check your address and balance."
        );
    }

    // ============ FUNCTION TO UPDATE ETH COLLECTADDRESS ============
    function setCollectAddress(address _collectAddress) external onlyOwner {
        collectAddress = _collectAddress;
    }

    // ============ FUNCTION TO UPDATE BASEURIS ============
    function updateBaseURI(
        uint256[] calldata _arrNumOfTokens,
        string[] calldata _arrBaseURIs
    ) external onlyOwner {
        require(
            _arrNumOfTokens.length == _arrBaseURIs.length,
            "Please input the numOfTokens and baseURIs info as same length."
        );
        require(putCap == false, "Now the supply is capped. No more items are not added till activated again");
        uint256 i;
        uint256 tmp = 0;
        for (i = 0; i < _arrNumOfTokens.length; i++) {
            tmp += _arrNumOfTokens[i];
        }
        require(totalCntOfContent + tmp <= maxPublicMint, "The total count of contents is overflow.");        
        for (i = 0; i < _arrNumOfTokens.length; i++) {
            totalCntOfContent += _arrNumOfTokens[i];
            if (smallestCnt > totalCntOfContent) {
                smallestCnt = totalCntOfContent;
            }
            arrBaseURIs[totalCntOfContent] = _arrBaseURIs[i];
        }
    }

    // ============ FUNCTION TO UPDATE STAGE SCHEDULED TIME ============
    function updateScheduledTime(uint256[] calldata _stageTimes)
        external
        onlyOwner
    {
        require(
            _stageTimes[0] <= _stageTimes[1],
            "Please input the stageTimes in valid format"
        );
        for (uint256 i = 0; i < _stageTimes.length; i++) {
            stageTime[i] = _stageTimes[i];
        }
    }

    // ============ FUNCTION TO UPDATE STAGE INFO OF FIXED PRICE MODEL============
    function updateFixedModelStagesInfo(
        uint256 _premintPrice,
        uint256 _publicMintPrice
    ) external onlyOwner {
        PRE_MINT_PRICES[maxPublicMint] = _premintPrice;
        PUBLIC_MINT_PRICES[maxPublicMint] = _publicMintPrice;
    }

    // ============ FUNCTION TO UPDATE STAGE INFO OF DYNAMIC PRICE MODEL============
    function updateDynamicModelStagesInfo(
        uint256[] calldata _arrPremintTokens,
        uint256[] calldata _arrPremintPrices,
        uint256[] calldata _arrPublicmintTokens,
        uint256[] calldata _arrPublicMintPrices
    ) external onlyOwner {
        require(_arrPremintPrices.length == _arrPremintTokens.length, "Please input valid array of premintTokenIds and premintPrices of same length.");
        require(_arrPublicMintPrices.length == _arrPublicmintTokens.length, "Please input valid array of publicmintTokenIds and publicmintPrices of same length.");
        uint256 index;
        for (index = 0; index < _arrPremintPrices.length; index++) {
            cntOfPreMints += _arrPremintTokens[index];
            PRE_MINT_PRICES[cntOfPreMints] = _arrPremintPrices[index];
            PRE_MINT_IDS[premintLength] = cntOfPreMints;
            premintLength++;
        }
        PRE_MINT_IDS[premintLength] = maxPublicMint;
        premintLength++;
        for (index = 0; index < _arrPublicMintPrices.length; index++) {
            cntOfPublicMints += _arrPublicmintTokens[index];
            PUBLIC_MINT_PRICES[cntOfPublicMints] = _arrPublicMintPrices[index];
            PUBLIC_MINT_IDS[publicmintLength] = cntOfPublicMints;
            publicmintLength++;
        }
        PUBLIC_MINT_IDS[publicmintLength] = maxPublicMint;
        publicmintLength++;
    }

    // FUNCTION TO TRIGGER TO CAP THE SUPPLY
    function capTrigger(bool _putCap) external onlyOwner {
        if (putCap != _putCap) {
            putCap = _putCap;
        }        
    }
}