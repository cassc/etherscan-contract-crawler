// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "./BlackholePrevention.sol";

contract VOXSeries4 is
    ERC721,
    ERC721Enumerable,
    ERC721Burnable,
    AccessControl,
    ERC1155Receiver,
    Pausable,
    VRFConsumerBaseV2,
    BlackholePrevention
{
    //events
    event onMinted(address beneficiary, uint256 tokenId);
    event onAllMinted(
        address beneficiary,
        uint256[] tokenIds,
        uint256 totalCount
    );
    event onERC1155ReceivedExecuted(
        uint256 requestId,
        address from,
        uint256 value
    );

    using Address for address payable;
    using Strings for uint256;

    struct MintRequest {
        address beneficiary;
        uint256 amount;
    }

    string public constant PROVENANCE =
        "0ba89c0f46c57b1c75918ee6f22525c04cbd1854c460ccfd678bead77b907163";
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    uint256 public offset = 0;
    uint256 public maxSupply = 8888;
    uint256 public MAX_PURCHASE = 10;

    uint64 public saleStartTimestamp;
    address public erc1155Contract;
    uint256 public erc1155Token;

    //vrf settings
    bytes32 public vrfKeyHash;
    address public vrfCoordinator;
    uint16 public vrfConfirmationCount = 3;
    uint32 public vrfMaxGasLimit = 2500000;
    uint64 private vrfSubscriptionId;
    VRFCoordinatorV2Interface COORDINATOR;

    mapping(uint256 => MintRequest) public mintRequests;
    mapping(address => uint32) public pendingRequests;
    mapping(uint256 => uint256) public randomForwarder;
    uint256 public pending;

    constructor(
        uint64 _saleStartTimestamp,
        address _erc1155Contract,
        uint256 _erc1155Token,
        address _vrfCoordinator,
        bytes32 _vrfKeyhash,
        uint64 _vrfSubscriptionId
    )
        ERC721("VOX Series 4: DreamWorks Trolls", "VOX4")
        VRFConsumerBaseV2(_vrfCoordinator)
    {
        saleStartTimestamp = _saleStartTimestamp;
        erc1155Contract = _erc1155Contract;
        erc1155Token = _erc1155Token;
        vrfKeyHash = _vrfKeyhash;
        vrfSubscriptionId = _vrfSubscriptionId;
        vrfCoordinator = _vrfCoordinator;
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    function onERC1155Received(
        address,
        address from,
        uint256 id,
        uint256 value,
        bytes memory
    ) public virtual override returns (bytes4) {
        require(
            block.timestamp >= saleStartTimestamp,
            "VOX Series 4: not started"
        );
        require(
            msg.sender == erc1155Contract,
            "VOX Series 4: incorrect contract"
        );
        require(id == erc1155Token, "VOX Series 4: incorrect token");
        require(value > 0, "VOX Series 4: amount is zero");
        require(
            value <= MAX_PURCHASE,
            "VOX Series 4: amount exceeds the max of exchange"
        );
        require(from != address(0), "VOX Series 4: from is address(0)");
        require(!paused(), "VOX Series 4: paused");
        require(
            value + pending + totalSupply() <= maxSupply,
            "VOX Series 4: Cannot buy that many"
        );

        uint256 requestId = COORDINATOR.requestRandomWords(
            vrfKeyHash,
            vrfSubscriptionId,
            vrfConfirmationCount,
            vrfMaxGasLimit,
            uint32(value)
        );

        mintRequests[requestId] = MintRequest(from, value);
        pendingRequests[from] += uint32(value);
        pending += value;
        emit onERC1155ReceivedExecuted(requestId, from, value);

        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public pure override returns (bytes4) {
        revert("VOX Series 4: Not allowed");
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        MintRequest memory request = mintRequests[requestId];
        require(
            request.beneficiary != address(0),
            "VOX Series 4: Invalid request"
        );

        uint256 remaining = maxSupply - totalSupply();
        require(remaining >= request.amount, "VOX Series 4: Not enough NFTs");

        uint256[] memory newTokenIds = new uint256[](request.amount);

        for (uint256 i = 0; i < request.amount; i++) {
            uint256 newId = (randomWords[i] % remaining);
            uint256 newTokenId = randomForwarder[newId] > 0
                ? randomForwarder[newId]
                : newId;

            randomForwarder[newId] = randomForwarder[remaining - 1] > 0
                ? randomForwarder[remaining - 1]
                : remaining - 1;

            _safeMint(request.beneficiary, newTokenId);
            newTokenIds[i] = newTokenId;
            emit onMinted(request.beneficiary, newTokenId);
            remaining--;
        }

        delete mintRequests[requestId];
        pendingRequests[request.beneficiary] -= uint32(request.amount);
        pending -= request.amount;

        emit onAllMinted(request.beneficiary, newTokenIds, newTokenIds.length);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://collectvox.com/metadata/trolls/";
    }

    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    function updateVrfKeyHash(bytes32 _vrfKeyHash)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        vrfKeyHash = _vrfKeyHash;
    }

    function updateVrfSubscriptionId(uint64 _vrfSubscriptionId)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        vrfSubscriptionId = _vrfSubscriptionId;
    }

    function updateVrfConfirmationCount(uint16 _vrfConfirmationCount)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        vrfConfirmationCount = _vrfConfirmationCount;
    }

    function updateVrfMaxGasLimit(uint32 _vrfMaxGasLimit)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        vrfMaxGasLimit = _vrfMaxGasLimit;
    }

    function getVrfSubscriptionId()
        public
        view
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (uint64)
    {
        return vrfSubscriptionId;
    }

    function getPendingRequests(address addr) public view returns (uint32) {
        return pendingRequests[addr];
    }

    function withdrawEther(address payable receiver, uint256 amount)
        external
        virtual
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _withdrawEther(receiver, amount);
    }

    function withdrawERC20(
        address payable receiver,
        address tokenAddress,
        uint256 amount
    ) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _withdrawERC20(receiver, tokenAddress, amount);
    }

    function withdrawERC721(
        address payable receiver,
        address tokenAddress,
        uint256 _tokenId
    ) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _withdrawERC721(receiver, tokenAddress, _tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC1155Receiver, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return
            interfaceId == type(IERC1155Receiver).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IAccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function setSaleStartDateTime(uint64 _saleStartTimestamp)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        saleStartTimestamp = _saleStartTimestamp;
    }

    function setMaxPurchase(uint256 _MAX_PURCHASE) public onlyRole(ADMIN_ROLE) {
        MAX_PURCHASE = _MAX_PURCHASE;
    }
}