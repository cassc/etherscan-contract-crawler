// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10 <0.9.0;

/*

                                            .^!7777777?J?!:.
                          ~~:            ^?5GB######&&#P7:.
                        !YP5J~          ^YB&@@@@@@@@@B5?~.
                      [email protected]@P!.        !5#@@@@@@@@@@#P~
                  .!JG&@@#Y:       ^[email protected]@@@@@@@@@@#Y:
                  :JG&@@@@&5~.    :~Y&@@@@@@@@@@@@#J          ..::..
                  !#@@@@@@&#P7.  :?G&@@@@@@@@@@@@@&GJ~:~?YPGGBBBBBBBBGG5J~:.
                  7&@@@@@@@@&GY?JP#@@@@@@@@@@@@@@@@@&&##&&@@@@@@@@@@@@@@&#P!
                :J#@@@@@@@@@@&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#P7^.
                :J#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&B?
                  7&@@@@@@@@@@@@@@@&&&&&&&&&&&&&&&&&&&&@@@@@@@@@@@@@&#B5J?77?YYJ7^.
                  !#@@@@@@@@@@@@@@&57^~~~~~~~~~~~~~~^75&@@@@@@@@@@&B57^..    ..::.
      ~77^.       ~P#&@@@@@@@@@@&B5~                  ~5B&@@@@@@@@&P7:
      JB&GY~       ^5#@@@@@@@@@@BJ:                    :[email protected]@@@@@@@@&B57~:
      7P#@&P!^.    ^5#@@@@@@@@&P7:                      :7P&@@@@@@@@@@&B5?~.
      !5B&@@@B5JJJ5G#@@@@@@@@&G!.                        .!G&@@@@@@@@@@@@@#P?~.
      7P#&@@@@@@@@@@@@@@@@@@#Y:.                          .:Y#@@@@@@@@@@@@@@@GJ^
      75B&@@@@@@@@@@@@@@@@&GY~                              ~YG&@@@@@@@@@@@@@@&GJ^
      .!Y&@@@@@@@@@@@@@@@@#?.                                .?#@@@@@@@@@@@@@@@@&Y!:
        ^JG&@@@@@@@@@@@@@@&GY~                              ~JG&@@@@@@@@@@@@@@@@&B57
          ^[email protected]@@@@@@@@@@@@@@#Y.                            .J#@@@@@@@@@@@@@@@@@@&#P7
          .~?P#@@@@@@@@@@@@@#G!.                        .!P#@@@@@@@@&[email protected]@@&B5!
              .~?5B&@@@@@@@@@@&P7:                      :7P&@@@@@@@@&5^    .^!P&@#P7
                :~75B&@@@@@@@@@BJ:                    [email protected]@@@@@@@@@#5^       ~YG&BJ
                    :7P&@@@@@@@@&B5~                  ^YB&@@@@@@@@@@@#G~       .^77^
        .::..    ..:!YB&@@@@@@@@@@&5!^^~~~~~~~~~~~~^^!Y&@@@@@@@@@@@@@@#!
      .^7JYY?77?J5G#&@@@@@@@@@@@@@&&&&&&&&&&&&&&&&&&&&@@@@@@@@@@@@@@@&?.
        . JB&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#J:
          .^7P#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&@@@@@@@@@@#J:
              !P#&@@@@@@@@@@@@@@@&##&&@@@@@@@@@@@@@@@@@#PYJYG&@@@@@@@@&?
              .:~JPGBBBBBBBBBBGP5?!^~JG&@@@@@@@@@@@@@&B?:...!5B&@@@@@@#!
                    .:::::.          [email protected]@@@@@@@@@@@&5!:     ~5&@@@@&BJ^
                                    .Y#@@@@@@@@@@@B5^       :Y#@@&BY!.
                                    ^P#@@@@@@@@@@#5!        .!5&@BJ:
                                .^[email protected]@@@@@@@@&BY~.         ~J5PY!
                              ..!PB&&######BG5?^            :~~.
                              .:~?J?7777777!~.
    */

import {ERC2981} from "openzeppelin/token/common/ERC2981.sol";
import {ERC721A} from "erc721a/contracts/ERC721A.sol";
import {IDelegationRegistry} from "./IDelegationRegistry.sol";
import {Lists} from "./Lists.sol";
import {OperatorFilterer} from "closedsea/OperatorFilterer.sol";
import {Ownable} from "openzeppelin/access/Ownable.sol";
import {ReentrancyGuard} from "openzeppelin/security/ReentrancyGuard.sol";

