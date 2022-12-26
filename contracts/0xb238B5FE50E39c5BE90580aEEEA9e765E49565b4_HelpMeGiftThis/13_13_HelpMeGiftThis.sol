// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;
import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/utils/Strings.sol';
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./ERC721A.sol";

///@author helpmedebugthis.eth
///@notice Santa is coming!
///@notice Gift will be ready, when you are asleep.
///@notice Just like good old time.

/*
((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((
((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((
((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((
((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((
((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((
(((((((((((((((((((((((((((((((((@%/(&@/((#@%@@@#(((((((((((((((((((((((((((((((
((((((((((((((((((((((((((((((((# $.(&%@&@@ $.&(@@@(((((((((((((((((((((((((((((
(((((((((((((((((((((((((((((((( (@ %(@(@@    /#@@@&@@((((((((((((((((((((((((((
((((((((((((((((((((((((((((((((@#@@#(((/@,(@ @@#@%#@%@@@@((((((((((((((((((((((
((((((((((((((((((((((((((((((@/((//(///////$/[email protected]@###(&@@@%@@((((((((((((((((((((
((((((((((((((((((((((((((((%,$,/,,$$/$$/////////@/(@%%@%@@@@@@(((((((((((((((((
(((((((((((((((((((((((((((((@@@$/(@@@@$(@@%%%$##$,,@((@@@@@&@#@@(((((((((((((((
(((((((((((@@&/(((((((((((((((((@,., ..    .. .   .$(&@@%@@(/,@@@@&(((((((((((((
((((((((((#,. @@.$ &@(((((((((((((@@@#,,...... (/(@@@%@@# %@&#%/,(@@((((((((((((
(((((((((((@$ ##(( /,[email protected]@#@((((&%%%%(((%%(&#(/,@@@@$ [email protected]&@@(/(%@@@&@@@&((((((((((
(((((((((((@.#(#(%./(..,@&((@@@@./ /$$$(&@@##/  ....,@##//(%#&&@@&@&@@((((((((((
(((((((((((& .$.((#/. . @&@@/@@@   $((&@#&(#(@.. ..(/@/(//##@%@@@@%@@&@(((((((((
((((((((((((&...  .,$,/$$%@%&#/@ @@@@@(#&%(/%%#(////($/((&&@@@@#/.(#&@@(((((((((
((((((((((((@.(/.,##(($ ,@(((((@  .(##@@%%%%%@@&%&((&&%%%%@@#,  (%&@&%#&((((((((
((((((((((((@ $(..#$,%(/[email protected]#&(((((&@@@&&#@@@@@@&@@@@@@&%%@@@@@@@@@@&@&@@%((((((((
(((((((((((((@/ ,...%##(((#@(((((((@%&%@(###@@@@@@@@@@@@(#/#///%%@@@@@@(((((((((
((((((((((((((((&  ,[email protected],[email protected]@@@##@@((@&#@($$. .$/($((@%////((&#&%&%@@@(((((((((((
(((((((((((@%[email protected]@@./(,[email protected]&%@##@%@%@%,@@@%@@@$$((/#@%@@%///(/%#%#&@@@@@/(((((((((((
(((((((((#../,[email protected]@(,.//$&##@      &&@@#@@ @@@@@@%##@/&@((&#%%#&&@@@@@@@@@@((((((
(((((((((((/@@&$,(.$/..,#@@. .$$/,@ ,[email protected]@%@@@( #@@@@&@/@(@@@%%@@&&&%(((((((((((((
(((((((((((((((((((/@@./@@@    $//@/@&$##@@@@@@@%@((((((((((((((((((((((((((((((
((((((((((((((((((((((((((# . ,//$&(((((((((((((%(/(((((((((((((((((((((((((((((
((((((((((((((#@@&,/&((((((&   $#(/((((((((((@(&(%@@(@&%@(((((((((((((((((((((((
((((((((((((((((((%((#(((((%@&%&@@@@&&@(((((((&@@@@@@@@%((&(((((((((((((((((((((
((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((
((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((
((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((
*/


