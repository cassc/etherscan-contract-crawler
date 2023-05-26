// SPDX-License-Identifier: MIT
/******************************************************************
 (                                                                *
 )\ )                                                             *
(()/(    )      (   (  (    (          (   (             (   (    *
 /(_))  (      ))\  )\))(   )\   (    ))\  )(    (      ))\  )\ ) *
(_))    )\  ' /((_)((_))\  ((_)  )\  /((_)(()\   )\ )  /((_)(()/( *
/ __| _((_)) (_))(  (()(_)_ | | ((_)(_))(  ((_) _(_/( (_))   )(_))*
\__ \| '  \()| || |/ _` || || |/ _ \| || || '_|| ' \))/ -_) | || |*
|___/|_|_|_|  \_,_|\__, | \__/ \___/ \_,_||_|  |_||_| \___|  \_, |*
                   |___/                                     |__/ *
*******************************************************************/
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract SmugJourney is ERC721A, DefaultOperatorFilterer, Ownable {
    using ECDSA for bytes32;
    using Strings for uint256;

    enum SalePhase {
        Free,
        Whitelist,
        Public
    }

    struct MintSettings {
        uint256 freeStartTime;
        uint256 freeEndTime;
        uint256 freePrice;
        uint256 freePerUserMint;
        uint256 freeMaxCount;

        uint256 whitelistStartTime;
        uint256 whitelistEndTime;
        uint256 whitelistPrice;
        uint256 whitelistPerUserMint;
        uint256 whitelistMaxCount;

        uint256 publicStartTime;
        uint256 publicEndTime;
        uint256 publicPrice;
        uint256 publicPerUserMint;
    }

    string public baseURI;
    address public withdrawAddress;
    uint256 public totalQuantity;

    uint256 public freeStartTime;
    uint256 public freeEndTime;
    uint256 public freePrice;
    uint256 public freePerUserMint;
    uint256 public freeMaxCount;

    uint256 public wlStartTime;
    uint256 public wlEndTime;
    uint256 public wlPrice;
    uint256 public wlPerUserMint;
    uint256 public wlMaxCount;


    uint256 public publicStartTime;
    uint256 public publicEndTime;
    uint256 public publicPrice;
    uint256 public publicPerUserMint;

    bool public openFreeMint;
    bool public openWhitelistMint;
    bool public openPublicMint;


    mapping(SalePhase => mapping(address => uint256)) public mintedCount;
    mapping(SalePhase => uint256) public salePhaseMinted;

    bytes32 public freeMerkleRoot;
    bytes32 public whitelistMerkleRoot;

    constructor() ERC721A("SmugJourney", "SmugJourney"){
        withdrawAddress = owner();
        totalQuantity = 4500;

        freeStartTime = 1677825000;
        freeEndTime = 1677826800;
        freePrice = 0 ether;
        freePerUserMint = 2;
        freeMaxCount = 838;

        wlStartTime = 1677826800;
        wlEndTime = 1677834000;
        wlPrice = 0.01 ether;
        wlPerUserMint= 2;
        wlMaxCount = 4500;

        publicStartTime = 1677834000;
        publicEndTime = 1677920400;
        publicPrice = 0.02 ether;
        publicPerUserMint = 2;
        openFreeMint = true;
        openWhitelistMint = true;
        openPublicMint = true;
        baseURI = "https://www.smugbunny.io/smugjourney/metadata/";
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable  override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)  public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }


    function setTotalQuantity(uint256 _totalQuantity) external onlyOwner {
        totalQuantity = _totalQuantity;
    }

    function setWithdrawAddress(address newWithdrawAddress) external onlyOwner {
        withdrawAddress = newWithdrawAddress;
    }

    function setFreeMint(uint256 _freeStartTime,uint256 _freeEndTime,uint256 _freePrice,uint256 _freePerUserMint,uint256 _freeMaxCount) external onlyOwner {
        freeStartTime = _freeStartTime;
        freeEndTime = _freeEndTime;
        freePrice = _freePrice;
        freePerUserMint= _freePerUserMint;
        freeMaxCount = _freeMaxCount;
    }

    function setWhitelistMint(uint256 _wlStartTime,uint256 _wlEndTime,uint256 _wlPrice,uint256 _wlPerUserMint,uint256 _wlMaxCount) external onlyOwner {
        wlStartTime = _wlStartTime;
        wlEndTime = _wlEndTime;
        wlPrice = _wlPrice;
        wlPerUserMint= _wlPerUserMint;
        wlMaxCount = _wlMaxCount;
    }

    function setPublicMint(uint256 _publicStartTime, uint256 _publicEndTime, uint256 _publicPrice, uint256 _publicPerUserMint) external onlyOwner {
        publicStartTime = _publicStartTime;
        publicEndTime = _publicEndTime;
        publicPrice = _publicPrice;
        publicPerUserMint = _publicPerUserMint;
    }

    function setMintStatus(bool _openFreeMint,bool _openWhitelistMint, bool _openPublicMint) external onlyOwner {
        openFreeMint = _openFreeMint;
        openWhitelistMint = _openWhitelistMint;
        openPublicMint = _openPublicMint;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract.");
        _;
    }

    modifier isWithdrawAddress() {
        require(
            withdrawAddress == msg.sender,"The caller is incorrect address."
        );
        _;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory)  {
        if (!_exists(tokenId))
        {
            revert URIQueryForNonexistentToken();
        }
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")): "";
    }

    function withdrawTo(address beneficiary, uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "amount is illegal");
        payable(beneficiary).transfer(amount);
    }

    function withdraw() external isWithdrawAddress callerIsUser() {
        payable(withdrawAddress).transfer(address(this).balance);
    }

    function setMerkleRoot(bytes32 _freeRoot, bytes32 _whitelistRoot) external onlyOwner {
        freeMerkleRoot = _freeRoot;
        whitelistMerkleRoot= _whitelistRoot;
    }

    function airdrop(address[] calldata recipients, uint256[] calldata values) external onlyOwner {
        require(recipients.length == values.length, "len wrong");
        for (uint256 i = 0; i < recipients.length; i++) {
            require(_totalMinted() + values[i] <= totalQuantity,"Max supply reached");
            _safeMint(recipients[i], values[i]);
        }
    }

    function freeMint( bytes32 root, bytes32[] calldata proof,uint256 quantity) external payable callerIsUser {
        require(openFreeMint == true,"Sale phase mismatch");
        require(freeStartTime < block.timestamp,"Sale no start");
        require(freeEndTime > block.timestamp,"Sale end");
        require(salePhaseMinted[SalePhase.Free] + quantity <= freeMaxCount,"Exceeds phase limit");
        require(_totalMinted() + quantity <= totalQuantity,"Max supply reached");
        uint256 walletMinted = mintedCount[SalePhase.Free][msg.sender];
        require(freePerUserMint - walletMinted >= quantity,"Exceeds personal limit");
        require(msg.value >= freePrice * quantity, "Incorrect price");
        require (freeMerkleRoot == root, "Invalid merkle root");
        require(MerkleProof.verify(proof, root, keccak256(abi.encodePacked(msg.sender))),"Invalid proof");
        mintedCount[SalePhase.Free][msg.sender] += quantity;
        salePhaseMinted[SalePhase.Free] += quantity;
        _safeMint(msg.sender, quantity);
    }

    function whitelistMint( bytes32 root, bytes32[] calldata proof,uint256 quantity) external payable callerIsUser {
        require(openWhitelistMint == true,"Sale phase mismatch");
        require(wlStartTime < block.timestamp,"Sale no start");
        require(wlEndTime > block.timestamp,"Sale end");
        require(salePhaseMinted[SalePhase.Whitelist] + quantity <= wlMaxCount,"Exceeds phase limit");
        require(_totalMinted() + quantity <= totalQuantity,"Max supply reached");

        uint256 walletMinted = mintedCount[SalePhase.Whitelist][msg.sender];
        require(wlPerUserMint - walletMinted >= quantity,"Exceeds personal limit");
        require(msg.value >= wlPrice * quantity, "Incorrect price");
        require (whitelistMerkleRoot == root, "Invalid merkle root");
        require(MerkleProof.verify(proof, root, keccak256(abi.encodePacked(msg.sender))),"Invalid proof");
        mintedCount[SalePhase.Whitelist][msg.sender] += quantity;
        salePhaseMinted[SalePhase.Whitelist] += quantity;
        _safeMint(msg.sender, quantity);
    }

    function publicMint(uint256 quantity) external payable callerIsUser {
        require(openPublicMint == true,"Sale phase mismatch");
        require(publicStartTime < block.timestamp,"Sale no start");
        require(publicEndTime > block.timestamp,"Sale end");
        require(_totalMinted() + quantity <= totalQuantity,"Max supply reached");
        uint256 walletMinted = mintedCount[SalePhase.Public][msg.sender];
        require(publicPerUserMint - walletMinted >= quantity,"Exceeds personal limit");
        require(msg.value >= publicPrice * quantity, "Incorrect price");
        mintedCount[SalePhase.Public][msg.sender] += quantity;
        salePhaseMinted[SalePhase.Public] += quantity;
        _safeMint(msg.sender, quantity);
    }

    function totalMinted() public view returns(uint256) {
        return _totalMinted();
    }

    function getMintSettings() external view
    returns (
            MintSettings memory settings
    ){
        return MintSettings(
            freeStartTime,
            freeEndTime,
            freePrice,
            freePerUserMint,
            freeMaxCount,
            wlStartTime,
            wlEndTime,
            wlPrice,
            wlPerUserMint,
            wlMaxCount,
            publicStartTime,
            publicEndTime,
            publicPrice,
            publicPerUserMint
        );
    }

    function getMintedInfo(address _address) external view
    returns (
            uint256 _freeMinted,
            uint256 _whitelistMinted,
            uint256 _publicMinted,
            uint256 _totalMinted,
            uint256 _totalQuantity,
            bool _openFreeMint,
            bool _openWhitelistMint,
            bool _openPublicMint
    ){
        return (
            mintedCount[SalePhase.Free][_address],
            mintedCount[SalePhase.Whitelist][_address],
            mintedCount[SalePhase.Public][_address],
            totalMinted(),
            totalQuantity,
            openFreeMint,
            openWhitelistMint,
            openPublicMint
        );
    }
}