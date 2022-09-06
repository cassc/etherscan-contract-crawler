// SPDX-License-Identifier: Unlicense
// Creator: CrudeBorne

//  ∰∰∰∰∰∰∰∰∰∰∰∰∰∰∰∰∰∰∰∰∰∰∰∰∰∰∰∰∰∰∰∰∰∰∰∰∰∰∰
//  ∰∰∰∰∰∰∰∰∰∰∰∰∰∰      __爪爪__      ∰∰∰∰∰∰∰∰∰∰∰∰∰∰∰
//  ∰∰∰∰∰∰∰∰∰∰∰∰      爪ρρρρρρρρρρρρ爪      ∰∰∰∰∰∰∰∰∰∰∰∰∰
//  ∰∰∰∰∰∰∰∰∰∰      爪ρρρρρρρρρρρρρρρρρρρρ爪      ∰∰∰∰∰∰∰∰∰∰∰
//  ∰∰∰∰∰∰∰∰Ω      爪ρρρρρρρρρρρρ☤☤ρρρρρρρρρρρρ爪      Ω∰∰∰∰∰∰∰∰∰
//  ∰∰∰∰∰∰∰Ω     爪ρρρρρρρρρρρρρρρ☤☤ρρρρρρρρρρρρρρρ爪     Ω∰∰∰∰∰∰∰∰
//  ∰∰∰∰∰∰Ω     爪ρρρρρρρρρρρρρρρρρ☤☤ρρρρρρρρρρρρρρρρρ爪     Ω∰∰∰∰∰∰∰
//  ∰∰∰∰∰Ω     爪ρρρρρρρρρρρρρρρρρρ☤☤☤☤ρρρρρρρρρρρρρρρρρρ爪     Ω∰∰∰∰∰∰
//  ∰∰∰∰∰     爪ρρρρρρρρρρρρρρρρρρ☤☤☤☤☤☤ρρρρρρρρρρρρρρρρρρ爪     ∰∰∰∰∰∰
//  ∰∰∰∰Ω     爪ρρρρρρρρρρρρρρρρρρ☤☤☤☤☤☤☤☤ρρρρρρρρρρρρρρρρρρ爪     Ω∰∰∰∰∰
//  ∰∰∰∰     爪ρρρρρρρρρρρρρρρρρ☤☤☤☤☤☤☤☤☤☤☤☤ρρρρρρρρρρρρρρρρρ爪     ∰∰∰∰∰
//  ∰∰∰Ω     爪ρρρρρρρρρρρρρρρρ☤☤☤☤☤☤☤☤☤☤☤☤☤☤☤☤ρρρρρρρρρρρρρρρρ爪     Ω∰∰∰∰
//  ∰∰∰Ω     爪ρρρρρρρρρρρρρ☤☤☤☤☤☤☤☤EGGGGG☤☤☤☤☤☤☤☤ρρρρρρρρρρρρρ爪     Ω∰∰∰∰
//  ∰∰∰Ω     爪ρρρρρρρρρρρρ☤☤☤☤☤☤☤☤☤☤☤☤☤☤☤☤☤☤☤☤☤☤☤☤ρρρρρρρρρρρρ爪     Ω∰∰∰∰
//  ∰∰∰Ω     爪ρρρρρρρρρρρρ☤☤☤☤☤☤☤☤☤☤ρ☤☤ρ☤☤☤☤☤☤☤☤☤☤ρρρρρρρρρρρρ爪     Ω∰∰∰∰
//  ∰∰∰∰     爪ρρρρρρρρρρρρρ☤☤☤☤☤☤ρρρ☤☤ρρρ☤☤☤☤☤☤ρρρρρρρρρρρρρ爪     ∰∰∰∰∰
//  ∰∰∰∰Ω     爪ρρρρρρρρρρρρρρρρρρρρρ☤☤ρρρρρρρρρρρρρρρρρρρρρ爪     Ω∰∰∰∰∰
//  ∰∰∰∰∰      爪ρρρρρρρρρρρρρρρρρρ☤☤☤☤ρρρρρρρρρρρρρρρρρρ爪      ∰∰∰∰∰∰
//  ∰∰∰∰∰∰Ω      爪ρρρρρρρρρρρρρ☤☤☤☤☤☤☤☤ρρρρρρρρρρρρρ爪      Ω∰∰∰∰∰∰∰
//  ∰∰∰∰∰∰∰∰Ω       爪ρρρρρρρρρρρρρρρρρρρρρρρρ爪       Ω∰∰∰∰∰∰∰∰∰
//  ∰∰∰∰∰∰∰∰∰∰ΩΩΩ       °°°°爪爪爪爪°°°°        ΩΩΩ∰∰∰∰∰∰∰∰∰∰
//  ∰∰∰∰∰∰∰∰∰∰∰∰∰∰∰∰∰∰∰∰∰∰∰∰∰∰∰∰∰∰∰∰∰∰∰∰∰∰

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./ERC721.sol";