contract IronPawGang is ERC721A, ERC2981, Ownable, OperatorFilterer, ReentrancyGuard {
    using Lists for Lists.Store;

    event DriverSwap(uint256 indexed tokenA, uint256 indexed tokenB);

    // Mint
    error ContractMintDisallowedError();
    error IncorrectAmountError();
    error InvalidProofError();
    error ListDisabledError();
    error MaxAmountExceededError();
    error MaxSupplyExceededError();
    error SaleStateClosedError();
    error UnknownListError();
    error MaxPerTransactionExceededError();
    error MissingDelegationError();

    // Drivers
    error InvalidSwapError();
    error OutOfBoundsError();
    error SenderDoesntOwnTokenError();
    error RecentSwapTransferProhibitedError();
    error DriverSwappingDisabledError();

    string public PROVENANCE_HASH;
    uint256 constant MAX_SUPPLY = 4000;
    uint256 constant price = 0.15 ether;
    uint256 public maxMintPerTransaction = 1;

    bool public driverSwapEnabled;
    uint256 public postSwapTransferLockDuration = 86400;
    mapping(uint256 => uint256) private _swappedDriverIDs;
    mapping(uint256 => uint256) private _lastSwapTimes;

    string public baseURI;

    IDelegationRegistry public delegationRegistry;

    enum SaleState {
        Closed,
        Private,
        Public
    }

    SaleState public saleState = SaleState.Closed;

    Lists.Store private _lists;

    bool public operatorFilteringEnabled;

    constructor(string memory initialBaseURI, address payable royaltiesReceiver, address delegationRegistryAddress)
        ERC721A("Iron Paw Gang", "IPG")
    {
        baseURI = initialBaseURI;
        setRoyaltyInfo(royaltiesReceiver, 500);
        delegationRegistry = IDelegationRegistry(delegationRegistryAddress);

        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
    }

    function withdraw(address payable destination) external onlyOwner {
        destination.transfer(address(this).balance);
    }

    // Metadata

    function setProvenanceHash(string calldata hash) external onlyOwner {
        PROVENANCE_HASH = hash;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    // Modifiers

    modifier verifySaleState(SaleState requiredState) {
        if (saleState != requiredState) revert SaleStateClosedError();
        _;
    }

    modifier verifyAmount(uint256 amount, uint256 price_) {
        if (msg.value != price_ * amount) revert IncorrectAmountError();
        _;
    }

    modifier verifyMaxPerTransaction(uint256 amount) {
        if (amount > maxMintPerTransaction) revert MaxPerTransactionExceededError();
        _;
    }

    modifier verifyAvailableSupply(uint256 amount) {
        if (totalSupply() + amount > MAX_SUPPLY) revert MaxSupplyExceededError();
        _;
    }

    modifier verifyListExists(string calldata list) {
        if (_lists.roots[list] == "") revert UnknownListError();
        if (!_lists.active[list]) revert ListDisabledError();
        _;
    }

    // Driver swaps

    function setDriverSwapEnabled(bool enabled) external onlyOwner {
        driverSwapEnabled = enabled;
    }

    function setPostSwapTransferLockDuration(uint256 secs) external onlyOwner {
        postSwapTransferLockDuration = secs;
    }

    function driverId(uint256 tokenId) public view returns (uint256) {
        if (tokenId < 1 || tokenId > MAX_SUPPLY) revert OutOfBoundsError();

        uint256 swappedId = _swappedDriverIDs[tokenId];
        if (swappedId != 0) return swappedId;
        return tokenId;
    }

    function lastSwapTime(uint256 tokenId) public view returns (uint256) {
        return _lastSwapTimes[tokenId];
    }

    function swapDrivers(uint256 a, uint256 b) external nonReentrant {
        if (!driverSwapEnabled) revert DriverSwappingDisabledError();
        if (a == b) revert InvalidSwapError();
        if (ownerOf(a) != _msgSender() && ownerOf(b) != _msgSender()) revert SenderDoesntOwnTokenError();

        uint256 aDriver = driverId(a);
        uint256 bDriver = driverId(b);

        _swappedDriverIDs[a] = bDriver;
        _swappedDriverIDs[b] = aDriver;

        _lastSwapTimes[a] = block.timestamp;
        _lastSwapTimes[b] = block.timestamp;

        emit DriverSwap(a, b);
    }

    function _beforeTokenTransfers(address, address, uint256 startTokenId, uint256 quantity) internal view override {
        uint256 tokenId = startTokenId;

        for (uint256 end = tokenId + quantity; tokenId < end; ++tokenId) {
            if (lastSwapTime(tokenId) == 0) continue;
            if (block.timestamp - lastSwapTime(tokenId) < postSwapTransferLockDuration) {
                revert RecentSwapTransferProhibitedError();
            }
        }
    }

    // Minting

    function setSaleState(SaleState state) external onlyOwner {
        saleState = state;
    }

    function setListRoot(string calldata list, bytes32 root, bool active) public onlyOwner {
        _lists.roots[list] = root;
        _lists.active[list] = active;
    }

    function setListRoot(string calldata list, bytes32 root) external onlyOwner {
        setListRoot(list, root, true);
    }

    function setListActive(string calldata list, bool active) external onlyOwner {
        _lists.active[list] = active;
    }

    function setMaxPerTransaction(uint256 max) external onlyOwner {
        maxMintPerTransaction = max;
    }

    function listMintCount(string calldata list, address account) public view returns (uint256) {
        return _lists.usageCount(list, account);
    }

    function mintListed(
        string calldata list,
        uint256 amount,
        bytes32[] calldata merkleProof,
        uint256 maxAmount,
        address onBehalfOf
    )
        public
        payable
        verifySaleState(SaleState.Private)
        verifyAvailableSupply(amount)
        verifyListExists(list)
        verifyAmount(amount, price)
        nonReentrant
    {
        if (!_lists.verify(list, merkleProof, onBehalfOf, maxAmount)) revert InvalidProofError();

        if (_msgSender() != onBehalfOf) {
            if (!delegationRegistry.checkDelegateForContract(_msgSender(), onBehalfOf, address(this))) {
                revert MissingDelegationError();
            }
        }

        _checkMaxAmountAndRecordUsage(list, onBehalfOf, amount, maxAmount);
        _mint(_msgSender(), amount);
    }

    function mintListed(string calldata list, uint256 amount, bytes32[] calldata merkleProof, uint256 maxAmount)
        public
        payable
    {
        mintListed(list, amount, merkleProof, maxAmount, _msgSender());
    }

    function mintMonke(string calldata list, uint256 amount, bytes32[] calldata merkleProof, uint256 maxAmount)
        public
        payable
        verifySaleState(SaleState.Private)
        verifyAvailableSupply(amount)
        verifyListExists(list)
        verifyAmount(amount, 0)
        nonReentrant
    {
        if (!_lists.verify(list, merkleProof, _msgSender(), maxAmount)) revert InvalidProofError();

        _checkMaxAmountAndRecordUsage(list, _msgSender(), amount, maxAmount);
        _mint(_msgSender(), amount);
    }

    function _checkMaxAmountAndRecordUsage(string calldata list, address account, uint256 amount, uint256 maxAmount)
        private
    {
        uint256 alreadyUsed = _lists.usageCount(list, account);
        if (amount > maxAmount - alreadyUsed) revert MaxAmountExceededError();
        _lists.incrementUsageCount(list, account, amount);
    }

    function mintPublic(uint256 amount)
        external
        payable
        verifySaleState(SaleState.Public)
        verifyAmount(amount, price)
        verifyAvailableSupply(amount)
        verifyMaxPerTransaction(amount)
        nonReentrant
    {
        if (_msgSender() != tx.origin) revert ContractMintDisallowedError();
        _mint(_msgSender(), amount);
    }

    function ownerMint(address to, uint256 amount) external onlyOwner verifyAvailableSupply(amount) {
        _mint(to, amount);
    }

    // ERC721A

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // OperatorFilterer

    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override(ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override(ERC721A)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override(ERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override(ERC721A)
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
        // OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }

    // IERC2981

    function setRoyaltyInfo(address payable receiver, uint96 numerator) public onlyOwner {
        _setDefaultRoyalty(receiver, numerator);
    }

    // ERC165

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }
}