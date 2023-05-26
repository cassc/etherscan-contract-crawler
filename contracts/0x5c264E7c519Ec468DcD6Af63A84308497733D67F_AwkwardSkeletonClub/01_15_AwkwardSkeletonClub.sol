// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

//Author: Block3 (@ferduhart, @richgtz)
//Developper: Jesus Cocaño (@jcocano)
//Tittle: Awkward Skeleton Club NFT

/* 
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&BGP5JJ77!~~~~~~~~~~~~~~~!!7?JY5PG#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&BPY?!~^:::::::::::::::::::::::::::::::::^^~7?YPB&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#GY?!^::::::::::::::::::::::::::::::::::::::::::::::::^!?YG#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&B5?!^::::::::::::::::::::::::::::::::::::::::::::::::::::::::::^~?5B&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#5?~^:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::~?P#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&GJ!^::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::^[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&GJ~::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@#Y!:::^::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::!Y#@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@&P7^::^^:::::::::::::::::::::::::::::::::^^^^^^^^^^^^:::::::::::::::::::::::::::::::::::::::::::^[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@#5!::^^^:::::::::::::::::::::::::^~!77???JJJ?????????JJJJJJ?7!~^:::::::::::::::::::::::::::::::::::::!5&@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@#J~::^^^:::::::::::::::::::::^~!7JJJ??!!~^^^:::::::::::::^^^~!!7????7!^::::::::::::::::::::::::::::::::::~Y&@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@&Y~:^^^^:::::::::::::::::::^~7?J?7!~^:::::::::::::::::::::::::::::::^^!7JJ?!^::::::::::::::::::::::::::::::::^Y&@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@P~:^^^^::::::::::::::::::~7JJ?!^::::::::::::::::::::::::::::::::::::::::::^~?YJ7^:::::::::::::::::::::::::::::::[email protected]@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@B7::^^^:::::::::::::::::^7J?!^:::::::::::::::::::::::::::::::::::::::::::::::::^!?YJ!:::::::::::::::::::::::::::::::[email protected]@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@&J^:^^:::::::::::::::::::!57^:::::::::::::::::::::::::::::::^^^^^::::::::::::::::::^~!JY7^:::::::::::::::::::::::::::::^J&@@@@@@@@@@@@@@
@@@@@@@@@@@@@B!:^^::::::::::::::::::::!P^::::::::::::::::::::::::::::::~?YYYJJJJ?!^:::::::::::::::^~~!J5?^:::::::::::::::::::::::::::::[email protected]@@@@@@@@@@@@
@@@@@@@@@@@@P^:^:::::::::::::::::::::^G!:::::::::!?YYJJJ?!^::::::::::^J5?~^::::^~?5J~::::::::::::::^~~~~J5!:::::::::::::::::::::::::::::^[email protected]@@@@@@@@@@@
@@@@@@@@@@@J:::::::::::::::::::::::::5J:::::::^?5J!^:::^~?5?::::::::~G?:::::::::::^7PJ^::::::::::::^~~~~~!5Y^:::::::::::::::::::::::::::::[email protected]@@@@@@@@@@
@@@@@@@@@@?:::::::::::::::::::::::::7P:::::::!PJ^:~?JJ?!:.^55::::::^G?:::!JPGGPJ~:::^YG~::::::::::::^~~~~~~JP~:::::::::::::::::::::::::::::?&@@@@@@@@@
@@@@@@@@&7:::::::::::::::::::::::::^G~::::::?G~.!5#@@@@@B?::55:::::^~::~5B&@&#&@&P~:::JB^::::::::::::^~~~~~^?G!:::::::::::::::::::::::::::::7&@@@@@@@@
@@@@@@@&!::::::::::::::::::::::::::?Y::::::?P^:JG#@@[email protected]@@P^:Y^:::::::~BG&@@[email protected]@&?:::JP::::::::::::^~~~~7~^7G~:::::::::::::::::::::::::::::7&@@@@@@@
@@@@@@@7:::::::::::::::::::::::::::P~:::::~B^:[email protected]@[email protected]@@G^::::::::^GP#@@[email protected]@@Y:::G?::::::::::::~~~~YG7^?G^:::::::::::::::::::::::::::::[email protected]@@@@@@
@@@@@@J:::::::::::::::::::::::::::75::::::[email protected]@5~7G7?#@@@5::::::::[email protected]@[email protected]@@J::?B::::::::::::^~~~~?B7^5Y::::::::::::::::::::::::::::::[email protected]@@@@@
@@@@@G::::::::::::::::::::::::::::57:::::~B^~BY#@5!!?G77J&@@&!:::::::G5#@#[email protected]@&!:~G~:::::::::::^~~~~^JG~~B~::::::::::::::::::::::::::::::[email protected]@@@@
@@@@&~:::::::::::::::::::::::::::^G^:::::[email protected]!!!?G777Y&@@Y::::::~B5&&[email protected]@G::^^:::::::::::^~~~~~~GJ^5Y::::::::::::::::::::::::::::::!&@@@@
@@@@J::::::::::::::::::::::::::::7G::::::!7^[email protected]@B::::::[email protected][email protected]&!::::::::::::::^~~~~?~?G^?G:::::::::::::::::::::::::::::::[email protected]@@@
@@@#^::::::::::::::::::::::::::::JY::::::::[email protected]&~:::::[email protected]::::::::::::::^~~~~55!B~!B^::::::::::::::::::::::::::::::^#@@@
@@@J:::::::::::::::::::::::::::::P?::::::::J#BYY5YYJPPY55P55#@~:::::~#&55Y?777GJJJY5PG&G:::^::::::::::~~~!~7B~B!~#~:::::::::::::::::::::::::::::::[email protected]@@
@@&~:::::::::::::::::::::::::::::P7::::::::[email protected]#5YJ?775PJJY5PG#&~:::::^#&[email protected]^:5~:::::::::^~~7B~?B~B!!B~:::::::::::::::::::::::::::::::~&@@
@@P::::::::::::::::::::::::::::::P!::::::::?BPJ7JYYYGGPP5Y?Y&&~::::::5GG?!7?JJBPJ?77J&@B^~P^:::::::::^7~!#~55!B~7B:::::::::::::::::::::::::::::::::[email protected]@
@@J::::::::::::::::::::::::::::::P!::::::::!BYG7~!!7PP??77Y&@B:::::::!BY#J~!!~PY7?7?#@@B:~P:::::::::^~P57B~G7JG^Y5:::::::::::::::::::::::::::::::::[email protected]@
@@!::::::::::::::::::::::::::::::P?::::::::^BYPB!!!~5Y777J&@@Y::::::::[email protected][email protected]@@5:^G^::::::::^~GY557G~BY^G!:::::::::::::::::::::::::::::::::[email protected]@
@&~::::::::::::::::::::::::::::::YJ:::::::::5PJ&B!!!PY77J&@@&~::::::::[email protected][email protected]@@@!::YJ:::::::^~7#7B7G?7#~?G::::::::::::::::::::::::::::::::::[email protected]@
@&^::::::::::::::::::::::::::::::75:::::::::[email protected]!!GY7?#@@@Y::::::::::[email protected][email protected]@@@P:::^P~:::::^~~BJ55JG~BJ~B7::::::::::::::::::::::::::::::::::~&@
@&^::::::::::::::::::::::::::::::^G^:::::::::YGJ#@5~PJ?#@@@G^:::::::::::[email protected]?GJ&@@@B^::::~5~:::^^~GY?B7B!YG^55:::::::::::::::::::::::::::::::::::^&@
@&^:::::::::::::::::::::::::::::::YJ::::::::::5GY#@[email protected]@@G^::::!7^::::::~5GPBGB#@@@G~::::::~Y7::^7GJ7B7GJ?B~JP::::::::::::::::::::::::::::::::::::^&@
@&~:::::::::::::::::::::::::::::::^G~::::::::::JG5G&##@@&Y^:::~P&@#5!::::::[email protected]&#P?:::::::::^?J?!?77B7P57B!JP^::::::::::::::::::::::::::::::::::::~&@
@@!::::::::::::::::::::::::::::::::!P~:^!?!:::::~J5P#@@P!::::7B#@@@@@5^::::::^75PJ!~:::::::::::^7JY77!JPJG!Y5^:::::::::::::::::::::::::::::::::::::[email protected]@
@@J:::::::::::::::::::::::::::::::::~PJJ7~::::::::^755!:::::[email protected]@@@@@@#!::::::::^!7!::::::::::::::~YJ~~!Y75Y:::::::::::::::::::::::::::::::::::::::[email protected]@
@@G:::::::::::::::::::::::::::::::::757::::::::~JJJ?~:::::::[email protected]@@@@@@@#~:::::::::::::::::::::::::::5?~^7P7::::::::::::::::::::::::::::::::::::::::[email protected]@
@@&~:::::::::::::::::::::::::::::::?5^:::::::::^^^::::::::::G5&@@@@@@@@@G:::::::::::::::::::::::::~:?J~Y5~::::::::::::::::::::::::::::::::::::::::[email protected]@@
@@@Y::::::::::::::::::::::::::::::^G^:::::::::::::::::::::::G5#@@@@@@@@@@!:::::::::::::::::::::::~P^5P57::::::::::::::::::::::::::::::::::::::::::[email protected]@@
@@@#^:::::::::::::::::::::::::::::~G::::::::::::::::::::::::[email protected]@@@@@@@@@!::::::::::::::::::::^~?J75B?^::::::::::::::::::::::::::::::::::::::::::~&@@@
@@@@J::::::::::::::::::::::::::::::5J::::::::::::::::::::::::JP#@&GB&@@&5^:::::::::::::::::^YY?J55Y!:::::::::::::::::::::::::::::::::::::::::::::[email protected]@@@
@@@@&~:::::::::::::::::::::::::::::^Y5!^::::::::::::::::::::::^!!^::~77~:::::::::::::::::::!P~^::?P:::::::::::::::::::::::::::::::::::::::::::::[email protected]@@@@
@@@@@G:::::::::::::::::::::::::::::::~?JJ?77!!!!~:::::::::::::::::::::::::::::::::::::::::?B7:^^^:YY:::::::::::::::::::::::::::::::::::::::::::^#@@@@@
@@@@@@Y:::::::::::::::::::::::::::::::::^~!7777?GY^::::::::::::::::::::::::::::::::::::::~5?J:::::^G^::::::::::::::::::::::::::::::::::::::::::[email protected]@@@@@
@@@@@@@?:::::::::::::::::::::::::::::::::::::::Y?!~::::::::::::::::::::::::::::^^^^^~~~!!77?B7:::::P!:::::::::::::::::::::::::::::::::::::::::[email protected]@@@@@@
@@@@@@@@7:::::::::::::::::::::::::::::::::::::^B!::::::::::::::^^~~~~!!7?7!7?57!!5B7~!5#!^[email protected]@!::::G?::::::::::::::::::::::::::::::::::::::::[email protected]@@@@@@@
@@@@@@@@&?:::::::::::::::::::::::::::::::::::::!YJ7~!!!!?777!7P7!!?#[email protected][email protected]#@GPB&@##&@@@5:::^B7:::::::::::::::::::::::::::::::::::::::[email protected]@@@@@@@@
@@@@@@@@@@J::::::::::::::::::::::::::::::::::::::[email protected][email protected]@&B#&@@@@@@@@@@@@@@@@@@@@@@5:::~B^:::::::::::::::::::::::::::::::::::^::[email protected]@@@@@@@@@
@@@@@@@@@@@Y::::::::::::::::::::::::::::::::::::::^[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@?:::J5:::::::::::::::::::::::::::::::::^^^:^[email protected]@@@@@@@@@@
@@@@@@@@@@@@G^::::::::::::::::::::::::::::::::::::::::[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#^:^!G~:::::::::::::::::::::::::::::::^^^^:[email protected]@@@@@@@@@@@
@@@@@@@@@@@@@#7:::::::::::::::::::::::::::::::::::::::~#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]&7:^?P!::::::::::::::::::::::::::::::^^^^^:?#@@@@@@@@@@@@@
@@@@@@@@@@@@@@@Y^::::::::::::::::::::::::::::::::::::::7&@@@@@@@@@@@@@@@@@@@@@@@&&@&BG#G!7??~~?YJ~:::::::::::::::::::::::::::::^^^^^:[email protected]@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@B7::::::::::::::::::::::::::::::::::::::7&@@@@@&&@@@#BB&@#[email protected]?777~^^7YY7^:::::::::::::::::::::::::::::^^^^^:^?#@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@P!:::::::::::::::::::::::::::::::::::^PJ7?&57!7J#P777YGJ7!!!7!~^^::::~7JY?~::::::::::::::::::::::::::::::^^^^^^:[email protected]@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@5~::::::::::::::::::::::::::::::::!YJ!!!!~~~~~~^^^^::::::::::^^~7?JJ?~:::::::::::::::::::::::::::::::^^^^^^:[email protected]@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@&Y~::::::::::::::::::::::::::::::PJ.:::::::::::::::::^^^^~!7JYY?!^::::::::::::::::::::::::::::::::^^^^^::!5&@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@&P!::::::::::::::::::::::::::::~YJ?!^^^::::^^^^^~~!7?JJYJ?!^:::::::::::::::::::::::::::::::::^^^^^^:^!P&@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@G?^:::::::::::::::::::::::::::~7?JJJJJJJJJJYYYJJ?7!~^:::::::::::::::::::::::::::::::::::^^^^^::[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@#5!::::::::::::::::::::::::::::::^^~~~~~^^^^::::::::::::::::::::::::::::::::::::::::^^^^::^7P&@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@BJ~::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::^^:::^[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B57^::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::^[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#PJ!^::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::^!JG&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#PJ!^::::::::::::::::::::::::::::::::::::::::::::::::::::::::::^!JP#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&G5?!~^::::::::::::::::::::::::::::::::::::::::::::::^~!J5B&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#G5J7!~^:::::::::::::::::::::::::::::::^^~!?Y5G#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#BGP5YJ?77!!~~~~~~~~~!!!77?JY5PB#&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
*/

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";