contract HelpMeGiftThis is ERC721A, Ownable {
    using Strings for uint256;
    event ReceivedEth(uint256 amount);

    uint256 public constant maxSupply = 2023;

    uint256 public max_whitelist_supply = 0;
    uint256 public max_public_supply = 0;


    uint256 public  maxPerTx = 1;
    uint256 public  maxPerWallet = 1;
    uint256 public  maxPerWalletWL = 2; 

    uint256 public token_price = 0 ether;

    uint256 public stage;

    bool public publicSaleActive;
    bool public WLSaleActive;

    bytes32 public whitelistMerkleRoot;

    mapping(address => uint256) public wlMintClaimed;

    string[] private _baseTokenURI;


    constructor() ERC721A("HelpMeGiftThis", "GIFT") {
        _safeMint(msg.sender, 3);
    }

    modifier underMaxSupply(uint256 _quantity) {
        require(
            _totalMinted() + _quantity <= maxSupply,
            "Mint would exceed max supply"
        );

        _;
    }

    modifier validatePublicStatus(uint256 _quantity) {
        require(publicSaleActive, "Sale hasn't started");
        require(msg.value >= token_price * _quantity, "Need to send more ETH.");
        require(_quantity > 0 && _quantity <= maxPerTx, "Invalid mint amount.");
        require(
            _numberMinted(msg.sender) + _quantity <= maxPerWallet,
            "This purchase would exceed maximum allocation for public mints for this wallet"
        );

        _;
    }

    modifier validateWLStatus(uint256 _quantity) {
        require(WLSaleActive, "WL Sale hasn't started yet.");
        require(msg.value >= token_price * _quantity, "Need to send more ETH.");
        require(wlMintClaimed[msg.sender] + _quantity <= maxPerWalletWL, "Exceeds WhiteList allowed amount");
        _;
    }

    modifier validateSupply(uint256 _maxSupply, uint256 _quantity) {
        require(
            _totalMinted() + _quantity <= _maxSupply,
            "The current stage has nothing remaining"
        );
        _;
    }

    modifier validateWLAddress(
        bytes32[] calldata _merkleProof,
        bytes32 _merkleRoot
    ) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, _merkleRoot, leaf),
            "You are not whitelisted"
        );
        _;
    }

    /**
     * @dev override ERC721A _startTokenId()
     */
    function _startTokenId() 
        internal 
        view 
        virtual
        override 
        returns (uint256) {
        return 1;
    }

    function mint(uint256 _quantity)
        external
        payable
        validatePublicStatus(_quantity)
        validateSupply(max_public_supply, _quantity)
        underMaxSupply(_quantity)
    {
        _mint(msg.sender, _quantity, "", false);
    }

    function whiteListMint(uint256 _quantity, bytes32[] calldata _proof)
        external
        validateWLStatus(_quantity)
        validateSupply(max_whitelist_supply, _quantity)
        validateWLAddress(_proof, whitelistMerkleRoot)
        payable
    {
        wlMintClaimed[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI[0];
    }

    function _baseURI(uint256 _stage) internal view returns (string memory) {
        return _baseTokenURI[_stage];
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI(stage);
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : '';
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function setCurrentStage(uint256 _stage) external onlyOwner {
        stage = _stage;
    } 

    function setMaxPerTxn(uint256 _num) external onlyOwner {
        require(_num >= 0, "Num must be greater than zero");
        maxPerTx = _num;
    } 

    function setMaxPerWallet(uint256 _num) external onlyOwner {
        require(_num >= 0, "Num must be greater than zero");
        maxPerWallet = _num;
    } 

    function setTokenPrice(uint256 newPrice) external onlyOwner {
        require(newPrice >= 0, "Token price must be greater than zero");
        token_price = newPrice;
    }

    function setWhitelistMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        whitelistMerkleRoot = _merkleRoot;
    }

    function setWLMaxSupply(uint256 _supply) external onlyOwner {
        max_whitelist_supply = _supply;
    }

    function setPublicMaxSupply(uint256 _supply) external onlyOwner {
        max_public_supply = _supply;
    }

    function initBaseURI(uint256 _numStage) external onlyOwner {
        while (_baseTokenURI.length > 0) {
            _baseTokenURI.pop();
        }
        for (uint256 i = 0; i < _numStage; i++) {
            _baseTokenURI.push('');
        }
    }

    function sendGift(address[] calldata _addresses, uint256[] calldata _quantities) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            _safeMint(_addresses[i], _quantities[i]);
        }
    }

    function setBaseURI(string calldata baseURI, uint256 _stage) external onlyOwner {
        _baseTokenURI[_stage] = baseURI;
    }

    function withdrawFunds() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function withdrawFundsToAddress(address _address, uint256 amount) external onlyOwner {
        (bool success, ) =_address.call{value: amount}("");
        require(success, "Transfer failed.");
    }

    function flipPublicSale() external onlyOwner {
        publicSaleActive = !publicSaleActive;
    }

    function merryChristmas() public payable {
        emit ReceivedEth(msg.value);
    }

    receive() external payable  { 
        merryChristmas();
    }

    fallback() external payable {
        merryChristmas();
    }
}