//        ꃃꆂ꒓ꁒꍟ
//       ________     ________    __        __   _______       _________
//      /⚚⚚⚚⚚⚚⚚⚚⚚\   ||.‾‾‾‾‾\\   ||.       ||  ||.‾‾‾‾\\     |⚚.‾‾‾‾‾‾\\
//     /⚚⚚/‾‾‾‾\⚚⚚\  ||.      \\  ||.       ||  ||.     \\    ||.       ‾
//    /⚚⚚/      ‾‾‾  ||.      //  ||.       ||  |⚚.      \\   ||.
//    |⚚⚚|           ||._____//   ||.       ||  ||.       ||  ||.======|
//    \⚚⚚\      ___  |⚚.‾‾‾‾‾\\    \\.      //  ||.      //   ||.
//     \⚚⚚\____/⚚⚚/  ||.      \\    \\.    //   ||.     //    ||.       _
//      \⚚⚚⚚⚚⚚⚚⚚⚚/   ||.       ||    \⚚.__//    ||.____//     ||.______//
//       ‾‾‾‾‾‾‾‾    ‾‾        ‾‾     ‾‾‾‾‾      ‾‾‾‾‾‾‾       ‾‾‾‾‾‾‾‾‾
//        ꃃꆂ꒓ꁒꍟ

