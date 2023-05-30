// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "./BlackholePrevention.sol";

contract Fuzzles is
    ERC721,
    ERC721Enumerable,
    ERC721Burnable,
    Ownable,
    ERC1155Holder,
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

    string public constant PROVENANCE = "QmP2mGzZoKDS96gWj8sb72a4VtjboRHL59SBCZLzHo5Ptm";
    uint256 public offset = 0;
    uint256 public maxSupply = 9997;
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
    string public baseURI ="ipfs://QmP2mGzZoKDS96gWj8sb72a4VtjboRHL59SBCZLzHo5Ptm/";

    constructor(
        uint64 _saleStartTimestamp,
        address _erc1155Contract,
        uint256 _erc1155Token,
        address _vrfCoordinator,
        bytes32 _vrfKeyhash,
        uint64 _vrfSubscriptionId
    ) ERC721("Fuzzles", "FUZZ") VRFConsumerBaseV2(_vrfCoordinator) {
        saleStartTimestamp = _saleStartTimestamp;
        erc1155Contract = _erc1155Contract;
        erc1155Token = _erc1155Token;
        vrfKeyHash = _vrfKeyhash;
        vrfSubscriptionId = _vrfSubscriptionId;
        vrfCoordinator = _vrfCoordinator;
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
    }

    function onERC1155Received(
        address,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata
    ) public override returns (bytes4) {
        require(block.timestamp >= saleStartTimestamp, "Fuzzles: not started");
        require(msg.sender == erc1155Contract, "Fuzzles: incorrect contract");
        require(id == erc1155Token, "Fuzzles: incorrect token");
        require(value > 0, "Fuzzles: amount is zero");
        require(
            value <= MAX_PURCHASE,
            "Fuzzles: amount exceeds the max of exchange"
        );
        require(from != address(0), "Fuzzles: from is address(0)");
        require(!paused(), "Fuzzles: paused");
        require(
            value + pending + totalSupply() <= maxSupply,
            "Fuzzles: Cannot buy that many"
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
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) public pure override returns (bytes4) {
        revert("Fuzzles: Not allowed");
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        MintRequest memory request = mintRequests[requestId];
        require(request.beneficiary != address(0), "Fuzzles: Invalid request");
        uint256 remaining = maxSupply - totalSupply();
        require(remaining >= request.amount, "Fuzzles: Not enough NFTs");

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

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(),".json"))
                : "";
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function updateVrfKeyHash(bytes32 _vrfKeyHash) external onlyOwner {
        vrfKeyHash = _vrfKeyHash;
    }

    function updateVrfSubscriptionId(uint64 _vrfSubscriptionId)
        external
        onlyOwner
    {
        vrfSubscriptionId = _vrfSubscriptionId;
    }

    function updateVrfConfirmationCount(uint16 _vrfConfirmationCount)
        public
        onlyOwner
    {
        vrfConfirmationCount = _vrfConfirmationCount;
    }

    function updateVrfMaxGasLimit(uint32 _vrfMaxGasLimit) public onlyOwner {
        vrfMaxGasLimit = _vrfMaxGasLimit;
    }

    function getVrfSubscriptionId() public view onlyOwner returns (uint64) {
        return vrfSubscriptionId;
    }

    function getPendingRequests(address addr) public view returns (uint32) {
        return pendingRequests[addr];
    }

    function withdrawEther(address payable receiver, uint256 amount)
        external
        virtual
        onlyOwner
    {
        _withdrawEther(receiver, amount);
    }

    function withdrawERC20(
        address payable receiver,
        address tokenAddress,
        uint256 amount
    ) external virtual onlyOwner {
        _withdrawERC20(receiver, tokenAddress, amount);
    }

    function withdrawERC721(
        address payable receiver,
        address tokenAddress,
        uint256 _tokenId
    ) external virtual onlyOwner {
        _withdrawERC721(receiver, tokenAddress, _tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC1155Receiver, ERC721Enumerable)
        returns (bool)
    {
        return
            interfaceId == type(IERC1155Receiver).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function setSaleStartDateTime(uint64 _saleStartTimestamp) public onlyOwner {
        saleStartTimestamp = _saleStartTimestamp;
    }

    function setMaxPurchase(uint256 _MAX_PURCHASE) public onlyOwner {
        MAX_PURCHASE = _MAX_PURCHASE;
    }
}