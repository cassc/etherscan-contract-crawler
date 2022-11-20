// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./ERC721M.sol";
import "./DefaultOperatorFilterer.sol";

contract NFT is ERC721M, ReentrancyGuard, Ownable, DefaultOperatorFilterer {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
    using SafeMath for uint256;

    event CrossChain(
        address indexed from,
        bytes32 indexed h,
        bytes32 indexed f,
        uint256 tokenId
    );
    event Redeem(address indexed receiver, uint256 indexed tokenId);
    event Stake(
        address indexed account,
        uint256 indexed tokenId,
        uint256 indexed timestamp
    );
    event UnStake(
        address indexed account,
        uint256 indexed tokenId,
        uint256 indexed timestamp
    );
    event OperationResult(bool result);

    EnumerableSet.AddressSet private _customDisableMarket;
    EnumerableSet.AddressSet private _rota;
    EnumerableSet.UintSet private _ticket;

    // CROSS-CHAIN
    uint256 public crossChainPrice = 0.009 ether;
    bool public crossChainOpen = false;

    // TEAM
    uint256 _teamLimit = 1400;
    uint256 public teamMinted;

    // OG
    uint256 _ogLimit = 3;
    uint256 _ogPrice = 0.035 ether;
    bool public ogMintingOpen = false;
    mapping(address => uint256) public ogMinted;
    bytes32 public ogRoot;

    // WL
    uint256 _wlLimit = 2;
    uint256 _wlPrice = 0.04 ether;
    bool public wlMintingOpen = false;
    mapping(address => uint256) public wlMinted;
    bytes32 public wlRoot;

    // PUBLIC
    uint256 _publicPrice = 0.12 ether;
    bool public publicMintingOpen = false;

    // STAKE
    bool public stakingOpen = false;
    uint256 _stakeBase = 1 days;
    mapping(uint256 => uint256) private stakingStarted;
    mapping(uint256 => uint256) private stakingTotal;
    mapping(uint256 => uint256) private tokenStakingCycle;

    // SPECIAL
    bytes32 public bcnRoot;
    mapping(uint256 => uint256) public bcnMinted;

    // ETHEREUM
    string _baseTokenURI;
    uint256 _counter;
    uint256 _maxSupply = 7388;
    uint256 _maxIndex = 8888;

    constructor(string memory name, string memory symbol)
        ERC721M(name, symbol, _maxIndex)
    {
        addDisableMarket(0xF849de01B080aDC3A814FaBE1E2087475cF2E354);
        addDisableMarket(0x024aC22ACdB367a3ae52A3D94aC6649fdc1f0779);
    }

    // ACCESS
    modifier onlyMinter() {
        require(
            isMinter(_msgSender()),
            "Roles: Caller does not have the minter role"
        );
        _;
    }

    modifier onlyApprovedOrOwner(uint256 tokenId) {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721Common: Not approved nor owner"
        );
        _;
    }

    // METADATA
    function baseURI() public view returns (string memory) {
        return _baseURI();
    }

    function setBaseURI(string memory newBaseTokenURI) public onlyOwner {
        _baseTokenURI = newBaseTokenURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    // FOR MARKET
    function addDisableMarket(address value) public onlyOwner{
        bool result = _customDisableMarket.add(value);
        emit OperationResult(result);
    }

    function removeDisableMarket(address value) public onlyOwner {
        bool result = _customDisableMarket.remove(value);
        emit OperationResult(result);
    }

    // FOR CROSS-CHAIN
    function isMinter(address value) public view returns (bool) {
        return _rota.contains(value);
    }

    function addMinter(address value) public onlyOwner {
        bool result = _rota.add(value);
        emit OperationResult(result);
    }

    function removeMinter(address value) public onlyOwner {
        bool result = _rota.remove(value);
        emit OperationResult(result);
    }

    function minterNumber() public view returns (uint256) {
        return _rota.length();
    }

    function minterList() public view returns (address[] memory) {
        return _rota.values();
    }

    // FOR STAKING
    function isStakingCycle(uint256 value) public view returns (bool) {
        return _ticket.contains(value);
    }

    function addStakingCycle(uint256 value) public {
        bool result = _ticket.add(value);
        emit OperationResult(result);
    }

    function removeStakingCycle(uint256 value) public {
        bool result = _ticket.remove(value);
        emit OperationResult(result);
    }

    function stakingCycleList() public view returns (uint256[] memory) {
        return _ticket.values();
    }

    // UTILS
    function _reverse(bool state) internal pure returns (bool) {
        if (state) {
            return false;
        }
        return true;
    }

    function _verify(
        address addr,
        bytes32[] calldata proof,
        bytes32 root
    ) internal pure {
        bytes32 leaf = keccak256(abi.encodePacked(addr));
        require(MerkleProof.verify(proof, root, leaf), "Invalid address!");
    }

    // USUAL
    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function totalSupply() public view returns (uint256) {
        return _counter;
    }

    function _multiMintV2(
        address to,
        uint256 fromTokenId,
        uint256 quantity
    ) internal {
        _multiMint(to, fromTokenId, quantity);
        _counter = SafeMath.add(_counter, quantity);
    }

    // USUAL SPECIAL
    function _checkNotDisableMarket(address operator) internal view {
       if (_customDisableMarket.contains(operator)) {
            revert OperatorNotAllowed(msg.sender);
        }
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperator(operator)
    {
        _checkNotDisableMarket(operator);
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override
        onlyAllowedOperator(operator)
    {
        _checkNotDisableMarket(operator);
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        _checkNotDisableMarket(from);
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        _checkNotDisableMarket(from);        
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        _checkNotDisableMarket(from);
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        super._beforeTokenTransfer(from, to, tokenId);
        require(stakingStarted[tokenId] == 0, "Error: staking");
    }

    // SETTINGS
    function setRoot(
        bytes32 _og,
        bytes32 _wl,
        bytes32 _bcn
    ) public onlyOwner {
        ogRoot = _og;
        wlRoot = _wl;
        bcnRoot = _bcn;
    }

    function setOgMintingOpen() public onlyOwner {
        ogMintingOpen = _reverse(ogMintingOpen);
    }

    function setWlMintingOpen() public onlyOwner {
        wlMintingOpen = _reverse(wlMintingOpen);
    }

    function setPublicMintingOpen() public onlyOwner {
        publicMintingOpen = _reverse(publicMintingOpen);
    }

    function setStakingOpen() public onlyOwner {
        stakingOpen = _reverse(stakingOpen);
    }

    function setCrossChainOpen() public onlyOwner {
        crossChainOpen = _reverse(crossChainOpen);
    }

    function setCrossChainPrice(uint256 amount) public onlyOwner {
        crossChainPrice = amount;
    }

    // MINT
    function _ensureMint(
        bool state,
        uint256 quantity,
        uint256 price
    ) internal view {
        require(state, "Mint Closed!");
        require(_msgSender() == tx.origin, "Invalid address");
        require(quantity > 0, "Invalid mint quantity!");
        require(msg.value >= SafeMath.mul(price, quantity), "Insufficient funds!");
        require(SafeMath.add(_counter, quantity) <= _maxSupply, "Current chain mint limit");
    }

    function mintByBcn(
        bytes32[] calldata proof,
        address bcn,
        uint256 bcnTokenId,
        address receiver,
        uint256 quantity
    ) public payable nonReentrant {
        _ensureMint(wlMintingOpen, quantity, _wlPrice);

        uint256 minted = wlMinted[_msgSender()].add(quantity);
        require(minted <= _wlLimit, "Address receive number Limited");
        require(
            isBcnOwner(proof, bcn, bcnTokenId, receiver),
            "Not bcn family owner"
        );

        wlMinted[receiver] = minted;
        _multiMintV2(receiver, _counter, quantity);
    }

    function ogMint(bytes32[] calldata proof, uint256 quantity) public payable nonReentrant {
        _ensureMint(ogMintingOpen, quantity, _ogPrice);

        uint256 minted = ogMinted[_msgSender()].add(quantity);
        require(minted <= _ogLimit, "Mint Limited!");
        _verify(_msgSender(), proof, ogRoot);

        ogMinted[_msgSender()] = minted;
        _multiMintV2(_msgSender(), _counter, quantity);
    }

    function wlMint(bytes32[] calldata proof, uint256 quantity) public payable nonReentrant {
        _ensureMint(wlMintingOpen, quantity, _wlPrice);
        uint256 minted = wlMinted[_msgSender()].add(quantity);
        require(minted <= _wlLimit, "Mint Limited!");

        _verify(_msgSender(), proof, wlRoot);
        wlMinted[_msgSender()] = minted;
        _multiMintV2(_msgSender(), _counter, quantity);
    }

    function publicMint(uint256 quantity) public payable nonReentrant {
        _ensureMint(publicMintingOpen, quantity, _publicPrice);
        _multiMintV2(_msgSender(), _counter, quantity);
    }

    function teamMint(address receiver, uint256 quantity) public onlyOwner {
        uint256 minted = teamMinted.add(quantity);
        require(minted <= _teamLimit, "Mint Limited!");
        teamMinted = minted;
        _multiMintV2(receiver, _counter, quantity);
    }

    // STAKE
    function toggleStaking(uint256 tokenId, uint256 cycle)
        internal
        onlyApprovedOrOwner(tokenId)
    {
        require(isStakingCycle(cycle), "Invalid staking cycle");
        uint256 start = stakingStarted[tokenId];
        uint256 currentTime = block.timestamp;

        if (start == 0) {
            require(stakingOpen, "Staking closed");

            tokenStakingCycle[tokenId] = cycle;
            stakingStarted[tokenId] = currentTime;

            emit Stake(_msgSender(), tokenId, cycle);
        } else {
            uint256 pasted = SafeMath.sub(block.timestamp, start);
            uint256 needed = SafeMath.mul(tokenStakingCycle[tokenId], _stakeBase);
            require(pasted > needed, "Not unstake time");

            stakingTotal[tokenId] = SafeMath.mul(stakingTotal[tokenId], needed);
            stakingStarted[tokenId] = 0;
            emit UnStake(_msgSender(), tokenId, needed);
        }
    }

    function toggleStaking(
        uint256[] calldata tokenIds,
        uint256[] calldata cycles
    ) external nonReentrant {
        require(stakingOpen, "Staking closed");

        uint256 n = tokenIds.length;
        for (uint256 i = 0; i < n; ++i) {
            toggleStaking(tokenIds[i], cycles[i]);
        }
    }

    function stakingPeriod(uint256 tokenId)
        external
        view
        returns (
            bool staking,
            uint256 pasted,
            uint256 needed,
            uint256 total
        )
    {
        uint256 start = stakingStarted[tokenId];
        if (start != 0) {
            staking = true;
            pasted = SafeMath.sub(block.timestamp, start);
            needed = SafeMath.mul(tokenStakingCycle[tokenId], _stakeBase);
        }
        total = stakingTotal[tokenId];
    }

    // OTHERS
    function isBcnOwner(
        bytes32[] calldata proof,
        address bcn,
        uint256 bcnTokenId,
        address receiver
    ) public view returns (bool) {
        _verify(bcn, proof, bcnRoot);

        address tokenOwner = IERC721(bcn).ownerOf(bcnTokenId);
        if (receiver == tokenOwner) {
            return true;
        }
        return false;
    }

    // CROSS-CHAIN
    function redeem(address receiver, uint256 tokenId) public onlyMinter {
        require(crossChainOpen, "Cross-chain Closed");
        require(tokenId < _maxIndex, "Token");

        _multiMintV2(receiver, tokenId, 1);
        emit Redeem(receiver, tokenId);
    }

    function transferToAnotherChain(
        uint256 tokenId,
        bytes32 h,
        bytes32 f
    ) public payable onlyApprovedOrOwner(tokenId) nonReentrant {
        require(crossChainOpen, "Cross-chain Closed");
        require(
            msg.value == crossChainPrice,
            "Just send correct number of ether"
        );

        _burn(tokenId);
        _counter--;
        emit CrossChain(_msgSender(), h, f, tokenId);
    }

    // MONEY
    function withdraw() public onlyOwner nonReentrant {
        (bool success, ) = payable(_msgSender()).call{
            value: address(this).balance
        }("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }
}