// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "erc721a/contracts/ERC721A.sol";

import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./SignedMinting.sol";

contract WhoWhosTreeHouse is
    ERC721A,
    Ownable,
    VRFConsumerBaseV2,
    PaymentSplitter,
    SignedMinting
{
    using Address for address;

    // Sale Info
    uint256 public constant MAX_SUPPLY = 7777;
    uint256 public constant TEAM_RESERVED = 45;

    uint256 public salePrice = 0.08 ether; //
    uint256 public presalePrice = 0.07 ether; //
    uint256 public txLimit = 3; //

    // Chainlink
    VRFCoordinatorV2Interface VRFCoordinator; //
    bytes32 public gasLaneKeyHash; //
    uint64 public linkSubscriptionId; //
    uint32 public callbackGasLimit; //
    uint16 public requestConfirmations; //
    uint256 public randomRequestId;

    // Metadata
    string public baseURI;
    string public provenanceHash;
    uint256 public tokenOffset;
    bool public metadataFrozen;

    // State
    address public developer;
    address public premintAddress;
    bool public preminted;
    enum SaleState {
        CLOSED,
        PRESALE,
        PUBLIC
    }
    SaleState public saleState;

    constructor(
        address _owner,
        address _premintAddress,
        address _mintSigner,
        address[] memory payees,
        uint256[] memory shares_
    )
        ERC721A("WhoWhos TreeHouse", "WHOWHO")
        PaymentSplitter(payees, shares_)
        Ownable()
        VRFConsumerBaseV2(0x271682DEB8C4E0901D1a1550aD2e64D568E69909)
        SignedMinting(_mintSigner)
    {
        require(_owner != address(0));
        require(_premintAddress != address(0));
        require(_mintSigner != address(0));
        developer = _msgSender();
        _transferOwnership(_owner);

        premintAddress = _premintAddress;

        VRFCoordinator = VRFCoordinatorV2Interface(
            0x271682DEB8C4E0901D1a1550aD2e64D568E69909
        );
        linkSubscriptionId = 37;
        gasLaneKeyHash = 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef;

        callbackGasLimit = 400000;
        requestConfirmations = 3;
    }

    function mint(
        address _to,
        uint256 amount,
        bytes memory _signature
    ) public payable isNotContract {
        require(
            saleState == SaleState.PUBLIC ||
                (saleState == SaleState.PRESALE &&
                    validateSignature(_signature, _to))
        );
        uint256 price = saleState == SaleState.PUBLIC
            ? salePrice
            : presalePrice;
        require(msg.value == price * amount, "Invalid Payment");
        require(amount <= txLimit, "Tx Limit");
        _mintWhowhos(_to, amount);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // Admin
    function setMintSigner(address _signer) public onlyAuthorized {
        _setMintingSigner(_signer);
    }

    function setProvenanceHash(string calldata _hash) public onlyAuthorized {
        require(!metadataFrozen, "Metadata is frozen");
        require(bytes(provenanceHash).length == 0, "Hash already set");
        provenanceHash = _hash;
    }

    function setBaseURI(string calldata __baseURI) public onlyAuthorized {
        require(!metadataFrozen, "Metadata Frozen");
        baseURI = __baseURI;
    }

    function emergencySetTokenOffset(uint256 _tokenOffset)
        public
        onlyAuthorized
    {
        require(!metadataFrozen, "Metadata Frozen");
        require(tokenOffset == 0, "Token offset already set");
        tokenOffset = _tokenOffset;
    }

    function freezeMetadata() public onlyAuthorized {
        require(!metadataFrozen, "Metadata Frozen");
        metadataFrozen = true;
    }

    function generateTokenOffset() public onlyAuthorized {
        require(tokenOffset == 0, "Token offset already set");

        randomRequestId = VRFCoordinator.requestRandomWords(
            gasLaneKeyHash,
            linkSubscriptionId,
            requestConfirmations,
            callbackGasLimit,
            2
        );
    }

    function premint() public onlyAuthorized {
        require(!preminted);
        _mintWhowhos(premintAddress, TEAM_RESERVED);
        preminted = true;
    }

    function adminMint(address _to, uint256 _amount) public onlyAuthorized {
        _mintWhowhos(_to, _amount);
    }

    function setSaleState(SaleState _saleState) public onlyAuthorized {
        require(preminted);
        saleState = _saleState;
    }

    function setSalePrice(uint256 _salePrice) public onlyAuthorized {
        salePrice = _salePrice;
    }

    function setPresalePrice(uint256 _presalePrice) public onlyAuthorized {
        presalePrice = _presalePrice;
    }

    function setTxLimit(uint256 _TxLimit) public onlyAuthorized {
        txLimit = _TxLimit;
    }

    function setPremintAddress(address _premintAddress) public onlyAuthorized {
        require(!preminted);
        premintAddress = _premintAddress;
    }

    function setDeveloper(address _developer) public onlyAuthorized {
        developer = _developer;
    }

    function setGasLaneKeyHash(bytes32 _gasLaneKeyHash) public onlyAuthorized {
        gasLaneKeyHash = _gasLaneKeyHash;
    }

    function setLinkSubscriptionId(uint64 _linkSubscriptionId)
        public
        onlyAuthorized
    {
        linkSubscriptionId = _linkSubscriptionId;
    }

    function setCallbackGasLimit(uint32 _callbackGasLimit)
        public
        onlyAuthorized
    {
        callbackGasLimit = _callbackGasLimit;
    }

    function setRequestConfirmations(uint16 _requestConfirmations)
        public
        onlyAuthorized
    {
        requestConfirmations = _requestConfirmations;
    }

    // Modifiers

    modifier onlyAuthorized() {
        checkAuthorized();
        _;
    }

    function checkAuthorized() private view {
        require(
            _msgSender() == owner() || _msgSender() == developer,
            "Unauthorized"
        );
    }

    modifier isNotContract() {
        require(tx.origin == msg.sender, "Contracts cannot mint");
        _;
    }

    // Private/Internal
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function fulfillRandomWords(uint256, uint256[] memory randomWords)
        internal
        override
    {
        tokenOffset = randomWords[0];
        if (tokenOffset == 0) {
            // unlikely
            tokenOffset = randomWords[1];
        }
    }

    function _mintWhowhos(address _to, uint256 amount) private {
        require(_to != address(0), "Cannot mint to 0x0");
        require(amount > 0, "Amount cannot be 0");
        require(amount + totalSupply() <= MAX_SUPPLY, "Sold out");
        _safeMint(_to, amount);
    }
}