contract AwkwardSkeletonClub is Ownable, ERC721A, PaymentSplitter{

    using Strings for uint;

    enum Phase {
        Whitelist,
        Public,
        SoldOut,
        Reveal
    }

    string private baseURI;
    string public hiddenURI;

    Phase public salesPhase;

    uint private constant MAXSUPPLY = 7373;
    uint private constant MAXMINTPERTX = 10;

    uint public wlprice = 0.02 ether;
    uint public pubprice = 0.03 ether;

    bool public paused = true;
    bool public revealed = false;

    address private royaltyReceiver;
    uint96 private royaltyFeesInBeeps = 500;

    bytes32 public merkleRoot;

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;


    mapping(address => uint256) public totalPublicMint;
    mapping(address => uint256) public totalWhitelistMint;

    uint private teamLength;

    constructor(
        address[] memory _team,
        uint[] memory _teamShares,
        bytes32 _merkleRoot, 
        string memory _baseURI,
        string memory _hiddenURI
    ) ERC721A ("Awkward Skeleton Club", "ASC")
      PaymentSplitter(_team, _teamShares){
        merkleRoot = _merkleRoot;
        baseURI = _baseURI;
        hiddenURI = _hiddenURI;
        teamLength = _team.length;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Cannot be called from another contract");
        _;
    }

    modifier mintCompliance(uint256 _mintAmmount) {
    require(_mintAmmount > 0 && _mintAmmount <= MAXMINTPERTX, "ASC: Mint must be greater than 0 and at most 10!");
    require(totalSupply() + _mintAmmount <= MAXSUPPLY, "ASC: Max supply exceeded!");
    _;
    }

    //Mint
    function whiteListMint(uint256 _mintAmmount, bytes32[] calldata _proof) external payable mintCompliance(_mintAmmount) callerIsUser{
        uint256 price = wlprice;
        require(price != 0, "ASC: Price must be greater that 0");
        require(salesPhase == Phase.Whitelist, "ASC: Whitelist sale is not activated");
        require(msg.value >= price * _mintAmmount, "You don't have enought funds");
        require(!paused, "ASC contract is paused!");
        require(isWhiteListed(msg.sender, _proof), "ASC: You'r not whitelisted");

        totalWhitelistMint[msg.sender] += _mintAmmount;
        _safeMint(msg.sender, _mintAmmount);
    }

    function publicMint(uint256 _mintAmmount) external payable mintCompliance(_mintAmmount) callerIsUser{
        uint256 price = pubprice;
        require(price != 0, "ASC: Price must be greater that 0");
        require(salesPhase == Phase.Public, "ASC: Public sale is not activated");
        require(msg.value >= price * _mintAmmount, "You don't have enought funds");
        require(!paused, "ASC contract is paused!");

        totalPublicMint[msg.sender] += _mintAmmount;
        _safeMint(msg.sender, _mintAmmount);
    }

    function givaweyMint(uint256 _mintAmmount, address _reciver) external mintCompliance(_mintAmmount) onlyOwner{
        _safeMint(_reciver, _mintAmmount);
    }

    //Miscellaneous
    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = _startTokenId();
    uint256 ownedTokenIndex = 0;
    address latestOwnerAddress;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= MAXSUPPLY) {
    TokenOwnership memory ownership = _ownerships[currentTokenId];

    if (!ownership.burned && ownership.addr != address(0)) {
        latestOwnerAddress = ownership.addr;
    }

    if (latestOwnerAddress == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;

        ownedTokenIndex++;
        }

      currentTokenId++;
    }

    return ownedTokenIds;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
    }

    function selectPhase(uint _phase) external onlyOwner{
        salesPhase = Phase(_phase);
    }

    function setPaused(bool _state) external onlyOwner {
        paused = _state;
    }

    function setBaseUri(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setHiddenMetadataUri(string memory _hiddenURI) external onlyOwner {
        hiddenURI = _hiddenURI;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

    if (revealed == false) {
      return hiddenURI;
    } 

    string memory currentBaseURI = baseURI;
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), ".json"))
        : '';
    }

    function setRevealed(bool _state) external onlyOwner {
        revealed = _state;
    }

    //Whitelist
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function isWhiteListed(address _account, bytes32[] calldata _proof) internal view returns(bool) {
        return _verify(leaf(_account), _proof);
    }

    function leaf(address _account) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked(_account));
    }

    function _verify(bytes32 _leaf, bytes32[] memory _proof) internal view returns(bool) {
        return MerkleProof.verify(_proof, merkleRoot, _leaf);
    }

    //withdrawal
    function withdrawalsAll() external {
        for(uint i = 0 ; i < teamLength ; i++) {
            release(payable(payee(i)));
        }
    }

    //Implementing Royalty Interface (EIP2891)
    function supportsInterface(bytes4 interfaceId) 
        public 
        view 
        virtual 
        override (ERC721A)
        returns (bool) 
    {
        if (interfaceId == _INTERFACE_ID_ERC2981) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }

    //RoyaltyInfo
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(_tokenId), "ERC2981Royality: Cannot query non-existent token");
        return (royaltyReceiver, (_salePrice * royaltyFeesInBeeps) / 10000);
    }

    function calculatingRoyalties(uint256 _salePrice) view public returns (uint256) {
        return (_salePrice / 10000) * royaltyFeesInBeeps;
    }

    function setRoyalty(uint96 _royaltyFeesInBeeps) external onlyOwner {
        royaltyFeesInBeeps = _royaltyFeesInBeeps;
    }

    function setRoyaltyReceiver(address _receiver) external onlyOwner{
        royaltyReceiver = _receiver;
    }
}