// SPDX-License-Identifier: Unlicense
// Creator: U dont need 2 know dat u farkers

// ┻┳|
// ┻┳|
// ┳┻|
// ┳┻|
// ┻┳|
// ┻┳|
// ┳┻|
// ┳┻|
// ┻┳|
// ┳┻|
// ┻┳|
// ┳┻| _
// ┻┳| •.•)  [환영하다, wat r u looking at]
// ┳┻|⊂ﾉ
// ┻┳|

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./ERC721.sol";
import "./ENSResolver.sol";


// ꏸ꒓ꐇꁕꍟ
//        _____    _______     __        _   ______       ________
//      //.    \  ||.     \    ||.       |  ||.    \     ||.      \
//     //.        |☥.      \   ||.       |  ||.     \    ||.
//    //.         ||.      /   |☥.       |  ||.      \   ||.
//    |☥.         ||._____/    ||.       |  ||.       |  ||.-----|
//    \\.         ||.     \    \\.      /   ||.      /   |☥.
//     \\.        ||.      \    \\.    /    |☥.     /    ||.
//      \\.____/  ||.       |    \\.__/     ||.____/     ||.______/
// ꃃꆂ꒓ꁒꍟ


// 卵卵卵卵卵卵卵卵卵卵
contract CrudeBorneEggs is ERC721, Ownable {
    using Strings for uint256;
    string public PROVENANCE;
    bool provenanceSet;

    uint256 public treeFiddy;
    uint256 public allOfDem;
    uint256 public onlyDisMuch; // ‱‱‱‱‱‱‱‱‱‱
    uint256 private disMuchForOwnur;

    bool public paused;

    enum MintStatus {
        CrudeBirth,
        CrudeBorne,
        NoMore4U // ∏ø móår
    }

    MintStatus public mintStatus = MintStatus.CrudeBirth;

    mapping(address => uint256) public totalMintsPerAddress;
    mapping(address => uint256) public totalGiftsPerAddress;

    mapping(address => uint256) private paymentInfo;
    uint256 totalReceived = 0;
    mapping(address => uint256) amountsWithdrawn;

    modifier onlyPayee() {
        _isPayee();
        _;
    }
    function _isPayee() internal view virtual {
        require(paymentInfo[msg.sender] > 0, "not a royalty payee");
    }

    ENSResolver fancyFrenFinder;

    string collectionDescription = "CrudeBorne Eggs are the beginning of the CrudeBorne saga.";
    string collecImg = "";
    string externalLink = "https://crudeborne.wtf";

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxPossibleSupply,
        uint256 _mintPrice,
        uint256 _maxAllowedMints,
        uint256 _maxOwnerAllowedMints,
        address[] memory _payees,
        uint128[] memory _basisPoints
    ) ERC721(_name, _symbol, _maxAllowedMints, _maxOwnerAllowedMints) {
        allOfDem = _maxPossibleSupply;
        treeFiddy = _mintPrice;
        onlyDisMuch = _maxAllowedMints;
        disMuchForOwnur = _maxOwnerAllowedMints;

        for (uint256 i = 0; i < _payees.length; i++) {
            paymentInfo[_payees[i]] = _basisPoints[i];
        }

        // ✼✼✼✼✼✼✼✼✼✼
        fancyFrenFinder = new ENSResolver();
        // ✺✺✺✺✺✺✺✺✺✺
    }

    function _ENSResolverAddress() public view returns (address) {
        return address(fancyFrenFinder);
    }

    function flipPaused() external onlyOwner {
        paused = !paused;
    }

    function preMint(address _to) public onlyOwner {
        require(mintStatus == MintStatus.CrudeBirth, "s");
        require(totalSupply() + disMuchForOwnur*10 <= allOfDem, "m");
        // Wę fêėł łîkē ït
        for (uint i = 0; i < 10; i++) {
            _safeMint(true, address(0), _to, disMuchForOwnur);
        }
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        require(!provenanceSet);
        PROVENANCE = provenanceHash;
        provenanceSet = true;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

    function setPreRevealURI(string memory preRevealURI) public onlyOwner {
        _setPreRevealURI(preRevealURI);
    }

    function changeMintStatus(MintStatus _status) external onlyOwner {
        require(_status != MintStatus.CrudeBirth);
        mintStatus = _status;
    }

    function min(uint256 x, uint256 y) public pure returns(uint256) {
        if (x < y) {
            return x;
        }
        return y;
    }

    function calculateMintCost(uint amount, address minter) public view returns(uint256) {
        uint256 toReturn = treeFiddy * amount;
        if (balanceOf(minter) == 0) {
            toReturn -= min(2, amount)*treeFiddy;
        }
        else if (balanceOf(minter) == 1) {
            toReturn -= min(1, amount)*treeFiddy;
        }
        return toReturn;
    }

    // 𝕰𝕲𝕲𝖅𝖅𝖅
    function getDemEggz(uint amount) public payable {
        require(mintStatus == MintStatus.CrudeBorne && !paused, "s");
        require(totalSupply() + amount <= allOfDem, "m");
        require(totalMintsPerAddress[msg.sender] + amount <= onlyDisMuch, "l");

        uint256 requirePrice = calculateMintCost(amount, msg.sender);

        require(requirePrice <= msg.value, "rp");

        totalReceived += msg.value;

        totalMintsPerAddress[msg.sender] = totalMintsPerAddress[msg.sender] + amount;
        _safeMint(false, address(0), msg.sender, amount);

        if (totalSupply() == allOfDem) {
            mintStatus = MintStatus.NoMore4U;
        }
    }

    function gibEggz2Fren(uint amount, address to) public payable {
        _gibCrude2Fren(amount, to);
    }

    function gibEggz2FancyFren(uint amount, string memory ensAddr) public payable {
        address to = fancyFrenFinder.resolve(ensAddr);
        _gibCrude2Fren(amount, to);
    }

    function calculateGiftMintCost(
        uint amount,
        address giver
    ) public view returns(uint256) {
        uint256 toReturn = treeFiddy * amount;
        if (totalGiftsPerAddress[giver] == 0) {
            toReturn -= min(1, amount)*treeFiddy;
        }
        return toReturn;
    }

    function _gibCrude2Fren(uint amount, address to) internal {
        require(mintStatus == MintStatus.CrudeBorne && !paused, "s");
        require(totalSupply() + amount <= allOfDem, "m");
        require(totalMintsPerAddress[to] + amount <= onlyDisMuch, "l");
        require(to != msg.sender, "ns");

        uint256 requirePrice = calculateGiftMintCost(amount, msg.sender);

        require(requirePrice <= msg.value, "rp");

        totalReceived += msg.value;

        totalMintsPerAddress[to] = totalMintsPerAddress[to] + amount;
        totalGiftsPerAddress[msg.sender] = totalGiftsPerAddress[msg.sender] + amount;
        _safeMint(false, msg.sender, to, amount);

        if (totalSupply() == allOfDem) {
            mintStatus = MintStatus.NoMore4U;
        }
    }

    // ρ(௶Ø†ξ) ∺ 爪(ϒ६∑ナ)/∰(￥Ꭿ₸ໂ) //

    function setCollectionDescription(string memory _collectionDescription) public onlyOwner {
        collectionDescription = _collectionDescription;
    }

    function setCollecImg(string memory _collecImg) public onlyOwner {
        collecImg = _collecImg;
    }

    function setExternalLink(string memory _externalLink) public onlyOwner {
        externalLink = _externalLink;
    }

    function contractURI() public view returns (string memory) {
        return string(
            abi.encodePacked(
                "data:application/json;utf8,{\"name\":\"CrudeBorne: Eggs\",",
                "\"description\":\"", collectionDescription, "\",",
                "\"image\":\"", collecImg, "\",",
                "\"external_link\":\"", externalLink, "\",",
                "\"seller_fee_basis_points\":500,\"fee_recipient\":\"",
                uint256(uint160(address(this))).toHexString(), "\"}"
            )
        );
    }

    // 🝧.🜖.Ω //

    receive() external payable {
        totalReceived += msg.value;
    }

    function withdraw() public onlyPayee {
        uint256 totalForPayee = (totalReceived/10000)*paymentInfo[msg.sender];
        uint256 toWithdraw = totalForPayee - amountsWithdrawn[msg.sender];
        amountsWithdrawn[msg.sender] = totalForPayee;
        (bool success, ) = payable(msg.sender).call{value: toWithdraw}("");
        require(success, "Payment failed!");
    }

    // 01001110 01100101 01110110 01100101 01110010 00100000 01100111 01101111
    // 01101110 01101110 01100001 00100000 01100111 01101001 01110110 01100101
    // 00100000 01111001 01101111 01110101 00100000 01110101 01110000 00001101
    // 00001010 01001110 01100101 01110110 01100101 01110010 00100000 01100111
    // 01101111 01101110 01101110 01100001 00100000 01101100 01100101 01110100
    // 00100000 01111001 01101111 01110101 00100000 01100100 01101111 01110111
    // 01101110 00001101 00001010 01001110 01100101 01110110 01100101 01110010
    // 00100000 01100111 01101111 01101110 01101110 01100001 00100000 01110010
    // 01110101 01101110 00100000 01100001 01110010 01101111 01110101 01101110
    // 01100100 00100000 01100001 01101110 01100100 00100000 01100100 01100101
    // 01110011 01100101 01110010 01110100 00100000 01111001 01101111 01110101
    // 00001101 00001010 01001110 01100101 01110110 01100101 01110010 00100000
    // 01100111 01101111 01101110 01101110 01100001 00100000 01101101 01100001
    // 01101011 01100101 00100000 01111001 01101111 01110101 00100000 01100011
    // 01110010 01111001 00001101 00001010 01001110 01100101 01110110 01100101
    // 01110010 00100000 01100111 01101111 01101110 01101110 01100001 00100000
    // 01110011 01100001 01111001 00100000 01100111 01101111 01101111 01100100
    // 01100010 01111001 01100101 00001101 00001010 01001110 01100101 01110110
    // 01100101 01110010 00100000 01100111 01101111 01101110 01101110 01100001
    // 00100000 01110100 01100101 01101100 01101100 00100000 01100001 00100000
    // 01101100 01101001 01100101 00100000 01100001 01101110 01100100 00100000
    // 01101000 01110101 01110010 01110100 00100000 01111001 01101111 01110101

    function withdrawTokens(address tokenAddress) external onlyOwner() {
        IERC20(tokenAddress).transfer(msg.sender, IERC20(tokenAddress).balanceOf(address(this)));
    }

    //    ////\\     //||\\     //\|\\      ///||\
    //    /`O-O'     ` @ @\     //o o//       a a
    //    ]          >          ) | (        _)
    //    -          -          -           ~
}