contract JellyBabies is ERC721, Ownable {
    using Strings for uint256;
    string public PROVENANCE;
    bool provenanceSet;

    bool public swimming;

    enum Timeline {
        Yate,
        Yeet,
        Yote
    }

    Timeline public wen = Timeline.Yate;

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

    mapping(address => bool) public authorized;

    mapping(uint256 => uint256) public companionFound;

    CrudeBorneEggs public cbeContract;

    string collectionDescription = "Would you like a jelly baby?";
    string collecImg = "";
    string externalLink = "https://crudeborne.wtf";

    //  ____        ____
    //  |  |        |  |
    //  |54|====----|74|
    //  \  \        /  /
    //   \68\===---/49/
    //    \  \    /  /
    //     \65\=-/64/
    //      \  \/  /
    //       \⇓⇓\ /
    //        \⇓⇓\
    //       / \⇓⇓\
    //      /  /\  \
    //     /6E/-=\42\
    //    /  /    \  \
    //   /69/---===\61\
    //  /  /        \  \
    //  |46|----====|73|
    //  |  |        |  |
    //  |75|====----|65|
    //  \  \        /  /
    //   \6F\===---/64/
    //    \  \    /  /
    //     \59\=-/43/
    //      \  \/  /
    //       \⇑⇑\ /
    //        \⇑⇑\
    //       / \⇑⇑\
    //      /  /\  \
    //     /6F/-=\6E\
    //    /  /    \  \
    //   /64/---===\61\
    //  /  /        \  \
    //  |65|----====|43|
    //  |  |        |  |
    //  ‾‾‾‾        ‾‾‾‾

    constructor(
        address _cbeAddy,
        string memory _name,
        string memory _symbol,
        address[] memory _payees,
        uint128[] memory _basisPoints
    ) ERC721(_name, _symbol) {
        for (uint256 i = 0; i < _payees.length; i++) {
            paymentInfo[_payees[i]] = _basisPoints[i];
        }

        cbeContract = CrudeBorneEggs(_cbeAddy);
    }

    // p̸͓̂ą̵̢̗̘̫̼̯̻̃û̶̦̰̝͉͋̈́ͅs̵͉̒̃̐e̶͓̐̋̂̽̀̂́̕͝.̶̢̼̮͚̪̲͐̿̀̉͐̅̊͌̈̚.̴̯̮͈͋̂͗͒͐͊̌͋.̴̧͕̣͓̗͓͛̔ ̵̡͇̩̟̭̖͔͎͒̊̕͘t̴̫͚͚͚͒̀͒̃̈̈̿̍̽ĥ̸̨͓̠͖͎͙̙̱̙̄i̸̤͖̪̥͓̪̬̰͍͆́̒̊̒̃̏͒̈n̸̼̩̼̖̾͐̂̃̈́̅̈́͊̚͘ķ̸̡̋.̶̳͕̱̫͍̮́͒̉.̷̨̲̝̰̮͖̳̈́̔̄͗͊̈́̀̕.̵̙̗̦͗̄͗͝

    function addAuthorized(address toAuthorize) public onlyOwner {
        authorized[toAuthorize] = true;
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        require(!provenanceSet);
        PROVENANCE = provenanceHash;
        provenanceSet = true;
    }

    function swimOrSink() external onlyOwner {
        swimming = !swimming;
    }

    // ຟi๖๖lฯ ຟ໐๖๖lฯ
    function setTimeyWimey(Timeline _wen) public onlyOwner {
        require(_wen != Timeline.Yate);
        wen = _wen;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

    function hazCompanion(uint256 disEgg) public view returns (bool) {
        uint256 eggBlocc = disEgg/250;
        uint256 eggSlot = disEgg - eggBlocc*250;
        return ((companionFound[eggBlocc] >> eggSlot)%2 == 1);
    }

    function dontGoAlone(uint256[] memory eggz) public {
        require(wen == Timeline.Yeet || (authorized[msg.sender] && (wen == Timeline.Yate)), 'w');

        uint256 curBlocc = 0;
        uint256 bloccUpdates = 0;
        uint256 eggBlocc;

        bool companionRequire = true;
        bool ownerRequire = true;

        // ʂơɱɛ ɬɧıŋɠʂ ɧą۷ɛ ƈơɱɛ ɬɧཞơųɠɧ ơųɬ ơʄ ơཞɖɛཞ
        for (uint256 i = 0; i < eggz.length; i++) {
            eggBlocc = eggz[i]/250;
            if (eggBlocc != curBlocc) {
                companionFound[curBlocc] = companionFound[curBlocc] | bloccUpdates;
                curBlocc = eggBlocc;
                bloccUpdates = 0;
            }

            uint256 eggSlot = eggz[i] - curBlocc*250;
            companionRequire = companionRequire && (companionFound[curBlocc] >> eggSlot)%2 == 0;
            ownerRequire = ownerRequire && cbeContract.ownerOf(eggz[i]) == msg.sender;

            bloccUpdates += (1 << eggSlot);
        }
        require(companionRequire, 'c');
        require(ownerRequire, 'o');

        companionFound[curBlocc] = companionFound[curBlocc] | bloccUpdates;

        _safeMint(msg.sender, eggz.length);
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

    // ᄃ8ん10刀4の2

    function contractURI() public view returns (string memory) {
        return string(
            abi.encodePacked(
                "data:application/json;utf8,{\"name\":\"CrudeBorne: Jelly Babies\",",
                "\"description\":\"", collectionDescription, "\",",
                "\"image\":\"", collecImg, "\",",
                "\"external_link\":\"", externalLink, "\",",
                "\"seller_fee_basis_points\":420,\"fee_recipient\":\"",
                uint256(uint160(address(this))).toHexString(), "\"}"
            )
        );
    }

    ///////////////////////
    //        鷹         //
    // ☢☢☢☢☢☢☢☢☢☢☢☢☢☢☢☢ //
    /////////////////////

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
}

// ⟨ρ|∞⟩

abstract contract CrudeBorneEggs {
    function balanceOf(address owner) public view virtual returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual returns (uint256);
    function ownerOf(uint256 tokenId) public view virtual returns (address);
}

////////////////////////////////////////