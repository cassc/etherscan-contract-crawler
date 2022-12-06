//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract FURY is ERC721, Ownable, ReentrancyGuard, DefaultOperatorFilterer {
    // using Strings for uint256;

    // merkle root
    bytes32 immutable _wl1Root;
    bytes32 immutable _wl2Root;

    // max mint per wallet
    uint256 public immutable _wl1MaxPerUser = 1;
    uint256 public immutable _wl2MaxPerUser = 1;
    uint256 public immutable _wlPMaxPerUser = 1;

    // max mint totally
    uint256 public immutable _wl1Max = 1250;
    uint256 public immutable _wl2Max = 700;

    uint256 public constant _reservedAmount = 50;

    // currently minted amount
    uint256 public _wl1Minted;
    uint256 public _wl2Minted;
    uint256 public _wlPMinted;

    // wl1 user => minted nft amount
    mapping(address => uint256) public _wl1MintedPerUser;
    // wl2 user => minted nft amount
    mapping(address => uint256) public _wl2MintedPerUser;
    // public mint user => mintd nft amount
    mapping(address => uint256) public _wlPMintedPerUser;

    // claim period
    Period public _period;

    // 16 weapons available amount
    //      Weapon               ID        Amount
    //      Axe                  1         157 -3
    //      Bamboo               2         207 -3
    //      Bare Fists           3         138 -3
    //      Baseball Bat         4         112 -3
    //      Bow                  5         44 -4
    //      Broom                6         155 -3
    //      Chain Whip           7         117 -3
    //      Flute                8         87 -3
    //      Knife                9         164 -3
    //      Kung Fu Fan          10        72 -3
    //      Shield               11        168 -3
    //      Sickle               12        53 -3
    //      Spear                13        121 -3
    //      Sword                14        254 -3
    //      Trident              15        42 -4
    //      Wolf-Toothed Cudgel  16        109 -3
    // weapon id => remaining amount
    mapping(uint256 => uint256) public _weaponAmount;
    // nft id => weapon id
    mapping(uint256 => uint256) public _weaponType;

    // // owner => ids
    // mapping(address => uint256[]) public _owner2ids;

    // track last minted nft id
    uint256 public _id;

    // bool public _isBlind;

    // base uri
    string public _buri;

    // public mint price
    uint256 public immutable _price;

    uint256 private _royaltyBps;
    address payable private _royaltyRecipient;

    event Withdraw(address indexed receiver, uint256 indexed amount);
    // event OpenBlind();
    event UpdateRoyalties(address payable recipient, uint256 bps);

    modifier _checkWl1(bytes32[] calldata proof) {
        require(checkWl1(msg.sender, proof), "verify wl1 failed");
        _;
    }

    modifier _checkWl2(bytes32[] calldata proof) {
        require(checkWl2(msg.sender, proof), "verify wl2 failed");
        _;
    }

    modifier _checkPeriod1() {
        require(checkPeriod1(), "invalid period 1");
        _;
    }

    modifier _checkPeriod2() {
        require(checkPeriod2(), "invalid period 2");
        _;
    }

    modifier _checkPeriodP() {
        require(checkPeriodP(), "invalid period public");
        _;
    }

    modifier _checkPerUser1(uint256 amount) {
        require(checkPerUser1(msg.sender, amount), "exceed per user 1");
        _;
    }

    modifier _checkPerUser2(uint256 amount) {
        require(checkPerUser2(msg.sender, amount), "exceed per user 2");
        _;
    }

    modifier _checkPerUserP(uint256 amount) {
        require(checkPerUserP(msg.sender, amount), "exceed per user p");
        _;
    }

    modifier _checkMax1(uint256 amount) {
        require(checkMax1(amount), "exceed max 1");
        _;
    }

    modifier _checkMax2(uint256 amount) {
        require(checkMax2(amount), "exceed max 2");
        _;
    }

    modifier _checkWeaponAmount(uint256 id, uint256 amount) {
        require(checkWeaponAmount(id, amount), "insufficient weapon");
        _;
    }

    modifier _checkAmountP(uint256 amount) {
        // check amount
        require(checkAmountP(amount), "insufficient token");
        _;
    }

    modifier _checkValueP(uint256 amount) {
        // check value
        uint256 totalValue = amount * _price;
        require(msg.value >= totalValue, "insuffcient value");
        _;
    }

    struct BaseInfo {
        string name;
        string symbol;
        string baseUri;
        uint256 price;
    }

    struct Root {
        bytes32 wl1Root;
        bytes32 wl2Root;
    }

    struct Period {
        uint256 start1;
        uint256 end1;
        uint256 start2;
        uint256 end2;
        uint256 startP;
        uint256 endP;
    }

    constructor(
        BaseInfo memory bi,
        Root memory r,
        Period memory p
    ) ERC721(bi.name, bi.symbol) {
        require(
            p.end1 > p.start1 && p.start1 >= block.timestamp,
            "invalid period 1 range"
        );
        require(
            p.end2 > p.start2 && p.start2 >= block.timestamp,
            "invalid period 2 range"
        );

        _id = _reservedAmount;

        _buri = bi.baseUri;
        _price = bi.price;

        _wl1Root = r.wl1Root;
        _wl2Root = r.wl2Root;

        _period = p;

        _weaponAmount[1] = 157 - 3; // 2-158
        _weaponAmount[2] = 207 - 3; // 159 - 365
        _weaponAmount[3] = 138 - 3; // 366 - 503
        _weaponAmount[4] = 112 - 3; // 504 - 615
        _weaponAmount[5] = 44 - 4; // 616 - 659
        _weaponAmount[6] = 155 - 3; // 660 - 814
        _weaponAmount[7] = 117 - 3; // 815 - 931
        _weaponAmount[8] = 87 - 3; // 932 - 1018
        _weaponAmount[9] = 164 - 3; // 1019 - 1182
        _weaponAmount[10] = 72 - 3; // 1183 - 1254
        _weaponAmount[11] = 168 - 3; // 1255 - 1422
        _weaponAmount[12] = 53 - 3; // 1423 - 1475
        _weaponAmount[13] = 121 - 3; // 1476 - 1596
        _weaponAmount[14] = 254 - 3; // 1597 - 1850
        _weaponAmount[15] = 42 - 4; // 1851 - 1892
        _weaponAmount[16] = 109 - 3; // 1893 - 2001
    }

    function checkWl1(address user, bytes32[] calldata proof)
        public
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(user));
        return MerkleProof.verify(proof, _wl1Root, leaf);
    }

    function checkWl2(address user, bytes32[] calldata proof)
        public
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(user));
        return MerkleProof.verify(proof, _wl2Root, leaf);
    }

    function checkPeriod1() public view returns (bool) {
        return
            block.timestamp >= _period.start1 &&
            block.timestamp <= _period.end1;
    }

    function checkPeriod2() public view returns (bool) {
        return
            block.timestamp >= _period.start2 &&
            block.timestamp <= _period.end2;
    }

    function checkPeriodP() public view returns (bool) {
        return
            block.timestamp >= _period.startP &&
            block.timestamp <= _period.endP;
    }

    function checkPerUser1(address user, uint256 amount)
        public
        view
        returns (bool)
    {
        return _wl1MintedPerUser[user] + amount <= _wl1MaxPerUser;
    }

    function checkPerUser2(address user, uint256 amount)
        public
        view
        returns (bool)
    {
        return _wl2MintedPerUser[user] + amount <= _wl2MaxPerUser;
    }

    function checkPerUserP(address user, uint256 amount)
        public
        view
        returns (bool)
    {
        return _wlPMintedPerUser[user] + amount <= _wlPMaxPerUser;
    }

    function checkMax1(uint256 amount) public view returns (bool) {
        return _wl1Minted + amount <= _wl1Max;
    }

    function checkMax2(uint256 amount) public view returns (bool) {
        uint256 remaining1 = _wl1Max - _wl1Minted;
        return _wl2Minted + amount <= _wl2Max + remaining1;
    }

    function checkWeaponAmount(uint256 id, uint256 amount)
        public
        view
        returns (bool)
    {
        return _weaponAmount[id] >= amount;
    }

    function checkAmountP(uint256 amount) public view returns (bool) {
        return
            _wl1Minted + _wl2Minted + _wlPMinted + amount <= _wl1Max + _wl2Max;
    }

    function claim1(
        bytes32[] calldata proof_,
        uint256 weaponId_,
        uint256 amount
    )
        public
        _checkPeriod1
        _checkWl1(proof_)
        _checkPerUser1(amount)
        _checkMax1(amount)
        _checkWeaponAmount(weaponId_, amount)
    {
        for (uint256 i = 0; i < amount; i++) {
            // mint
            _id++;
            _safeMint(msg.sender, _id);
            _weaponType[_id] = weaponId_;
        }
        _wl1MintedPerUser[msg.sender] += amount;
        _wl1Minted += amount;
        _weaponAmount[weaponId_] -= amount;
    }

    function claim2(
        bytes32[] calldata proof_,
        uint256 weaponId_,
        uint256 amount
    )
        public
        _checkPeriod2
        _checkMax2(amount)
        _checkWeaponAmount(weaponId_, amount)
    {
        if (checkWl1(msg.sender, proof_)) {
            require(checkPerUser1(msg.sender, amount), "exceed per user 1");
        } else if (checkWl2(msg.sender, proof_)) {
            require(checkPerUser2(msg.sender, amount), "exceed per user 2");
        } else {
            require(false, "invalid");
        }

        for (uint256 i = 0; i < amount; i++) {
            // mint
            _id++;
            _safeMint(msg.sender, _id);
            _weaponType[_id] = weaponId_;
        }

        _wl2Minted += amount;
        _weaponAmount[weaponId_] -= amount;

        if (checkWl1(msg.sender, proof_)) {
            _wl1MintedPerUser[msg.sender] += amount;
        } else if (checkWl2(msg.sender, proof_)) {
            _wl2MintedPerUser[msg.sender] += amount;
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _buri;
    }

    function publicMint(uint256 weaponId_, uint256 amount)
        public
        payable
        nonReentrant
        _checkPeriodP
        _checkPerUserP(amount)
        _checkAmountP(amount)
        _checkValueP(amount)
        _checkWeaponAmount(weaponId_, amount)
    {
        for (uint256 i = 0; i < amount; i++) {
            // mint
            _id++;
            _safeMint(msg.sender, _id);
            _weaponType[_id] = weaponId_;
        }
        _wlPMinted += amount;
        _wlPMintedPerUser[msg.sender] += amount;
        _weaponAmount[weaponId_] -= amount;

        // change
        payable(msg.sender).transfer(msg.value - amount * _price);
    }

    // mint reserve nft
    function reserveMint() public onlyOwner {
        for (uint256 i = 1; i <= _reservedAmount; i++) {
            _safeMint(msg.sender, i);
        }
    }

    function remainingMint(uint256 amount)
        public
        onlyOwner
        _checkAmountP(amount)
    {
        require(block.timestamp > _period.endP, "only after public mint");
        for (uint256 i = 0; i < amount; i++) {
            // mint
            _id++;
            _safeMint(msg.sender, _id);
        }
        _wlPMinted += amount;
    }

    function withdraw() public onlyOwner nonReentrant {
        payable(msg.sender).transfer(address(this).balance);
        emit Withdraw(msg.sender, address(this).balance);
    }

    // royalty functions
    function updateRoyalties(address payable recipient, uint256 bps)
        external
        onlyOwner
    {
        require(recipient != address(0), "zero royalty recipient address");
        _royaltyRecipient = recipient;
        _royaltyBps = bps;
        emit UpdateRoyalties(recipient, bps);
    }

    function getRoyalties(uint256 tokenId)
        external
        view
        returns (address, uint256)
    {
        require(
            _exists(tokenId),
            "get royalty info: query for nonexistent token"
        );
        return (_royaltyRecipient, _royaltyBps);
    }

    function getFeeRecipients(uint256 tokenId) external view returns (address) {
        require(
            _exists(tokenId),
            "get fee recipients: query for nonexistent token"
        );
        return _royaltyRecipient;
    }

    function getFeeBps(uint256 tokenId) external view returns (uint256) {
        require(_exists(tokenId), "get fee bps: query for nonexistent token");
        return _royaltyBps;
    }

    function royaltyInfo(uint256 tokenId, uint256 value)
        external
        view
        returns (address, uint256)
    {
        require(_exists(tokenId), "royalty info: query for nonexistent token");
        return (_royaltyRecipient, (value * _royaltyBps) / 10000);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}