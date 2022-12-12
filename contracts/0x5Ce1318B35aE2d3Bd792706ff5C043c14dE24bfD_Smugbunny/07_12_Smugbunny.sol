// SPDX-License-Identifier: MIT
/*********************************************************************************************************************************************************************************
*                                                                                 bbbbbbbb                                                                                       *
*    SSSSSSSSSSSSSSS                                                              b::::::b                                                                                       *
*  SS:::::::::::::::S                                                             b::::::b                                                                                       *
* S:::::SSSSSS::::::S                                                             b::::::b                                                                                       *
* S:::::S     SSSSSSS                                                              b:::::b                                                                                       *
* S:::::S               mmmmmmm    mmmmmmm   uuuuuu    uuuuuu     ggggggggg   gggggb:::::bbbbbbbbb    uuuuuu    uuuuuunnnn  nnnnnnnn    nnnn  nnnnnnnn yyyyyyy           yyyyyyy *
* S:::::S             mm:::::::m  m:::::::mm u::::u    u::::u    g:::::::::ggg::::gb::::::::::::::bb  u::::u    u::::un:::nn::::::::nn  n:::nn::::::::nny:::::y         y:::::y  *
*  S::::SSSS         m::::::::::mm::::::::::mu::::u    u::::u   g:::::::::::::::::gb::::::::::::::::b u::::u    u::::un::::::::::::::nn n::::::::::::::nny:::::y       y:::::y   *
*   SS::::::SSSSS    m::::::::::::::::::::::mu::::u    u::::u  g::::::ggggg::::::ggb:::::bbbbb:::::::bu::::u    u::::unn:::::::::::::::nnn:::::::::::::::ny:::::y     y:::::y    *
*     SSS::::::::SS  m:::::mmm::::::mmm:::::mu::::u    u::::u  g:::::g     g:::::g b:::::b    b::::::bu::::u    u::::u  n:::::nnnn:::::n  n:::::nnnn:::::n y:::::y   y:::::y     *
*        SSSSSS::::S m::::m   m::::m   m::::mu::::u    u::::u  g:::::g     g:::::g b:::::b     b:::::bu::::u    u::::u  n::::n    n::::n  n::::n    n::::n  y:::::y y:::::y      *
*             S:::::Sm::::m   m::::m   m::::mu::::u    u::::u  g:::::g     g:::::g b:::::b     b:::::bu::::u    u::::u  n::::n    n::::n  n::::n    n::::n   y:::::y:::::y       *
*             S:::::Sm::::m   m::::m   m::::mu:::::uuuu:::::u  g::::::g    g:::::g b:::::b     b:::::bu:::::uuuu:::::u  n::::n    n::::n  n::::n    n::::n    y:::::::::y        *
* SSSSSSS     S:::::Sm::::m   m::::m   m::::mu:::::::::::::::uug:::::::ggggg:::::g b:::::bbbbbb::::::bu:::::::::::::::uun::::n    n::::n  n::::n    n::::n     y:::::::y         *
* S::::::SSSSSS:::::Sm::::m   m::::m   m::::m u:::::::::::::::u g::::::::::::::::g b::::::::::::::::b  u:::::::::::::::un::::n    n::::n  n::::n    n::::n      y:::::y          *
* S:::::::::::::::SS m::::m   m::::m   m::::m  uu::::::::uu:::u  gg::::::::::::::g b:::::::::::::::b    uu::::::::uu:::un::::n    n::::n  n::::n    n::::n     y:::::y           *
*  SSSSSSSSSSSSSSS   mmmmmm   mmmmmm   mmmmmm    uuuuuuuu  uuuu    gggggggg::::::g bbbbbbbbbbbbbbbb       uuuuuuuu  uuuunnnnnn    nnnnnn  nnnnnn    nnnnnn    y:::::y            *
*                                                                          g:::::g                                                                           y:::::y             *
*                                                              gggggg      g:::::g                                                                          y:::::y              *
*                                                              g:::::gg   gg:::::g                                                                         y:::::y               *
*                                                               g::::::ggg:::::::g                                                                        y:::::y                *
*                                                                gg:::::::::::::g                                                                        yyyyyyy                 *
*                                                                  ggg::::::ggg                                                                                                  *
*                                                                     gggggg                                                                                                     *
**********************************************************************************************************************************************************************************/
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract Smugbunny is ERC721A, DefaultOperatorFilterer, Ownable {
    using ECDSA for bytes32;
    using Strings for uint256;

    enum SalePhase {
        Free,
        Fashion,
        Pioneer,
        Public
    }

    struct MintSettings {
        uint256 freeStartTime;
        uint256 freeEndTime;
        uint256 freePrice;
        uint256 freePerUserMint;
        uint256 freeMaxCount;

        uint256 fashionStartTime;
        uint256 fashionEndTime;
        uint256 fashionPrice;
        uint256 fashionPerUserMint;
        uint256 fashionMaxCount;

        uint256 pioneerStartTime;
        uint256 pioneerEndTime;
        uint256 pioneerPrice;
        uint256 pioneerPerUserMint;
        uint256 pioneerMaxCount;

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

    uint256 public fashionStartTime;
    uint256 public fashionEndTime;
    uint256 public fashionPrice;
    uint256 public fashionPerUserMint;
    uint256 public fashionMaxCount;

    uint256 public pioneerStartTime;
    uint256 public pioneerEndTime;
    uint256 public pioneerPrice;
    uint256 public pioneerPerUserMint;
    uint256 public pioneerMaxCount;



    uint256 public publicStartTime;
    uint256 public publicEndTime;
    uint256 public publicPrice;
    uint256 public publicPerUserMint;

    bool public openFreeMint;
    bool public openFashionMint;
    bool public openPioneerMint;
    bool public openPublicMint;


    mapping(SalePhase => mapping(address => uint256)) public mintedCount;
    mapping(SalePhase => uint256) public salePhaseMinted;

    bytes32 public freeMerkleRoot;
    bytes32 public fashionMerkleRoot;
    bytes32 public pioneerMerkleRoot;


    constructor() ERC721A("Smugbunny", "Smugbunny"){
        withdrawAddress = owner();
        totalQuantity = 5000;

        freeStartTime = 1674226800;
        freeEndTime = 1674313200;
        freePrice = 0 ether;
        freePerUserMint = 1;
        freeMaxCount = 50;

        fashionStartTime = 1674226800;
        fashionEndTime = 1674313200;
        fashionPrice = 0.1 ether;
        fashionPerUserMint= 1;
        fashionMaxCount = 4950;

        pioneerStartTime = 1674226800;
        pioneerEndTime = 1674313200;
        pioneerPrice = 0.1 ether;
        pioneerPerUserMint= 2;
        pioneerMaxCount = 4950;

        publicStartTime = 1674313200;
        publicEndTime = 1674399600;
        publicPrice = 0.15 ether;
        publicPerUserMint = 5;
        openFreeMint = true;
        openFashionMint = true;
        openPioneerMint = true;
        openPublicMint = true;
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

    function setFashionMint(uint256 _fashionStartTime,uint256 _fashionEndTime,uint256 _fashionPrice,uint256 _fashionPerUserMint,uint256 _fashionMaxCount) external onlyOwner {
        fashionStartTime = _fashionStartTime;
        fashionEndTime = _fashionEndTime;
        fashionPrice = _fashionPrice;
        fashionPerUserMint= _fashionPerUserMint;
        fashionMaxCount = _fashionMaxCount;
    }

    function setPioneerMint(uint256 _pioneerStartTime,uint256 _pioneerEndTime,uint256 _pioneerPrice,uint256 _pioneerPerUserMint,uint256 _pioneerMaxCount) external onlyOwner {
        pioneerStartTime = _pioneerStartTime;
        pioneerEndTime = _pioneerEndTime;
        pioneerPrice = _pioneerPrice;
        pioneerPerUserMint= _pioneerPerUserMint;
        pioneerMaxCount = _pioneerMaxCount;
    }


    function setPublicMint(uint256 _publicStartTime, uint256 _publicEndTime, uint256 _publicPrice, uint256 _publicPerUserMint) external onlyOwner {
        publicStartTime = _publicStartTime;
        publicEndTime = _publicEndTime;
        publicPrice = _publicPrice;
        publicPerUserMint = _publicPerUserMint;
    }

    function setMintStatus(bool _openFreeMint,bool _openFashionMint, bool _openPioneerMint, bool _openPublicMint) external onlyOwner {
        openFreeMint = _openFreeMint;
        openFashionMint = _openFashionMint;
        openPioneerMint = _openPioneerMint;
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

    function setMerkleRoot(bytes32 _freeRoot, bytes32 _fashionRoot, bytes32 _pioneerRoot) external onlyOwner {
        freeMerkleRoot = _freeRoot;
        fashionMerkleRoot = _fashionRoot;
        pioneerMerkleRoot = _pioneerRoot;
    }

    function earlySupporterMint( bytes32 root,bytes32[] calldata proof,uint256 quantity) external payable callerIsUser {
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

    function fashionMint( bytes32 root,bytes32[] calldata proof,uint256 quantity) external payable callerIsUser {
        require(openFashionMint == true,"Sale phase mismatch");
        require(fashionStartTime < block.timestamp,"Sale no start");
        require(fashionEndTime > block.timestamp,"Sale end");
        require(salePhaseMinted[SalePhase.Fashion] + quantity <= fashionMaxCount,"Exceeds phase limit");

        uint256 remainFreeCount = freeMaxCount - salePhaseMinted[SalePhase.Free];
        require(_totalMinted() + remainFreeCount + quantity <= totalQuantity,"Max supply reached");

        uint256 walletMinted = mintedCount[SalePhase.Fashion][msg.sender];
        require(fashionPerUserMint - walletMinted >= quantity,"Exceeds personal limit");
        require(msg.value >= fashionPrice * quantity, "Incorrect price");
        require (fashionMerkleRoot == root, "Invalid merkle root");
        require(MerkleProof.verify(proof, root, keccak256(abi.encodePacked(msg.sender))),"Invalid proof");
        mintedCount[SalePhase.Fashion][msg.sender] += quantity;  
        salePhaseMinted[SalePhase.Fashion] += quantity;  
        _safeMint(msg.sender, quantity);
    }


    function pioneerMint( bytes32 root,bytes32[] calldata proof,uint256 quantity) external payable callerIsUser {
        require(openPioneerMint == true,"Sale phase mismatch.");
        require(pioneerStartTime < block.timestamp,"Sale no start");
        require(pioneerEndTime > block.timestamp,"Sale end");
        require(salePhaseMinted[SalePhase.Pioneer] + quantity <= pioneerMaxCount,"Exceeds phase limit");

        uint256 remainFreeCount = freeMaxCount - salePhaseMinted[SalePhase.Free];
        require(_totalMinted() + remainFreeCount + quantity <= totalQuantity,"Max supply reached");

        uint256 walletMinted = mintedCount[SalePhase.Pioneer][msg.sender];
        require(pioneerPerUserMint - walletMinted >= quantity,"Exceeds personal limit");
        require(msg.value >= pioneerPrice * quantity, "Incorrect price");
        require (pioneerMerkleRoot == root, "Invalid merkle root");
        require(MerkleProof.verify(proof, root, keccak256(abi.encodePacked(msg.sender))),"Invalid proof");
        mintedCount[SalePhase.Pioneer][msg.sender] += quantity;
        salePhaseMinted[SalePhase.Pioneer] += quantity;
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
            fashionStartTime,
            fashionEndTime,
            fashionPrice,
            fashionPerUserMint,
            fashionMaxCount,
            pioneerStartTime,
            pioneerEndTime,
            pioneerPrice,
            pioneerPerUserMint,
            pioneerMaxCount,
            publicStartTime,
            publicEndTime,
            publicPrice,
            publicPerUserMint
        );
    }

    function getMintedInfo(address _address) external view
    returns (
            uint256 _freeMinted,
            uint256 _fashionMinted,
            uint256 _pioneerMinted,
            uint256 _publicMinted,
            uint256 _totalMinted,
            uint256 _totalQuantity,
            bool _openFreeMint,
            bool _openFashionMint,
            bool _openPioneerMint,
            bool _openPublicMint
    ){
        return (
            mintedCount[SalePhase.Free][_address],
            mintedCount[SalePhase.Fashion][_address],
            mintedCount[SalePhase.Pioneer][_address],
            mintedCount[SalePhase.Public][_address],
            totalMinted(),
            totalQuantity,
            openFreeMint,
            openFashionMint,
            openPioneerMint,
            openPublicMint
        );
    }
}